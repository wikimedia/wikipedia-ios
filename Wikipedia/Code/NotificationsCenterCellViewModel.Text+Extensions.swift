
import Foundation

extension NotificationsCenterCellViewModel.Text {
    init(project: RemoteNotificationsProject, notification: RemoteNotification) {
        self.header = Self.determineHeaderText(project: project, notification: notification)
        self.subheader = nil
        self.body = nil
        self.footer = nil
    }
    
    private static func determineHeaderText(project: RemoteNotificationsProject, notification: RemoteNotification) -> String {
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

            return agentName

        case .welcome,
             .editMilestone,
             .translationMilestone:
            return projectName(project: project, shouldReturnCodedFormat: false)
        case .successfulMention:
            
            guard let agentName = notification.agentName else {
                return genericHeaderText(type: notification.type, project: project)
            }
            
            return mentionText(agentName: agentName)
        case .loginFailKnownDevice,
             .loginFailUnknownDevice,
             .loginSuccessUnknownDevice,
             .failedMention:
            return alertText(project: project)
        case .unknownSystemAlert,
             .unknownSystemNotice,
             .unknownAlert,
             .unknownNotice,
             .unknown:
            guard let agentName = notification.agentName else {
                return genericHeaderText(type: notification.type, project: project)
            }

            return agentName
        }
    }
}

//MARK: Header text determination helper methods

private extension NotificationsCenterCellViewModel.Text {

    /// Returns formatted descriptive project name
    /// - Parameters:
    ///   - project: RemoteNotificationsProject that the notification is from
    ///   - shouldReturnCodedFormat: Boolean for if you want description in coded format for langauge projects ("EN-Wikipedia" vs  "English Wikipedia"). This is ignored for commons and wikidata projects.
    /// - Returns: Formatted descriptive project name
    static func projectName(project: RemoteNotificationsProject, shouldReturnCodedFormat: Bool) -> String {
        
        switch project {
        case .language(let languageCode, let localizedLanguageName):
            let format = WMFLocalizedString("notifications-language-project-name-format", value: "%1$@ %2$@", comment: "Format used for the ordering of language project name descriptions. This description is inserted into the header text of notifications in Notification Center. For example, \"English Wikipedia\". Use this format to reorder these words if necessary or insert additional connecting words. Parameters: %1$@ = localized language name (\"English\"), %2$@ = localized name for Wikipedia (\"Wikipedia\")")

            if let localizedLanguageName = localizedLanguageName,
               !shouldReturnCodedFormat {
                return String.localizedStringWithFormat(format, localizedLanguageName, CommonStrings.plainWikipediaName)
            } else {
                let codedProjectName = "\(languageCode.localizedUppercase)-\(CommonStrings.plainWikipediaName)"
                return codedProjectName
            }
            
        case .commons:
            return WMFLocalizedString("notifications-commons-project-name", value: "Wikimedia Commons", comment: "Project name description for Wikimedia Commons, used in notification headers.")
        case .wikidata:
            return WMFLocalizedString("notifications-wikidata-project-name", value: "Wikidata", comment: "Project name description for Wikidata, used in notification headers.")
        }
    }
    
    static func noticeText(project: RemoteNotificationsProject) -> String {
        let format = WMFLocalizedString("notifications-header-notice-from-project", value: "Notice from %1$@", comment: "Header text for notice notifications in Notification Center. %1$@ is replaced with a project name such as \"EN-Wikipedia\" or \"Wikimedia Commons\".")
        let projectName = projectName(project: project, shouldReturnCodedFormat: true)
        return String.localizedStringWithFormat(format, projectName)
    }
    
    static func alertText(project: RemoteNotificationsProject) -> String {

        let format = WMFLocalizedString("notifications-header-alert-from-project", value: "Alert from %1$@", comment: "Header text for alert notifications in Notification Center. %1$@ is replaced with a project name such as \"EN-Wikipedia\".")
        let projectName = projectName(project: project, shouldReturnCodedFormat: true)
        return String.localizedStringWithFormat(format, projectName)
    }
    
    static func mentionText(agentName: String) -> String {
        let format = WMFLocalizedString("notifications-header-mention-format", value: "To: %1$@", comment: "Header text for successful mention notifications in Notification Center. %1$@ is replaced with the mentioned username (e.g. \"To: Jimbo Wales\").")
        return String.localizedStringWithFormat(format, agentName)
    }
    
    static func genericHeaderText(type: RemoteNotificationType, project: RemoteNotificationsProject) -> String {
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
