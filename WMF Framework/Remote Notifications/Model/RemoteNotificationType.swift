import Foundation

public enum RemoteNotificationType: Hashable {
    case userTalkPageMessage //Message on your talk page
    case mentionInTalkPage //Mention in article talk
    case mentionInEditSummary //Mention in edit summary
    case successfulMention //Successful mention
    case failedMention //Failed mention
    case editReverted //Edit reverted
    case userRightsChange //Usage rights change
    case pageReviewed //Page review
    case pageLinked //Page link
    case connectionWithWikidata //Wikidata link
    case emailFromOtherUser //Email from other user
    case thanks //Thanks
    case translationMilestone(Int) //Translation milestone
    case editMilestone //Editing milestone
    case welcome //Welcome
    case loginFailUnknownDevice //Failed log in from an unfamiliar device
    case loginFailKnownDevice //Log in Notify
    case loginSuccessUnknownDevice //Successful log in unfamiliar device
    case unknownSystemAlert //No specific type ID, system alert type
    case unknownSystemNotice //No specific type ID, system notice type
    case unknownNotice //No specific type ID, notice type
    case unknownAlert //No specific type ID, alert type
    case unknown
    case other
    
//Possible flow-related notifications to target. Leaving it to default handling for now but we may need to bring these in for special handling.
//    case flowUserTalkPageNewTopic //Message on your talk page
//    case flowUserTalkPageReply //Reply on your talk page
//    case flowDiscussionNewTopic //??
//    case flowDiscussionReply //Reply on an article talk page
//    case flowMention //Mention in article talk
//    case flowThanks //Thanks
}

public extension RemoteNotificationType {
    var imageName: String {
        // Return image for the notification type
        switch self {
        case .userTalkPageMessage:
            return "notifications-type-user-talk-message"
        case .mentionInTalkPage, .mentionInEditSummary, .successfulMention, .failedMention:
            return "notifications-type-mention"
        case .editReverted:
            return "notifications-type-edit-revert"
        case .userRightsChange:
            return "notifications-type-user-rights"
        case .pageReviewed:
            return "notifications-type-page-reviewed"
        case .pageLinked, .connectionWithWikidata:
            return "notifications-type-link"
        case .thanks:
            return "notifications-type-thanks"
        case .welcome, .translationMilestone(_), .editMilestone:
            return "notifications-type-milestone"
        case .loginFailKnownDevice, .loginFailUnknownDevice, .loginSuccessUnknownDevice,
             .unknownSystemAlert, .unknownAlert:
            return "notifications-type-login-notify"
        case .emailFromOtherUser:
            return "notifications-type-email"
        default:
            return "notifications-type-default"
        }
    }
    
    func imageBackgroundColorWithTheme(_ theme: Theme) -> UIColor {
        switch self {
        case .editMilestone, .translationMilestone(_), .welcome, .thanks:
            return theme.colors.accent
        case .loginFailKnownDevice, .loginFailUnknownDevice, .loginSuccessUnknownDevice:
            return theme.colors.error
        case .failedMention, .editReverted, .userRightsChange:
            return theme.colors.warning
        default:
            return theme.colors.link
        }
    }
    
    init?(from filterIdentifier: String) {
        
        switch filterIdentifier {
            case "userTalkPageMessage":
                self = .userTalkPageMessage
            case "pageReviewed":
                self = .pageReviewed
            case "pageLinked":
                self = .pageLinked
            case "connectionWithWikidata":
                self = .connectionWithWikidata
            case "emailFromOtherUser":
                self = .emailFromOtherUser
            case "mentionInTalkPage":
                self = .mentionInTalkPage
            case "mentionInEditSummary":
                self = .mentionInEditSummary
            case "successfulMention":
                self = .successfulMention
            case "failedMention":
                self = .failedMention
            case "userRightsChange":
                self = .userRightsChange
            case "editReverted":
                self = .editReverted
            case "loginFailKnownDevice", //for filters this represents both known and unknown devices
                    "loginFailUnknownDevice":
                self = .loginFailKnownDevice
            case "loginSuccessUnknownDevice":
                self = .loginSuccessUnknownDevice
            case "editMilestone":
                self = .editMilestone
            case "translationMilestone":
                self = .translationMilestone(1) //for filters this represents other translation associated values as well (ten, hundred milestones).
            case "thanks":
                self = .thanks
            case "welcome":
                self = .welcome
            default:
                return nil
        }
    }
    
