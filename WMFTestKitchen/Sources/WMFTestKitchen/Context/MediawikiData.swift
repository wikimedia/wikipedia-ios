import Foundation

public struct MediawikiData: Encodable {
    public var database: String?

    public init(database: String? = nil) {
        self.database = database
    }
}
