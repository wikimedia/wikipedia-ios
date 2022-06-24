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
        case "loginSuccess":
            self = .loginSuccess
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
            return "loginSuccess"
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
            return CommonStrings.notificationsCenterUserTalkPageMessage
        case .pageReviewed:
            return CommonStrings.notificationsCenterPageReviewed
        case .pageLinked:
            return CommonStrings.notificationsCenterPageLinked
        case .connectionWithWikidata:
            return CommonStrings.notificationsCenterConnectionWithWikidata
        case .emailFromOtherUser:
            return CommonStrings.notificationsCenterEmailFromOtherUser
        case .mentionInTalkPage:
            return CommonStrings.notificationsCenterMentionInTalkPage
        case .mentionInEditSummary:
            return CommonStrings.notificationsCenterMentionInEditSummary
        case .successfulMention:
            return CommonStrings.notificationsCenterSuccessfulMention
        case .failedMention:
            return CommonStrings.notificationsCenterFailedMention
        case .userRightsChange:
            return CommonStrings.notificationsCenterUserRightsChange
        case .editReverted:
            return CommonStrings.notificationsCenterEditReverted
        case .loginAttempts:
            return CommonStrings.notificationsCenterLoginAttempts
        case .loginSuccess:
            return CommonStrings.notificationsCenterLoginSuccess
        case .editMilestone:
            return CommonStrings.notificationsCenterEditMilestone
        case .translationMilestone:
            return CommonStrings.notificationsCenterTranslationMilestone
        case .thanks:
            return CommonStrings.notificationsCenterThanks
        case .welcome:
            return CommonStrings.notificationsCenterWelcome
        case .other:
            return CommonStrings.notificationsCenterOtherFilter
        }
    }
}
