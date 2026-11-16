import Foundation

/// The interests the Discover reading list is built from. Kept apart from the For You interests,
/// like on Android, so a change on one screen never shows on the other.
public struct WMFDiscoverInterests: Codable, Sendable, Equatable {

    /// An article the reader picked as an interest, on the wiki it was picked from.
    public struct Page: Codable, Sendable, Hashable {
        public let title: String
        public let project: WMFProject

        public init(title: String, project: WMFProject) {
            self.title = title
            self.project = project
        }

        /// True when both pages name the same article on the same wiki, whatever the spacing of the title.
        public func matches(_ other: Page) -> Bool {
            project == other.project && title.normalizedForCoreData == other.title.normalizedForCoreData
        }
    }

    public static let empty = WMFDiscoverInterests(topics: [], pages: [])

    /// Selected topics, in the order the reader selected them.
    public var topics: [WMFArticleTopic]

    /// Selected articles, in the order the reader selected them.
    public var pages: [Page]

    public init(topics: [WMFArticleTopic], pages: [Page]) {
        self.topics = topics
        self.pages = pages
    }

    /// A topic the app no longer knows is dropped instead of failing the whole decode.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let rawTopics = try container.decodeIfPresent([String].self, forKey: .topics) ?? []
        let topics = rawTopics.compactMap(WMFArticleTopic.init(rawValue:))
        let pages = try container.decodeIfPresent([Page].self, forKey: .pages) ?? []
        self.init(topics: topics, pages: pages)
    }

    public var isEmpty: Bool {
        topics.isEmpty && pages.isEmpty
    }

    public var count: Int {
        topics.count + pages.count
    }

    public func contains(_ page: Page) -> Bool {
        pages.contains { $0.matches(page) }
    }
}
