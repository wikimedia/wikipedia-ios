import Foundation
import CoreData

@objc(RemoteNotification)
public class RemoteNotification: NSManagedObject {
    public var type: RemoteNotificationType {
        switch (categoryString, typeString) {
        case ("edit-user-talk", "edit-user-talk"):
            return .userTalkPageMessage
        case ("mention", "mention"):
            return .mentionInTalkPage
        case ("mention", "mention-summary"):
            return .mentionInEditSummary
        case ("mention-success", "mention-success"):
            return .successfulMention
        case ("mention-failure", "mention-failure"),
             ("mention-failure", "mention-failure-too-many"):
            return .failedMention
        case ("reverted", "reverted"):
            return .editReverted
        case ("user-rights", "user-rights"):
            return .userRightsChange
        case ("page-review", "pagetriage-mark-as-reviewed"):
            return .pageReviewed
        case ("article-linked", "page-linked"):
            return .pageLinked
        case ("wikibase-action", "page-connection"):
            return .connectionWithWikidata
        case ("emailuser", "emailuser"):
            return .emailFromOtherUser
        case ("edit-thank", "edit-thank"):
            return .thanks
        case ("cx", "cx-first-translation"):
            return .translationMilestone(1)
        case ("cx", "cx-tenth-translation"):
            return .translationMilestone(10)
        case ("cx", "cx-hundredth-translation"):
            return .translationMilestone(100)
        case ("thank-you-edit", "thank-you-edit"):
            return .editMilestone
        case ("system-noemail", "welcome"):
            return .welcome
        case ("login-fail", "login-fail-new"):
            return .loginFailUnknownDevice
        case ("login-fail", "login-fail-known"):
            return .loginFailKnownDevice
        case ("login-success", "login-success"):
            return .loginSuccessUnknownDevice
        case ("system", _),
             ("system-noemail", _),
             ("system-emailonly", _):
            
            switch self.section {
            case "alert":
                return .unknownSystemAlert
            case "message":
                return .unknownSystemNotice
            default:
                return .unknown
            }
            
        default:
            
            switch self.section {
            case "alert":
                return .unknownAlert
            case "message":
                return .unknownNotice
            default:
                return .unknown
            }
        }
    }
    
    public static func categoryStringsForRemoteNotificationType(type: RemoteNotificationType) -> [String] {
        
        switch type {
        case .userTalkPageMessage:
            return ["edit-user-talk"]
        case .mentionInTalkPage,
                .mentionInEditSummary:
            return ["mention"]
        case .successfulMention:
            return ["mention-success"]
        case .failedMention:
            return ["mention-failure"]
        case .editReverted:
            return ["reverted"]
        case .userRightsChange:
            return ["user-rights"]
        case .pageReviewed:
            return ["page-review"]
        case .pageLinked:
            return ["article-linked"]
        case .connectionWithWikidata:
            return ["wikibase-action"]
        case .emailFromOtherUser:
            return ["emailuser"]
        case .thanks:
            return ["edit-thank"]
        case .translationMilestone: //Note: this will include the other translation type associated values
            return ["cx"]
        case .editMilestone:
            return ["thank-you-edit"]
        case .welcome:
            return ["system-noemail"]
        case .loginFailKnownDevice: //Note: this will include the other login types
            return ["login-fail", "login-success"]
        default:
            return []
        }
    }
    
    public static func typeStringsForRemoteNotificationType(type: RemoteNotificationType) -> [String] {
        switch type {
        case .userTalkPageMessage:
            return ["edit-user-talk"]
        case .mentionInTalkPage:
            return ["mention"]
        case .mentionInEditSummary:
            return ["mention-summary"]
        case .successfulMention:
            return ["mention-success"]
        case .failedMention:
            return ["mention-failure", "mention-failure-too-many"]
        case .editReverted:
            return ["reverted"]
        case .userRightsChange:
            return ["user-rights"]
        case .pageReviewed:
            return ["pagetriage-mark-as-reviewed"]
        case .pageLinked:
            return ["page-linked"]
        case .connectionWithWikidata:
            return ["page-connection"]
        case .emailFromOtherUser:
            return ["emailuser"]
        case .thanks:
            return ["edit-thank"]
        case .translationMilestone: //Note: this will include the other translation type associated values
            return ["cx-first-translation", "cx-tenth-translation", "cx-hundredth-translation"]
        case .editMilestone:
            return ["thank-you-edit"]
        case .welcome:
            return ["welcome"]
        case .loginFailKnownDevice: //Note: this will include the other login types
            return ["login-fail-new", "login-fail-known", "login-success"]
        default:
            return []
        }
    }

    public var primaryLinkHost: String? {
        return messageLinks?.primary?.url?.host
    }

    public var primaryLinkFragment: String? {
        return primaryLinkURL?.fragment
    }
    
    public var primaryLinkURL: URL? {
        return messageLinks?.primary?.url
    }
    
    public var legacyPrimaryLinkURL: URL? {
        return messageLinks?.legacyPrimary?.url
    }
    
    public var legacyPrimaryLinkFragment: String? {
        return legacyPrimaryLinkURL?.fragment
    }
    
    public var primaryLinkLabel: String? {
        return messageLinks?.primary?.label
    }
    
    public var primaryLink: RemoteNotificationLink? {
        return messageLinks?.primary
    }
    
    public var secondaryLinks: [RemoteNotificationLink]? {
        return messageLinks?.secondary
    }
    
    public struct IdentifierGroup: Hashable {
        let key: String?
        let id: String?
        let wiki: String?
    }
    
    public var identifierGroup: IdentifierGroup {
        return IdentifierGroup(key: key, id: id, wiki: wiki)
    }
}
