import Foundation

public struct WidgetOnThisDayElement: Codable {

    // MARK: - Nested Types

    enum CodingKeys: String, CodingKey {
        case text
        case year
        case pages
    }

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

        let title: String?
        let displayTitle: String
        let normalizedTitle: String?
        let description: String?
        let language: String?
        let languageDirection: String?
        let extract: String?
        let extractHTML: String?
        let contentURL: WidgetContentURL
        let thumbnailImageSource: WidgetImageSource?
        let originalImageSource: WidgetImageSource?

        // MARK: - Computed Properties

        public var isRTL: Bool {
            return languageDirection?.caseInsensitiveCompare("rtl") == .orderedSame
        }
        
    }

    // MARK: - Properties

    let text: String
    let year: Int
    let pages: [Page]

    /// Pages dropped while decoding `pages`, for diagnostics. Not persisted.
    public var droppedPageErrors: [String] = []

    // MARK: - Public

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        text = try container.decode(String.self, forKey: .text)
        year = try container.decode(Int.self, forKey: .year)
        // A page without a required key is dropped; the event itself is kept.
        let lossyPages = try container.decodeIfPresent(WidgetLossyDecodingArray<Page>.self, forKey: .pages)
        pages = lossyPages?.elements ?? []
        droppedPageErrors = lossyPages?.droppedElementErrors ?? []
    }

}
