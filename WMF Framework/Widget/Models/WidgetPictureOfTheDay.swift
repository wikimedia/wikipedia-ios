import Foundation

public struct WidgetPictureOfTheDay: Codable {

    // MARK: - Nested Types

    enum CodingKeys: String, CodingKey {
        case description
        case license
        case thumbnailImageSource = "thumbnail"
        case originalImageSource = "image"
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
        public let html: String
        public let language: String
    }

    // MARK: - Properties

    public let description: Description
    public let license: License
    public var thumbnailImageSource: WidgetImageSource?
    public var originalImageSource: WidgetImageSource?

}
