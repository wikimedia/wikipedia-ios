import Foundation

public enum RemoteNotificationType {
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
    public static var orderingForFilters: [RemoteNotificationType] {
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
    
    var title: String? {
        switch self {
        case .userTalkPageMessage: return "Talk page message"
        case .pageReviewed: return "Page review"
        case .pageLinked: return "Page link"
        case .connectionWithWikidata: return "Connection with Wikidata"
        case .emailFromOtherUser: return "Email from other user"
        case .mentionInTalkPage: return "Talk page mention"
        case .mentionInEditSummary: return "Edit summary mention"
        case .successfulMention: return "Sent mention success"
        case .failedMention: return "Sent mention failure"
        case .userRightsChange: return "User rights change"
        case .editReverted: return "Edit reverted"
        case .loginFailKnownDevice: return "Login issues" //for filters this represents any login-related notification (i.e. also loginFailUnknownDevice, loginSuccessUnknownDevice, etc.). todo: clean this up. todo: split up into login attempts vs login success?
        case .editMilestone: return "Edit milestone"
        case .translationMilestone: return "Translation milestone"  //for filters this represents other translation associated values as well (ten, hundred milestones).
        case .thanks: return "Thanks"
        case .welcome: return "Welcome"
        default:
            return nil
        }
    }
}

extension RemoteNotificationType: Equatable {
    public static func == (lhs: RemoteNotificationType, rhs: RemoteNotificationType) -> Bool {
        switch lhs {
        case .userTalkPageMessage:
            switch rhs {
            case .userTalkPageMessage:
                return true
            default:
                return false
            }
        case .pageReviewed:
            switch rhs {
            case .pageReviewed:
                return true
            default:
                return false
            }
            
        case .pageLinked:
            switch rhs {
            case .pageLinked:
                return true
            default:
                return false
            }
            
        case .connectionWithWikidata:
            switch rhs {
            case .connectionWithWikidata:
                return true
            default:
                return false
            }
            
        case .emailFromOtherUser:
            switch rhs {
            case .emailFromOtherUser:
                return true
            default:
                return false
            }
            
        case .mentionInTalkPage:
            switch rhs {
            case .mentionInTalkPage:
                return true
            default:
                return false
            }
            
        case .mentionInEditSummary:
            switch rhs {
            case .mentionInEditSummary:
                return true
            default:
                return false
            }
            
        case .successfulMention:
            switch rhs {
            case .successfulMention:
                return true
            default:
                return false
            }
            
        case .failedMention:
            switch rhs {
            case .failedMention:
                return true
            default:
                return false
            }
        
        
            
        case .userRightsChange:
            switch rhs {
            case .userRightsChange:
                return true
            default:
                return false
            }
            
            
        case .editReverted:
            switch rhs {
            case .editReverted:
                return true
            default:
                return false
            }
            
        case .loginFailKnownDevice: //for filters this represents any login-related notification (i.e. also loginFailUnknownDevice, loginSuccessUnknownDevice, etc.). todo: clean this up. todo: split up into login attempts vs login success?
            switch rhs {
            case .loginFailKnownDevice:
                return true
            default:
                return false
            }
            
        case .editMilestone:
            switch rhs {
            case .editMilestone:
                return true
            default:
                return false
            }
            
        case .translationMilestone: //for filters this represents other translation associated values as well (ten, hundred milestones).
            switch rhs {
            case .translationMilestone:
                return true
            default:
                return false
            }
        
            
        case .thanks:
            switch rhs {
            case .thanks:
                return true
            default:
                return false
            }
            
        case .welcome:
            switch rhs {
            case .welcome:
                return true
            default:
                return false
            }
        default:
            return false
        }
    }
    
    
}
