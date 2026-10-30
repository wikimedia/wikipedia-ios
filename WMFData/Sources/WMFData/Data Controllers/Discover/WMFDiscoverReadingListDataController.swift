import Foundation

/// Generates and stores the Discover reading list.
///
/// The behaviour mirrors the Android app: seed articles come from the reader's interests, saved
/// articles or reading history, each seed is expanded with a `morelike:` search on the seed's own
/// wiki, articles already recommended once are never recommended again, and the list is kept locally
/// and never synced.
public actor WMFDiscoverReadingListDataController {

    public enum DiscoverReadingListError: Error, Equatable {
        case missingUserDefaultsStore
        /// The selected source has no articles to seed the list with.
        case sourceHasNoArticles(WMFDiscoverSource)
    }

    public static let shared = WMFDiscoverReadingListDataController()

    /// The `gsrlimit` the related pages request uses. A seed whose results are all used up moves its offset by this much.
    /// Kept at the TextExtracts maximum, so every page comes with its extract.
    static let relatedPagesPageSize = WMFRelatedPagesDataController.maximumPageLimit

    /// How many related pages requests may come back without a new article before generation gives up on the network.
    static let maximumEmptyAttempts = 10

    struct Seed: Hashable, Sendable {
        let title: String
        let project: WMFProject

        var key: String { "\(project.id)|\(title.normalizedForCoreData)" }
    }

    struct Candidate: Sendable {
        let title: String
        let displayTitle: String?
        let project: WMFProject
        let description: String?
        let thumbnailURL: URL?
        let extract: String?

        var key: String { "\(project.id)|\(title.normalizedForCoreData)" }
    }

    private let injectedCoreDataStore: WMFCoreDataStore?
    private let injectedUserDefaultsStore: WMFKeyValueStore?
    let relatedPagesDataController: WMFRelatedPagesDataController
    let calendar: Calendar

    /// Stores default to the environment at call time, because the Core Data store is created
    /// asynchronously during launch and may not exist yet when `shared` is first touched.
    public init(coreDataStore: WMFCoreDataStore? = nil, userDefaultsStore: WMFKeyValueStore? = nil, relatedPagesDataController: WMFRelatedPagesDataController = .shared, calendar: Calendar = .current) {
        self.injectedCoreDataStore = coreDataStore
        self.injectedUserDefaultsStore = userDefaultsStore
        self.relatedPagesDataController = relatedPagesDataController
        self.calendar = calendar
    }

    var coreDataStore: WMFCoreDataStore? {
        injectedCoreDataStore ?? WMFDataEnvironment.current.coreDataStore
    }

    var userDefaultsStore: WMFKeyValueStore? {
        injectedUserDefaultsStore ?? WMFDataEnvironment.current.userDefaultsStore
    }

    // MARK: - Settings

    public var settings: WMFDiscoverSettings {
        let storedSettings: WMFDiscoverSettings? = try? userDefaultsStore?.load(key: WMFUserDefaultsKey.discoverSettings.rawValue)
        return storedSettings ?? .default
    }

    /// Persists the settings. Changing the source throws the current list away on the next generation check, like on Android.
    public func saveSettings(_ newSettings: WMFDiscoverSettings) throws {
        guard let userDefaultsStore else {
            throw DiscoverReadingListError.missingUserDefaultsStore
        }

        let previousSettings = settings
        try userDefaultsStore.save(key: WMFUserDefaultsKey.discoverSettings.rawValue, value: newSettings)

        if previousSettings.source != newSettings.source {
            try userDefaultsStore.save(key: WMFUserDefaultsKey.discoverNeedsRegeneration.rawValue, value: true)
        }
    }

    // MARK: - Onboarding

    /// True after the reader has seen the toast that explains the list on their first visit.
    public var hasShownOnboardingToast: Bool {
        let storedFlag: Bool? = try? userDefaultsStore?.load(key: WMFUserDefaultsKey.discoverOnboardingToastShown.rawValue)
        return storedFlag ?? false
    }

    public func markOnboardingToastShown() throws {
        guard let userDefaultsStore else {
            throw DiscoverReadingListError.missingUserDefaultsStore
        }
        try userDefaultsStore.save(key: WMFUserDefaultsKey.discoverOnboardingToastShown.rawValue, value: true)
    }

    // MARK: - Schedule

    public var lastGeneratedDate: Date? {
        let storedDate: Date? = try? userDefaultsStore?.load(key: WMFUserDefaultsKey.discoverLastGeneratedDate.rawValue)
        return storedDate
    }

    var needsRegeneration: Bool {
        let storedFlag: Bool? = try? userDefaultsStore?.load(key: WMFUserDefaultsKey.discoverNeedsRegeneration.rawValue)
        return storedFlag ?? false
    }

    /// True when there is no list yet, the source changed, or the cadence's next date has arrived.
    public func isGenerationDue(now: Date = Date()) async throws -> Bool {
        if needsRegeneration {
            return true
        }

        let storedRecommendations = try await fetchStoredRecommendations(includeExpired: false)
        guard !storedRecommendations.isEmpty else {
            return true
        }

        return WMFDiscoverSchedule.isGenerationDue(cadence: settings.cadence, lastGeneratedDate: lastGeneratedDate, now: now, calendar: calendar)
    }

    /// Generates a new list when one is due, and returns the current list either way.
    public func generateRecommendationsIfNeeded(now: Date = Date()) async throws -> [WMFDiscoverRecommendedPage] {
        if let generationTask {
            return try await generationTask.value
        }

        guard try await isGenerationDue(now: now) else {
            return try await fetchCurrentRecommendations()
        }

        return try await generateRecommendations(now: now)
    }

    // MARK: - Reading

    /// The current list, in display order.
    public func fetchCurrentRecommendations() async throws -> [WMFDiscoverRecommendedPage] {
        try await fetchStoredRecommendations(includeExpired: false).compactMap(WMFDiscoverRecommendedPage.init(stored:))
    }

    /// Articles from previous lists. They are kept so they are never recommended twice.
    public func fetchExpiredRecommendations() async throws -> [WMFDiscoverRecommendedPage] {
        try await fetchStoredRecommendations(includeExpired: true)
            .filter(\.isExpired)
            .compactMap(WMFDiscoverRecommendedPage.init(stored:))
    }

    // MARK: - Generation

    /// The generation in flight. Overlapping callers wait for it instead of starting a second one.
    private var generationTask: Task<[WMFDiscoverRecommendedPage], Error>?

    /// Replaces the current list with a new one.
    ///
    /// The previous list is expired, not deleted, so its articles are not recommended again and can
    /// fill the new list when the network gives too few new articles. Throws without touching the
    /// previous list when the source has nothing to seed from. The actor is reentrant at every
    /// `await`, so a call that arrives while a generation runs joins that run and gets its list.
    @discardableResult
    public func generateRecommendations(now: Date = Date()) async throws -> [WMFDiscoverRecommendedPage] {
        if let generationTask {
            return try await generationTask.value
        }

        let generationTask = Task { try await performGeneration(now: now) }
        self.generationTask = generationTask
        defer { self.generationTask = nil }

        return try await generationTask.value
    }

    private func performGeneration(now: Date) async throws -> [WMFDiscoverRecommendedPage] {
        let settings = settings
        let targetCount = settings.articleCount

        let seeds = try await fetchSeeds(source: settings.source, count: targetCount)
        guard !seeds.isEmpty else {
            throw DiscoverReadingListError.sourceHasNoArticles(settings.source)
        }

        try await expireAllRecommendations()

        let previouslyRecommended = try await fetchStoredRecommendations(includeExpired: true)
        var excludedKeys = Set(previouslyRecommended.map(\.key))
        var picked = try await pickCandidates(seeds: seeds, targetCount: targetCount, excludedKeys: &excludedKeys)

        if picked.count < targetCount {
            let pickedKeys = Set(picked.map(\.key))
            let revived = previouslyRecommended
                .filter { !pickedKeys.contains($0.key) }
                .shuffled()
                .prefix(targetCount - picked.count)
                .compactMap(Candidate.init(stored:))
            picked.append(contentsOf: revived)
        }

        let orderedList = Array(picked.shuffled().prefix(targetCount))
        try await persistGeneratedList(orderedList, now: now)

        try userDefaultsStore?.save(key: WMFUserDefaultsKey.discoverLastGeneratedDate.rawValue, value: now)
        try userDefaultsStore?.remove(key: WMFUserDefaultsKey.discoverNeedsRegeneration.rawValue)

        return try await fetchCurrentRecommendations()
    }

    /// Walks the seeds round-robin, taking a share of each seed's related pages until the list is full
    /// or the network stops producing unseen articles.
    private func pickCandidates(seeds: [Seed], targetCount: Int, excludedKeys: inout Set<String>) async throws -> [Candidate] {
        var picked: [Candidate] = []
        var seedOffsets = loadSeedOffsets()
        var emptyAttempts = 0
        var seedIndex = 0

        let candidatesPerSeed = max(1, Int((Double(targetCount) / Double(seeds.count)).rounded(.up)))

        while picked.count < targetCount && emptyAttempts < Self.maximumEmptyAttempts {
            let seed = seeds[seedIndex % seeds.count]
            seedIndex += 1

            let offset = seedOffsets[seed.key] ?? 0
            let relatedPages = (try? await relatedPagesDataController.fetchRelatedPages(title: seed.title, project: seed.project, limit: Self.relatedPagesPageSize, offset: offset)) ?? []

            let unseen = relatedPages
                .map { Candidate(relatedPage: $0, project: seed.project) }
                .filter { !excludedKeys.contains($0.key) }

            guard !unseen.isEmpty else {
                if relatedPages.count >= Self.relatedPagesPageSize {
                    seedOffsets[seed.key] = offset + Self.relatedPagesPageSize
                }
                emptyAttempts += 1
                continue
            }

            for candidate in unseen.prefix(candidatesPerSeed) {
                picked.append(candidate)
                excludedKeys.insert(candidate.key)
            }
        }

        saveSeedOffsets(seedOffsets)
        return picked
    }

    private func loadSeedOffsets() -> [String: Int] {
        let storedOffsets: [String: Int]? = try? userDefaultsStore?.load(key: WMFUserDefaultsKey.discoverSeedOffsets.rawValue)
        return storedOffsets ?? [:]
    }

    private func saveSeedOffsets(_ offsets: [String: Int]) {
        try? userDefaultsStore?.save(key: WMFUserDefaultsKey.discoverSeedOffsets.rawValue, value: offsets)
    }

    // MARK: - Reset

    /// Deletes every stored recommendation and the schedule, so the next check generates a fresh list.
    public func deleteAllRecommendations() async throws {
        try await deleteStoredRecommendations()
        try? userDefaultsStore?.remove(key: WMFUserDefaultsKey.discoverLastGeneratedDate.rawValue)
        try? userDefaultsStore?.remove(key: WMFUserDefaultsKey.discoverSeedOffsets.rawValue)
        try? userDefaultsStore?.remove(key: WMFUserDefaultsKey.discoverNeedsRegeneration.rawValue)
    }
}

