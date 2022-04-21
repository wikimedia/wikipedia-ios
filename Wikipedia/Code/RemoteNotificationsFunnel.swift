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
        let action: String
        let selection_token: String?
    }
    private func event(notificationId: Int, notificationWiki: String, notificationType: String, action: RemoteNotificationAction, selectionToken: String?) {
        let event = Event(is_anon: isAnon.boolValue, notification_id: notificationId, notification_wiki: notificationWiki, notification_type: notificationType, action: action.rawValue, selection_token: selectionToken)
        EventPlatformClient.shared.submit(stream: .remoteNotificationsInteraction, event: event)
    }
    
    public func logNotificationInteraction(notificationId: Int, notificationWiki: String, notificationType: String, action: RemoteNotificationAction, selectionToken: String?) {
        event(notificationId: notificationId,
              notificationWiki: notificationWiki,
              notificationType: notificationType,
              action: action,
              selectionToken: selectionToken)
    }

}

public enum RemoteNotificationAction: String {
     case markRead = "mark_read"
     case markUnread = "mark_unread"
     case userTalk = "user_talk"
     case senderPage = "sender_page"
     case diff = "diff"
     case articleTalk = "article_talk"
     case article = "article"
     case wikidataItem = "wikidata_item"
     case listGroupRights = "list_group_rights"
     case linkedFromArticle = "linked_from_article"
     case settings = "settings"
 }
