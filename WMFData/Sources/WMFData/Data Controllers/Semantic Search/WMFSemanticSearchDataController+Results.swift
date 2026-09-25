import Foundation

extension WMFSemanticSearchDataController {

    public enum SearchError: Error, Equatable {
        case rateLimited
        case backendUnavailable
        case mediaWikiError(code: String)

        init(mediaWikiErrorCode code: String) {
            if code.contains("ratelimit") {
                self = .rateLimited
            } else if code.contains("backend") {
                self = .backendUnavailable
            } else {
                self = .mediaWikiError(code: code)
            }
        }
    }

    public static let resultsPageSize = 3

    private var basicService: WMFService? { WMFDataEnvironment.current.basicService }

    // MARK: - Results

    /// Fetches one page of passages for `query`. Pass the `nextOffset` of the previous page to
    /// fetch the page after it.
    public func fetchResults(query: String, project: WMFProject, offset: Int = 0) async throws -> WMFSemanticSearchResultsPage {
        guard let basicService else {
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
            "gsrsearch": query,
            "gsrwhat": "text",
            "gsrnamespace": "0",
            "gsrlimit": String(Self.resultsPageSize),
            "gsrprop": "snippet|sectiontitle|redirecttitle",
            "cirrusSemanticSearch": "hl",
            "prop": "pageimages",
            "piprop": "thumbnail",
            "errorformat": "html",
            "errorsuselocal": "1"
        ]

        if offset > 0 {
            parameters["gsroffset"] = String(offset)
        }

        let request = WMFBasicServiceRequest(
            url: url,
            method: .GET,
            languageVariantCode: project.languageVariantCode,
            parameters: parameters,
            acceptType: .json
        )
        let response: SearchResponse = try await performDecodableGET(request: request, service: basicService)

        if let error = response.errors?.first {
            throw SearchError(mediaWikiErrorCode: error.code)
        }

        let pages = (response.query?.pages ?? [])
            .sorted { ($0.index ?? Int.max) < ($1.index ?? Int.max) }

        let results = pages.map { page in
            WMFSemanticSearchResult(
                pageID: page.pageid,
                title: page.title,
                snippetHTML: page.snippet ?? "",
                sectionTitle: page.sectiontitle,
                redirectTitle: page.redirecttitle,
                thumbnailURL: page.thumbnail?.source.flatMap { URL(string: $0) }
            )
        }

        return WMFSemanticSearchResultsPage(results: results, nextOffset: response.continue?.gsroffset)
    }

    // MARK: - Attribution

    public func fetchAttribution(title: String, project: WMFProject) async throws -> WMFSemanticSearchAttribution {
        guard let basicService else {
            throw WMFDataControllerError.basicServiceUnavailable
        }

        let url = URL.mediaWikiRestAPIURL(
            project: project,
            additionalPathComponents: ["attribution", "v0-beta", "pages", title.spacesToUnderscores, "signals"]
        )

        guard !title.isEmpty, let url else {
            throw WMFDataControllerError.failureCreatingRequestURL
        }

        let parameters: [String: Any] = [
            "redirect": "true",
            "expand": "trust_and_relevance"
        ]

        let request = WMFBasicServiceRequest(
            url: url,
            method: .GET,
            languageVariantCode: project.languageVariantCode,
            parameters: parameters,
            acceptType: .json
        )
        let response: AttributionResponse = try await performDecodableGET(request: request, service: basicService)
        let signals = response.trustAndRelevance

        return WMFSemanticSearchAttribution(
            contributorCount: signals?.contributorCounts,
            referenceCount: signals?.referenceCount,
            lastUpdated: signals?.lastUpdated.flatMap { DateFormatter.mediaWikiAPIDateFormatter.date(from: $0) }
        )
    }

    // MARK: - Service

    private func performDecodableGET<T: Decodable & Sendable>(request: WMFBasicServiceRequest, service: WMFService) async throws -> T {
        let value: T = try await withCheckedThrowingContinuation { continuation in
            service.performDecodableGET(request: request) { (result: Result<T, Error>) in
                switch result {
                case .success(let value):
                    continuation.resume(returning: value)
                case .failure(let error):
                    continuation.resume(throwing: Self.searchError(from: error))
                }
            }
        }

        try Task.checkCancellation()
        return value
    }

    private static func searchError(from error: Error) -> Error {
        guard let serviceError = error as? WMFServiceError,
              case .invalidHttpResponse(let statusCode?) = serviceError else {
            return error
        }

        if statusCode == 429 {
            return SearchError.rateLimited
        }

        if (500...599).contains(statusCode) {
            return SearchError.backendUnavailable
        }

        return error
    }

    // MARK: - Response Models

    private struct SearchResponse: Decodable, Sendable {
        let query: Query?
        let `continue`: Continue?
        let errors: [WMFMediaWikiError]?

        struct Query: Decodable, Sendable {
            let pages: [Page]?
        }

        struct Page: Decodable, Sendable {
            let pageid: Int
            let title: String
            let index: Int?
            let snippet: String?
            let sectiontitle: String?
            let redirecttitle: String?
            let thumbnail: Thumbnail?

            struct Thumbnail: Decodable, Sendable {
                let source: String?
            }
        }

        struct Continue: Decodable, Sendable {
            let gsroffset: Int?
        }
    }

    private struct AttributionResponse: Decodable, Sendable {
        let trustAndRelevance: TrustAndRelevance?

        enum CodingKeys: String, CodingKey {
            case trustAndRelevance = "trust_and_relevance"
        }

        struct TrustAndRelevance: Decodable, Sendable {
            let lastUpdated: String?
            let contributorCounts: Int?
            let referenceCount: Int?

            enum CodingKeys: String, CodingKey {
                case lastUpdated = "last_updated"
                case contributorCounts = "contributor_counts"
                case referenceCount = "reference_count"
            }
        }
    }
}
