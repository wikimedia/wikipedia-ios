import Foundation

/// Builds the link that shares a reading list. The link opens Special:ReadingLists, which imports the list in the apps and on the web.
/// The link has the same format as the link of the Android app.
public final class WMFShareReadingListDataController: Sendable {

    public struct Page: Sendable, Equatable {
        public let title: String
        public let project: WMFProject

        public init(title: String, project: WMFProject) {
            self.title = title
            self.project = project
        }
    }

    public enum ShareError: Error {
        case noPageIDs
        case missingPages
    }

    /// The API accepts 50 titles at most in one request.
    static let maximumTitlesPerRequest = 50
    static let provenance = "rlsi1"

    private let basicService: WMFService?

    public init(basicService: WMFService? = WMFDataEnvironment.current.basicService) {
        self.basicService = basicService
    }

    /// Gets the page IDs of the pages from the API, then makes the link on the wiki of `linkProject`.
    /// Pages that are not on a Wikipedia, or that the API does not find, are not in the link.
    public func fetchShareURL(for pages: [Page], linkProject: WMFProject) async throws -> URL {
        let pageIDsByLanguageCode = try await fetchPageIDsByLanguageCode(for: pages)
        guard !pageIDsByLanguageCode.isEmpty else {
            throw ShareError.noPageIDs
        }
        guard let url = Self.shareURL(siteURL: linkProject.siteURL, pageIDsByLanguageCode: pageIDsByLanguageCode) else {
            throw WMFDataControllerError.failureCreatingRequestURL
        }
        return url
    }

    // MARK: - Page IDs

    func fetchPageIDsByLanguageCode(for pages: [Page]) async throws -> [String: [Int]] {
        var projects: [WMFProject] = []
        var titlesByProject: [WMFProject: [String]] = [:]
        for page in pages where page.project.languageCode != nil {
            if titlesByProject[page.project] == nil {
                projects.append(page.project)
            }
            titlesByProject[page.project, default: []].append(page.title)
        }

        var pageIDsByLanguageCode: [String: [Int]] = [:]
        for project in projects {
            guard let languageCode = project.languageCode,
                  let titles = titlesByProject[project] else {
                continue
            }
            for titlesInRequest in Self.chunks(of: titles, size: Self.maximumTitlesPerRequest) {
                let pageIDs = try await fetchPageIDs(titles: titlesInRequest, project: project)
                pageIDsByLanguageCode[languageCode, default: []].append(contentsOf: pageIDs)
            }
        }
        return pageIDsByLanguageCode.filter { !$0.value.isEmpty }
    }

    private func fetchPageIDs(titles: [String], project: WMFProject) async throws -> [Int] {
        guard let basicService else {
            throw WMFDataControllerError.basicServiceUnavailable
        }
        guard let url = URL.mediaWikiAPIURL(project: project) else {
            throw WMFDataControllerError.failureCreatingRequestURL
        }

        let parameters: [String: Any] = [
            "action": "query",
            "titles": titles.joined(separator: "|"),
            "redirects": "1",
            "format": "json",
            "formatversion": "2",
            "errorformat": "html",
            "errorsuselocal": "1"
        ]

        let request = WMFBasicServiceRequest(url: url, method: .GET, languageVariantCode: project.languageVariantCode, parameters: parameters, acceptType: .json)
        let response: PageIDsResponse = try await withCheckedThrowingContinuation { continuation in
            basicService.performDecodableGET(request: request) { (result: Result<PageIDsResponse, Error>) in
                continuation.resume(with: result)
            }
        }
        // A response with API errors has no pages. Throw, so that the link does not lose the articles of this request.
        guard let pages = response.query?.pages else {
            throw ShareError.missingPages
        }
        return pages.compactMap(\.pageID)
    }

    static func chunks(of titles: [String], size: Int) -> [[String]] {
        stride(from: 0, to: titles.count, by: size).map { start in
            Array(titles[start..<min(start + size, titles.count)])
        }
    }

    // MARK: - Link

    /// The `limport` value is the base64 of `{"list":{"<language code>":[<page IDs>]}}`.
    static func shareURL(siteURL: URL?, pageIDsByLanguageCode: [String: [Int]]) -> URL? {
        guard let siteURL,
              let encodedList = encodedList(pageIDsByLanguageCode: pageIDsByLanguageCode) else {
            return nil
        }
        return URL(string: siteURL.absoluteString + "/wiki/Special:ReadingLists?limport=\(encodedList)&wprov=\(provenance)")
    }

    /// Percent encodes the base64 text. A raw "+" in a query becomes a space on the web.
    static func encodedList(pageIDsByLanguageCode: [String: [Int]]) -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        guard let data = try? encoder.encode(ExportedReadingList(list: pageIDsByLanguageCode)) else {
            return nil
        }
        return data.base64EncodedString().addingPercentEncoding(withAllowedCharacters: .alphanumerics)
    }
}

// MARK: - Models

extension WMFShareReadingListDataController {
    struct ExportedReadingList: Codable, Equatable {
        let list: [String: [Int]]
    }
}

private struct PageIDsResponse: Decodable, Sendable {
    struct Query: Decodable, Sendable {
        let pages: [Page]?
    }

    struct Page: Decodable, Sendable {
        let pageID: Int?

        enum CodingKeys: String, CodingKey {
            case pageID = "pageid"
        }
    }

    let query: Query?
}
