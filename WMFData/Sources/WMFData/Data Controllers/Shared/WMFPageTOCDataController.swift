import Foundation

/// One entry in a page's table of contents. `tocLevel` is 1 for top level sections, 2 for their
/// subsections, and so on, so a section's parent is the nearest preceding entry with a lower level.
public struct WMFPageTOCSection: Sendable {
    public let tocLevel: Int

    /// Display title of the section. May contain HTML markup.
    public let line: String
    public let anchor: String

    /// Hierarchical section number, e.g. "5.1".
    public let number: String

    public init(tocLevel: Int, line: String, anchor: String, number: String) {
        self.tocLevel = tocLevel
        self.line = line
        self.anchor = anchor
        self.number = number
    }
}

/// Fetches a page's table of contents. Results are cached in memory, and concurrent requests for
/// the same page share one network call.
public actor WMFPageTOCDataController {

    public static let shared = WMFPageTOCDataController()

    private var cache: [String: [WMFPageTOCSection]] = [:]
    private var inFlightRequests: [String: Task<[WMFPageTOCSection], Error>] = [:]

    private var basicService: WMFService? { WMFDataEnvironment.current.basicService }

    public init() {}

    public func fetchSections(title: String, project: WMFProject) async throws -> [WMFPageTOCSection] {

        let cacheKey = "\(project.id)-\(title)"

        if let cachedSections = cache[cacheKey] {
            return cachedSections
        }

        if let inFlightRequest = inFlightRequests[cacheKey] {
            return try await inFlightRequest.value
        }

        let task = Task<[WMFPageTOCSection], Error> {
            try await performFetch(title: title, project: project)
        }
        inFlightRequests[cacheKey] = task

        do {
            let sections = try await task.value
            inFlightRequests[cacheKey] = nil
            cache[cacheKey] = sections
            return sections
        } catch {
            inFlightRequests[cacheKey] = nil
            throw error
        }
    }

    private func performFetch(title: String, project: WMFProject) async throws -> [WMFPageTOCSection] {

        guard let basicService else {
            throw WMFDataControllerError.basicServiceUnavailable
        }

        guard !title.isEmpty,
              let url = URL.mediaWikiAPIURL(project: project) else {
            throw WMFDataControllerError.failureCreatingRequestURL
        }

        let parameters: [String: Any] = [
            "action": "parse",
            "format": "json",
            "formatversion": "2",
            "page": title,
            "prop": "tocdata",
            "redirects": "1"
        ]

        let request = WMFBasicServiceRequest(url: url, method: .GET, languageVariantCode: project.languageVariantCode, parameters: parameters, acceptType: .json)

        let response: TOCResponse = try await withCheckedThrowingContinuation { continuation in
            basicService.performDecodableGET(request: request) { (result: Result<TOCResponse, Error>) in
                continuation.resume(with: result)
            }
        }

        // `tocdata` is absent for pages without a table of contents.
        let sections = response.parse?.tocdata?.sections ?? []

        return sections.compactMap { section in
            guard let tocLevel = section.tocLevel,
                  let line = section.line else {
                return nil
            }
            return WMFPageTOCSection(tocLevel: tocLevel, line: line, anchor: section.anchor ?? "", number: section.number ?? "")
        }
    }

    @_spi(Testing) public func reset() {
        cache.removeAll()
        inFlightRequests.removeAll()
    }
}

// MARK: - API Response

private struct TOCResponse: Decodable {

    struct Parse: Decodable {

        struct TOCData: Decodable {

            struct Section: Decodable {
                let tocLevel: Int?
                let line: String?
                let anchor: String?
                let number: String?
            }

            let sections: [Section]?
        }

        let tocdata: TOCData?
    }

    let parse: Parse?
}
