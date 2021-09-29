import Foundation
import CoreData

@objc(RemoteNotification)
public class RemoteNotification: NSManagedObject {
    public lazy var type: RemoteNotificationType = {
        return calculateRemoteNotificationType()
    }()
    
    public override func didChangeValue(forKey key: String,
        withSetMutation mutationKind: NSKeyValueSetMutationKind,
        using objects: Set<AnyHashable>) {
        super.didChangeValue(forKey: key, withSetMutation: mutationKind, using: objects)
        if key == "categoryString" || key == "typeString" || key == "section" {
            type = calculateRemoteNotificationType()
        }
    }
}

private extension RemoteNotification {
    func calculateRemoteNotificationType() -> RemoteNotificationType {
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
}
