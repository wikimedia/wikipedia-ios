
import Foundation

/// Shared cache object used by the Notifications Service Extension for persisted values set in the main app, and vice versa.
public struct PushNotificationsCache: Codable {
    public var settings: PushNotificationsSettings
    public var notifications: Set<RemoteNotificationsAPIController.NotificationsResult.Notification>
    
    public init(settings: PushNotificationsSettings, notifications: Set<RemoteNotificationsAPIController.NotificationsResult.Notification>) {
        self.settings = settings
        self.notifications = notifications
    }
}
