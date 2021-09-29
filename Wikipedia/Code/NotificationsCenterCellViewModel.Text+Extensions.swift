
import Foundation

extension NotificationsCenterCellViewModel.Text {
    init(project: RemoteNotificationsProject, notification: RemoteNotification) {
        self.header = Self.determineHeaderText(project: project, notification: notification)
        self.subheader = Self.determineSubheaderText(notification: notification)
        self.body = Self.determineBodyText(notification: notification)
        self.footer = Self.determineFooterText(notification: notification)
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
    
    private static func determineSubheaderText(notification: RemoteNotification) -> String? {
        
        switch notification.type {
        case .userTalkPageMessage:
            guard let topicTitle = topicTitleFromTalkPageNotification(notification) else {
                return WMFLocalizedString("notifications-subheader-message-user-talk-page", value: "Message on your talk page", comment: "Subheader text for user talk page message notifications in Notification Center.")
            }
            
            return topicTitle
        case .mentionInTalkPage:
            
            guard let topicTitle = topicTitleFromTalkPageNotification(notification) else {
                
                guard let namespace = PageNamespace(rawValue: Int(notification.titleNamespaceKey)),
                      namespace == .talk else {
                    //TODO: Should we target other talk page types and have a more specific string? See PageNamespace options.
                    return WMFLocalizedString("notifications-subheader-mention-talk-page", value: "Mention on talk page", comment: "Subheader text for non-Talk namespace mention notifications in Notification Center.")
                }
                
                return WMFLocalizedString("notifications-subheader-mention-article-talk-page", value: "Mention on article talk page", comment: "Subheader text for Talk namespace mention notifications in Notification Center.")
            }
            
            return topicTitle
            
        case .mentionInEditSummary:
            return WMFLocalizedString("notifications-subheader-mention-edit-summary", value: "Mention in edit summary", comment: "Subheader text for 'mention in edit summary' notifications in Notification Center.")
        case .successfulMention:
            return WMFLocalizedString("notifications-subheader-mention-successful", value: "Successful mention", comment: "Subheader text for successful mention notifications in Notification Center.")
        case .failedMention:
            return WMFLocalizedString("notifications-subheader-mention-failed", value: "Failed mention", comment: "Subheader text for failed mention notifications in Notification Center.")
        case .editReverted:
            return WMFLocalizedString("notifications-subheader-edit-reverted", value: "Your edit was reverted", comment: "Subheader text for edit reverted notifications in Notification Center.")
        case .userRightsChange:
            return WMFLocalizedString("notifications-subheader-user-rights-change", value: "User rights change", comment: "Subheader text for user rights change notifications in Notification Center.")
        case .pageReviewed:
            return WMFLocalizedString("notifications-subheader-page-reviewed", value: "Page reviewed", comment: "Subheader text for page reviewed notifications in Notification Center.")
        case .pageLinked:
            return WMFLocalizedString("notifications-subheader-page-link", value: "Page link", comment: "Subheader text for page link notifications in Notification Center.")
        case .connectionWithWikidata:
            return WMFLocalizedString("notifications-subheader-wikidata-connection", value: "Wikidata connection made", comment: "Subheader text for 'Wikidata connection made' notifications in Notification Center.")
        case .emailFromOtherUser:
            return WMFLocalizedString("notifications-subheader-email-from-other-user", value: "New email", comment: "Subheader text for 'email from other user' notifications in Notification Center.")
        case .thanks:
            return WMFLocalizedString("notifications-subheader-thanks", value: "Thanks", comment: "Subheader text for thanks notifications in Notification Center.")
        case .translationMilestone(_):
            return WMFLocalizedString("notifications-subheader-translate-milestone", value: "Translation milestone", comment: "Subheader text for translation milestone notifications in Notification Center.")
        case .editMilestone:
            return WMFLocalizedString("notifications-subheader-edit-milestone", value: "Editing milestone", comment: "Subheader text for edit milestone notifications in Notification Center.")
        case .welcome:
            return WMFLocalizedString("notifications-subheader-welcome", value: "Translation milestone", comment: "Subheader text for welcome notifications in Notification Center.")
        case .loginFailUnknownDevice:
            return WMFLocalizedString("notifications-subheader-login-fail-unknown-device", value: "Failed log in attempt", comment: "Subheader text for 'Failed login from an unknown device' notifications in Notification Center.")
        case .loginFailKnownDevice:
            return WMFLocalizedString("notifications-subheader-login-fail-known-device", value: "Multiple failed log in attempts", comment: "Subheader text for 'Failed login from a known device' notifications in Notification Center.")
        case .loginSuccessUnknownDevice:
            return WMFLocalizedString("notifications-subheader-login-success-unknown-device", value: "Log in from an unfamiliar device", comment: "Subheader text for 'Successful login from an unknown device' notifications in Notification Center.")
        case .unknownSystemNotice,
             .unknownSystemAlert,
             .unknownNotice,
             .unknownAlert,
             .unknown:
            return notification.messageHeader?.removingHTML
        }
    }
    
    private static func determineBodyText(notification: RemoteNotification) -> String? {
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
    
    private static func determineFooterText(notification: RemoteNotification) -> String? {
        switch notification.type {
        case .welcome,
             .emailFromOtherUser:
            return nil
        case .loginFailKnownDevice,
             .loginFailUnknownDevice,
             .loginSuccessUnknownDevice:
            return WMFLocalizedString("notifications-footer-change-password", value: "Change password", comment: "Footer text for login-related notifications in Notification Center.")
        case .unknownSystemAlert,
             .unknownSystemNotice,
             .unknownAlert,
             .unknownNotice,
             .unknown:
            guard let primaryLinkTitle = notification.messageLinks?.primaryLabel else {
                return nil
            }
            
            return primaryLinkTitle
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

//MARK: Subheader text determination helper methods

private extension NotificationsCenterCellViewModel.Text {
    static func topicTitleFromTalkPageNotification(_ notification: RemoteNotification) -> String? {
        
        //We can extract the talk page title from the primary url's first fragment for user talk page message notifications
        
        guard let primaryUrl = notification.messageLinks?.primaryUrl else {
            return nil
        }
        
        let components = URLComponents(url: primaryUrl, resolvingAgainstBaseURL: false)
        guard let fragment = components?.fragment else {
            return nil
        }
        
        return fragment.removingPercentEncoding?.replacingOccurrences(of: "_", with: " ")
    }
}
