import Foundation

public struct WidgetTopRead: Codable {

    // MARK: - Nested Types

    enum CodingKeys: String, CodingKey {
        case elements = "articles"
    }

    public struct Article: Codable {

        // MARK: - Nested Types

        public struct ViewHistoryDataPoint: Codable {
            let views: Int
        }

        enum CodingKeys: String, CodingKey {
            case views
            case titles
            case pageTitle = "title"
            case displayTitle = "displaytitle"
            case normalizedTitle = "normalizedtitle"
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

        let views: Int
        let titles: WidgetTitles
        let pageTitle: String
        let displayTitle: String
        let normalizedTitle: String
        let timestamp: String
        let viewHistory: [ViewHistoryDataPoint] // ordered from oldest to newest
        let thumbnailImageSource: WidgetImageSource?
        let originalImageSource: WidgetImageSource?
        let language: String
        let languageDirection: String
        let contentURL: WidgetContentURL
        let extract: String
        let extractHTML: String

        // MARK: - Computed Properties

        public var isRTL: Bool {
            return languageDirection.caseInsensitiveCompare("rtl") == .orderedSame
        }

    }

    // MARK: - Properties

    public let elements: [Article]

}
