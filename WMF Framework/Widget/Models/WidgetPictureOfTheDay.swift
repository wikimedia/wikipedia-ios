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
        let type: String
        let url: String
    }

    public struct Description: Codable {
        enum CodingKeys: String, CodingKey {
            case text
            case html
            case language = "lang"
        }

        let text: String
        let html: String
        let language: String
    }

    // MARK: - Properties

    let description: Description
    let license: License
    let thumbnailImageSource: WidgetImageSource? // thumbnail
    let originalImageSource: WidgetImageSource? // image

}