    var filterIdentifier: String? {
        switch self {
        case .userTalkPageMessage:
            return "userTalkPageMessage"
        case .pageReviewed:
            return "pageReviewed"
        case .pageLinked:
            return "pageLinked"
        case .connectionWithWikidata:
            return "connectionWithWikidata"
        case .emailFromOtherUser:
            return "emailFromOtherUser"
        case .mentionInTalkPage:
            return "mentionInTalkPage"
        case .mentionInEditSummary:
            return "mentionInEditSummary"
        case .successfulMention:
            return "successfulMention"
        case .failedMention:
            return "failedMention"
        case .userRightsChange:
            return "userRightsChange"
        case .editReverted:
            return "editReverted"
        case .loginFailKnownDevice, //for filters this represents both known and unknown devices
                .loginFailUnknownDevice:
            return "loginFailKnownDevice"
        case .loginSuccessUnknownDevice:
            return "loginSuccessUnknownDevice"
        case .editMilestone:
            return "editMilestone"
        case .translationMilestone:
            return "translationMilestone" //for filters this represents other translation associated values as well (ten, hundred milestones).
        case .thanks:
            return "thanks"
        case .welcome:
            return "welcome"
        default:
            return nil
        }
    }
}

public extension RemoteNotificationType {
    
    static var orderingForFilters: [RemoteNotificationType] {
        return [
            .userTalkPageMessage,
            .pageReviewed,
            .pageLinked,
            .connectionWithWikidata,
            .emailFromOtherUser,
            .mentionInTalkPage,
            .mentionInEditSummary,
            .successfulMention,
            .failedMention,
            .userRightsChange,
            .editReverted,
            .loginFailKnownDevice, //for filters this represents both known and unknown devices
            .loginSuccessUnknownDevice,
            .editMilestone,
            .translationMilestone(1), //for filters this represents other translation associated values as well (ten, hundred milestones).
            .thanks,
            .welcome,
            .other
        ]
    }
    
