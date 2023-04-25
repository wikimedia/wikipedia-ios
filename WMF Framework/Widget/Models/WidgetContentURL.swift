import Foundation

public struct WidgetContentURL: Codable {

    // MARK: - Nested Types

    public struct PageURL: Codable {
        public let page: String
    }

    // MARK: - Properties

    public let desktop: PageURL

}
