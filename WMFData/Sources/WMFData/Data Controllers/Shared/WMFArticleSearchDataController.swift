import Foundation

public actor WMFArticleSearchDataController {

    public static let shared = WMFArticleSearchDataController()

    private let basicService: WMFService?

    public init(basicService: WMFService? = WMFDataEnvironment.current.basicService) {
        self.basicService = basicService
    }

    /// Prefix-searches article titles on the given project via the MediaWiki action API.
    ///
    /// Results are not restricted to the main namespace: plain search terms resolve to
    /// mainspace pages, but explicit namespace prefixes (e.g. "Talk:") resolve to pages in
    /// those namespaces, which are returned with their `namespace` populated so callers can
    /// decide how to handle them.
    /// - Parameters:
    ///   - term: The search term. Empty or whitespace-only terms return an empty result without a network call.
    ///   - project: The WMFProject to search on.
    ///   - limit: Maximum number of results to return.
    public func search(term: String, project: WMFProject, limit: Int = 10) async throws -> [WMFArticleSearchResult] {
        let trimmedTerm = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTerm.isEmpty else {
            return []
        }

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
            "generator": "prefixsearch",
            "gpssearch": trimmedTerm,
            "gpslimit": String(limit),
            "redirects": "1",
            "prop": "description|pageimages|info",
            "inprop": "displaytitle",
            "piprop": "thumbnail",
            "pilicense": "any",
            "pithumbsize": "120"
        ]

        let request = WMFBasicServiceRequest(url: url, method: .GET, languageVariantCode: project.languageVariantCode, parameters: parameters, acceptType: .json)
        let response: WMFArticleSearchAPIResponse = try await withCheckedThrowingContinuation { continuation in
            service.performDecodableGET(request: request) { (result: Result<WMFArticleSearchAPIResponse, Error>) in
                continuation.resume(with: result)
            }
        }

        let pages = response.query?.pages ?? []
        return pages.sorted { ($0.index ?? Int.max) < ($1.index ?? Int.max) }
    }
}

// MARK: - Response models

struct WMFArticleSearchAPIResponse: Decodable, Sendable {
    let query: WMFArticleSearchQuery?
}

struct WMFArticleSearchQuery: Decodable, Sendable {
    let pages: [WMFArticleSearchResult]?
}

public struct WMFArticleSearchResult: Decodable, Sendable, Equatable {
    public let pageID: Int
    public let namespace: Int
    public let title: String
    public let displayTitle: String?
    public let description: String?
    public let index: Int?
    let thumbnail: WMFArticleSearchThumbnail?

    public var isMainNamespace: Bool {
        return namespace == 0
    }

    public var thumbnailURL: URL? {
        return thumbnail?.url
    }

    enum CodingKeys: String, CodingKey {
        case pageID = "pageid"
        case namespace = "ns"
        case title
        case displayTitle = "displaytitle"
        case description
        case index
        case thumbnail
    }
}

struct WMFArticleSearchThumbnail: Decodable, Sendable, Equatable {
    let source: String?

    var url: URL? {
        guard let source else { return nil }
        return URL(string: source)
    }
}