    var title: String {
        switch self {
        case .userTalkPageMessage:
            return WMFLocalizedString("notifications-center-type-title-user-talk-page-messsage", value: "Talk page message", comment: "Title of \"user talk page message\" notification type. Used on filters view toggles and the notification detail view.")
        case .pageReviewed:
            return WMFLocalizedString("notifications-center-type-title-page-review", value: "Page review", comment: "Title of \"page review\" notification type. Used on filters view toggles and the notification detail view.")
        case .pageLinked:
            return WMFLocalizedString("notifications-center-type-title-page-link", value: "Page link", comment: "Title of \"page link\" notification type. Used on filters view toggles and the notification detail view.")
        case .connectionWithWikidata:
            return WMFLocalizedString("notifications-center-type-title-connection-with-wikidata", value: "Connection with Wikidata", comment: "Title of \"connection with Wikidata\" notification type. Used on filters view toggles and the notification detail view.")
        case .emailFromOtherUser:
            return WMFLocalizedString("notifications-center-type-title-email-from-other-user", value: "Email from other user", comment: "Title of \"email from other user\" notification type. Used on filters view toggles and the notification detail view.")
        case .mentionInTalkPage:
            return WMFLocalizedString("notifications-center-type-title-talk-page-mention", value: "Talk page mention", comment: "Title of \"talk page mention\" notification type. Used on filters view toggles and the notification detail view.")
        case .mentionInEditSummary:
            return WMFLocalizedString("notifications-center-type-title-edit-summary-mention", value: "Edit summary mention", comment: "Title of \"edit summary mention\" notification type. Used on filters view toggles and the notification detail view.")
        case .successfulMention:
            return WMFLocalizedString("notifications-center-type-title-sent-mention-success", value: "Sent mention success", comment: "Title of \"sent mention success\" notification type. Used on filters view toggles and the notification detail view.")
        case .failedMention:
            return WMFLocalizedString("notifications-center-type-title-sent-mention-failure", value: "Sent mention failure", comment: "Title of \"sent mention failure\" notification type. Used on filters view toggles and the notification detail view.")
        case .userRightsChange:
            return WMFLocalizedString("notifications-center-type-title-user-rights-change", value: "User rights change", comment: "Title of \"user rights change\" notification type. Used on filters view toggles and the notification detail view.")
        case .editReverted:
            return WMFLocalizedString("notifications-center-type-title-edit-reverted", value: "Edit reverted", comment: "Title of \"edit reverted\" notification type. Used on filters view toggles and the notification detail view.")
        case .loginFailKnownDevice,
                .loginFailUnknownDevice:
            return WMFLocalizedString("notifications-center-type-title-login-attempts", value: "Login attempts", comment: "Title of \"Login attempts\" notification type. Used on filters view toggles and the notification detail view. Represents failed logins from both a known and unknown device.")
        case .loginSuccessUnknownDevice:
            return WMFLocalizedString("notifications-center-type-title-login-success", value: "Login success", comment: "Title of \"login success\" notification type. Used on filters view toggles and the notification detail view. Represents successful logins from an unknown device.")
        case .editMilestone:
            return WMFLocalizedString("notifications-center-type-title-edit-milestone", value: "Edit milestone", comment: "Title of \"edit milestone\" notification type. Used on filters view toggles and the notification detail view.")
        case .translationMilestone:
            return WMFLocalizedString("notifications-center-type-title-translation-milestone", value: "Translation milestone", comment: "Title of \"translation milestone\" notification type. Used on filters view toggles and the notification detail view.") //for filters this represents other translation associated values as well (ten, hundred milestones).
        case .thanks:
            return WMFLocalizedString("notifications-center-type-title-thanks", value: "Thanks", comment: "Title of \"thanks\" notification type. Used on filters view toggles and the notification detail view.")
        case .welcome:
            return WMFLocalizedString("notifications-center-type-title-welcome", value: "Welcome", comment: "Title of \"welcome\" notification type. Used on filters view toggles and the notification detail view.")
        case .other:
            return WMFLocalizedString("notifications-center-type-title-other", value: "Other", comment: "Title of \"other\" notifications filter. Used on filter toggles.")
        case .unknownSystemAlert,
                .unknownAlert,
                .unknown:
                    return CommonStrings.notificationsCenterAlert
        case .unknownSystemNotice,
                .unknownNotice:
            return CommonStrings.notificationsCenterNotice
        }
    }
}

/// Interruption levels and and relevance scores
@available(iOS 15.0, *) public extension RemoteNotificationType {

    typealias Priority = (interruptionLevel: UNNotificationInterruptionLevel, relevanceScore: Double)

    /// Multiple notifications coalesced into a single alert
    static var bulkPriority: Priority = (.passive, 0.2)

    var priority: Priority {
        switch self {
        case .userTalkPageMessage:
            return (.timeSensitive, 1)
        case .mentionInTalkPage:
            return (.timeSensitive, 0.9)
        case .mentionInEditSummary:
            return (.timeSensitive, 0.85)
        case .editReverted:
            return (.timeSensitive, 0.9)
        case .userRightsChange:
            return (.active, 0.6)
        case .pageReviewed:
            return (.active, 0.7)
        case .pageLinked:
            return (.passive, 0.2)
        case .connectionWithWikidata:
            return (.passive, 0.3)
        case .emailFromOtherUser:
            return (.passive, 0.5)
        case .thanks:
            return (.active, 0.7)
        case .translationMilestone(_):
            return (.passive, 0.5)
        case .editMilestone:
            return (.passive, 0.4)
        case .failedMention:
            return (.active, 0.5)
        case .successfulMention:
            return (.passive, 0.65)
        case .welcome:
            return (.active, 0.8)
        case .loginSuccessUnknownDevice:
            return (.passive, 0.7)
        case .loginFailUnknownDevice, .loginFailKnownDevice:
            return (.active, 0.85)
        default:
            return (.passive, 0.1)
        }
    }

}
