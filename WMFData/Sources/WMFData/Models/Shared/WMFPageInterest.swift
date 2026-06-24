import Foundation

public struct WMFPageInterest: Sendable {
    public let title: String
    public let projectID: String
    public let timestamp: Date

    public init(title: String, projectID: String, timestamp: Date) {
        self.title = title
        self.projectID = projectID
        self.timestamp = timestamp
    }
}
