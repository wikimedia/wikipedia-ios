import Foundation

public final actor WMFHomeDataController {

    private let feedDataController: any WMFFeedDataControlling
    private let basicService: WMFService?
    private let relatedPagesDataController: WMFRelatedPagesDataController
    private let savedArticlesDataController: WMFSavedArticlesDataController
    private let onThisDayDataController: WMFOnThisDayDataController

    private var pageInterestDataController: WMFPageInterestDataController? {
        try? WMFPageInterestDataController()
    }

    private var pageViewsDataController: WMFPageViewsDataController? {
        try? WMFPageViewsDataController()
    }

    // Accessed only from `nonisolated` UserDefaults helpers below; WMFKeyValueStore is not Sendable.
    nonisolated(unsafe) private let userDefaultsStore: WMFKeyValueStore?

    // Dates for which feed data has been fetched per project, in descending order (most recent first).
    private var communityFetchedDates: [WMFProject: [Date]] = [:]

    public static let shared = WMFHomeDataController()

    public init(feedDataController: any WMFFeedDataControlling = WMFFeedDataController.shared, basicService: WMFService? = WMFDataEnvironment.current.basicService, userDefaultsStore: WMFKeyValueStore? = WMFDataEnvironment.current.userDefaultsStore, relatedPagesDataController: WMFRelatedPagesDataController = WMFRelatedPagesDataController.shared, savedArticlesDataController: WMFSavedArticlesDataController = WMFSavedArticlesDataController.shared, onThisDayDataController: WMFOnThisDayDataController = WMFOnThisDayDataController.shared) {
        self.feedDataController = feedDataController
        self.basicService = basicService
        self.userDefaultsStore = userDefaultsStore
        self.relatedPagesDataController = relatedPagesDataController
        self.savedArticlesDataController = savedArticlesDataController
        self.onThisDayDataController = onThisDayDataController
    }
    
    // MARK: - Settings: New Install Onboarding

    public nonisolated func didSendNewInstallOnboardingStartEvent() -> Bool {
        return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.didSendNewInstallOnboardingStartEvent.rawValue)) ?? false
    }

    public nonisolated func setDidSendNewInstallOnboardingStartEvent(_ newValue: Bool) {
        try? userDefaultsStore?.save(key: WMFUserDefaultsKey.didSendNewInstallOnboardingStartEvent.rawValue, value: newValue)
    }

    public nonisolated func hasSeenNewHomeOnboarding() -> Bool {
        return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.hasSeenNewHomeOnboarding.rawValue)) ?? false
    }

    public nonisolated func setHasSeenNewHomeOnboarding(_ newValue: Bool) {
        try? userDefaultsStore?.save(key: WMFUserDefaultsKey.hasSeenNewHomeOnboarding.rawValue, value: newValue)
    }

    // MARK: - Settings: Selected Language

    public nonisolated func selectedLanguage() -> WMFLanguage? {
        return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.homeSelectedLanguage.rawValue)) ?? nil
    }

    public nonisolated func setSelectedLanguage(_ newValue: WMFLanguage) {
        try? userDefaultsStore?.save(key: WMFUserDefaultsKey.homeSelectedLanguage.rawValue, value: newValue)
    }

    // MARK: - Settings: See first content preference

    /// Which content the Home feed shows first, chosen during app onboarding.
    public nonisolated func seeFirstContent() -> WMFHomeFeedSeeFirst {
        return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.homeFeedSeeFirst.rawValue)) ?? .community
    }

    public nonisolated func setSeeFirstContent(_ newValue: WMFHomeFeedSeeFirst) {
        try? userDefaultsStore?.save(key: WMFUserDefaultsKey.homeFeedSeeFirst.rawValue, value: newValue)
    }

    // MARK: - Settings: Community Modules

    public nonisolated func communityFeaturedArticleIsOn() -> Bool {
        return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.homeFeedCommunityFeaturedArticleIsOn.rawValue)) ?? true
    }

    public nonisolated func setCommunityFeaturedArticleIsOn(_ newValue: Bool) {
        try? userDefaultsStore?.save(key: WMFUserDefaultsKey.homeFeedCommunityFeaturedArticleIsOn.rawValue, value: newValue)
        NotificationCenter.default.post(name: WMFNSNotification.communityModuleVisibilityDidChange, object: nil)
    }

    public nonisolated func communityTopReadIsOn() -> Bool {
        return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.homeFeedCommunityTopReadIsOn.rawValue)) ?? true
    }

    public nonisolated func setCommunityTopReadIsOn(_ newValue: Bool) {
        try? userDefaultsStore?.save(key: WMFUserDefaultsKey.homeFeedCommunityTopReadIsOn.rawValue, value: newValue)
        NotificationCenter.default.post(name: WMFNSNotification.communityModuleVisibilityDidChange, object: nil)
    }

    public nonisolated func communityInTheNewsIsOn() -> Bool {
        return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.homeFeedCommunityInTheNewsIsOn.rawValue)) ?? true
    }

    public nonisolated func setCommunityInTheNewsIsOn(_ newValue: Bool) {
        try? userDefaultsStore?.save(key: WMFUserDefaultsKey.homeFeedCommunityInTheNewsIsOn.rawValue, value: newValue)
        NotificationCenter.default.post(name: WMFNSNotification.communityModuleVisibilityDidChange, object: nil)
    }

    public nonisolated func communityOnThisDayIsOn() -> Bool {
        return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.homeFeedCommunityOnThisDayIsOn.rawValue)) ?? true
    }

    public nonisolated func setCommunityOnThisDayIsOn(_ newValue: Bool) {
        try? userDefaultsStore?.save(key: WMFUserDefaultsKey.homeFeedCommunityOnThisDayIsOn.rawValue, value: newValue)
        NotificationCenter.default.post(name: WMFNSNotification.communityModuleVisibilityDidChange, object: nil)
    }

    public nonisolated func communityPictureOfTheDayIsOn() -> Bool {
        return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.homeFeedCommunityPictureOfTheDayIsOn.rawValue)) ?? true
    }

    public nonisolated func setCommunityPictureOfTheDayIsOn(_ newValue: Bool) {
        try? userDefaultsStore?.save(key: WMFUserDefaultsKey.homeFeedCommunityPictureOfTheDayIsOn.rawValue, value: newValue)
        NotificationCenter.default.post(name: WMFNSNotification.communityModuleVisibilityDidChange, object: nil)
    }

    // MARK: - Settings: For You Modules

    public nonisolated func forYouBasedOnInterestsIsOn() -> Bool {
        return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.homeFeedForYouBasedOnInterestsIsOn.rawValue)) ?? true
    }

    public nonisolated func setForYouBasedOnInterestsIsOn(_ newValue: Bool) {
        try? userDefaultsStore?.save(key: WMFUserDefaultsKey.homeFeedForYouBasedOnInterestsIsOn.rawValue, value: newValue)
        NotificationCenter.default.post(name: WMFNSNotification.forYouModuleVisibilityDidChange, object: nil)
    }

    public nonisolated func forYouBecauseYouReadIsOn() -> Bool {
        return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.homeFeedForYouBecauseYouReadIsOn.rawValue)) ?? true
    }

    public nonisolated func setForYouBecauseYouReadIsOn(_ newValue: Bool) {
        try? userDefaultsStore?.save(key: WMFUserDefaultsKey.homeFeedForYouBecauseYouReadIsOn.rawValue, value: newValue)
        NotificationCenter.default.post(name: WMFNSNotification.forYouModuleVisibilityDidChange, object: nil)
    }

    public nonisolated func forYouContinueReadingIsOn() -> Bool {
        return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.homeFeedForYouContinueReadingIsOn.rawValue)) ?? true
    }

    public nonisolated func setForYouContinueReadingIsOn(_ newValue: Bool) {
        try? userDefaultsStore?.save(key: WMFUserDefaultsKey.homeFeedForYouContinueReadingIsOn.rawValue, value: newValue)
        NotificationCenter.default.post(name: WMFNSNotification.forYouModuleVisibilityDidChange, object: nil)
    }

    // MARK: - Seen Articles

    /// How long an article that the user saw stays out of the feed.
    public static let seenArticleSuppressionDays = 30

    /// The largest number of seen articles that the app keeps. The oldest go away first.
    private static let maxSeenArticles = 1000

    private nonisolated func seenArticleKey(title: String, project: WMFProject) -> String {
        "\(project.id)_\(title.normalizedForDisplay)"
    }

    /// Records that the user saw this article. Call this only when a card is on the screen.
    public nonisolated func recordSeenArticle(title: String, project: WMFProject, date: Date = Date()) {
        var seen = storedSeenArticles()
        seen[seenArticleKey(title: title, project: project)] = date

        // Remove the articles that are too old, then the oldest of the others, so the list has a limit.
        seen = Self.removingExpired(seen, now: date)
        if seen.count > Self.maxSeenArticles {
            let newest = seen.sorted { $0.value > $1.value }.prefix(Self.maxSeenArticles)
            seen = Dictionary(uniqueKeysWithValues: newest.map { ($0.key, $0.value) })
        }

        try? userDefaultsStore?.save(key: WMFUserDefaultsKey.homeFeedSeenArticles.rawValue, value: seen)
    }

    /// The titles of the articles that the user saw in the suppression period, for one project.
    public nonisolated func seenArticleTitles(project: WMFProject, now: Date = Date()) -> Set<String> {
        let seen = Self.removingExpired(storedSeenArticles(), now: now)
        let prefix = "\(project.id)_"

        return Set(seen.keys.compactMap { key in
            guard key.hasPrefix(prefix) else { return nil }
            return String(key.dropFirst(prefix.count))
        })
    }

    private nonisolated func storedSeenArticles() -> [String: Date] {
        return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.homeFeedSeenArticles.rawValue)) ?? [:]
    }

    private nonisolated static func removingExpired(_ seen: [String: Date], now: Date) -> [String: Date] {
        guard let oldest = Calendar.current.date(byAdding: .day, value: -seenArticleSuppressionDays, to: now) else {
            return seen
        }
        return seen.filter { $0.value > oldest }
    }

    // MARK: - Settings: Hidden Cards

    private static let maxHiddenCardKeys = 100

    public nonisolated func hiddenCardKeys() -> [String] {
        return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.homeFeedHiddenCardKeys.rawValue)) ?? []
    }

    public nonisolated func hideCard(key: String) {
        var keys = hiddenCardKeys()
        guard !keys.contains(key) else { return }
        keys.append(key)
        if keys.count > Self.maxHiddenCardKeys {
            keys = Array(keys.dropFirst(keys.count - Self.maxHiddenCardKeys))
        }
        try? userDefaultsStore?.save(key: WMFUserDefaultsKey.homeFeedHiddenCardKeys.rawValue, value: keys)
    }

    public nonisolated func isCardHidden(key: String) -> Bool {
        return hiddenCardKeys().contains(key)
    }

    // MARK: - Settings: Interest Topics

    public nonisolated func interestTopics() -> [WMFArticleTopic] {
        let ids: [String] = (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.homeFeedInterestTopics.rawValue)) ?? []
        return ids.compactMap { WMFArticleTopic(rawValue: $0) }
    }

    public nonisolated func setInterestTopics(_ topics: [WMFArticleTopic]) {
        try? userDefaultsStore?.save(key: WMFUserDefaultsKey.homeFeedInterestTopics.rawValue, value: topics.map { $0.rawValue })
    }

    // MARK: - Public API

    public func fetchForYou(project: WMFProject, forceFetch: Bool = false) async throws -> WMFForYouResponse {
        guard WMFDataEnvironment.current.coreDataStore != nil else {
            throw WMFDataControllerError.coreDataStoreUnavailable
        }

        if !forceFetch, let cached = cachedForYouResponse(for: project) {
            return cached
        }

        let excluded = await excludedSuggestionTitles(project: project)

        async let interestTopicRandomArticles = fetchForYouInterestTopicRandomArticles(project: project, excluding: excluded)
        async let interestPageRelatedArticles = fetchForYouInterestPageRelatedArticles(project: project, excluding: excluded)
        async let becauseYouReadArticles = fetchForYouBecauseYouReadArticles(project: project, excluding: excluded)
        async let continueReading = fetchForYouContinueReading(project: project)
        let response = try await WMFForYouResponse(
            interestTopicRandomArticles: interestTopicRandomArticles,
            interestPageRelatedArticles: interestPageRelatedArticles,
            becauseYouReadArticles: becauseYouReadArticles,
            continueReadingArticles: continueReading
        )
        cacheForYouResponse(response, for: project)
        return response
    }

    /// The titles that must never be a suggestion: the articles of the user, and the articles they saw.
    private func excludedSuggestionTitles(project: WMFProject) async -> Set<String> {
        var titles: Set<String> = []

        if let pageInterestDataController,
           let interests = try? await pageInterestDataController.fetchPageInterests(project: project) {
            titles.formUnion(interests.map { $0.title.normalizedForDisplay })
        }

        // A new article is better than an article that the user saw in the last days.
        titles.formUnion(seenArticleTitles(project: project))

        return titles
    }


    /// Puts the articles that the app can suggest first, so that a module never becomes empty.
    private nonisolated func candidatesPreferringNotExcluded(_ articles: [WMFRelatedPagesDataController.WMFRelatedPage], excluding excluded: Set<String>) -> [WMFRelatedPagesDataController.WMFRelatedPage] {
        let allowed = articles.filter { !excluded.contains($0.title.normalizedForDisplay) }
        let rest = articles.filter { excluded.contains($0.title.normalizedForDisplay) }

        return allowed.shuffled() + rest.shuffled()
    }

    private func fetchForYouInterestTopicRandomArticles(project: WMFProject, excluding excluded: Set<String>) async throws -> [WMFForYouInterestTopicRandomArticles] {
        let topics = interestTopics().shuffled()
        guard !topics.isEmpty else { return [] }

        return try await withThrowingTaskGroup(of: WMFForYouInterestTopicRandomArticles.self) { group in
            for topic in topics {
                group.addTask {
                    let articles = try await self.fetchArticles(for: topic, project: project)
                    let allowed = articles.filter { !excluded.contains($0.title.normalizedForDisplay) }
                    // The topic search gives a new random group each time, thus this is only a safety net.
                    let candidates = allowed.count >= 4 ? allowed : articles
                    let mapped = await self.assignCardSlots(candidates)
                        .map { WMFForYouArticle(title: $0.title, project: project) }
                    return WMFForYouInterestTopicRandomArticles(topic: topic, articles: mapped)
                }
            }
            var results: [WMFForYouInterestTopicRandomArticles] = []
            for try await item in group { results.append(item) }
            return results
        }
    }

    private func fetchForYouInterestPageRelatedArticles(project: WMFProject, excluding excluded: Set<String>) async throws -> [WMFForYouInterestPageRelatedArticles] {
        guard let pageInterestDataController else { return [] }
        let interests = try await pageInterestDataController.fetchPageInterests(project: project)
        let selected = interests.shuffled()
        guard !selected.isEmpty else { return [] }

        return try await withThrowingTaskGroup(of: WMFForYouInterestPageRelatedArticles.self) { group in
            for interest in selected {
                group.addTask {
                    let related = try await self.relatedPagesDataController.fetchRelatedPages(title: interest.title, project: project)
                    let candidates = self.candidatesPreferringNotExcluded(related, excluding: excluded)
                    let mapped = candidates.prefix(4).map { WMFForYouArticle(title: $0.title, project: project) }
                    return WMFForYouInterestPageRelatedArticles(pageInterest: WMFForYouArticle(title: interest.title, project: project), articles: mapped)
                }
            }
            var results: [WMFForYouInterestPageRelatedArticles] = []
            for try await item in group { results.append(item) }
            return results
        }
    }
    
    private func assignCardSlots(_ articles: [WMFRelatedPagesDataController.WMFRelatedPage]) -> [WMFRelatedPagesDataController.WMFRelatedPage] {
        let withThumbnail = articles.filter { $0.thumbnailURL != nil }
        let withoutThumbnail = articles.filter { $0.thumbnailURL == nil }

        var imageQueue = withThumbnail.makeIterator()
        var textQueue = withoutThumbnail.makeIterator()

        func next(preferImage: Bool) -> WMFRelatedPagesDataController.WMFRelatedPage? {
            preferImage ? (imageQueue.next() ?? textQueue.next())
                        : (textQueue.next() ?? imageQueue.next())
        }

        return [
            next(preferImage: true),
            next(preferImage: true),
            next(preferImage: false),
            next(preferImage: true)
        ].compactMap { $0 }
    }
    
    private func assignCardSlots(_ articles: [WMFRandomArticle]) -> [WMFRandomArticle] {
        let withThumbnail = articles.filter { $0.thumbnail != nil }
            .sorted { ($0.index ?? Int.max) < ($1.index ?? Int.max) }
        let withoutThumbnail = articles.filter { $0.thumbnail == nil }
            .sorted { ($0.index ?? Int.max) < ($1.index ?? Int.max) }

        // Slot layout: 0 = image, 1 = image, 2 = text, 3 = image
        var imageQueue = withThumbnail.makeIterator()
        var textQueue = withoutThumbnail.makeIterator()

        func next(preferImage: Bool) -> WMFRandomArticle? {
            if preferImage {
                return imageQueue.next() ?? textQueue.next()
            } else {
                return textQueue.next() ?? imageQueue.next()
            }
        }

        return [
            next(preferImage: true),   // slot 0 — image
            next(preferImage: true),   // slot 1 — image
            next(preferImage: false),  // slot 2 — text
            next(preferImage: true)   // slot 3 — image
        ].compactMap { $0 }
    }

    private func fetchForYouBecauseYouReadArticles(project: WMFProject, excluding excluded: Set<String>) async throws -> WMFForYouBecauseYouReadArticles? {
        guard let pageViewsDataController else { return nil }
        // T427675:  Ensure freshness: instead of just taking the last article read, for every new explore day, take all articles that were read for 1+ minutes in the last month and randomly pick one as the seed
        var pages = try await pageViewsDataController.fetchRecentlyReadPages(project: project, minimumSeconds: 60, mainNamespaceOnly: true)
        if pages.isEmpty {
            pages = try await pageViewsDataController.fetchRecentlyReadPages(project: project, minimumSeconds: 10, mainNamespaceOnly: true)
        }
        guard let recentlyRead = pages.randomElement() else { return nil }
        let related = try await relatedPagesDataController.fetchRelatedPages(title: recentlyRead.title, project: project)
        let candidates = candidatesPreferringNotExcluded(related, excluding: excluded)
        let mapped = candidates.prefix(4).map { WMFForYouArticle(title: $0.title, project: project) }
        return WMFForYouBecauseYouReadArticles(
            recentlyRead: WMFForYouArticle(title: recentlyRead.title, project: project),
            articles: mapped
        )
    }

    private func fetchForYouContinueReading(project: WMFProject) async throws -> WMFForYouContinueReading? {
        guard let pageViewsDataController else { return nil }
        let pages = try await pageViewsDataController.fetchRecentlyReadPages(project: project, minimumSeconds: 60, mainNamespaceOnly: true)
        let saved = try await savedArticlesDataController.fetchRecentlySavedArticles(limit: 3, projectID: project.id)
        let fromReadingList = saved.compactMap { item -> WMFForYouArticle? in
            guard let itemProject = WMFProject(id: item.page.projectID),
                  itemProject.languageCode == project.languageCode else { return nil }
            return WMFForYouArticle(title: item.page.title, project: itemProject)
        }
        if let seed = pages.randomElement() {
            return WMFForYouContinueReading(
                continueReadingArticle: WMFForYouArticle(title: seed.title, project: project),
                fromReadingListArticles: fromReadingList
            )
        } else {
            return WMFForYouContinueReading(
                continueReadingArticle: nil,
                fromReadingListArticles: fromReadingList
            )
        }
    }

    // MARK: - Fetching articles by topic

    /// Fetches random articles for display when no interest topics have been selected.
    public func fetchRandomArticles(project: WMFProject) async throws -> [WMFRandomArticle] {
        return try await WMFRandomDataController.shared.fetchRandomArticles(project: project)
    }

    /// Fetches articles matching a specific interest topic.
    public func fetchArticles(for topic: WMFArticleTopic, project: WMFProject) async throws -> [WMFRandomArticle] {
        let topicID = topic.rawValue
        guard let service = basicService else {
            throw WMFDataControllerError.basicServiceUnavailable
        }

        guard case .wikipedia = project else {
            throw WMFDataControllerError.unsupportedProject
        }

        guard let url = URL.mediaWikiAPIURL(project: project) else {
            throw WMFDataControllerError.failureCreatingRequestURL
        }

        let parameters: [String: Any] = [
            "format": "json",
            "formatversion": "2",
            "errorformat": "html",
            "errorsuselocal": "1",
            "action": "query",
            "generator": "search",
            "redirects": "",
            "converttitles": "",
            "prop": "description|pageimages|pageprops|info|extracts",
            "ppprop": "mainpage|disambiguation",
            "exchars": "500",
            "exintro": "1",
            "explaintext": "1",
            "piprop": "thumbnail",
            "pilicense": "any",
            "gsrnamespace": "0",
            "inprop": "varianttitles|displaytitle",
            "pithumbsize": "330",
            "gsrsearch": "articletopic:\(topicID)^95",
            "gsrlimit": "20",
            "gsrqiprofile": "classic_noboostlinks",
            "gsrsort": "random"
        ]

        let request = WMFBasicServiceRequest(url: url, method: .GET, languageVariantCode: project.languageVariantCode, parameters: parameters, acceptType: .json)
        let response: WMFTopicArticlesAPIResponse = try await withCheckedThrowingContinuation { continuation in
            service.performDecodableGET(request: request) { (result: Result<WMFTopicArticlesAPIResponse, Error>) in
                continuation.resume(with: result)
            }
        }
        // A disambiguation page and the main page are not good content for a suggestion.
        return (response.query?.pages ?? []).filter { page in
            return page.pageprops?.disambiguation == nil && page.pageprops?.mainpage == nil
        }
    }

    // MARK: - Community

    /// Fetches the Home feed "Community" data for the given date.
    /// Pass `Date()` (the default) to fetch today's data. The first-page response is cached per project per day.
    @discardableResult
    public func fetchCommunity(project: WMFProject, date: Date = Date(), forceFetch: Bool = false) async throws -> WMFCommunityResponse {
        if !forceFetch, let cached = cachedCommunityResponse(for: project) {
            recordCommunityFetchedDate(date, project: project)
            return cached
        }
        let calendar = Calendar(identifier: .gregorian)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        async let feedResponse = feedDataController.fetchFeed(project: project, date: date)
        async let onThisDay = try? onThisDayDataController.fetchOnThisDay(project: project, month: month, day: day)
        let response = try await WMFCommunityResponse(date: date, feedResponse: feedResponse, onThisDay: onThisDay)
        recordCommunityFetchedDate(date, project: project)
        cacheCommunityResponse(response, for: project)
        return response
    }

    /// Fetches the feed data for the day that precedes the earliest date already fetched for the given project.
    /// Callers must have fetched at least one page via `fetchCommunity` before calling this.
    public func fetchCommunityPreviousPage(project: WMFProject) async throws -> WMFCommunityResponse {
        guard let earliest = communityFetchedDates[project]?.last else {
            throw WMFHomeDataControllerError.noFetchedDatesAvailable
        }

        let calendar = Calendar(identifier: .gregorian)
        guard let previousDate = calendar.date(byAdding: .day, value: -1, to: earliest) else {
            throw WMFHomeDataControllerError.failureCalculatingPreviousDate
        }

        let month = calendar.component(.month, from: previousDate)
        let day = calendar.component(.day, from: previousDate)
        async let feedResponse = feedDataController.fetchFeed(project: project, date: previousDate)
        async let onThisDay = try? onThisDayDataController.fetchOnThisDay(project: project, month: month, day: day)
        let response = try await WMFCommunityResponse(date: previousDate, feedResponse: feedResponse, onThisDay: onThisDay)
        recordCommunityFetchedDate(previousDate, project: project)
        return response
    }

    // MARK: - Private

    private func forYouCacheKey(for project: WMFProject) -> String {
        "home.forYou.\(project.id)"
    }

    private func communityCacheKey(for project: WMFProject) -> String {
        "home.community.\(project.id)"
    }

    private func cachedForYouResponse(for project: WMFProject) -> WMFForYouResponse? {
        guard let store = WMFDataEnvironment.current.sharedCacheStore,
              let entry: WMFHomeForYouCacheEntry = try? store.load(key: forYouCacheKey(for: project)),
              Calendar.current.isDateInToday(entry.date) else { return nil }
        return entry.response
    }

    private func cacheForYouResponse(_ response: WMFForYouResponse, for project: WMFProject) {
        guard let store = WMFDataEnvironment.current.sharedCacheStore else { return }
        let entry = WMFHomeForYouCacheEntry(date: Date(), response: response)
        try? store.save(key: forYouCacheKey(for: project), value: entry)
    }

    private func cachedCommunityResponse(for project: WMFProject) -> WMFCommunityResponse? {
        guard let store = WMFDataEnvironment.current.sharedCacheStore,
              let entry: WMFHomeCommunityFirstPageCacheEntry = try? store.load(key: communityCacheKey(for: project)),
              Calendar.current.isDateInToday(entry.date) else { return nil }
        return entry.response
    }

    private func cacheCommunityResponse(_ response: WMFCommunityResponse, for project: WMFProject) {
        guard let store = WMFDataEnvironment.current.sharedCacheStore else { return }
        let entry = WMFHomeCommunityFirstPageCacheEntry(date: Date(), response: response)
        try? store.save(key: communityCacheKey(for: project), value: entry)
    }

    private func recordCommunityFetchedDate(_ date: Date, project: WMFProject) {
        let calendar = Calendar(identifier: .gregorian)
        let normalized = calendar.startOfDay(for: date)
        var dates = communityFetchedDates[project] ?? []
        guard !dates.contains(where: { calendar.isDate($0, inSameDayAs: normalized) }) else { return }
        dates.append(normalized)
        dates.sort(by: >)
        communityFetchedDates[project] = dates
    }
}

