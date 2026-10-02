import Foundation

/// Every kind of local notification the app can schedule. Add a case here for each new local notification feature.
public enum WMFLocalNotificationType: String, Codable, Sendable, CaseIterable {
    case dailyTopRead

    /// userInfo key used to identify which feature a delivered local notification belongs to.
    public static let userInfoKey = "wmfLocalNotificationType"
}

public struct WMFLocalNotification: Sendable {
    public let type: WMFLocalNotificationType
    public let identifier: String
    public let title: String?
    public let body: String
    public let fireDate: Date
    public let userInfo: [String: String]

    public init(type: WMFLocalNotificationType, identifier: String, title: String? = nil, body: String, fireDate: Date, userInfo: [String: String] = [:]) {
        self.type = type
        self.identifier = identifier
        self.title = title
        self.body = body
        self.fireDate = fireDate
        var userInfo = userInfo
        userInfo[WMFLocalNotificationType.userInfoKey] = type.rawValue
        self.userInfo = userInfo
    }
}

public enum WMFLocalNotificationAuthorizationStatus: String, Codable, Sendable {
    case notDetermined
    case denied
    case authorized
    case provisional
    case ephemeral
    case unknown

    public var isAuthorized: Bool {
        switch self {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined, .denied, .unknown:
            return false
        }
    }
}

/// A persisted record of a local notification lifecycle event, used to investigate scheduling reliability.
public struct WMFLocalNotificationLogEntry: Codable, Sendable, Equatable {

    public enum Event: String, Codable, Sendable {
        case attempt
        case scheduled
        case skippedAlreadyHandled
        case skippedNotAuthorized
        case skippedTooLate
        case failedFetch
        case failedNoContent
        case failedSchedule
        case cancelledByUserVisit
        case cancelledByDisable
        case tapped
    }

    public let timestamp: Date
    public let type: WMFLocalNotificationType
    public let event: Event
    public let appState: String?
    public let authorizationStatus: String?
    public let contentSummary: String?
    public let fireDate: Date?
    public let error: String?

    public init(timestamp: Date = Date(), type: WMFLocalNotificationType, event: Event, appState: String? = nil, authorizationStatus: String? = nil, contentSummary: String? = nil, fireDate: Date? = nil, error: String? = nil) {
        self.timestamp = timestamp
        self.type = type
        self.event = event
        self.appState = appState
        self.authorizationStatus = authorizationStatus
        self.contentSummary = contentSummary
        self.fireDate = fireDate
        self.error = error
    }

    // Dates are persisted as ISO 8601 strings so the exported log file is human-readable.

    enum CodingKeys: String, CodingKey {
        case timestamp, type, event, appState, authorizationStatus, contentSummary, fireDate, error
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.timestamp = try Date(container.decode(String.self, forKey: .timestamp), strategy: .iso8601)
        self.type = try container.decode(WMFLocalNotificationType.self, forKey: .type)
        self.event = try container.decode(Event.self, forKey: .event)
        self.appState = try container.decodeIfPresent(String.self, forKey: .appState)
        self.authorizationStatus = try container.decodeIfPresent(String.self, forKey: .authorizationStatus)
        self.contentSummary = try container.decodeIfPresent(String.self, forKey: .contentSummary)
        self.fireDate = try container.decodeIfPresent(String.self, forKey: .fireDate).map { try Date($0, strategy: .iso8601) }
        self.error = try container.decodeIfPresent(String.self, forKey: .error)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(timestamp.formatted(.iso8601), forKey: .timestamp)
        try container.encode(type, forKey: .type)
        try container.encode(event, forKey: .event)
        try container.encodeIfPresent(appState, forKey: .appState)
        try container.encodeIfPresent(authorizationStatus, forKey: .authorizationStatus)
        try container.encodeIfPresent(contentSummary, forKey: .contentSummary)
        try container.encodeIfPresent(fireDate?.formatted(.iso8601), forKey: .fireDate)
        try container.encodeIfPresent(error, forKey: .error)
    }
}
