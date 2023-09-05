import Foundation

public enum RemoteNotificationType: Hashable {
    case userTalkPageMessage // Message on your talk page
    case mentionInTalkPage // Mention in article talk
    case mentionInEditSummary // Mention in edit summary
    case successfulMention // Successful mention
    case failedMention // Failed mention
    case editReverted // Edit reverted
    case userRightsChange // Usage rights change
    case pageReviewed // Page review
    case pageLinked // Page link
    case connectionWithWikidata // Wikidata link
    case emailFromOtherUser // Email from other user
    case thanks // Thanks
    case translationMilestone(Int) // Translation milestone
    case editMilestone // Editing milestone
    case welcome // Welcome
    case loginFailUnknownDevice // Failed log in from an unfamiliar device
    case loginFailKnownDevice // Log in Notify
    case loginSuccessUnknownDevice // Successful log in unfamiliar device
    case unknownSystemAlert // No specific type ID, system alert type
    case unknownSystemNotice // No specific type ID, system notice type
    case unknownNotice // No specific type ID, notice type
    case unknownAlert // No specific type ID, alert type
    case unknown
    
// Possible flow-related notifications to target. Leaving it to default handling for now but we may need to bring these in for special handling.
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
        case .welcome, .translationMilestone, .editMilestone:
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
        case .editMilestone, .translationMilestone, .welcome, .thanks:
            return theme.colors.accent
        case .loginFailKnownDevice, .loginFailUnknownDevice, .loginSuccessUnknownDevice:
            return theme.colors.error
        case .failedMention, .editReverted, .userRightsChange:
            return theme.colors.warning
        default:
            return theme.colors.link
        }
    }
    
}

public extension RemoteNotificationType {
    
    var title: String {
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
        case .loginFailKnownDevice,
                .loginFailUnknownDevice:
            return CommonStrings.notificationsCenterLoginAttempts
        case .loginSuccessUnknownDevice:
            return CommonStrings.notificationsCenterLoginSuccess
        case .editMilestone:
            return CommonStrings.notificationsCenterEditMilestone
        case .translationMilestone:
            return CommonStrings.notificationsCenterTranslationMilestone
        case .thanks:
            return CommonStrings.notificationsCenterThanks
        case .welcome:
            return CommonStrings.notificationsCenterWelcome
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
public extension RemoteNotificationType {

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
        case .translationMilestone:
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
