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
        /// No article could be fetched for the seeds, for example without network, or the run was
        /// stopped by a settings change or by the time budget. The previous list is kept.
        case recommendationsUnavailable
    }

    public static let shared = WMFDiscoverReadingListDataController()

    /// The `gsrlimit` the related pages request uses. A seed whose results are all used up moves its offset by this much.
    static let relatedPagesPageSize = WMFRelatedPagesDataController.maximumPageLimit

    /// How many related pages requests may come back without a new article before generation gives up on the network.
    static let maximumEmptyAttempts = 10

    /// The time one generation may take. Other wikis answer `morelike:` searches slower than
    /// English Wikipedia, and a run that goes over the budget stops and keeps the previous list.
    public static let defaultGenerationTimeout: Duration = .seconds(30)

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

        var key: String { "\(project.id)|\(title.normalizedForCoreData)" }
    }

    private let injectedCoreDataStore: WMFCoreDataStore?
    private let injectedUserDefaultsStore: WMFKeyValueStore?
    let relatedPagesDataController: WMFRelatedPagesDataController
    let interestsDataController: WMFDiscoverInterestsDataController
    let homeDataController: WMFHomeDataController
    let calendar: Calendar
    let generationTimeout: Duration
    /// Receives `discoverListStateDidChange`. A test gives the controller and the view models their own center.
    let notificationCenter: NotificationCenter

    /// Stores default to the environment at call time, because the Core Data store is created
    /// asynchronously during launch and may not exist yet when `shared` is first touched.
    /// The interests controller reads the same user defaults store as this controller unless one is injected.
    public init(coreDataStore: WMFCoreDataStore? = nil, userDefaultsStore: WMFKeyValueStore? = nil, relatedPagesDataController: WMFRelatedPagesDataController = .shared, interestsDataController: WMFDiscoverInterestsDataController? = nil, homeDataController: WMFHomeDataController = .shared, calendar: Calendar = .current, generationTimeout: Duration = WMFDiscoverReadingListDataController.defaultGenerationTimeout, notificationCenter: NotificationCenter = .default) {
        self.injectedCoreDataStore = coreDataStore
        self.injectedUserDefaultsStore = userDefaultsStore
        self.relatedPagesDataController = relatedPagesDataController
        self.interestsDataController = interestsDataController ?? WMFDiscoverInterestsDataController(coreDataStore: coreDataStore, userDefaultsStore: userDefaultsStore)
        self.homeDataController = homeDataController
        self.calendar = calendar
        self.generationTimeout = generationTimeout
        self.notificationCenter = notificationCenter
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

    /// Persists the settings. A new source or a new article count throws the current list away
    /// on the next generation check, like on Android, and stops a generation in flight, so Undo on
    /// the source toast never lets a list for the undone source land. A new cadence keeps the
    /// current list. A changed setting posts `discoverListStateDidChange`, so the Saved tab follows
    /// the switch at once.
    public func saveSettings(_ newSettings: WMFDiscoverSettings) throws {
        guard let userDefaultsStore else {
            throw DiscoverReadingListError.missingUserDefaultsStore
        }

        let currentSettings = settings
        guard currentSettings != newSettings else {
            return
        }
        try userDefaultsStore.save(key: WMFUserDefaultsKey.discoverSettings.rawValue, value: newSettings)
        if currentSettings.source != newSettings.source || currentSettings.articleCount != newSettings.articleCount || currentSettings.isEnabled != newSettings.isEnabled {
            cancelGeneration()
        }
        postListStateDidChange()
    }

    /// Turns Discover off and throws the list and its schedule away. The other settings stay, so a
    /// later turn on builds the list the same way. The onboarding toast shows again on that list.
    public func turnOff() async throws {
        var newSettings = settings
        newSettings.isEnabled = false
        try saveSettings(newSettings)
        try await deleteAllRecommendations()
        try? userDefaultsStore?.remove(key: WMFUserDefaultsKey.discoverOnboardingToastShown.rawValue)
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

    // MARK: - Unseen list

    /// True from the moment a list is generated until the reader opens it. The Saved tab shows a
    /// dot on the entry card and on the tab icon while it is true, like the Android app.
    public var hasUnseenList: Bool {
        let storedFlag: Bool? = try? userDefaultsStore?.load(key: WMFUserDefaultsKey.discoverHasUnseenList.rawValue)
        return storedFlag ?? false
    }

    /// Clears the unseen flag. Call it when the reader opens the list.
    public func markCurrentListSeen() throws {
        guard let userDefaultsStore else {
            throw DiscoverReadingListError.missingUserDefaultsStore
        }
        guard hasUnseenList else {
            return
        }
        try userDefaultsStore.remove(key: WMFUserDefaultsKey.discoverHasUnseenList.rawValue)
        postListStateDidChange()
    }

    private func postListStateDidChange() {
        notificationCenter.post(name: WMFNSNotification.discoverListStateDidChange, object: nil)
    }

    // MARK: - Schedule

    public var lastGeneratedDate: Date? {
        let storedDate: Date? = try? userDefaultsStore?.load(key: WMFUserDefaultsKey.discoverLastGeneratedDate.rawValue)
        return storedDate
    }

    /// What a list is built from. The inputs of the current list are stored with it, so a change
    /// undone before the next check keeps the list, and a change made while a run goes on still
    /// regenerates on the next check. The interests count for every source, so an interests edit
    /// makes the next check regenerate even when the source is saved or history.
    struct GenerationInputs: Codable, Equatable, Sendable {
        let source: WMFDiscoverSource
        let articleCount: Int
        let interests: WMFDiscoverInterests
    }

    private func currentGenerationInputs() async throws -> GenerationInputs {
        let settings = settings
        return GenerationInputs(source: settings.source, articleCount: settings.articleCount, interests: try await interestsDataController.fetchInterests())
    }

    /// True when the source, the article count or the interests differ from the ones the current list was built from.
    func needsRegeneration() async throws -> Bool {
        let storedInputs: GenerationInputs? = try? userDefaultsStore?.load(key: WMFUserDefaultsKey.discoverGeneratedListInputs.rawValue)
        return try await storedInputs != currentGenerationInputs()
    }

    /// True when there is no list yet, the source, the article count or the interests changed, or the cadence's next date has arrived.
    public func isGenerationDue(now: Date = Date()) async throws -> Bool {
        if try await needsRegeneration() {
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
            return try await list(from: generationTask)
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

    /// The run that a settings change stopped. It can still be inside a write, so the next run
    /// starts its work after it ends.
    private var stoppedGenerationTask: Task<[WMFDiscoverRecommendedPage], Error>?

    /// True while a list is generated. The Saved tab shows the card in its generating state.
    public var isGenerating: Bool {
        generationTask != nil
    }

    /// Replaces the current list with a new one.
    ///
    /// The previous list is expired, not deleted, so its articles are not recommended again and can
    /// fill the new list when the network gives too few new articles. Throws without touching the
    /// previous list when the source has nothing to seed from or when the network gives no article
    /// at all, so an empty list is never stored. The actor is reentrant at every `await`, so a call
    /// that arrives while a generation runs joins that run and gets its list.
    ///
    /// The run posts `discoverListStateDidChange` when it starts and when it ends, so the Saved tab
    /// can show and hide the generating state. A run over `generationTimeout` stops and throws
    /// `recommendationsUnavailable`.
    @discardableResult
    public func generateRecommendations(now: Date = Date()) async throws -> [WMFDiscoverRecommendedPage] {
        if let generationTask {
            return try await list(from: generationTask)
        }

        let stoppedGenerationTask = self.stoppedGenerationTask
        let generationTask = Task {
            if let stoppedGenerationTask {
                _ = try? await stoppedGenerationTask.value
                if self.stoppedGenerationTask == stoppedGenerationTask {
                    self.stoppedGenerationTask = nil
                }
            }
            return try await fetchAndPersistList(now: now)
        }
        self.generationTask = generationTask
        postListStateDidChange()

        let timeoutTask = Task { [generationTimeout] in
            try await Task.sleep(for: generationTimeout)
            generationTask.cancel()
        }
        defer {
            timeoutTask.cancel()
            finishGeneration(generationTask)
        }

        return try await list(from: generationTask)
    }

    /// A stopped run reads as an unavailable list, so every caller keeps the previous list.
    private func list(from generationTask: Task<[WMFDiscoverRecommendedPage], Error>) async throws -> [WMFDiscoverRecommendedPage] {
        do {
            return try await generationTask.value
        } catch is CancellationError {
            throw DiscoverReadingListError.recommendationsUnavailable
        }
    }

    /// Clears the run when it is still the one in flight, then tells the observers that it ended.
    /// A settings change that stopped the run cleared it and posted already.
    private func finishGeneration(_ generationTask: Task<[WMFDiscoverRecommendedPage], Error>) {
        guard self.generationTask == generationTask else {
            return
        }
        self.generationTask = nil
        postListStateDidChange()
    }

    private func cancelGeneration() {
        guard let generationTask else { return }
        
        generationTask.cancel()
        stoppedGenerationTask = generationTask
        self.generationTask = nil
    }

    private func fetchAndPersistList(now: Date) async throws -> [WMFDiscoverRecommendedPage] {
        let inputs = try await currentGenerationInputs()
        let targetCount = inputs.articleCount

        let seeds = try await fetchSeeds(source: inputs.source, count: targetCount)
        guard !seeds.isEmpty else {
            throw DiscoverReadingListError.sourceHasNoArticles(inputs.source)
        }

        let previouslyRecommended = try await fetchStoredRecommendations(includeExpired: true)
        var excludedKeys = Set(previouslyRecommended.map(\.key))
        let picks = try await pickCandidates(seeds: seeds, targetCount: targetCount, excludedKeys: &excludedKeys)
        guard picks.didGetAResponse else {
            throw DiscoverReadingListError.recommendationsUnavailable
        }

        var picked = picks.candidates
        if picked.count < targetCount {
            let pickedKeys = Set(picked.map(\.key))
            let revived = previouslyRecommended
                .filter { !pickedKeys.contains($0.key) }
                .shuffled()
                .prefix(targetCount - picked.count)
                .compactMap(Candidate.init(stored:))
            picked.append(contentsOf: revived)
        }
        guard !picked.isEmpty else {
            throw DiscoverReadingListError.recommendationsUnavailable
        }

        let orderedList = Array(picked.shuffled().prefix(targetCount))

        // A stopped run must not touch the previous list.
        try Task.checkCancellation()
        try await replaceRecommendations(with: orderedList, now: now)

        try userDefaultsStore?.save(key: WMFUserDefaultsKey.discoverGeneratedListInputs.rawValue, value: inputs)
        try userDefaultsStore?.save(key: WMFUserDefaultsKey.discoverLastGeneratedDate.rawValue, value: now)
        try userDefaultsStore?.save(key: WMFUserDefaultsKey.discoverHasUnseenList.rawValue, value: true)

        return try await fetchCurrentRecommendations()
    }

    struct Picks {
        var candidates: [Candidate] = []
        /// False when every related pages request failed, for example without network. Then the
        /// generation cannot tell new articles from used-up ones and gives up.
        var didGetAResponse = false
    }

    /// Walks the seeds round-robin, taking a share of each seed's related pages until the list is full
    /// or the network stops producing unseen articles.
    private func pickCandidates(seeds: [Seed], targetCount: Int, excludedKeys: inout Set<String>) async throws -> Picks {
        var picks = Picks()
        var seedOffsets = loadSeedOffsets()
        var emptyAttempts = 0
        var seedIndex = 0

        let candidatesPerSeed = max(1, Int((Double(targetCount) / Double(seeds.count)).rounded(.up)))

        while picks.candidates.count < targetCount && emptyAttempts < Self.maximumEmptyAttempts {
            try Task.checkCancellation()
            let seed = seeds[seedIndex % seeds.count]
            seedIndex += 1

            let offset = seedOffsets[seed.key] ?? 0
            let relatedPages: [WMFRelatedPagesDataController.WMFRelatedPage]
            do {
                // The list shows no extract, and the extracts make one request many times slower.
                relatedPages = try await relatedPagesDataController.fetchRelatedPages(title: seed.title, project: seed.project, limit: Self.relatedPagesPageSize, offset: offset, includesExtracts: false)
                picks.didGetAResponse = true
            } catch {
                relatedPages = []
            }

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
                picks.candidates.append(candidate)
                excludedKeys.insert(candidate.key)
            }
        }

        saveSeedOffsets(seedOffsets)
        return picks
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
        try? userDefaultsStore?.remove(key: WMFUserDefaultsKey.discoverGeneratedListInputs.rawValue)
        try? userDefaultsStore?.remove(key: WMFUserDefaultsKey.discoverHasUnseenList.rawValue)
        postListStateDidChange()
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
            recommendedDate: stored.timestamp
        )
    }
}

extension WMFDiscoverReadingListDataController.Candidate {

    init(relatedPage: WMFRelatedPagesDataController.WMFRelatedPage, project: WMFProject) {
        self.init(title: relatedPage.title, displayTitle: relatedPage.displayTitle, project: project, description: relatedPage.description, thumbnailURL: relatedPage.thumbnailURL)
    }

    init?(stored: WMFDiscoverReadingListDataController.StoredRecommendation) {
        guard let project = WMFProject(id: stored.projectID) else {
            return nil
        }

        self.init(title: stored.title.underscoresToSpaces, displayTitle: stored.displayTitle, project: project, description: stored.description, thumbnailURL: stored.thumbnailURLString.flatMap { URL(string: $0) })
    }
}
