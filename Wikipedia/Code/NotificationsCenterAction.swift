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
}
