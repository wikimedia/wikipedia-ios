import Foundation
import CoreLocation

public final class WMFSearchDataController {

    // MARK: - Models

    public struct SearchResult: Identifiable, Equatable {
        public let id: Int
        public let title: String
        public let displayTitle: String?
        public let displayTitleHTML: String?
        public let description: String?
        public let extract: String?
        public let thumbnailURL: URL?
        public let index: Int?
        public let namespace: Int?
        public let location: CLLocation?
        public let articleURL: URL?
    }

    public struct SearchResults: Sequence {
        public let term: String
        public let results: [SearchResult]
        public let suggestion: String?

        public func makeIterator() -> IndexingIterator<[SearchResult]> {
            results.makeIterator()
        }
    }

    // MARK: - Properties

    private let session: URLSession

    // MARK: - Init

    public init(session: URLSession = .shared) {
        self.session = session
    }
}

// MARK: - Public API

extension WMFSearchDataController {

    public func searchArticles(
        term: String,
        siteURL: URL,
        limit: Int = 24,
        fullText: Bool = false
    ) async throws -> SearchResults {

        let queryParameters = buildQueryParameters(
            term: term,
            limit: limit,
            fullText: fullText
        )

        guard var components = URLComponents(
            url: siteURL,
            resolvingAgainstBaseURL: false
        ) else {
            throw NSError(
                domain: "WMFSearchDataController",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "Invalid site URL"]
            )
        }

        components.path = "/w/api.php"
        components.queryItems = queryParameters.map {
            URLQueryItem(name: $0.key, value: "\($0.value)")
        }

        guard let url = components.url else {
            throw NSError(
                domain: "WMFSearchDataController",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "Failed to construct URL"]
            )
        }

        let (data, _) = try await session.data(from: url)
        let json = try JSONSerialization.jsonObject(
            with: data,
            options: []
        ) as? [String: Any]

        return try parseSearchResponse(
            json: json,
            searchTerm: term,
            siteURL: siteURL
        )
    }
}

// MARK: - Private helpers

private extension WMFSearchDataController {

    func buildQueryParameters(
        term: String,
        limit: Int,
        fullText: Bool
    ) -> [String: Any] {

        let maxLimit = min(limit, 24)

        if !fullText {
            return [
                "action": "query",
                "generator": "prefixsearch",
                "gpssearch": term,
                "gpsnamespace": 0,
                "gpslimit": maxLimit,
                "prop": "description|pageprops|pageimages|revisions|coordinates",
                "coprop": "type|dim",
                "piprop": "thumbnail",
                "pithumbsize": 320,
                "pilimit": maxLimit,
                "ppprop": "displaytitle",
                "rvprop": "ids",
                "list": "search",
                "srsearch": term,
                "srnamespace": 0,
                "srwhat": "text",
                "srinfo": "suggestion",
                "srprop": "",
                "sroffset": 0,
                "srlimit": 1,
                "redirects": 1,
                "continue": "",
                "format": "json"
            ]
        }

        return [
            "action": "query",

            "generator": "search",
            "gsrsearch": term,
            "gsrnamespace": 0,
            "gsrwhat": "text",
            "gsrinfo": "",
            "gsrprop": "redirecttitle",
            "gsroffset": 0,
            "gsrlimit": maxLimit,

            "prop": "description|pageprops|pageimages|revisions|coordinates",
            "coprop": "type|dim",
            "ppprop": "displaytitle",
            "piprop": "thumbnail",
            "pithumbsize": 320,
            "pilimit": maxLimit,
            "rvprop": "ids",

            "redirects": 1,
            "continue": "",
            "format": "json"
        ]
    }


    func parseSearchResponse(
        json: [String: Any]?,
        searchTerm: String,
        siteURL: URL
    ) throws -> SearchResults {

        guard let query = json?["query"] as? [String: Any] else {
            return SearchResults(
                term: searchTerm,
                results: [],
                suggestion: nil
            )
        }

        var results: [SearchResult] = []

        // MARK: generator=search (full-text search)

        if let pages = query["pages"] as? [String: Any] {

            for (_, value) in pages {
                guard
                    let page = value as? [String: Any],
                    let pageID = page["pageid"] as? Int,
                    let title = page["title"] as? String
                else { continue }

                let description = page["description"] as? String
                let extract = page["extract"] as? String

                let thumbnailURL: URL? = {
                    guard
                        let thumbnail = page["thumbnail"] as? [String: Any],
                        let source = thumbnail["source"] as? String
                    else { return nil }
                    return URL(string: source)
                }()

                let articleURL = articleURL(
                    for: title,
                    siteURL: siteURL
                )

                results.append(
                    SearchResult(
                        id: pageID,
                        title: title,
                        displayTitle: title,
                        displayTitleHTML: title,
                        description: description,
                        extract: extract,
                        thumbnailURL: thumbnailURL,
                        index: page["index"] as? Int,
                        namespace: page["ns"] as? Int,
                        location: nil,
                        articleURL: articleURL
                    )
                )
            }
        }

        // MARK: list=search (prefix search)

        else if let searchArray = query["search"] as? [[String: Any]] {

            for page in searchArray {
                guard
                    let pageID = page["pageid"] as? Int,
                    let title = page["title"] as? String
                else { continue }

                let rawSnippet = page["snippet"] as? String
                let cleanSnippet = rawSnippet.map(stripHTML)

                let articleURL = articleURL(
                    for: title,
                    siteURL: siteURL
                )

                results.append(
                    SearchResult(
                        id: pageID,
                        title: title,
                        displayTitle: title,
                        displayTitleHTML: title,
                        description: cleanSnippet,
                        extract: nil,
                        thumbnailURL: nil,
                        index: page["index"] as? Int,
                        namespace: page["ns"] as? Int,
                        location: nil,
                        articleURL: articleURL
                    )
                )
            }
        }

        let suggestion =
            (query["searchinfo"] as? [String: Any])?["suggestion"] as? String

        return SearchResults(
            term: searchTerm,
            results: results.sorted { ($0.index ?? 0) < ($1.index ?? 0) },
            suggestion: suggestion
        )
    }

    // MARK: - Utilities

    func articleURL(for title: String, siteURL: URL) -> URL? {
        guard let host = siteURL.host else { return nil }
        let encodedTitle =
            title.addingPercentEncoding(
                withAllowedCharacters: .urlPathAllowed
            ) ?? title
        return URL(string: "https://\(host)/wiki/\(encodedTitle)")
    }

    func stripHTML(_ html: String) -> String {
        let data = Data(html.utf8)
        let attributed = try? NSAttributedString(
            data: data,
            options: [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ],
            documentAttributes: nil
        )
        return attributed?.string ?? html
    }
}
