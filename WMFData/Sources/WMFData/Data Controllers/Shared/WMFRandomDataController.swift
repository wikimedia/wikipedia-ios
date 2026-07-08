import Foundation

public actor WMFRandomDataController {

    public static let shared = WMFRandomDataController()

    private let basicService: WMFService?

    public init(basicService: WMFService? = WMFDataEnvironment.current.basicService) {
        self.basicService = basicService
    }

    // MARK: - Fetch single random article summary

    /// Fetches a summary for a single random article via the Wikimedia REST API.
    /// - Parameters:
    ///   - project: The WMFProject to fetch from.
    public func fetchRandomArticleSummary(project: WMFProject) async throws -> WMFArticleSummary {
        guard let service = basicService else {
            throw WMFDataControllerError.basicServiceUnavailable
        }

        guard case .wikipedia = project else {
            throw WMFDataControllerError.unsupportedProject
        }

        guard let url = URL.wikimediaRestAPIURL(project: project, additionalPathComponents: ["page", "random", "summary"]) else {
            throw WMFDataControllerError.failureCreatingRequestURL
        }

        let request = WMFBasicServiceRequest(url: url, method: .GET, languageVariantCode: project.languageVariantCode, acceptType: .json)
        return try await withCheckedThrowingContinuation { continuation in
            service.performDecodableGET(request: request) { (result: Result<WMFArticleSummary, Error>) in
                continuation.resume(with: result)
            }
        }
    }

    // MARK: - Fetch multiple random articles

    /// Fetches up to 40 random articles with page properties, images, descriptions, extracts, and variant titles via the MediaWiki action API.
    /// - Parameters:
    ///   - project: The WMFProject to fetch from.
    public func fetchRandomArticles(project: WMFProject) async throws -> [WMFRandomArticle] {
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
            "generator": "random",
            "grnfilterredir": "nonredirects",
            "grnnamespace": "0",
            "prop": "pageprops|pageimages|description|info|extracts",
            "exchars": "500",
            "exintro": "1",
            "explaintext": "1",
            "piprop": "thumbnail",
            "pilicense": "any",
            "inprop": "varianttitles|displaytitle",
            "pithumbsize": "330",
            "grnlimit": "40"
        ]

        let request = WMFBasicServiceRequest(url: url, method: .GET, languageVariantCode: project.languageVariantCode, parameters: parameters, acceptType: .json)
        let response: WMFRandomArticlesAPIResponse = try await withCheckedThrowingContinuation { continuation in
            service.performDecodableGET(request: request) { (result: Result<WMFRandomArticlesAPIResponse, Error>) in
                continuation.resume(with: result)
            }
        }
        return response.query?.pages ?? []
    }
}

// MARK: - Multiple random articles response models

struct WMFRandomArticlesAPIResponse: Decodable, Sendable {
    let query: WMFRandomArticlesQuery?
}

struct WMFRandomArticlesQuery: Decodable, Sendable {
    let pages: [WMFRandomArticle]?
}

public struct WMFRandomArticle: Decodable, Sendable {
    public let pageid: Int
    public let title: String
    public let displayTitle: String?
    public let variantTitles: WMFRandomArticleVariantTitles?
    public let description: String?
    public let extract: String?
    public let thumbnail: WMFRandomArticleThumbnail?

    enum CodingKeys: String, CodingKey {
        case pageid
        case title
        case displayTitle = "displaytitle"
        case variantTitles = "varianttitles"
        case description
        case extract
        case thumbnail
    }
}

public struct WMFRandomArticleVariantTitles: Decodable, Sendable {
    public let en: String?
}

public struct WMFRandomArticleThumbnail: Decodable, Sendable {
    public let source: String?
    public let width: Int?
    public let height: Int?

    public var url: URL? {
        guard let source else { return nil }
        return URL(string: source)
    }
}
