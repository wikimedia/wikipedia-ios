
import Foundation

extension NotificationsCenterCellViewModel {
    
    enum SheetAction {
        case markAsReadOrUnread(SheetActionData)
        case custom(SheetActionData)
        case notificationSubscriptionSettings(SheetActionData)
    }
    
    struct SheetActionData {
        let text: String
        let url: URL?
    }
    
    func sheetActions(for configuration: Configuration) -> [SheetAction] {
        
        var sheetActions: [SheetAction] = []
        let markAsReadText = WMFLocalizedString("notifications-center-mark-as-read", value: "Mark as Read", comment: "Button text in Notifications Center to mark a notification as read.")
        let markAsUnreadText = WMFLocalizedString("notifications-center-mark-as-unread", value: "Mark as Unread", comment: "Button text in Notifications Center to mark a notification as unread.")
        let markAsReadOrUnreadText = isRead ? markAsUnreadText : markAsReadText
        let markAsReadOrUnreadActionData = SheetActionData(text: markAsReadOrUnreadText, url: nil)
        sheetActions.append(.markAsReadOrUnread(markAsReadOrUnreadActionData))
        
        switch notification.type {
        case .userTalkPageMessage:
            sheetActions.append(contentsOf: userTalkPageActions(for: configuration))
        case .mentionInTalkPage,
             .editReverted:
            sheetActions.append(contentsOf: mentionInTalkAndEditRevertedPageActions(for: configuration))
        case .mentionInEditSummary:
            sheetActions.append(contentsOf: mentionInEditSummaryActions(for: configuration))
        case .successfulMention,
             .failedMention:
            sheetActions.append(contentsOf: successfulAndFailedMentionActions(for: configuration))
        case .userRightsChange:
            sheetActions.append(contentsOf: userGroupRightsActions(for: configuration))
        case .pageReviewed:
            sheetActions.append(contentsOf: pageReviewedActions(for: configuration))
        case .pageLinked:
            sheetActions.append(contentsOf: pageLinkActions(for: configuration))
        case .connectionWithWikidata:
            sheetActions.append(contentsOf: connectionWithWikidataActions(for: configuration))
        case .emailFromOtherUser:
            sheetActions.append(contentsOf: emailFromOtherUserActions(for: configuration))
        case .thanks:
            sheetActions.append(contentsOf: thanksActions(for: configuration))
        case .translationMilestone,
             .editMilestone,
             .welcome:
            break
        case .loginFailKnownDevice,
             .loginFailUnknownDevice,
             .loginSuccessUnknownDevice:
            sheetActions.append(contentsOf: loginActions(for: configuration))

        case .unknownAlert,
             .unknownSystemAlert:
            sheetActions.append(contentsOf: genericAlertActions(for: configuration))

        case .unknownSystemNotice,
             .unknownNotice,
             .unknown:
            sheetActions.append(contentsOf: genericActions(for: configuration))

        }
        
        //TODO: add notification settings destination
        let notificationSubscriptionSettingsText = WMFLocalizedString("notifications-center-notifications-settings", value: "Notification settings", comment: "Button text in Notifications Center that automatically routes to the notifications settings screen.")
        let notificationSettingsActionData = SheetActionData(text: notificationSubscriptionSettingsText, url: nil)
        sheetActions.append(.notificationSubscriptionSettings(notificationSettingsActionData))
        
        return sheetActions
    }
}

//MARK: Private Helpers - Aggregate Swipe Action methods

private extension NotificationsCenterCellViewModel {
    func userTalkPageActions(for configuration: Configuration) -> [SheetAction] {
        var sheetActions: [SheetAction] = []

        if let agentUserPageAction = agentUserPageSheetAction(for: configuration) {
            sheetActions.append(agentUserPageAction)
        }

        if let diffAction = diffSheetAction(for: configuration) {
            sheetActions.append(diffAction)
        }

        if let talkPageAction = titleTalkPageSheetAction(for: configuration, yourPhrasing: true) {
            sheetActions.append(talkPageAction)
        }

        return sheetActions
    }

