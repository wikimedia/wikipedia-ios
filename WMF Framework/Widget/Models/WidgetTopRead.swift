import Foundation

public struct WidgetTopRead: Codable {

    // MARK: - Nested Types

    enum CodingKeys: String, CodingKey {
        case dateString = "date"
        case elements = "articles"
    }

    public struct Article: Codable {

        // MARK: - Nested Types

        public struct ViewHistoryDataPoint: Codable {
            public let views: Int
        }

        enum CodingKeys: String, CodingKey {
            case views
            case titles
            case pageTitle = "title"
            case displayTitle = "displaytitle"
            case normalizedTitle = "normalizedtitle"
            case description
            case timestamp
            case viewHistory = "view_history"
            case thumbnailImageSource = "thumbnail"
            case originalImageSource = "originalimage"
            case language = "lang"
            case languageDirection = "dir"
            case contentURL = "content_urls"
            case extract
            case extractHTML = "extract_html"
        }

        // MARK: - Properties

        public let views: Int
        public let titles: WidgetTitles
        public let pageTitle: String
        public let displayTitle: String
        public let normalizedTitle: String
        public let description: String?
        public let timestamp: String
        public let viewHistory: [ViewHistoryDataPoint] // ordered from oldest to newest
        public var thumbnailImageSource: WidgetImageSource?
        public let originalImageSource: WidgetImageSource?
        public let language: String
        public let languageDirection: String
        public let contentURL: WidgetContentURL
        public let extract: String
        public let extractHTML: String

        // MARK: - Computed Properties

        public var isRTL: Bool {
            return languageDirection.caseInsensitiveCompare("rtl") == .orderedSame
        }

    }

    // MARK: - Properties

    public var dateString: String?
    public var elements: [Article]

    public var topFourElements: [Article] {
        return Array(elements.prefix(4))
    }

}
