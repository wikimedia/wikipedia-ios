import Foundation

/// Searches pages with the MediaWiki action API.
///
/// The controller supports prefix search, full text search and search near a coordinate.
public actor WMFArticleSearchDataController {

    /// The sort order for a search near a coordinate.
    public enum SortStyle: Sendable {
        case none
        case pageViews
        case links
        case pageViewsAndLinks
    }

    public static let shared = WMFArticleSearchDataController()

    private let basicService: WMFService?

    public init(basicService: WMFService? = WMFDataEnvironment.current.basicService) {
        self.basicService = basicService
    }

    // MARK: - Prefix search

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

        guard case .wikipedia = project else {
            throw WMFDataControllerError.unsupportedProject
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

        let response = try await performQuery(project: project, parameters: parameters)
        let pages = response.query?.pages ?? []
        return pages.sorted { ($0.index ?? Int.max) < ($1.index ?? Int.max) }
    }

    // MARK: - Article and file search

    /// Search pages by title prefix or by full text.
    ///
    /// The request also asks for a spelling suggestion and the redirects that the results came from.
    /// - Parameters:
    ///   - term: The search term.
    ///   - project: The project to search. Wikipedia projects and Commons are supported.
    ///   - namespace: The namespace to search. Use 0 for articles and 6 for files.
    ///   - limit: The maximum number of results.
    ///   - fullText: `true` runs a full text search. `false` runs a title prefix search.
    ///   - thumbnailWidth: The width of the thumbnail images in the result.
    public func searchPages(term: String, project: WMFProject, namespace: Int = 0, limit: Int, fullText: Bool, thumbnailWidth: Int = ImageUtils.listThumbnailWidth()) async throws -> WMFArticleSearchResponse {
        switch project {
        case .wikipedia, .commons:
            break
        default:
            throw WMFDataControllerError.unsupportedProject
        }

        let limitString = String(limit)
        let namespaceString = String(namespace)
        var properties = "description|pageprops|pageimages|revisions|coordinates"
        if case .commons = project {
            properties = "description|pageprops|pageimages|revisions"
        }

        var parameters: [String: Any] = [
            "action": "query",
            "prop": properties,
            "coprop": "type|dim",
            "ppprop": "displaytitle",
            "piprop": "thumbnail",
            "pithumbsize": String(thumbnailWidth),
            "pilimit": limitString,
            "rvprop": "ids",
            "redirects": "1",
            "continue": "",
            "format": "json",
            "formatversion": "2"
        ]

        if fullText {
            parameters["generator"] = "search"
            parameters["gsrsearch"] = term
            parameters["gsrnamespace"] = namespaceString
            parameters["gsrwhat"] = "text"
            parameters["gsrinfo"] = ""
            parameters["gsrprop"] = "redirecttitle"
            parameters["gsroffset"] = "0"
            parameters["gsrlimit"] = limitString
        } else {
            parameters["generator"] = "prefixsearch"
            parameters["gpssearch"] = term
            parameters["gpsnamespace"] = namespaceString
            parameters["gpslimit"] = limitString
            // The `list=search` parameters make the API return a spelling suggestion.
            parameters["list"] = "search"
            parameters["srsearch"] = term
            parameters["srnamespace"] = namespaceString
            parameters["srwhat"] = "text"
            parameters["srinfo"] = "suggestion"
            parameters["srprop"] = ""
            parameters["sroffset"] = "0"
            parameters["srlimit"] = "1"
        }

        let response = try await performQuery(project: project, parameters: parameters)
        let pages = response.query?.pages ?? []
        return WMFArticleSearchResponse(
            results: pages.sorted { ($0.index ?? Int.max) < ($1.index ?? Int.max) },
            redirects: response.query?.redirects ?? [],
            suggestion: response.query?.searchinfo?.suggestion
        )
    }

    // MARK: - Search near a coordinate

    /// Search pages near a coordinate. The result is sorted by distance from the coordinate.
    ///
    /// A small radius without a search term uses the `geosearch` generator. A large radius, a search term
    /// or a sort style uses the full text search with a `nearcoord` filter.
    /// - Parameters:
    ///   - latitude: The latitude of the center.
    ///   - longitude: The longitude of the center.
    ///   - radius: The search radius in meters.
    ///   - term: An optional search term.
    ///   - sortStyle: The sort order for the full text search.
    ///   - limit: The maximum number of results.
    ///   - thumbnailWidth: The width of the thumbnail images in the result.
    ///   - extractCharacters: The maximum number of characters in the text extract of each result.
    public func searchNearby(project: WMFProject, latitude: Double, longitude: Double, radius: Double, term: String? = nil, sortStyle: SortStyle = .none, limit: Int, thumbnailWidth: Int = ImageUtils.nearbyThumbnailWidth(), extractCharacters: Int = 525) async throws -> [WMFArticleSearchResult] {
        guard case .wikipedia = project else {
            throw WMFDataControllerError.unsupportedProject
        }

        let limitString = String(limit)
        var parameters: [String: Any]

        if radius >= 10000 || term != nil || sortStyle != .none {
            var searchParts: [String] = []
            if let term {
                searchParts.append(term)
            }
            let roundedRadius = max(1, ceil(radius))
            searchParts.append(String(format: "nearcoord:%.0fm,%.3f,%.3f", roundedRadius, latitude, longitude))

            parameters = [
                "action": "query",
                "prop": "coordinates|pageimages|description|pageprops",
                "coprop": "type|dim",
                "colimit": limitString,
                "generator": "search",
                "gsrsearch": searchParts.joined(separator: " "),
                "gsrlimit": limitString,
                "piprop": "thumbnail",
                "pithumbsize": String(thumbnailWidth),
                "pilimit": limitString,
                "ppprop": "displaytitle",
                "format": "json",
                "formatversion": "2"
            ]

            switch sortStyle {
            case .links:
                parameters["cirrusIncLinkssW"] = "1000"
            case .pageViews:
                parameters["cirrusPageViewsW"] = "1000"
            case .pageViewsAndLinks:
                parameters["cirrusPageViewsW"] = "1000"
                parameters["cirrusIncLinkssW"] = "1000"
            case .none:
                break
            }
        } else {
            let coordinates = String(format: "%f|%f", latitude, longitude)
            parameters = [
                "action": "query",
                "prop": "coordinates|pageimages|description|pageprops|extracts",
                "coprop": "type|dim",
                "colimit": limitString,
                "pithumbsize": String(thumbnailWidth),
                "pilimit": limitString,
                "ppprop": "displaytitle",
                "generator": "geosearch",
                "ggscoord": coordinates,
                "codistancefrompoint": coordinates,
                "ggsradius": String(format: "%.0f", radius),
                "ggslimit": limitString,
                "exintro": "1",
                "exlimit": limitString,
                "explaintext": "",
                "exchars": String(extractCharacters),
                "format": "json",
                "formatversion": "2"
            ]
        }

        let response = try await performQuery(project: project, parameters: parameters)
        let pages = response.query?.pages ?? []
        return pages.sorted { ($0.coordinate?.distance ?? .greatestFiniteMagnitude) < ($1.coordinate?.distance ?? .greatestFiniteMagnitude) }
    }

    // MARK: - Private

    private func performQuery(project: WMFProject, parameters: [String: Any]) async throws -> WMFArticleSearchAPIResponse {
        guard let service = basicService else {
            throw WMFDataControllerError.basicServiceUnavailable
        }

        guard let url = URL.mediaWikiAPIURL(project: project) else {
            throw WMFDataControllerError.failureCreatingRequestURL
        }

        let request = WMFBasicServiceRequest(url: url, method: .GET, languageVariantCode: project.languageVariantCode, parameters: parameters, acceptType: .json)
        return try await withCheckedThrowingContinuation { continuation in
            service.performDecodableGET(request: request) { (result: Result<WMFArticleSearchAPIResponse, Error>) in
                continuation.resume(with: result)
            }
        }
    }
}

