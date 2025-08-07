import Foundation

public struct DidYouKnowCache: Codable {

    // MARK: - Properties

    public var facts: [WMFFeedDidYouKnow]?

    // MARK: - Public

    public init(facts: [WMFFeedDidYouKnow]? = nil ) {
        self.facts = facts
    }
}

