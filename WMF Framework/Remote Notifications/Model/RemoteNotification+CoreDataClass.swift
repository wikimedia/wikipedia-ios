import Foundation
import CoreData

@objc(RemoteNotification)
public class RemoteNotification: NSManagedObject {

    public var type: RemoteNotificationType {
        return RemoteNotification.typeFrom(category: self.categoryString, type: self.typeString, section: self.section)
    }

    public static func typeFrom(notification: RemoteNotificationsAPIController.NotificationsResult.Notification) -> RemoteNotificationType {
        return typeFrom(category: notification.category, type: notification.type, section: notification.section)
    }

    public static func typeFrom(category: String?, type: String?, section: String?) -> RemoteNotificationType {
        switch (category, type) {
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
            
            switch section {
            case "alert":
                return .unknownSystemAlert
            case "message":
                return .unknownSystemNotice
            default:
                return .unknown
            }
            
        default:
            switch section {
            case "alert":
                return .unknownAlert
            case "message":
                return .unknownNotice
            default:
                return .unknown
            }
        }
    }

    public var linkHost: String? {
        if let primaryLinkHost = messageLinks?.primary?.url?.host {
            return primaryLinkHost
        }
        
        if let secondaryLinks = messageLinks?.secondary {
            for secondaryLink in secondaryLinks {
                if let secondaryHost = secondaryLink.url?.host {
                    return secondaryHost
                }
            }
        }
        
        return nil
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
