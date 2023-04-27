import Foundation

public struct WidgetImageSource: Codable {

    // MARK: - Nested Types

    enum CodingKeys: String, CodingKey {
        case source
        case width
        case height
        case data
    }

    // MARK: - Properties

    public var source: String
    public let width: Int
    public let height: Int

    // Data is populated via local network request, not via API featured content API request
    public var data: Data?

}
