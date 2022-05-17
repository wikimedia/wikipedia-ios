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
    
}
