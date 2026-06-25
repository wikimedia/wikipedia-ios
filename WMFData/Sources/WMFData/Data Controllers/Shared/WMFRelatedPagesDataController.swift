import Foundation

public actor WMFRelatedPagesDataController {

    public static let shared = WMFRelatedPagesDataController()

    private let service: WMFService?

    public init(basicService: WMFService? = WMFDataEnvironment.current.basicService) {
        self.service = basicService
    }

    public struct WMFRelatedPage: Sendable {
        public let pageid: Int
        public let title: String
        public let description: String?
        public let thumbnailURL: URL?
        public let extract: String?
    }

    // MARK: - Response Models

    private struct Response: Codable {
        let query: Query?

        struct Query: Codable {
            let pages: [Page]?
        }

        struct Page: Codable {
            let pageid: Int
            let title: String
            let description: String?
            let thumbnail: Thumbnail?
            let extract: String?

            struct Thumbnail: Codable {
                let source: String?
            }
        }
    }

    // MARK: - Public API

    public func fetchRelatedPages(title: String, project: WMFProject) async throws -> [WMFRelatedPage] {
        guard let service else {
            throw WMFDataControllerError.basicServiceUnavailable
        }

        guard let url = URL.mediaWikiAPIURL(project: project) else {
            throw WMFDataControllerError.failureCreatingRequestURL
        }

        let parameters: [String: Any] = [
            "action": "query",
            "format": "json",
            "formatversion": "2",
            "generator": "search",
            "gsrsearch": "morelike:\(title)",
            "gsrnamespace": "0",
            "gsrlimit": "20",
            "gsrqiprofile": "classic_noboostlinks",
            "prop": "pageimages|description|info|extracts",
            "piprop": "thumbnail",
            "pithumbsize": "160",
            "pilimit": "20",
            "exintro": "1",
            "explaintext": "1",
            "inprop": "varianttitles",
            "maxage": "86400",
            "smaxage": "86400",
            "origin": "*"
        ]

        let request = WMFBasicServiceRequest(url: url, method: .GET, languageVariantCode: project.languageVariantCode, parameters: parameters, acceptType: .json)

        let response: Response = try await withCheckedThrowingContinuation { continuation in
            service.performDecodableGET(request: request) { (result: Result<Response, Error>) in
                switch result {
                case .success(let response):
                    continuation.resume(returning: response)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }

        guard let pages = response.query?.pages else {
            return []
        }

        return pages.map { page in
            let thumbnailURL = page.thumbnail?.source.flatMap { URL(string: $0) }
            return WMFRelatedPage(
                pageid: page.pageid,
                title: page.title,
                description: page.description,
                thumbnailURL: thumbnailURL,
                extract: page.extract
            )
        }
    }
}
