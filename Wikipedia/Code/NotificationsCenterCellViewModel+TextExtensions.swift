import Foundation
import WMF

extension NotificationsCenterCellViewModel {
    
    var subheaderText: String {
        let alertFromText = WMFLocalizedString("notifications-center-header-alert-from-agent", value: "Alert from %1$@", comment: "Subheader text for unknown alert type notifications in Notifications Center. %1$@ will be replaced with the origin agent of the notification.")

        switch notification.type {
        case .userTalkPageMessage,
             .mentionInTalkPage,
             .mentionInEditSummary,
             .editReverted,
             .userRightsChange,
             .thanks,
             .pageReviewed,
             .pageLinked,
             .connectionWithWikidata,
             .emailFromOtherUser:
            guard let agentName = notification.agentName else {
                return genericHeaderText(type: notification.type)
            }

            return String.localizedStringWithFormat(CommonStrings.notificationsCenterAgentDescriptionFromFormat, agentName)
        case .welcome,
             .editMilestone,
             .translationMilestone:
            return project.projectName(shouldReturnCodedFormat: false)
        case .loginFailKnownDevice,
             .loginFailUnknownDevice,
             .loginSuccessUnknownDevice,
             .failedMention,
             .successfulMention:
            return CommonStrings.notificationsCenterAlert
            
        case .unknownSystemAlert,
             .unknownSystemNotice,
             .unknownAlert,
             .unknownNotice,
             .unknown:
            guard let agentName = notification.agentName else {
                return genericHeaderText(type: notification.type)
            }

            return String.localizedStringWithFormat(alertFromText, agentName)
        }
    }
    
    var headerText: String? {
        return commonViewModel.verboseTitle
    }
    
    var bodyText: String? {
        return commonViewModel.message
    }
    
    var footerText: String? {
        switch notification.type {
        case .welcome,
             .emailFromOtherUser:
            return nil
        case .loginFailKnownDevice,
             .loginFailUnknownDevice,
             .loginSuccessUnknownDevice:
            return CommonStrings.notificationsChangePassword
        case .unknownSystemAlert,
             .unknownSystemNotice,
             .unknownAlert,
             .unknownNotice,
             .unknown:
            guard let primaryLinkLabel = notification.primaryLinkLabel else {
                return nil
            }
            
            return primaryLinkLabel
        case .userTalkPageMessage,
             .mentionInTalkPage,
             .mentionInEditSummary,
             .successfulMention,
             .failedMention,
             .editReverted,
             .userRightsChange,
             .pageReviewed,
             .pageLinked,
            .connectionWithWikidata,
            .thanks,
            .translationMilestone,
            .editMilestone:
            return notification.titleFull
        }
    }
    
    var dateText: String? {
        commonViewModel.dateText
    }
    
    
    var projectText: String? {
        switch project {
        case .wikipedia(let languageCode, _, _):
            return languageCode.uppercased()
        case .commons,
                .wikiquote,
                .wikibooks,
                .wiktionary,
                .wikisource,
                .wikinews,
                .wikiversity,
                .wikivoyage,
                .mediawiki,
                .wikispecies,
                .wikidata:
            return nil
        }
    }
}

// MARK: Header text determination helper methods

private extension NotificationsCenterCellViewModel {
    
    func genericHeaderText(type: RemoteNotificationType) -> String {
        switch type {
        case .unknownSystemAlert, .unknownAlert:
            return CommonStrings.notificationsCenterAlert
        case .unknownSystemNotice, .unknownNotice:
            return CommonStrings.notificationsCenterNotice
        default:
            return CommonStrings.notificationsCenterNotice
        }
    }
}
