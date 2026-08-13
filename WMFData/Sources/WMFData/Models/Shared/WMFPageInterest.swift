import Foundation

public struct WMFPageInterest: Sendable {
    public let title: String
    public let timestamp: Date

    /// The project the interest was saved from.
    ///
    /// Populated when the interests are read back without filtering by project, so the caller can
    /// tell which wiki each one came from. Nil when the caller already filtered by project.
    public let project: WMFProject?

    public init(title: String, timestamp: Date, project: WMFProject? = nil) {
        self.title = title
        self.timestamp = timestamp
        self.project = project
    }
}
