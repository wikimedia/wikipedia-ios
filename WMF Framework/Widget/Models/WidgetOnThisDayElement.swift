import Foundation

public struct WidgetOnThisDayElement: Codable {

    // MARK: - Nested Types

    public struct Page: Codable {

        // MARK: - Nested Types

        enum CodingKeys: String, CodingKey {
            case title
            case displayTitle = "displaytitle"
            case normalizedTitle = "normalizedtitle"
            case description
            case language = "lang"
            case languageDirection = "dir"
            case extract
            case extractHTML = "extract_html"
            case contentURL = "content_urls"
            case thumbnailImageSource = "thumbnail"
            case originalImageSource = "originalimage"
        }

        // MARK: - Properties

        let title: String
        let displayTitle: String
        let normalizedTitle: String
        let description: String?
        let language: String
        let languageDirection: String
        let extract: String
        let extractHTML: String
        let contentURL: WidgetContentURL
        let thumbnailImageSource: WidgetImageSource?
        let originalImageSource: WidgetImageSource?

        // MARK: - Computed Properties

        public var isRTL: Bool {
            return languageDirection.caseInsensitiveCompare("rtl") == .orderedSame
        }
        
    }

    // MARK: - Properties

    let text: String
    let year: Int
    let pages: [Page]

}

