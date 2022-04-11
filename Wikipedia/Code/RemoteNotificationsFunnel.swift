import Foundation

final class RemoteNotificationsFunnel: EventLoggingFunnel, EventLoggingStandardEventProviding {
    private enum Action: String, Codable {
        case notificationInteraction = "ios_notification_interaction"
    }
    
    public static let shared = RemoteNotificationsFunnel()
    
    private struct Event: EventInterface {
        static let schema: EventPlatformClient.Schema = .remoteNotificationsInteraction
        let is_anon: Bool
        let notification_id: Int
        let notification_wiki: String
        let notification_type: String
        let action_rank: Int
        let selection_token: String?
    }
    private func event(notificationId: Int, notificationWiki: String, notificationType: String, actionRank: ActionRank, selectionToken: String?) {
        let event = Event(is_anon: isAnon.boolValue, notification_id: notificationId, notification_wiki: notificationWiki, notification_type: notificationType, action_rank: actionRank.rawValue, selection_token: selectionToken)
        EventPlatformClient.shared.submit(stream: .remoteNotificationsInteraction, event: event)
    }
    
    public func logNotificationInteraction(notificationId: Int, notificationWiki: String, notificationType: String, actionRank: ActionRank, selectionToken: String?) {
        event(notificationId: notificationId,
              notificationWiki: notificationWiki,
              notificationType: notificationType,
              actionRank: actionRank,
              selectionToken: selectionToken)
    }
    
    enum ActionRank: Int {
        case markReadOrUnread = 0
    }
}
