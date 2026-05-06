import Foundation

public struct InteractionData {
    public let action: String?
    public let actionSubtype: String?
    public let actionSource: String?
    public let actionContext: String?
    public let elementId: String?
    public let elementFriendlyName: String?

    public init(
        action: String? = nil,
        actionSubtype: String? = nil,
        actionSource: String? = nil,
        actionContext: String? = nil,
        elementId: String? = nil,
        elementFriendlyName: String? = nil
    ) {
        self.action = action
        self.actionSubtype = actionSubtype
        self.actionSource = actionSource
        self.actionContext = actionContext
        self.elementId = elementId
        self.elementFriendlyName = elementFriendlyName
    }
}
