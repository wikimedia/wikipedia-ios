import Foundation

public actor WMFRelatedPagesDataController {

    public static let shared = WMFRelatedPagesDataController()

    private let service: WMFService?

    public init(basicService: WMFService? = WMFDataEnvironment.current.basicService) {
        self.service = basicService
    }

    public struct WMFRelatedPage: Sendable {
        public let pageid: Int
        /// The canonical page title. Use it for keys and URLs.
        public let title: String
        /// The title to show. It can contain HTML, like a summary's display title. Nil when the API gives none.
        public let displayTitle: String?
        public let description: String?
        public let thumbnailURL: URL?
        public let extract: String?
    }

    /// The largest number of pages one request returns. TextExtracts returns an extract for at most this many pages.
    public static let maximumPageLimit = 20
    public static let defaultPageLimit = 50

    // MARK: - Response Models

    private struct Response: Codable, Sendable {
        let query: Query?

        struct Query: Codable, Sendable {
            let pages: [Page]?
        }

        struct Page: Codable, Sendable {
            let pageid: Int
            let title: String
            let displaytitle: String?
            let varianttitles: [String: String]?
            let description: String?
            let thumbnail: Thumbnail?
            let extract: String?
            let pageprops: PageProps?

            /// The variant title for the project's language variant, else the display title.
            func displayTitle(languageVariantCode: String?) -> String? {
                if let languageVariantCode, let variantTitle = varianttitles?[languageVariantCode], !variantTitle.isEmpty {
                    return variantTitle
                }
                return displaytitle
            }

            struct Thumbnail: Codable, Sendable {
                let source: String?
            }

            struct PageProps: Codable, Sendable {
                let mainpage: String?
                let disambiguation: String?
            }
        }
    }

    // MARK: - Public API

    /// - Parameters:
    ///   - limit: The number of search results to ask for. Only the first `maximumPageLimit` results carry an extract.
    ///   - offset: Skips this many search results, so a caller that already used the first page of results can ask for the next one.
    ///   - includesExtracts: Asks for the extract of each page. The extracts make the request many times slower, so a caller that does not show them passes false and gets pages with a nil `extract`.
    public func fetchRelatedPages(title: String, project: WMFProject, limit: Int = WMFRelatedPagesDataController.defaultPageLimit, offset: Int = 0, includesExtracts: Bool = true) async throws -> [WMFRelatedPage] {
        guard let service else {
            throw WMFDataControllerError.basicServiceUnavailable
        }

        guard let url = URL.mediaWikiAPIURL(project: project) else {
            throw WMFDataControllerError.failureCreatingRequestURL
        }

        var parameters: [String: Any] = [
            "action": "query",
            "format": "json",
            "formatversion": "2",
            "generator": "search",
            "gsrsearch": "morelike:\(title)",
            "gsrnamespace": "0",
            "gsrlimit": String(limit),
            "gsrqiprofile": "classic_noboostlinks",
            "prop": includesExtracts ? "pageimages|description|info|extracts|pageprops" : "pageimages|description|info|pageprops",
            "ppprop": "mainpage|disambiguation",
            "piprop": "thumbnail",
            "pilicense": "any",
            "pithumbsize": "160",
            "pilimit": String(limit),
            "inprop": "varianttitles|displaytitle",
            "maxage": "86400",
            "smaxage": "86400",
            "origin": "*"
        ]

        if includesExtracts {
            parameters["exchars"] = "500"
            parameters["exintro"] = "1"
            parameters["explaintext"] = "1"
        }

        if offset > 0 {
            parameters["gsroffset"] = String(offset)
        }

        let request = WMFBasicServiceRequest(url: url, method: .GET, languageVariantCode: project.languageVariantCode, parameters: parameters, acceptType: .json)

        try Task.checkCancellation()
        let cancellation = WMFRequestCancellation()
        let response: Response = try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                let task = service.performCancellableDecodableGET(request: request) { (result: Result<Response, Error>) in
                    continuation.resume(with: result)
                }
                cancellation.setTask(task)
            }
        } onCancel: {
            cancellation.cancel()
        }

        guard let pages = response.query?.pages else {
            return []
        }

        return pages.filter { page in
            return page.pageprops?.disambiguation == nil && page.pageprops?.mainpage == nil
        }.map { page in
            let thumbnailURL = page.thumbnail?.source.flatMap { URL(string: $0) }
            return WMFRelatedPage(
                pageid: page.pageid,
                title: page.title,
                displayTitle: page.displayTitle(languageVariantCode: project.languageVariantCode),
                description: page.description,
                thumbnailURL: thumbnailURL,
                extract: page.extract
            )
        }
    }
}
