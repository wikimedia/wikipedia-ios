import Foundation
import UserNotifications

public protocol WMFLocalNotificationScheduling: Sendable {
    func authorizationStatus() async -> WMFLocalNotificationAuthorizationStatus
    func add(_ notification: WMFLocalNotification) async throws
    func pendingIdentifiers() async -> [String]
    func pendingIdentifiers(type: WMFLocalNotificationType) async -> [String]
    /// Removes both pending and delivered notifications with these identifiers.
    func remove(identifiers: [String]) async
}

/// Live scheduler backed by UNUserNotificationCenter.
public struct WMFUserNotificationCenterScheduler: WMFLocalNotificationScheduling {

    /// Fire dates closer than this use a time interval trigger instead of a calendar trigger.
    private static let timeIntervalTriggerThreshold: TimeInterval = 60

    public init() { }

    private var center: UNUserNotificationCenter {
        UNUserNotificationCenter.current()
    }

    public func authorizationStatus() async -> WMFLocalNotificationAuthorizationStatus {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined: return .notDetermined
        case .denied: return .denied
        case .authorized: return .authorized
        case .provisional: return .provisional
        case .ephemeral: return .ephemeral
        @unknown default: return .unknown
        }
    }

    public func add(_ notification: WMFLocalNotification) async throws {
        let content = UNMutableNotificationContent()
        if let title = notification.title {
            content.title = title
        }
        content.body = notification.body
        content.sound = .default
        content.userInfo = notification.userInfo

        let trigger: UNNotificationTrigger
        let interval = notification.fireDate.timeIntervalSinceNow
        if interval < Self.timeIntervalTriggerThreshold {
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, interval), repeats: false)
        } else {
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: notification.fireDate)
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        }

        let request = UNNotificationRequest(identifier: notification.identifier, content: content, trigger: trigger)
        try await center.add(request)
    }

    public func pendingIdentifiers() async -> [String] {
        await center.pendingNotificationRequests().map { $0.identifier }
    }

    public func pendingIdentifiers(type: WMFLocalNotificationType) async -> [String] {
        await center.pendingNotificationRequests()
            .filter { $0.content.userInfo[WMFLocalNotificationType.userInfoKey] as? String == type.rawValue }
            .map { $0.identifier }
    }

    public func remove(identifiers: [String]) async {
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        center.removeDeliveredNotifications(withIdentifiers: identifiers)
    }
}
