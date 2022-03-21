
import Foundation

extension NotificationsCenterCommonViewModel {
    var message: String? {
        switch notification.type {
        case .editReverted:
            return nil
        case .successfulMention,
             .failedMention,
             .userRightsChange,
             .pageReviewed,
             .pageLinked,
             .connectionWithWikidata,
             .emailFromOtherUser,
             .thanks,
             .translationMilestone,
             .editMilestone,
             .welcome,
             .loginFailUnknownDevice,
             .loginFailKnownDevice,
             .loginSuccessUnknownDevice:
            return notification.messageHeader?.removingHTML
        case .userTalkPageMessage,
             .mentionInTalkPage,
             .mentionInEditSummary,
             .unknownSystemAlert,
             .unknownSystemNotice,
             .unknownAlert,
             .unknownNotice,
             .unknown:
            return notification.messageBody?.removingHTML
        }
    }
}