// MARK: - Response models

struct WMFArticleSearchAPIResponse: Decodable, Sendable {
    let query: WMFArticleSearchQuery?
}

struct WMFArticleSearchQuery: Decodable, Sendable {
    let pages: [WMFArticleSearchResult]?
    let redirects: [WMFArticleSearchRedirect]?
    let searchinfo: WMFArticleSearchInfo?
}

struct WMFArticleSearchInfo: Decodable, Sendable {
    let suggestion: String?
}

/// The full result of a page search.
public struct WMFArticleSearchResponse: Sendable, Equatable {
    public let results: [WMFArticleSearchResult]
    public let redirects: [WMFArticleSearchRedirect]
    /// A spelling suggestion for the search term.
    public let suggestion: String?

    public init(results: [WMFArticleSearchResult], redirects: [WMFArticleSearchRedirect], suggestion: String?) {
        self.results = results
        self.redirects = redirects
        self.suggestion = suggestion
    }
}

/// A redirect that a search result came from.
public struct WMFArticleSearchRedirect: Decodable, Sendable, Equatable, Hashable {
    public let from: String
    public let to: String

    public init(from: String, to: String) {
        self.from = from
        self.to = to
    }
}

/// The coordinate data of a search result.
public struct WMFArticleSearchCoordinate: Decodable, Sendable, Equatable {
    public let latitude: Double
    public let longitude: Double
    /// The type of the place, for example `city` or `landmark`.
    public let type: String?
    /// The size of the place in meters.
    public let dimension: Int?
    /// The distance from the search coordinate in meters.
    public let distance: Double?

    public init(latitude: Double, longitude: Double, type: String?, dimension: Int?, distance: Double?) {
        self.latitude = latitude
        self.longitude = longitude
        self.type = type
        self.dimension = dimension
        self.distance = distance
    }

