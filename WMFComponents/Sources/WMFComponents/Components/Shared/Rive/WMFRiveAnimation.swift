import Foundation

public struct WMFRiveAnimation: Sendable, Equatable {

    public let resourceName: String
    public let artboardName: String?
    public let stateMachineName: String?
    /// The name of the view model instance that holds the flags of the artboard, such as `isUIWhite`.
    /// `nil` means the instance has the name of the artboard.
    public let viewModelInstanceName: String?

    public init(resourceName: String, artboardName: String? = nil, stateMachineName: String? = nil, viewModelInstanceName: String? = nil) {
        self.resourceName = resourceName
        self.artboardName = artboardName
        self.stateMachineName = stateMachineName
        self.viewModelInstanceName = viewModelInstanceName
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

/// An image property in the .riv, such as an article thumbnail.
public nonisolated struct WMFRiveImage: Sendable, Hashable {

    public let path: String

    public init(path: String) {
        self.path = path
    }
}

/// A boolean property in the .riv that the app reads, such as a flag that the artwork sets.
public nonisolated struct WMFRiveBool: Sendable, Hashable {

    public let path: String

    public init(path: String) {
        self.path = path
    }
}