// MARK: - See first preference

/// The content type the Home feed opens on, chosen during app onboarding.
public enum WMFHomeFeedSeeFirst: String, Codable, Sendable {
    case community
    case personalized
}

// MARK: - Community response model

public struct WMFCommunityResponse: Codable, Sendable {
    public let date: Date
    public let feedResponse: WMFFeedAPIResponse
    public let onThisDay: WMFOnThisDayResponse?
}

// MARK: - For You response models

public struct WMFForYouArticle: Codable, Sendable {
    public let title: String
    public let project: WMFProject
}

public struct WMFForYouInterestTopicRandomArticles: Codable, Sendable {
    public let topic: WMFArticleTopic
    public let articles: [WMFForYouArticle]
}

public struct WMFForYouInterestPageRelatedArticles: Codable, Sendable {
    public let pageInterest: WMFForYouArticle
    public let articles: [WMFForYouArticle]
}

public struct WMFForYouBecauseYouReadArticles: Codable, Sendable {
    public let recentlyRead: WMFForYouArticle
    public let articles: [WMFForYouArticle]
}

public struct WMFForYouContinueReading: Codable, Sendable {
    public let continueReadingArticle: WMFForYouArticle?
    public let fromReadingListArticles: [WMFForYouArticle]
}

public struct WMFForYouResponse: Codable, Sendable {
    public let interestTopicRandomArticles: [WMFForYouInterestTopicRandomArticles]
    public let interestPageRelatedArticles: [WMFForYouInterestPageRelatedArticles]
    public let becauseYouReadArticles: WMFForYouBecauseYouReadArticles?
    public let continueReadingArticles: WMFForYouContinueReading?
}

// MARK: - Cache entry models

private struct WMFHomeForYouCacheEntry: Codable {
    let date: Date
    let response: WMFForYouResponse
}

private struct WMFHomeCommunityFirstPageCacheEntry: Codable {
    let date: Date
    let response: WMFCommunityResponse
}

// MARK: - Topic articles response models

struct WMFTopicArticlesAPIResponse: Decodable {
    let query: WMFTopicArticlesQuery?
}

struct WMFTopicArticlesQuery: Decodable {
    let pages: [WMFRandomArticle]?
}

public enum WMFHomeDataControllerError: LocalizedError {
    case noFetchedDatesAvailable
    case failureCalculatingPreviousDate

    public var errorDescription: String? {
        switch self {
        case .noFetchedDatesAvailable:
            return "No feed pages have been fetched yet. Call fetchCommunity first."
        case .failureCalculatingPreviousDate:
            return "Failed to calculate the previous date."
        }
    }
}