    func mentionInTalkAndEditRevertedPageActions(for configuration: Configuration) -> [SheetAction] {
        var sheetActions: [SheetAction] = []

        if let agentUserPageAction = agentUserPageSheetAction(for: configuration) {
            sheetActions.append(agentUserPageAction)
        }

        if let diffAction = diffSheetAction(for: configuration) {
            sheetActions.append(diffAction)
        }

        if let titleTalkPageAction = titleTalkPageSheetAction(for: configuration, yourPhrasing: false) {
            sheetActions.append(titleTalkPageAction)
        }

        if let titleAction = titleSheetAction(for: configuration) {
            sheetActions.append(titleAction)
        }

        return sheetActions
    }

    func mentionInEditSummaryActions(for configuration: Configuration) -> [SheetAction] {
        var sheetActions: [SheetAction] = []

        if let agentUserPageAction = agentUserPageSheetAction(for: configuration) {
            sheetActions.append(agentUserPageAction)
        }

        if let diffAction = diffSheetAction(for: configuration) {
            sheetActions.append(diffAction)
        }

        if let titleAction = titleSheetAction(for: configuration) {
            sheetActions.append(titleAction)
        }

        return sheetActions
    }

    func successfulAndFailedMentionActions(for configuration: Configuration) -> [SheetAction] {
        if let titleAction = titleSheetAction(for: configuration) {
            return [titleAction]
        }

        return []
    }

    func userGroupRightsActions(for configuration: Configuration) -> [SheetAction] {
        var sheetActions: [SheetAction] = []

        if let specificUserGroupRightsAction = specificUserGroupRightsSheetAction {
            sheetActions.append(specificUserGroupRightsAction)
        }

        if let agentUserPageAction = agentUserPageSheetAction(for: configuration) {
            sheetActions.append(agentUserPageAction)
        }

        if let userGroupRightsAction = userGroupRightsSheetAction(for: configuration) {
            sheetActions.append(userGroupRightsAction)
        }

        return sheetActions
    }

    func pageReviewedActions(for configuration: Configuration) -> [SheetAction] {
        var sheetActions: [SheetAction] = []

        if let agentUserPageAction = agentUserPageSheetAction(for: configuration) {
            sheetActions.append(agentUserPageAction)
        }

        if let titleAction = titleSheetAction(for: configuration) {
            sheetActions.append(titleAction)
        }

        return sheetActions
    }

    func pageLinkActions(for configuration: Configuration) -> [SheetAction] {
        var sheetActions: [SheetAction] = []

        if let agentUserPageAction = agentUserPageSheetAction(for: configuration) {
            sheetActions.append(agentUserPageAction)
        }

        //Article where link was made
        if let pageLinkToAction = pageLinkToAction {
            sheetActions.append(pageLinkToAction)
        }
        
        //Article you edited
        if let titleAction = titleSheetAction(for: configuration) {
            sheetActions.append(titleAction)
        }

        if let diffAction = diffSheetAction(for: configuration) {
            sheetActions.append(diffAction)
        }

        return sheetActions
    }

    func connectionWithWikidataActions(for configuration: Configuration) -> [SheetAction] {
        var sheetActions: [SheetAction] = []

        if let agentUserPageAction = agentUserPageSheetAction(for: configuration) {
            sheetActions.append(agentUserPageAction)
        }

        if let titleAction = titleSheetAction(for: configuration) {
            sheetActions.append(titleAction)
        }

        if let wikidataItemAction = wikidataItemAction {
            sheetActions.append(wikidataItemAction)
        }

        return sheetActions
    }

    func emailFromOtherUserActions(for configuration: Configuration) -> [SheetAction] {
        if let agentUserPageAction = agentUserPageSheetAction(for: configuration) {
            return [agentUserPageAction]
        }

        return []
    }

