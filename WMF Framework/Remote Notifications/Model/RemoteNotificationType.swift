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
    
//Possible flow-related notifications to target. Leaving it to default handling for now but we may need to bring these in for special handling.
//    case flowUserTalkPageNewTopic //Message on your talk page
//    case flowUserTalkPageReply //Reply on your talk page
//    case flowDiscussionNewTopic //??
//    case flowDiscussionReply //Reply on an article talk page
//    case flowMention //Mention in article talk
//    case flowThanks //Thanks
}

public extension RemoteNotificationType {
    var imageName: String? {
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
            case "loginFailKnownDevice", //for filters this represents any login-related notification (i.e. also loginFailUnknownDevice, loginSuccessUnknownDevice, etc.). todo: clean this up. todo: split up into login attempts vs login success?
                    "loginFailUnknownDevice",
                    "loginSuccessUnknownDevice":
                self = .loginFailKnownDevice
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
        case .loginFailKnownDevice, //for filters this represents any login-related notification (i.e. also loginFailUnknownDevice, loginSuccessUnknownDevice, etc.). todo: clean this up. todo: split up into login attempts vs login success?
                .loginFailUnknownDevice,
                .loginSuccessUnknownDevice:
            return "loginFailKnownDevice"
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
            .mentionInTalkPage, //todo: combine this and edit summary mention to "received mention"?
            .mentionInEditSummary,
            .successfulMention,
            .failedMention,
            .userRightsChange,
            .editReverted,
            .loginFailKnownDevice, //for filters this represents any login-related notification (i.e. also loginFailUnknownDevice, loginSuccessUnknownDevice, etc.). todo: clean this up. todo: split up into login attempts vs login success?
            .editMilestone,
            .translationMilestone(1), //for filters this represents other translation associated values as well (ten, hundred milestones).
            .thanks,
            .welcome
        ]
    }
    
    var filterTitle: String? {
        switch self {
        case .userTalkPageMessage:
            return WMFLocalizedString("notifications-center-filters-types-item-title-user-talk-page-messsage", value: "Talk page message", comment: "Title of \"user talk page message\" toggle in the types section of the notifications center filter view. Toggling this off removes \"user talk page message\" notifications from the notifications center.")
        case .pageReviewed:
            return WMFLocalizedString("notifications-center-filters-types-item-title-page-review", value: "Page review", comment: "Title of \"page review\" toggle in the types section of the notifications center filter view. Toggling this off removes \"page review\" notifications from the notifications center.")
        case .pageLinked:
            return WMFLocalizedString("notifications-center-filters-types-item-title-page-link", value: "Page link", comment: "Title of \"page link\" toggle in the types section of the notifications center filter view. Toggling this off removes \"page link\" notifications from the notifications center.")
        case .connectionWithWikidata:
            return WMFLocalizedString("notifications-center-filters-types-item-title-connection-with-wikidata", value: "Connection with Wikidata", comment: "Title of \"connection with Wikidata\" toggle in the types section of the notifications center filter view. Toggling this off removes \"connection with Wikidata\" notifications from the notifications center.")
        case .emailFromOtherUser:
            return WMFLocalizedString("notifications-center-filters-types-item-title-email-from-other-user", value: "Email from other user", comment: "Title of \"email from other user\" toggle in the types section of the notifications center filter view. Toggling this off removes \"email from other user\" notifications from the notifications center.")
        case .mentionInTalkPage:
            return WMFLocalizedString("notifications-center-filters-types-item-title-talk-page-mention", value: "Talk page mention", comment: "Title of \"talk page mention\" toggle in the types section of the notifications center filter view. Toggling this off removes \"talk page mention\" notifications from the notifications center.")
        case .mentionInEditSummary:
            return WMFLocalizedString("notifications-center-filters-types-item-title-edit-summary-mention", value: "Edit summary mention", comment: "Title of \"edit summary mention\" toggle in the types section of the notifications center filter view. Toggling this off removes \"edit summary mention\" notifications from the notifications center.")
        case .successfulMention:
            return WMFLocalizedString("notifications-center-filters-types-item-title-sent-mention-success", value: "Sent mention success", comment: "Title of \"sent mention success\" toggle in the types section of the notifications center filter view. Toggling this off removes \"successful mention\" notifications from the notifications center.")
        case .failedMention:
            return WMFLocalizedString("notifications-center-filters-types-item-title-sent-mention-failure", value: "Sent mention failure", comment: "Title of \"sent mention failure\" toggle in the types section of the notifications center filter view. Toggling this off removes \"failed mention\" notifications from the notifications center.")
        case .userRightsChange:
            return WMFLocalizedString("notifications-center-filters-types-item-title-user-rights-change", value: "User rights change", comment: "Title of \"user rights change\" toggle in the types section of the notifications center filter view. Toggling this off removes \"user rights change\" notifications from the notifications center.")
        case .editReverted:
            return WMFLocalizedString("notifications-center-filters-types-item-title-edit-reverted", value: "Edit reverted", comment: "Title of \"edit reverted\" toggle in the types section of the notifications center filter view. Toggling this off removes \"edit reverted\" notifications from the notifications center.")
        case .loginFailKnownDevice:
            return WMFLocalizedString("notifications-center-filters-types-item-title-login-issues", value: "Login issues", comment: "Title of \"login issues\" toggle in the types section of the notifications center filter view. Toggling this off removes login-related notifications from the notifications center.") //for filters this represents any login-related notification (i.e. also loginFailUnknownDevice, loginSuccessUnknownDevice, etc.). todo: clean this up. todo: split up into login attempts vs login success?
        case .editMilestone:
            return WMFLocalizedString("notifications-center-filters-types-item-title-edit-milestone", value: "Edit milestone", comment: "Title of \"edit milestone\" toggle in the types section of the notifications center filter view. Toggling this off removes \"edit milestone\" notifications from the notifications center.")
        case .translationMilestone:
            return WMFLocalizedString("notifications-center-filters-types-item-title-translation-milestone", value: "Translation milestone", comment: "Title of \"translation milestone\" toggle in the types section of the notifications center filter view. Toggling this off removes \"translation milestone\" notifications from the notifications center.") //for filters this represents other translation associated values as well (ten, hundred milestones).
        case .thanks:
            return WMFLocalizedString("notifications-center-filters-types-item-title-thanks", value: "Thanks", comment: "Title of \"thanks\" toggle in the types section of the notifications center filter view. Toggling this off removes \"thanks\" notifications from the notifications center.")
        case .welcome:
            return WMFLocalizedString("notifications-center-filters-types-item-title-welcome", value: "Welcome", comment: "Title of \"welcome\" toggle in the types section of the notifications center filter view. Toggling this off removes \"welcome\" notifications from the notifications center.")
        default:
            return nil
        }
    }
}
