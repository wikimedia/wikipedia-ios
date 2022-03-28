import Foundation

enum NotificationsCenterAction: Equatable {
    case markAsReadOrUnread(NotificationsCenterActionData)
    case custom(NotificationsCenterActionData)
    case notificationSubscriptionSettings(NotificationsCenterActionData)
    
    static func == (lhs: NotificationsCenterAction, rhs: NotificationsCenterAction) -> Bool {
        switch lhs {
        case .markAsReadOrUnread(let lhsActionData):
            switch rhs {
            case .markAsReadOrUnread(let rhsActionData):
                return lhsActionData == rhsActionData
            default:
                return false
            }
        case .custom(let lhsActionData):
            switch rhs {
            case .custom(let rhsActionData):
                return lhsActionData == rhsActionData
            default:
                return false
            }
        case .notificationSubscriptionSettings(let lhsActionData):
            switch rhs {
            case .notificationSubscriptionSettings(let rhsActionData):
                return lhsActionData == rhsActionData
            default:
                return false
            }
        }
    }
}

struct NotificationsCenterActionData: Equatable {
    let text: String
    let url: URL?
}
