import WMFComponents

extension NotificationsCenterCommonViewModel {
    
    var title: String {
        return notification.type.title
    }
    
    var verboseTitle: String? {
        switch notification.type {
        case .userTalkPageMessage:
            guard let topicTitle = topicTitleFromTalkPageNotification(notification) else {
                return WMFLocalizedString("notifications-center-subheader-message-user-talk-page", value: "Message on your talk page", comment: "Subheader text for user talk page message notifications in Notifications Center.")
            }
            
            return topicTitle
        case .mentionInTalkPage:
            
            guard let topicTitle = topicTitleFromTalkPageNotification(notification) else {
                
                guard let namespace = PageNamespace(rawValue: Int(notification.titleNamespaceKey)),
                      namespace == .talk else {
                    return WMFLocalizedString("notifications-center-subheader-mention-talk-page", value: "Mention on talk page", comment: "Subheader text for non-Talk namespace mention notifications in Notifications Center.")
                }
                
                return WMFLocalizedString("notifications-center-subheader-mention-article-talk-page", value: "Mention on article talk page", comment: "Subheader text for Talk namespace mention notifications in Notifications Center.")
            }
            
            return topicTitle
            
        case .mentionInEditSummary:
            return WMFLocalizedString("notifications-center-subheader-mention-edit-summary", value: "Mention in edit summary", comment: "Subheader text for 'mention in edit summary' notifications in Notifications Center.")
        case .successfulMention:
            return WMFLocalizedString("notifications-center-subheader-mention-successful", value: "Successful mention", comment: "Subheader text for successful mention notifications in Notifications Center.")
        case .failedMention:
            return WMFLocalizedString("notifications-center-subheader-mention-failed", value: "Failed mention", comment: "Subheader text for failed mention notifications in Notifications Center.")
        case .editReverted:
            return WMFLocalizedString("notifications-center-subheader-edit-reverted", value: "Your edit was reverted", comment: "Subheader text for edit reverted notifications in Notifications Center.")
        case .userRightsChange:
            return WMFLocalizedString("notifications-center-subheader-user-rights-change", value: "User rights change", comment: "Subheader text for user rights change notifications in Notifications Center.")
        case .pageReviewed:
            return WMFLocalizedString("notifications-center-subheader-page-reviewed", value: "Page reviewed", comment: "Subheader text for page reviewed notifications in Notifications Center.")
        case .pageLinked:
            return WMFLocalizedString("notifications-center-subheader-page-link", value: "Page link", comment: "Subheader text for page link notifications in Notifications Center.")
        case .connectionWithWikidata:
            return WMFLocalizedString("notifications-center-subheader-wikidata-connection", value: "Wikidata connection made", comment: "Subheader text for 'Wikidata connection made' notifications in Notifications Center.")
        case .emailFromOtherUser:
            return WMFLocalizedString("notifications-center-subheader-email-from-other-user", value: "New email", comment: "Subheader text for 'email from other user' notifications in Notifications Center.")
        case .thanks:
            return WMFLocalizedString("notifications-center-subheader-thanks", value: "Thanks", comment: "Subheader text for thanks notifications in Notifications Center.")
        case .translationMilestone:
            return WMFLocalizedString("notifications-center-subheader-translate-milestone", value: "Translation milestone", comment: "Subheader text for translation milestone notifications in Notifications Center.")
        case .editMilestone:
            return WMFLocalizedString("notifications-center-subheader-edit-milestone", value: "Editing milestone", comment: "Subheader text for edit milestone notifications in Notifications Center.")
        case .welcome:
            return WMFLocalizedString("notifications-center-subheader-welcome", value: "Welcome!", comment: "Subheader text for welcome notifications in Notifications Center.")
        case .loginFailUnknownDevice:
            return WMFLocalizedString("notifications-center-subheader-login-fail-unknown-device", value: "Failed log in attempt", comment: "Subheader text for 'Failed login from an unknown device' notifications in Notifications Center.")
        case .loginFailKnownDevice:
            return WMFLocalizedString("notifications-center-subheader-login-fail-known-device", value: "Multiple failed log in attempts", comment: "Subheader text for 'Failed login from a known device' notifications in Notifications Center.")
        case .loginSuccessUnknownDevice:
            return CommonStrings.notificationsCenterLoginSuccessDescription
        case .unknownSystemNotice,
             .unknownSystemAlert,
             .unknownNotice,
             .unknownAlert,
             .unknown:
            return notification.messageHeader?.removingHTML
        }
    }
    
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
            
            if let messageHeader = notification.messageHeader?.removingHTML,
               !messageHeader.isEmpty {
                return messageHeader
            }
        
        case .userTalkPageMessage,
             .mentionInTalkPage,
             .mentionInEditSummary,
             .unknownSystemAlert,
             .unknownSystemNotice,
             .unknownAlert,
             .unknownNotice,
             .unknown:
            
            if let messageBody = notification.messageBody?.removingHTML,
               !messageBody.isEmpty {
                return messageBody
            }
        }
        
        return nil
    }
    
    var dateText: String? {
        guard let date = notification.date else {
            return nil
        }

        return (date as NSDate).wmf_localizedShortDateStringRelative(to: Date())
    }
}

// MARK: Talk page topic title determination helper methods

private extension NotificationsCenterCommonViewModel {
    func topicTitleFromTalkPageNotification(_ notification: RemoteNotification) -> String? {
        
        // We can try extracting the talk page title from the primary url's first fragment for user talk page message notifications
        
        let extractTitleFromURLBlock: (URL) -> String? = { url in
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            guard let fragment = components?.fragment else {
                return nil
            }
            
            return fragment.removingPercentEncoding?.replacingOccurrences(of: "_", with: " ")
        }
        
        // prefer legacyPrimary, since it seems to retain the section title as a fragment moreso than primary
        if let legacyPrimaryURL = notification.legacyPrimaryLinkURL,
        let legacyTitle = extractTitleFromURLBlock(legacyPrimaryURL) {
            if !legacyTitle.containsTalkPageSignature {
                return legacyTitle
            }
        }
        
        if let primaryURL = notification.primaryLinkURL,
           let title = extractTitleFromURLBlock(primaryURL) {
            if !title.containsTalkPageSignature {
                return title
            }
        }
        
        return nil
    }
}

private extension String {
    var containsISO8601DateText: Bool {
        let range = NSRange(location: 0, length: self.utf16.count)
        let regex = try! NSRegularExpression(pattern: ".+[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}\\.[0-9]{3}Z.+")
        
        let exists = regex.firstMatch(in: self, options: [], range: range) != nil
        return exists
    }
    
    var containsTalkPageSignature: Bool {
        return hasPrefix("c-") || containsISO8601DateText
    }
}