    func thanksActions(for configuration: Configuration) -> [SheetAction] {
        var sheetActions: [SheetAction] = []

        if let agentUserPageAction = agentUserPageSheetAction(for: configuration) {
            sheetActions.append(agentUserPageAction)
        }

        if let titleAction = titleSheetAction(for: configuration) {
            sheetActions.append(titleAction)
        }

        if let diffAction = diffSheetAction(for: configuration) {
            sheetActions.append(diffAction)
        }

        return sheetActions
    }

    func loginActions(for configuration: Configuration) -> [SheetAction] {
        var sheetActions: [SheetAction] = []

        if let loginHelpAction = loginNotificationsSheetAction(for: configuration) {
            sheetActions.append(loginHelpAction)
        }

        if let changePasswordSheetAction = changePasswordSheetAction(for: configuration) {
            sheetActions.append(changePasswordSheetAction)
        }

        return sheetActions
    }

    func genericAlertActions(for configuration: Configuration) -> [SheetAction] {
        var sheetActions: [SheetAction] = []

        if let secondaryLinks = notification.secondaryLinks {
            let secondarySheetActions = secondaryLinks.compactMap { sheetActionForGenericLink(link:$0, configuration:configuration) }
            sheetActions.append(contentsOf: secondarySheetActions)
        }

        if let diffAction = diffSheetAction(for: configuration) {
            sheetActions.append(diffAction)
        }

        if let primaryLink = notification.primaryLink,
           let primarySheetAction = sheetActionForGenericLink(link: primaryLink, configuration: configuration) {
            sheetActions.append(primarySheetAction)
        }

        return sheetActions
    }

    func genericActions(for configuration: Configuration) -> [SheetAction] {
        var sheetActions: [SheetAction] = []

        if let agentUserPageAction = agentUserPageSheetAction(for: configuration) {
            sheetActions.append(agentUserPageAction)
        }

        if let diffAction = diffSheetAction(for: configuration) {
            sheetActions.append(diffAction)
        }

        if let primaryLink = notification.primaryLink,
           let primarySheetAction = sheetActionForGenericLink(link: primaryLink, configuration: configuration) {
            sheetActions.append(primarySheetAction)
        }

        return sheetActions
    }
}

//MARK: Private Helpers - Individual Swipe Action methods

private extension NotificationsCenterCellViewModel {
    //Go to [Username]'s user page
    func agentUserPageSheetAction(for configuration: Configuration) -> SheetAction? {
        guard let agentName = notification.agentName,
              let url = customPrefixAgentNameURL(for: configuration, pageNamespace: .user) else {
            return nil
        }

        let format = WMFLocalizedString("notifications-center-go-to-user-page", value: "Go to %1$@'s user page", comment: "Button text in Notifications Center that routes to a web view of the user page of the sender that triggered the notification. %1$@ is replaced with the sender's username.")
        let text = String.localizedStringWithFormat(format, agentName)

        let data = SheetActionData(text: text, url: url)

        return SheetAction.custom(data)
    }

    //Go to diff
    func diffSheetAction(for configuration: Configuration) -> SheetAction? {
        guard let url = fullTitleDiffURL(for: configuration) else {
            return nil
        }

        let text = WMFLocalizedString("notifications-center-go-to-diff", value: "Go to diff", comment: "Button text in Notifications Center that routes to a diff screen of the revision that triggered the notification.")
        let data = SheetActionData(text: text, url: url)
        return SheetAction.custom(data)
    }

    //Go to [your?] talk page
    func titleTalkPageSheetAction(for configuration: Configuration, yourPhrasing: Bool = false) -> SheetAction? {
        
        guard let linkData = linkData(for: configuration),
              let namespace = linkData.titleNamespace,
              let talkEquivalent = namespace.talkEquivalent,
              let url = customPrefixTitleURL(for: configuration, pageNamespace: talkEquivalent) else {
            return nil
        }

        let text = yourPhrasing ? WMFLocalizedString("notifications-center-go-to-your-talk-page", value: "Go to your talk page", comment: "Button text in Notifications Center that routes to user's talk page.") : WMFLocalizedString("notifications-center-go-to-talk-page", value: "Go to talk page", comment: "Button text in Notifications Center that routes to a talk page.")

        let data = SheetActionData(text: text, url: url)
        return SheetAction.custom(data)
    }

