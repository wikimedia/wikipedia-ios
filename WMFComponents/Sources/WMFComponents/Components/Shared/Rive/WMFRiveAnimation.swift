import Foundation
import SwiftUI

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

/// An enum property in the .riv. Its value is the name of one of the enum cases in the file.
public nonisolated struct WMFRiveEnum: Sendable, Hashable {

    public let path: String

    public init(path: String) {
        self.path = path
    }
}

/// An enum property in the .riv that lays the artboard out from left to right or from right to left.
/// `WMFRiveView` sets it from the layout direction of the view, which follows the app language.
public nonisolated struct WMFRiveLayoutDirection: Sendable, Hashable {

    public let property: WMFRiveEnum
    /// The name of the enum case for a left-to-right layout.
    public let leftToRight: String
    /// The name of the enum case for a right-to-left layout.
    public let rightToLeft: String

    public init(property: WMFRiveEnum, leftToRight: String = "Left to Right", rightToLeft: String = "Right to Left") {
        self.property = property
        self.leftToRight = leftToRight
        self.rightToLeft = rightToLeft
    }

    /// The enum case for `layoutDirection`.
    public func value(for layoutDirection: LayoutDirection) -> String {
        layoutDirection == .rightToLeft ? rightToLeft : leftToRight
    }
}
