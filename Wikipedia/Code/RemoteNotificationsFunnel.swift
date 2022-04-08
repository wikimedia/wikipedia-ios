import Foundation

final class RemoteNotificationsFunnel: EventLoggingFunnel, EventLoggingStandardEventProviding {
    private enum Action: String, Codable {
        case notificationInteraction = "ios_notification_interaction"
    }
    
    public static let shared = RemoteNotificationsFunnel()
    
    private struct Event: EventInterface {
        static let schema: EventPlatformClient.Schema = .remoteNotificationsInteraction
        let action: Action
        let anon: Bool
        let notification_id: Int
        let notification_wiki: String
        let notification_type: String
        let action_rank: Int
        let selection_token: String?
    }
    private func event(notificationId: Int, notificationWiki: String, notificationType: String, actionRank: Rank, selectionToken: String?) {
        let event = Event(action: .notificationInteraction, anon: isAnon.boolValue, notification_id: 1, notification_wiki: "", notification_type: "", action_rank: actionRank.rawValue, selection_token: selectionToken)
        EventPlatformClient.shared.submit(stream: .remoteNotificationsInteraction, event: event)
    }
    
    public func logNotificationInteraction(notificationId: Int, notificationWiki: String, notificationType: String, actionRank: Rank, selectionToken: String?) {
        event(notificationId: notificationId, notificationWiki: notificationWiki, notificationType: notificationType, actionRank: actionRank, selectionToken: selectionToken)
        
    }
    
    enum Rank: Int {
        case markReadOrUnread = 0
    }
}
