import Foundation

public struct DidYouKnowCache: Codable {

    // MARK: - Properties

    public var didYouKnowItems: [WMFFeedDidYouKnow]?

    // MARK: - Public

    public init(didYouKnowItems: [WMFFeedDidYouKnow]? = nil ) {
        self.didYouKnowItems = didYouKnowItems
    }
}

