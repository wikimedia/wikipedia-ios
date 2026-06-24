import Foundation

public final actor WMFHomeDataController {

    private let feedDataController: any WMFFeedDataControlling
    private let basicService: WMFService?

    // Accessed only from `nonisolated` UserDefaults helpers below; WMFKeyValueStore is not Sendable.
    nonisolated(unsafe) private let userDefaultsStore: WMFKeyValueStore?

    // Dates for which feed data has been fetched per project, in descending order (most recent first).
    private var fetchedDates: [WMFProject: [Date]] = [:]

    public static let shared = WMFHomeDataController()

    public init(feedDataController: any WMFFeedDataControlling = WMFFeedDataController.shared, basicService: WMFService? = WMFDataEnvironment.current.basicService, userDefaultsStore: WMFKeyValueStore? = WMFDataEnvironment.current.userDefaultsStore) {
        self.feedDataController = feedDataController
        self.basicService = basicService
        self.userDefaultsStore = userDefaultsStore
    }

    // MARK: - Settings: Selected Language

    public nonisolated func selectedLanguage() -> WMFLanguage? {
        return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.homeSelectedLanguage.rawValue)) ?? nil
    }

    public nonisolated func setSelectedLanguage(_ newValue: WMFLanguage) {
        try? userDefaultsStore?.save(key: WMFUserDefaultsKey.homeSelectedLanguage.rawValue, value: newValue)
    }

    // MARK: - Settings: Community Modules

    public nonisolated func communityFeaturedArticleIsOn() -> Bool {
        return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.homeFeedCommunityFeaturedArticleIsOn.rawValue)) ?? true
    }

    public nonisolated func setCommunityFeaturedArticleIsOn(_ newValue: Bool) {
        try? userDefaultsStore?.save(key: WMFUserDefaultsKey.homeFeedCommunityFeaturedArticleIsOn.rawValue, value: newValue)
    }

    public nonisolated func communityTopReadIsOn() -> Bool {
        return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.homeFeedCommunityTopReadIsOn.rawValue)) ?? true
    }

    public nonisolated func setCommunityTopReadIsOn(_ newValue: Bool) {
        try? userDefaultsStore?.save(key: WMFUserDefaultsKey.homeFeedCommunityTopReadIsOn.rawValue, value: newValue)
    }

    public nonisolated func communityInTheNewsIsOn() -> Bool {
        return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.homeFeedCommunityInTheNewsIsOn.rawValue)) ?? true
    }

    public nonisolated func setCommunityInTheNewsIsOn(_ newValue: Bool) {
        try? userDefaultsStore?.save(key: WMFUserDefaultsKey.homeFeedCommunityInTheNewsIsOn.rawValue, value: newValue)
    }

    public nonisolated func communityOnThisDayIsOn() -> Bool {
        return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.homeFeedCommunityOnThisDayIsOn.rawValue)) ?? true
    }

    public nonisolated func setCommunityOnThisDayIsOn(_ newValue: Bool) {
        try? userDefaultsStore?.save(key: WMFUserDefaultsKey.homeFeedCommunityOnThisDayIsOn.rawValue, value: newValue)
    }

    public nonisolated func communityPictureOfTheDayIsOn() -> Bool {
        return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.homeFeedCommunityPictureOfTheDayIsOn.rawValue)) ?? true
    }

    public nonisolated func setCommunityPictureOfTheDayIsOn(_ newValue: Bool) {
        try? userDefaultsStore?.save(key: WMFUserDefaultsKey.homeFeedCommunityPictureOfTheDayIsOn.rawValue, value: newValue)
    }

    // MARK: - Settings: For You Modules

    public nonisolated func forYouBasedOnInterestsIsOn() -> Bool {
        return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.homeFeedForYouBasedOnInterestsIsOn.rawValue)) ?? true
    }

    public nonisolated func setForYouBasedOnInterestsIsOn(_ newValue: Bool) {
        try? userDefaultsStore?.save(key: WMFUserDefaultsKey.homeFeedForYouBasedOnInterestsIsOn.rawValue, value: newValue)
    }

    public nonisolated func forYouBecauseYouReadIsOn() -> Bool {
        return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.homeFeedForYouBecauseYouReadIsOn.rawValue)) ?? true
    }

    public nonisolated func setForYouBecauseYouReadIsOn(_ newValue: Bool) {
        try? userDefaultsStore?.save(key: WMFUserDefaultsKey.homeFeedForYouBecauseYouReadIsOn.rawValue, value: newValue)
    }

    public nonisolated func forYouContinueReadingIsOn() -> Bool {
        return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.homeFeedForYouContinueReadingIsOn.rawValue)) ?? true
    }

    public nonisolated func setForYouContinueReadingIsOn(_ newValue: Bool) {
        try? userDefaultsStore?.save(key: WMFUserDefaultsKey.homeFeedForYouContinueReadingIsOn.rawValue, value: newValue)
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
        return response.query?.pages ?? []
    }

    /// Fetches the Home feed "Community" data for the given date.
    /// Pass `Date()` (the default) to fetch today's data.
    @discardableResult
    public func fetchCommunity(project: WMFProject, date: Date = Date()) async throws -> WMFFeedAPIResponse {
        let response = try await feedDataController.fetchFeed(project: project, date: date)
        recordFetchedDate(date, project: project)
        return response
    }

    /// Fetches the feed data for the day that precedes the earliest date already fetched for the given project.
    /// Callers must have fetched at least one page via `fetchCommunity` before calling this.
    public func fetchPreviousPage(project: WMFProject) async throws -> WMFFeedAPIResponse {
        guard let earliest = fetchedDates[project]?.last else {
            throw WMFHomeDataControllerError.noFetchedDatesAvailable
        }

        let calendar = Calendar(identifier: .gregorian)
        guard let previousDate = calendar.date(byAdding: .day, value: -1, to: earliest) else {
            throw WMFHomeDataControllerError.failureCalculatingPreviousDate
        }

        let response = try await feedDataController.fetchFeed(project: project, date: previousDate)
        recordFetchedDate(previousDate, project: project)
        return response
    }

    // MARK: - Private

    private func recordFetchedDate(_ date: Date, project: WMFProject) {
        let calendar = Calendar(identifier: .gregorian)
        let normalized = calendar.startOfDay(for: date)
        var dates = fetchedDates[project] ?? []
        guard !dates.contains(where: { calendar.isDate($0, inSameDayAs: normalized) }) else { return }
        dates.append(normalized)
        dates.sort(by: >)
        fetchedDates[project] = dates
    }
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
