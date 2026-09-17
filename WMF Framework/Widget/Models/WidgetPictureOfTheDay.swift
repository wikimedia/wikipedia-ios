import Foundation

public struct WidgetPictureOfTheDay: Codable {

    // MARK: - Nested Types

    enum CodingKeys: String, CodingKey {
        case description
        case license
        case thumbnailImageSource = "thumbnail"
        case originalImageSource = "image"
        case structured
    }

    /// Structured data from Commons (Wikibase). The captions are per language code.
    public struct Structured: Codable {
        public let captions: [String: String]?
    }

    public struct License: Codable {
        public let type: String?
        public let code: String?
        public let url: String?
    }

    public struct Description: Codable {
        enum CodingKeys: String, CodingKey {
            case text
            case html
            case language = "lang"
        }

        public let text: String
        public let html: String?
        public let language: String?
    }

    // MARK: - Properties

    // The feed omits `description` when the Commons file has no caption in the wiki's language,
    // and `license` is not guaranteed either.
    public let description: Description?
    public let license: License?
    public var thumbnailImageSource: WidgetImageSource?
    public var originalImageSource: WidgetImageSource?
    public let structured: Structured?

    // MARK: - Public

    /// The text to show under the image: the feed description when there is one, otherwise the
    /// structured caption from Commons in the preferred language, then in English, then any.
    /// The image gallery in the app falls back the same way, so both show the same caption.
    public func caption(preferringLanguageCode languageCode: String?) -> String? {
        if let text = description?.text, !text.isEmpty {
            return text
        }
        guard let captions = structured?.captions, !captions.isEmpty else {
            return nil
        }
        if let languageCode = languageCode, let caption = captions[languageCode], !caption.isEmpty {
            return caption
        }
        if let caption = captions["en"], !caption.isEmpty {
            return caption
        }
        return captions.sorted { $0.key < $1.key }.first { !$0.value.isEmpty }?.value
    }

}
