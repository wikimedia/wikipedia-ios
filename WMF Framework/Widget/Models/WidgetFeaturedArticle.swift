import Foundation

public struct WidgetFeaturedArticle: Codable {

    // MARK: - Nested Types

    enum CodingKeys: String, CodingKey {
        case displayTitle = "displaytitle"
        case description
        case extract
        case languageCode = "lang"
        case languageDirection = "dir"
        case contentURL = "content_urls"
        case thumbnailImageSource = "thumbnail"
        case originalImageSource = "originalimage"
    }

    // MARK: - Properties

    // From supported language list at https://www.mediawiki.org/wiki/Wikifeeds
    static let supportedLanguageCodes = ["bg", "bn", "bs", "cs", "de", "el", "en", "fa", "he", "hu", "ja", "la", "no", "sco", "sd", "sv", "ur", "vi", "zh"]

    // Only what the widget renders is required: everything else is decoded when present.
    public var displayTitle: String
    public let description: String?
    public let extract: String?
    public let languageCode: String
    public let languageDirection: String?
    public let contentURL: WidgetContentURL
    public var thumbnailImageSource: WidgetImageSource?
    public var originalImageSource: WidgetImageSource?

    /// Runtime-only (excluded from `CodingKeys`): true when served from cache as a fallback, so
    /// the widget timeline can schedule an earlier retry for fresh content.
    public var isFromCacheFallback: Bool = false

    // MARK: - Computed Properties

    public var isRTL: Bool {
        return languageDirection?.caseInsensitiveCompare("rtl") == .orderedSame
    }
    
}
