import Foundation

/// A lightweight model to uniquely identify incoming push notifications
@objc public class PushNotificationContentIdentifier: NSObject, Codable {

    // MARK: - Properties

    fileprivate static let dictionaryKey = "WMFPushNotificationContentIdentifier"

    public let key: String
    public let date: Date?

    // MARK: - Lifecycle

    public init(key: String, date: Date?) {
        self.key = key
        self.date = date
    }

    // MARK: - Public Utilities

    public static func save(_ identifiers: [PushNotificationContentIdentifier], to userInfo: inout [AnyHashable: Any]) {
        let encoded = try? JSONEncoder().encode(identifiers)
        if let encoded = encoded {
            userInfo[dictionaryKey] = encoded
        }
    }

    @objc public static func load(from userInfo: [AnyHashable: Any]) -> [PushNotificationContentIdentifier] {
        guard let data = userInfo[dictionaryKey] as? Data, let decoded = try? JSONDecoder().decode([PushNotificationContentIdentifier].self, from: data) else {
            return []
        }

        return decoded
    }

}
