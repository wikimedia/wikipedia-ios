import Foundation

enum NotificationsCenterAction: Equatable {
    case markAsReadOrUnread(NotificationsCenterActionData)
    case custom(NotificationsCenterActionData)
    case notificationSubscriptionSettings(NotificationsCenterActionData)

    var actionData: NotificationsCenterActionData? {
        switch self {
        case .notificationSubscriptionSettings(let data), .markAsReadOrUnread(let data), .custom(let data):
            return data
        }
    }
}

struct NotificationsCenterActionData: Equatable {
    let text: String
    let url: URL?
    let iconType: NotificationsCenterIconType?
    let destinationText: String?
    let actionType: RemoteNotificationAction?
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
