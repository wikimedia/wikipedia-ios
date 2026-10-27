import Foundation

/// One article in the current Discover reading list.
public struct WMFDiscoverRecommendedPage: Sendable, Equatable, Identifiable {

    public var id: String { "\(project.id)|\(title)" }

    /// The canonical page title. Use it for keys and URLs.
    public let title: String
    /// The title to show. It can contain HTML, like a summary's display title. Falls back to `title`.
    public let displayTitle: String
    public let project: WMFProject
    public let description: String?
    public let thumbnailURL: URL?
    public let extract: String?

    /// When the article entered the current list.
    public let recommendedDate: Date

    public init(title: String, displayTitle: String? = nil, project: WMFProject, description: String?, thumbnailURL: URL?, extract: String?, recommendedDate: Date) {
        self.title = title
        self.displayTitle = displayTitle ?? title
        self.project = project
        self.description = description
        self.thumbnailURL = thumbnailURL
        self.extract = extract
        self.recommendedDate = recommendedDate
    }
}
