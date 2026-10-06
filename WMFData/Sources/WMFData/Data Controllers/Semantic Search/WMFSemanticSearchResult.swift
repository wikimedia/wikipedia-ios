import Foundation

/// One passage returned by the semantic search API. `snippetHTML` keeps the API markup: the
/// answer is wrapped in `<span class="searchmatch">` and entities are not decoded.
public struct WMFSemanticSearchResult: Sendable, Equatable {
    public let pageID: Int
    public let title: String
    public let snippetHTML: String
    public let sectionTitle: String?
    public let redirectTitle: String?
    public let thumbnailURL: URL?

    public init(pageID: Int, title: String, snippetHTML: String, sectionTitle: String?, redirectTitle: String?, thumbnailURL: URL?) {
        self.pageID = pageID
        self.title = title
        self.snippetHTML = snippetHTML
        self.sectionTitle = sectionTitle
        self.redirectTitle = redirectTitle
        self.thumbnailURL = thumbnailURL
    }
}

/// The semantic search results of one request, in the order the API ranked them.
public struct WMFSemanticSearchResults: Sendable, Equatable {
    public let results: [WMFSemanticSearchResult]

    public init(results: [WMFSemanticSearchResult]) {
        self.results = results
    }
}

/// Trust signals of an article from the Attribution API. Every value is optional because the
/// API returns null for signals it does not have yet.
public struct WMFSemanticSearchAttribution: Sendable, Equatable {
    public let contributorCount: Int?
    public let referenceCount: Int?
    public let lastUpdated: Date?

    public init(contributorCount: Int?, referenceCount: Int?, lastUpdated: Date?) {
        self.contributorCount = contributorCount
        self.referenceCount = referenceCount
        self.lastUpdated = lastUpdated
    }
}