extension WMFDiscoverRecommendedPage {

    init?(stored: WMFDiscoverReadingListDataController.StoredRecommendation) {
        guard let project = WMFProject(id: stored.projectID) else {
            return nil
        }

        self.init(
            title: stored.title.underscoresToSpaces,
            displayTitle: stored.displayTitle,
            project: project,
            description: stored.description,
            thumbnailURL: stored.thumbnailURLString.flatMap { URL(string: $0) },
            extract: stored.extract,
            recommendedDate: stored.timestamp
        )
    }
}

extension WMFDiscoverReadingListDataController.Candidate {

    init(relatedPage: WMFRelatedPagesDataController.WMFRelatedPage, project: WMFProject) {
        self.init(title: relatedPage.title, displayTitle: relatedPage.displayTitle, project: project, description: relatedPage.description, thumbnailURL: relatedPage.thumbnailURL, extract: relatedPage.extract)
    }

    init?(stored: WMFDiscoverReadingListDataController.StoredRecommendation) {
        guard let project = WMFProject(id: stored.projectID) else {
            return nil
        }

        self.init(title: stored.title.underscoresToSpaces, displayTitle: stored.displayTitle, project: project, description: stored.description, thumbnailURL: stored.thumbnailURLString.flatMap { URL(string: $0) }, extract: stored.extract)
    }
}
