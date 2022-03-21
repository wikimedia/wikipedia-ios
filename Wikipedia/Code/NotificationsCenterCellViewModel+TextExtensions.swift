
import Foundation

extension NotificationsCenterCellViewModel {
    
    var subheaderText: String {
        let fromText = WMFLocalizedString("notifications-center-subheader-from-agent", value: "From %1$@", comment: "Subheader text for notifications in Notifications Center. %1$@ will be replaced with the origin agent of the notification.")
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
                return genericHeaderText(type: notification.type, project: project)
            }

            return String.localizedStringWithFormat(fromText, agentName)
        case .welcome,
             .editMilestone,
             .translationMilestone:
            return String.localizedStringWithFormat(fromText, project.projectName(shouldReturnCodedFormat: false))
        case .loginFailKnownDevice,
             .loginFailUnknownDevice,
             .loginSuccessUnknownDevice,
             .failedMention,
             .successfulMention:
            return alertText(project: project)
            
        case .unknownSystemAlert,
             .unknownSystemNotice,
             .unknownAlert,
             .unknownNotice,
             .unknown:
            guard let agentName = notification.agentName else {
                return genericHeaderText(type: notification.type, project: project)
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
            return WMFLocalizedString("notifications-center-footer-change-password", value: "Change password", comment: "Footer text for login-related notifications in Notifications Center.")
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
        guard let date = notification.date else {
            return nil
        }

        return (date as NSDate).wmf_localizedShortDateStringRelative(to: Date())
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

//MARK: Header text determination helper methods

private extension NotificationsCenterCellViewModel {
    
    func noticeText(project: RemoteNotificationsProject) -> String {
        let format = WMFLocalizedString("notifications-center-header-notice-from-project", value: "Notice from %1$@", comment: "Header text for notice notifications in Notifications Center. %1$@ is replaced with a project name such as \"EN-Wikipedia\" or \"Wikimedia Commons\".")
        let projectName = project.projectName(shouldReturnCodedFormat: true)
        return String.localizedStringWithFormat(format, projectName)
    }
    
    func alertText(project: RemoteNotificationsProject) -> String {

        let format = WMFLocalizedString("notifications-center-header-alert-from-project", value: "Alert from %1$@", comment: "Header text for alert notifications in Notifications Center. %1$@ is replaced with a project name such as \"EN-Wikipedia\".")
        let projectName = project.projectName(shouldReturnCodedFormat: true)
        return String.localizedStringWithFormat(format, projectName)
    }
    
    func genericHeaderText(type: RemoteNotificationType, project: RemoteNotificationsProject) -> String {
        switch type {
        case .unknownSystemAlert, .unknownAlert:
            return alertText(project: project)
        case .unknownSystemNotice, .unknownNotice:
            return noticeText(project: project)
        default:
            return noticeText(project: project)
        }
    }
}
