import Foundation

public enum RemoteNotificationFilterType: String, CaseIterable {
    case userTalkPageMessage
    case pageReviewed
    case pageLinked
    case connectionWithWikidata
    case emailFromOtherUser
    case mentionInTalkPage
    case mentionInEditSummary
    case successfulMention
    case failedMention
    case userRightsChange
    case editReverted
    case loginAttempts
    case loginSuccess
    case editMilestone
    case translationMilestone
    case thanks
    case welcome
    case other
    
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
            case "loginAttempts":
                self = .loginAttempts
            case "editMilestone":
                self = .editMilestone
            case "translationMilestone":
                self = .translationMilestone
            case "thanks":
                self = .thanks
            case "welcome":
                self = .welcome
            case "other":
                self = .other
            default:
                return nil
        }
    }
    
    public var filterIdentifier: String? {
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
        case .loginAttempts:
            return "loginAttempts"
        case .loginSuccess:
            return "loginSucess"
        case .editMilestone:
            return "editMilestone"
        case .translationMilestone:
            return "translationMilestone"
        case .thanks:
            return "thanks"
        case .welcome:
            return "welcome"
        case .other:
            return "other"
        }
    }
    
    public static func categoryStringsForFilterType(type: RemoteNotificationFilterType) -> [String] {
        switch type {
        case .userTalkPageMessage:
            return ["edit-user-talk"]
        case .pageReviewed:
            return ["page-review"]
        case .pageLinked:
            return ["article-linked"]
        case .connectionWithWikidata:
            return ["wikibase-action"]
        case .emailFromOtherUser:
            return ["emailuser"]
        case .mentionInTalkPage,
                .mentionInEditSummary:
            return ["mention"]
        case .successfulMention:
            return ["mention-success"]
        case .failedMention:
            return ["mention-failure"]
        case .userRightsChange:
            return ["user-rights"]
        case .editReverted:
            return ["reverted"]
        case .loginAttempts:
            return ["login-fail"]
        case .loginSuccess:
            return ["login-success"]
        case .editMilestone:
            return ["thank-you-edit"]
        case .translationMilestone:
            return ["cx"]
        case .thanks:
            return ["edit-thank"]
        case .welcome:
            return ["system-noemail"]
        case .other:
            return []
        }
    }
    
    public static func typeStringForFilterType(type: RemoteNotificationFilterType) -> [String] {
        switch type {
            
        case .userTalkPageMessage:
            return ["edit-user-talk"]
        case .pageReviewed:
            return ["pagetriage-mark-as-reviewed"]
        case .pageLinked:
            return ["page-linked"]
        case .connectionWithWikidata:
            return ["page-connection"]
        case .emailFromOtherUser:
            return ["emailuser"]
        case .mentionInTalkPage:
            return ["mention"]
        case .mentionInEditSummary:
            return ["mention-summary"]
        case .successfulMention:
            return ["mention-success"]
        case .failedMention:
            return ["mention-failure",
                    "mention-failure-too-many"]
        case .userRightsChange:
            return ["user-rights"]
        case .editReverted:
            return ["reverted"]
        case .loginAttempts:
            return ["login-fail-new",
                    "login-fail-known"]
        case .loginSuccess:
            return ["login-success"]
        case .editMilestone:
            return ["thank-you-edit"]
        case .translationMilestone:
            return ["cx-first-translation",
                    "cx-tenth-translation",
                    "cx-hundredth-translation"]
        case .thanks:
            return ["edit-thank"]
        case .welcome:
            return ["welcome"]
        case .other:
            return []
        }
    }
    
   public var imageName: String {
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
       case .welcome, .translationMilestone, .editMilestone:
           return "notifications-type-milestone"
       case .loginAttempts, .loginSuccess:
           return "notifications-type-login-notify"
       case .emailFromOtherUser:
           return "notifications-type-email"
       case .other:
           return "notifications-type-default"
       }
   }
    
   public func imageBackgroundColorWithTheme(_ theme: Theme) -> UIColor {
        switch self {
        case .editMilestone, .translationMilestone, .welcome, .thanks:
            return theme.colors.accent
        case .loginAttempts, .loginSuccess:
            return theme.colors.error
        case .failedMention, .editReverted, .userRightsChange:
            return theme.colors.warning
        default:
            return theme.colors.link
        }
    }
    
   public static var orderingForFilters: [RemoteNotificationFilterType] {
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
        .loginAttempts,
        .loginSuccess,
        .editMilestone,
        .translationMilestone,
        .thanks,
        .welcome,
        .other
       ]
   }
    
    public var title: String {
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
        case .loginAttempts:
            return WMFLocalizedString("notifications-center-type-title-login-attempts", value: "Login attempts", comment: "Title of \"Login attempts\" notification type. Used on filters view toggles and the notification detail view. Represents failed logins from both a known and unknown device.")
        case .loginSuccess:
            return WMFLocalizedString("notifications-center-type-title-login-success", value: "Login success", comment: "Title of \"login success\" notification type. Used on filters view toggles and the notification detail view. Represents successful logins from an unknown device.")
        case .editMilestone:
            return WMFLocalizedString("notifications-center-type-title-edit-milestone", value: "Edit milestone", comment: "Title of \"edit milestone\" notification type. Used on filters view toggles and the notification detail view.")
        case .translationMilestone:
            return WMFLocalizedString("notifications-center-type-title-translation-milestone", value: "Translation milestone", comment: "Title of \"translation milestone\" notification type. Used on filters view toggles and the notification detail view.")
        case .thanks:
            return WMFLocalizedString("notifications-center-type-title-thanks", value: "Thanks", comment: "Title of \"thanks\" notification type. Used on filters view toggles and the notification detail view.")
        case .welcome:
            return WMFLocalizedString("notifications-center-type-title-welcome", value: "Welcome", comment: "Title of \"welcome\" notification type. Used on filters view toggles and the notification detail view.")
        case .other:
            return WMFLocalizedString("notifications-center-type-title-other", value: "Other", comment: "Title of \"other\" notifications filter. Used on filter toggles.")
        }
    }
    
}