    enum CodingKeys: String, CodingKey {
        case latitude = "lat"
        case longitude = "lon"
        case type
        case dimension = "dim"
        case distance = "dist"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        latitude = try container.decode(Double.self, forKey: .latitude)
        longitude = try container.decode(Double.self, forKey: .longitude)
        type = try container.decodeIfPresent(String.self, forKey: .type)
        distance = try container.decodeIfPresent(Double.self, forKey: .distance)

        // The API returns the dimension as a string, for example "1000", "2km" or "500m".
        if let dimensionString = try? container.decodeIfPresent(String.self, forKey: .dimension) {
            dimension = WMFArticleSearchCoordinate.meters(fromDimension: dimensionString)
        } else if let dimensionNumber = try? container.decodeIfPresent(Int.self, forKey: .dimension) {
            dimension = dimensionNumber
        } else {
            dimension = nil
        }
    }

    /// Convert a dimension string to meters. The string has an optional `km` or `m` suffix.
    static func meters(fromDimension dimension: String) -> Int? {
        let digits = dimension.trimmingCharacters(in: CharacterSet.decimalDigits.inverted)
        guard let value = Int(digits), value != 0 else {
            return nil
        }
        return dimension.lowercased().hasSuffix("km") ? value * 1000 : value
    }
}

public struct WMFArticleSearchResult: Decodable, Sendable, Equatable {
    public let pageID: Int
    public let namespace: Int
    public let title: String
    /// The display title. It can contain HTML.
    public let displayTitle: String?
    public let description: String?
    public let index: Int?
    public let thumbnail: WMFArticleSearchThumbnail?
    /// The ID of the latest revision.
    public let revisionID: Int?
    /// The plain text extract of the page.
    public let extract: String?
    public let coordinate: WMFArticleSearchCoordinate?

    public init(pageID: Int, namespace: Int, title: String, displayTitle: String?, description: String?, index: Int?, thumbnail: WMFArticleSearchThumbnail?) {
        self.init(pageID: pageID, namespace: namespace, title: title, displayTitle: displayTitle, description: description, index: index, thumbnail: thumbnail, revisionID: nil, extract: nil, coordinate: nil)
    }

    public init(pageID: Int, namespace: Int, title: String, displayTitle: String?, description: String?, index: Int?, thumbnail: WMFArticleSearchThumbnail?, revisionID: Int?, extract: String?, coordinate: WMFArticleSearchCoordinate?) {
        self.pageID = pageID
        self.namespace = namespace
        self.title = title
        self.displayTitle = displayTitle
        self.description = description
        self.index = index
        self.thumbnail = thumbnail
        self.revisionID = revisionID
        self.extract = extract
        self.coordinate = coordinate
    }

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
        case pageprops
        case description
        case index
        case thumbnail
        case revisions
        case extract
        case coordinates
    }

    private enum PagePropsKeys: String, CodingKey {
        case displaytitle
    }

    private struct Revision: Decodable {
        let revid: Int?
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        pageID = try container.decode(Int.self, forKey: .pageID)
        namespace = try container.decode(Int.self, forKey: .namespace)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        index = try container.decodeIfPresent(Int.self, forKey: .index)
        thumbnail = try container.decodeIfPresent(WMFArticleSearchThumbnail.self, forKey: .thumbnail)
        revisionID = try container.decodeIfPresent([Revision].self, forKey: .revisions)?.first?.revid
        coordinate = try container.decodeIfPresent([WMFArticleSearchCoordinate].self, forKey: .coordinates)?.first

        // The `inprop=displaytitle` and `ppprop=displaytitle` parameters put the display title in different places.
        if let displayTitle = try container.decodeIfPresent(String.self, forKey: .displayTitle) {
            self.displayTitle = displayTitle
        } else if let pageprops = try? container.nestedContainer(keyedBy: PagePropsKeys.self, forKey: .pageprops) {
            displayTitle = try pageprops.decodeIfPresent(String.self, forKey: .displaytitle)
        } else {
            displayTitle = nil
        }

        extract = WMFArticleSearchResult.cleanExtract(try container.decodeIfPresent(String.self, forKey: .extract))
    }

    /// Remove the ellipsis that the API adds to the end of a shortened extract.
    /// An extract that is only an ellipsis becomes nil.
    static func cleanExtract(_ extract: String?) -> String? {
        guard var extract else {
            return nil
        }
        if extract.hasSuffix("...") {
            guard extract.count > 3 else {
                return nil
            }
            extract = String(extract.dropLast(3))
        }
        return extract
    }
}

public struct WMFArticleSearchThumbnail: Decodable, Sendable, Equatable {
    public let source: String?
    public let width: Int?
    public let height: Int?

    public init(source: String?, width: Int? = nil, height: Int? = nil) {
        self.source = source
        self.width = width
        self.height = height
    }

    public var url: URL? {
        guard let source else { return nil }
        return URL(string: source)
    }
}
