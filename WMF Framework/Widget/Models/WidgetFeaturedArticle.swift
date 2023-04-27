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

    public var displayTitle: String
    public let description: String?
    public let extract: String
    public let languageCode: String
    public let languageDirection: String
    public let contentURL: WidgetContentURL
    public var thumbnailImageSource: WidgetImageSource?
    public var originalImageSource: WidgetImageSource?

    // MARK: - Computed Properties

    public var isRTL: Bool {
        return languageDirection.caseInsensitiveCompare("rtl") == .orderedSame
    }
    
}
