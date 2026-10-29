import Foundation

/// The order of saved articles and reading lists. The raw values match the legacy `sortOrder`
/// stored on each reading list, so a choice made before the rewrite is kept.
public enum WMFReadingListSortOrder: Int, Codable, Sendable, CaseIterable {
    case byTitle = 0
    case byRecentlyAdded = 1
}

public enum WMFSavedArticleAlertType: Equatable, Sendable {
    case listLimitExceeded(limit: Int)
    case entryLimitExceeded(limit: Int)
    case genericNotSynced
    case downloading
    case articleError(String)
    case none
}

public enum WMFReadingListAlertType: Equatable, Sendable {
    case listLimitExceeded(limit: Int)
    case entryLimitExceeded(limit: Int)
    case none
}

/// A saved article as the Saved tab shows it. The description and thumbnail come from the
/// article record on device; the rows do not call the network.
///
/// `title` is the canonical page title. Use it to build article URLs and database keys.
/// `displayTitle` can differ from it (for example "iPhone" for the page "IPhone"). Use it
/// only to show, search and sort.
public struct WMFSavedArticle: Identifiable, Equatable, Sendable {
    public let id: String
    public let title: String
    public let displayTitle: String
    public let project: WMFProject
    public let savedDate: Date?
    public let description: String?
    /// The first lines of the article, shown in the long-press preview.
    public let snippet: String?
    public let thumbnailURL: URL?
    public var readingListNames: [String]
    public var alertType: WMFSavedArticleAlertType

    public init(
        id: String,
        title: String,
        displayTitle: String? = nil,
        project: WMFProject,
        savedDate: Date?,
        description: String? = nil,
        snippet: String? = nil,
        thumbnailURL: URL? = nil,
        readingListNames: [String],
        alertType: WMFSavedArticleAlertType = .none
    ) {
        self.id = id
        self.title = title
        self.displayTitle = displayTitle ?? title
        self.project = project
        self.savedDate = savedDate
        self.description = description
        self.snippet = snippet
        self.thumbnailURL = thumbnailURL
        self.readingListNames = readingListNames
        self.alertType = alertType
    }
}

public struct WMFReadingList: Identifiable, Equatable, Sendable {
    public let id: String
    public let name: String
    public let description: String?
    public let isDefault: Bool
    public let createdDate: Date?
    public let articleCount: Int
    /// The ids of the articles in the list, in the same format as `WMFSavedArticle.id`.
    public let articleIDs: Set<String>
    /// Up to four thumbnails for the list cell.
    public let previewThumbnailURLs: [URL]
    public let alertType: WMFReadingListAlertType
    public let sortOrder: WMFReadingListSortOrder?

    public init(
        id: String,
        name: String,
        description: String?,
        isDefault: Bool,
        createdDate: Date?,
        articleCount: Int,
        articleIDs: Set<String>,
        previewThumbnailURLs: [URL] = [],
        alertType: WMFReadingListAlertType = .none,
        sortOrder: WMFReadingListSortOrder? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.isDefault = isDefault
        self.createdDate = createdDate
        self.articleCount = articleCount
        self.articleIDs = articleIDs
        self.previewThumbnailURLs = previewThumbnailURLs
        self.alertType = alertType
        self.sortOrder = sortOrder
    }
}

/// Which reading lists a screen wants.
public enum WMFReadingListsFilter: Equatable, Sendable {
    /// The Reading lists segment: every list, the default one only when it is enabled.
    case all
    /// The "Add to reading list" sheet: lists that do not already hold every one of these articles.
    case excludingListsContainingAll(articleIDs: Set<String>)
    /// The "+N" tag on a saved article: these lists only.
    case named([String])
}
