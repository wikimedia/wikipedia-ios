import Foundation

extension NotificationsCenterCellViewModel {

    // MARK: Public
    
    var primaryURL: URL? {

        return nil
//        //First try to explicitly generate urls based on notification type to limit url side effects
//        var calculatedURL: URL? = nil
//
//        switch notification.type {
//        case .userTalkPageMessage,
//             .mentionInTalkPage,
//             .failedMention,
//             .pageReviewed,
//             .pageLinked,
//             .editMilestone,
//             .successfulMention:
//            calculatedURL = commonViewModel.fullTitleURL
//        case .mentionInEditSummary,
//             .editReverted,
//             .thanks:
//            calculatedURL = commonViewModel.fullTitleDiffURL
//        case .userRightsChange:
//            calculatedURL = commonViewModel.userGroupRightsURL
//        case .connectionWithWikidata:
//            calculatedURL = commonViewModel.connectionWithWikidataItemURL
//        case .emailFromOtherUser:
//            calculatedURL = commonViewModel.customPrefixAgentNameURL(pageNamespace: .user)
//        case .welcome:
//            calculatedURL = commonViewModel.gettingStartedURL
//        case .translationMilestone:
//
//            //purposefully not allowing default to primaryLinkURL from server below
//            //business requirements are that there are no destination links for translations notification.
//            return nil
//
//        case .loginFailUnknownDevice,
//             .loginFailKnownDevice,
//             .loginSuccessUnknownDevice:
//            calculatedURL = commonViewModel.changePasswordURL
//
//        case .unknownSystemAlert,
//             .unknownSystemNotice,
//             .unknownAlert,
//             .unknownNotice,
//             .unknown:
//            break
//        }
//
//        //If unable to calculate url, default to primary url returned from server
//        return (calculatedURL ?? notification.primaryLinkURL)
    }
}
