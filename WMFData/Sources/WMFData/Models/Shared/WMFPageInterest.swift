import Foundation

public struct WMFPageInterest: Sendable {
    public let title: String
    public let timestamp: Date

    public init(title: String, timestamp: Date) {
        self.title = title
        self.timestamp = timestamp
    }
}
