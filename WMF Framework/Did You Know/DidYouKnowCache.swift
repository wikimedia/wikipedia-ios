import Foundation
import WMFData

public struct DidYouKnowCache: Codable {

    // MARK: - Properties

    public var didYouKnowItems: [WMFDidYouKnow]?

    // MARK: - Public

    public init(didYouKnowItems: [WMFDidYouKnow]? = nil ) {
        self.didYouKnowItems = didYouKnowItems
    }
}

