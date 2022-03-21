import Foundation

enum NotificationsCenterAction: Equatable {
    case markAsReadOrUnread(NotificationsCenterActionData)
    case custom(NotificationsCenterActionData)
    case notificationSubscriptionSettings(NotificationsCenterActionData)
}

struct NotificationsCenterActionData: Equatable {
    let text: String
    let url: URL?
}
