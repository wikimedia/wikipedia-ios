import Foundation

// MARK: - Models

public struct WMFTrendingArticle: Codable, Sendable, Identifiable {
    public let family: String
    public let project: String
    public let title: String

    public var id: String { "\(family)-\(project)-\(title)" }

    public var displayTitle: String {
        title.replacingOccurrences(of: "_", with: " ")
    }
}

// MARK: - Topics

public enum WMFTrendingTopic: String, CaseIterable, Sendable {
    // Culture
    case cultureLiterature = "Culture.Literature"
    case culturePerformingArts = "Culture.Performing_arts"
    case cultureSports = "Culture.Sports"
    case biographyWomen = "Culture.Biography.Women"
    // History and society
    case businessEconomics = "History_and_Society.Business_and_economics"
    case education = "History_and_Society.Education"
    case history = "History_and_Society.History"
    case militaryWarfare = "History_and_Society.Military_and_warfare"
    case politicsGovernment = "History_and_Society.Politics_and_government"
    case society = "History_and_Society.Society"
    case transportation = "History_and_Society.Transportation"
    // Science, technology, and math
    case biology = "STEM.Biology"
    case chemistry = "STEM.Chemistry"
    case computing = "STEM.Computing"
    case earthEnvironment = "STEM.Earth_and_environment"
    case engineering = "STEM.Engineering"
    case mathematics = "STEM.Mathematics"
    case physics = "STEM.Physics"
    case technology = "STEM.Technology"

    public var displayName: String {
        switch self {
        case .cultureLiterature: return "Literature"
        case .culturePerformingArts: return "Performing Arts"
        case .cultureSports: return "Sports"
        case .biographyWomen: return "Biography (Women)"
        case .businessEconomics: return "Business & Economics"
        case .education: return "Education"
        case .history: return "History"
        case .militaryWarfare: return "Military & Warfare"
        case .politicsGovernment: return "Politics & Government"
        case .society: return "Society"
        case .transportation: return "Transportation"
        case .biology: return "Biology"
        case .chemistry: return "Chemistry"
        case .computing: return "Computing"
        case .earthEnvironment: return "Earth & Environment"
        case .engineering: return "Engineering"
        case .mathematics: return "Mathematics"
        case .physics: return "Physics"
        case .technology: return "Technology"
        }
    }

    public var groupName: String {
        switch self {
        case .cultureLiterature, .culturePerformingArts, .cultureSports, .biographyWomen:
            return "Culture"
        case .businessEconomics, .education, .history, .militaryWarfare,
             .politicsGovernment, .society, .transportation:
            return "History & Society"
        case .biology, .chemistry, .computing, .earthEnvironment, .engineering,
             .mathematics, .physics, .technology:
            return "Science, Technology & Math"
        }
    }
}

// MARK: - Data Controller

public actor WMFTrendingDataController {

    public static let shared = WMFTrendingDataController()

    private var service: WMFService? {
        WMFDataEnvironment.current.basicService
    }

    private var cache: [String: [WMFTrendingArticle]] = [:]
    private var pageViewsCache: [String: Int] = [:]

    private init() {}

    // MARK: - Public API

    public func fetchTrendingByTopic(_ topic: WMFTrendingTopic, languageCode: String = "en") async throws -> [WMFTrendingArticle] {
        let cacheKey = "topic-\(topic.rawValue)-\(languageCode)"
        if let cached = cache[cacheKey] {
            return cached
        }

        guard let url = URL.trendingByTopicURL(topic: topic.rawValue) else {
            throw WMFDataControllerError.failureCreatingRequestURL
        }

        let articles = try await fetchArticles(from: url, languageCode: languageCode)
        cache[cacheKey] = articles
        return articles
    }

    public func fetchTrendingByCountry(_ country: String, languageCode: String = "en") async throws -> [WMFTrendingArticle] {
        let cacheKey = "country-\(country)-\(languageCode)"
        if let cached = cache[cacheKey] {
            return cached
        }

        guard let url = URL.trendingByCountryURL(country: country) else {
            throw WMFDataControllerError.failureCreatingRequestURL
        }

        let articles = try await fetchArticles(from: url, languageCode: languageCode)
        cache[cacheKey] = articles
        return articles
    }

    // MARK: - Private

    private func fetchArticles(from url: URL, languageCode: String) async throws -> [WMFTrendingArticle] {
        guard let service else {
            throw WMFDataControllerError.basicServiceUnavailable
        }

        let request = WMFBasicServiceRequest(url: url, method: .GET, acceptType: .json)

        return try await withCheckedThrowingContinuation { continuation in
            service.performDecodableGET(request: request) { (result: Result<[WMFTrendingArticle], Error>) in
                switch result {
                case .success(let all):
                    let filtered = all
                        .filter { $0.family == "wikipedia" && $0.project == languageCode && Self.isArticle($0.title) }
                        .prefix(20)
                    continuation.resume(returning: Array(filtered))
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Helpers

    // Returns false for navigation/special pages that aren't real articles:
    // - "Main_Page" and its localizations (contain no ":" but are non-articles)
    // - Namespace pages like "Special:Search", "Wikipedia:Portada" (contain ":")
    // - "index.html" artifacts
    private static func isArticle(_ title: String) -> Bool {
        guard !title.contains(":"), title != "index.html" else { return false }
        let lowered = title.lowercased()
        return lowered != "main_page" && lowered != "main page"
    }

    /// Fetches yesterday's user page views for a single article.
    /// Returns nil if the data is unavailable rather than throwing.
    public func fetchYesterdayPageViews(title: String, languageCode: String) async -> Int? {
        let project = "\(languageCode).wikipedia"
        let normalizedTitle = title.replacingOccurrences(of: " ", with: "_")
        let cacheKey = "pageviews-\(project)-\(normalizedTitle)"
        if let cached = pageViewsCache[cacheKey] {
            return cached
        }

        guard let service else { return nil }

        let calendar = Calendar(identifier: .gregorian)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        formatter.timeZone = TimeZone(identifier: "UTC")
        let dateString = formatter.string(from: yesterday) + "00"

        guard let url = URL.pageviewsPerArticleURL(project: project, article: normalizedTitle, start: dateString, end: dateString) else {
            return nil
        }

        let request = WMFBasicServiceRequest(url: url, method: .GET, acceptType: .json)

        return await withCheckedContinuation { continuation in
            service.performDecodableGET(request: request) { [self] (result: Result<PageViewsResponse, Error>) in
                switch result {
                case .success(let response):
                    let total = response.items.first?.views
                    if let views = total {
                        Task { self.pageViewsCache[cacheKey] = views }
                    }
                    continuation.resume(returning: total)
                case .failure:
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    // MARK: - Response Models

    private struct PageViewsResponse: Decodable {
        let items: [PageViewsItem]

        struct PageViewsItem: Decodable {
            let views: Int
        }
    }
}
