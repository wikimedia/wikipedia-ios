import Foundation

public struct WMFRiveAnimation: Sendable, Equatable {

    public let resourceName: String
    public let artboardName: String?
    public let stateMachineName: String?

    public init(resourceName: String, artboardName: String? = nil, stateMachineName: String? = nil) {
        self.resourceName = resourceName
        self.artboardName = artboardName
        self.stateMachineName = stateMachineName
    }
}

public nonisolated struct WMFRiveText: Sendable, Hashable {

    public let path: String

    public init(path: String) {
        self.path = path
    }
}

public nonisolated struct WMFRiveNumber: Sendable, Hashable {

    public let path: String

    public init(path: String) {
        self.path = path
    }
}
