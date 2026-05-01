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

public struct WMFTrendingArticlePin: Sendable, Identifiable {
    public let article: WMFTrendingArticle
    public let latitude: Double
    public let longitude: Double

    public var id: String { article.id }
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

    public func fetchPinsForArticles(_ articles: [WMFTrendingArticle], languageCode: String = "en") async throws -> [WMFTrendingArticlePin] {
        guard !articles.isEmpty else { return [] }

        guard let service else {
            throw WMFDataControllerError.basicServiceUnavailable
        }

        let titles = articles.map { $0.title }.joined(separator: "|")
        let project = WMFProject.wikipedia(WMFLanguage(languageCode: languageCode, languageVariantCode: nil))

        guard let baseURL = URL.mediaWikiAPIURL(project: project) else {
            throw WMFDataControllerError.failureCreatingRequestURL
        }

        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "action", value: "query"),
            URLQueryItem(name: "prop", value: "coordinates"),
            URLQueryItem(name: "titles", value: titles),
            URLQueryItem(name: "formatversion", value: "2"),
            URLQueryItem(name: "format", value: "json")
        ]

        guard let url = components?.url else {
            throw WMFDataControllerError.failureCreatingRequestURL
        }

        let request = WMFBasicServiceRequest(url: url, method: .GET, acceptType: .json)

        return try await withCheckedThrowingContinuation { continuation in
            service.performDecodableGET(request: request) { (result: Result<CoordinatesResponse, Error>) in
                switch result {
                case .success(let response):
                    var pins: [WMFTrendingArticlePin] = []
                    for page in response.query.pages {
                        guard let coords = page.coordinates?.first,
                              let article = articles.first(where: { $0.title == page.title }) else {
                            continue
                        }
                        pins.append(WMFTrendingArticlePin(article: article, latitude: coords.lat, longitude: coords.lon))
                    }
                    continuation.resume(returning: pins)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
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

    // MARK: - Response Models

    private struct CoordinatesResponse: Decodable {
        let query: QueryResult

        struct QueryResult: Decodable {
            let pages: [PageResult]
        }

        struct PageResult: Decodable {
            let title: String
            let coordinates: [Coordinate]?
        }

        struct Coordinate: Decodable {
            let lat: Double
            let lon: Double
        }
    }
}