    //Go to [Name of article]
    func titleSheetAction(for configuration: Configuration) -> SheetAction? {
        guard let linkData = linkData(for: configuration),
              let url = fullTitleURL(for: configuration),
              let title = notification.titleText else {
            return nil
        }
        
        var prefix = ""
        if let namespace = linkData.titleNamespace {
            prefix = namespace != .main ? "\(namespace.canonicalName):" : ""
        }
        let text = String.localizedStringWithFormat(CommonStrings.notificationsCenterGoToTitleFormat, "\(prefix)\(title)")
        let data = SheetActionData(text: text, url: url)
        return SheetAction.custom(data)
    }

    //Go to [Article where link was made]
    var pageLinkToAction: SheetAction? {
        guard let url = pageLinkToURL,
              let title = url.wmf_title else {
            return nil
        }

        let text = String.localizedStringWithFormat(CommonStrings.notificationsCenterGoToTitleFormat, title)
        let data = SheetActionData(text: text, url: url)
        return SheetAction.custom(data)
    }

    //Go to Wikidata item
    var wikidataItemAction: SheetAction? {
        guard let url = connectionWithWikidataItemURL else {
            return nil
        }

        let text = WMFLocalizedString("notifications-center-go-to-wikidata-item", value: "Go to Wikidata item", comment: "Button text in Notifications Center that routes to a Wikidata item page.")
        let data = SheetActionData(text: text, url: url)
        return SheetAction.custom(data)
    }

    //Go to specific Special:UserGroupRights#{Type} page
    var specificUserGroupRightsSheetAction: SheetAction? {
        guard let url = specificUserGroupRightsURL,
              let type = url.fragment,
              let title = url.wmf_title else {
            return nil
        }

        let text = String.localizedStringWithFormat(CommonStrings.notificationsCenterGoToTitleFormat, "\(title)#\(type)")
        let data = SheetActionData(text: text, url: url)
        return SheetAction.custom(data)
    }

    //Go to Special:UserGroupRights
    func userGroupRightsSheetAction(for configuration: Configuration) -> SheetAction? {
        guard let url = userGroupRightsURL,
              let title = url.wmf_title else {
            return nil
        }

        let text = String.localizedStringWithFormat(CommonStrings.notificationsCenterGoToTitleFormat, title)
        let data = SheetActionData(text: text, url: url)
        return SheetAction.custom(data)
    }

    //Login Notifications
    func loginNotificationsSheetAction(for configuration: Configuration) -> SheetAction? {
        guard let url = loginNotificationsHelpURL else {
            return nil
        }

        let text = WMFLocalizedString("notifications-center-login-notifications", value: "Login Notifications", comment: "Button text in Notifications Center that routes user to login notifications help page in web view.")

        let data = SheetActionData(text: text, url: url)
        return SheetAction.custom(data)
    }

    //Change password
    func changePasswordSheetAction(for configuration: Configuration) -> SheetAction? {

        guard let url = changePasswordURL(for: configuration) else {
            return nil
        }

        let text = WMFLocalizedString("notifications-center-change-password", value: "Change Password", comment: "Button text in Notifications Center that routes user to change password screen.")

        let data = SheetActionData(text: text, url: url)
        return SheetAction.custom(data)
    }

    func sheetActionForGenericLink(link: RemoteNotificationLink, configuration: Configuration) -> SheetAction? {
        guard let url = link.url,
              let text = link.label else {
            return nil
        }

        let data = SheetActionData(text: text, url: url)
        return SheetAction.custom(data)
    }
}
