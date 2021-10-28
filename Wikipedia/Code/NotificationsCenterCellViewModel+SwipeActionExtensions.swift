
import Foundation

extension NotificationsCenterCellViewModel {
    
    enum SwipeAction {
        case markAsRead(SwipeActionData)
        case custom(SwipeActionData)
        case notificationSubscriptionSettings(SwipeActionData)
    }
    
    struct SwipeActionData {
        let text: String
        let url: URL?
    }
    
    func swipeActions(for configuration: Configuration) -> [SwipeAction] {
        
        var swipeActions: [SwipeAction] = []
        let markAsReadText = WMFLocalizedString("notifications-center-mark-as-read", value: "Mark as Read", comment: "Button text in Notifications Center to mark a notification as read.")
        let markAsReadActionData = SwipeActionData(text: markAsReadText, url: nil)
        swipeActions.append(.markAsRead(markAsReadActionData))
        
        switch notification.type {
        case .userTalkPageMessage:
            swipeActions.append(contentsOf: userTalkPageActions(for: configuration))
        case .mentionInTalkPage,
             .editReverted:
            swipeActions.append(contentsOf: mentionInTalkAndEditRevertedPageActions(for: configuration))
        case .mentionInEditSummary: //done
            swipeActions.append(contentsOf: mentionInEditSummaryActions(for: configuration))
        case .successfulMention,
             .failedMention:
            swipeActions.append(contentsOf: successfulAndFailedMentionActions(for: configuration))
        case .userRightsChange:
            swipeActions.append(contentsOf: userGroupRightsActions(for: configuration))
        case .pageReviewed:
            swipeActions.append(contentsOf: pageReviewedActions(for: configuration))
        case .pageLinked:
            swipeActions.append(contentsOf: pageLinkActions(for: configuration))
        case .connectionWithWikidata:
            swipeActions.append(contentsOf: connectionWithWikidataActions(for: configuration))
        case .emailFromOtherUser:
            swipeActions.append(contentsOf: emailFromOtherUserActions(for: configuration))
        case .thanks:
            swipeActions.append(contentsOf: thanksActions(for: configuration))
        case .translationMilestone,
             .editMilestone,
             .welcome:
            break
        case .loginFailKnownDevice,
             .loginFailUnknownDevice,
             .loginSuccessUnknownDevice:
            swipeActions.append(contentsOf: loginActions(for: configuration))

        case .unknownAlert,
             .unknownSystemAlert:
            swipeActions.append(contentsOf: genericAlertActions(for: configuration))

        case .unknownSystemNotice,
             .unknownNotice,
             .unknown:
            swipeActions.append(contentsOf: genericActions(for: configuration))

        }
        
        //TODO: add notification settings destination
        let notificationSubscriptionSettingsText = WMFLocalizedString("notifications-center-notifications-settings", value: "Notification settings", comment: "Button text in Notifications Center that automatically routes to the notifications settings screen.")
        let notificationSettingsActionData = SwipeActionData(text: notificationSubscriptionSettingsText, url: nil)
        swipeActions.append(.notificationSubscriptionSettings(notificationSettingsActionData))
        
        return swipeActions
    }
}

//MARK: Private Helpers - Aggregate Swipe Action methods

private extension NotificationsCenterCellViewModel {
    func userTalkPageActions(for configuration: Configuration) -> [SwipeAction] {
        var swipeActions: [SwipeAction] = []

        if let agentUserPageAction = agentUserPageSwipeAction(for: configuration) {
            swipeActions.append(agentUserPageAction)
        }

        if let diffAction = diffSwipeAction(for: configuration) {
            swipeActions.append(diffAction)
        }

        if let talkPageAction = titleTalkPageSwipeAction(for: configuration, yourPhrasing: true) {
            swipeActions.append(talkPageAction)
        }

        return swipeActions
    }

    func mentionInTalkAndEditRevertedPageActions(for configuration: Configuration) -> [SwipeAction] {
        var swipeActions: [SwipeAction] = []

        if let agentUserPageAction = agentUserPageSwipeAction(for: configuration) {
            swipeActions.append(agentUserPageAction)
        }

        if let diffAction = diffSwipeAction(for: configuration) {
            swipeActions.append(diffAction)
        }

        if let titleTalkPageAction = titleTalkPageSwipeAction(for: configuration, yourPhrasing: false) {
            swipeActions.append(titleTalkPageAction)
        }

        if let titleAction = titleSwipeAction(for: configuration) {
            swipeActions.append(titleAction)
        }

        return swipeActions
    }

    func mentionInEditSummaryActions(for configuration: Configuration) -> [SwipeAction] {
        var swipeActions: [SwipeAction] = []

        if let agentUserPageAction = agentUserPageSwipeAction(for: configuration) {
            swipeActions.append(agentUserPageAction)
        }

        if let diffAction = diffSwipeAction(for: configuration) {
            swipeActions.append(diffAction)
        }

        if let titleAction = titleSwipeAction(for: configuration) {
            swipeActions.append(titleAction)
        }

        return swipeActions
    }

    func successfulAndFailedMentionActions(for configuration: Configuration) -> [SwipeAction] {
        if let titleAction = titleSwipeAction(for: configuration) {
            return [titleAction]
        }

        return []
    }

    func userGroupRightsActions(for configuration: Configuration) -> [SwipeAction] {
        var swipeActions: [SwipeAction] = []

        if let specificUserGroupRightsAction = specificUserGroupRightsSwipeAction {
            swipeActions.append(specificUserGroupRightsAction)
        }

        if let agentUserPageAction = agentUserPageSwipeAction(for: configuration) {
            swipeActions.append(agentUserPageAction)
        }

        if let userGroupRightsAction = userGroupRightsSwipeAction(for: configuration) {
            swipeActions.append(userGroupRightsAction)
        }

        return swipeActions
    }

    func pageReviewedActions(for configuration: Configuration) -> [SwipeAction] {
        var swipeActions: [SwipeAction] = []

        if let agentUserPageAction = agentUserPageSwipeAction(for: configuration) {
            swipeActions.append(agentUserPageAction)
        }

        if let titleAction = titleSwipeAction(for: configuration) {
            swipeActions.append(titleAction)
        }

        return swipeActions
    }

    func pageLinkActions(for configuration: Configuration) -> [SwipeAction] {
        var swipeActions: [SwipeAction] = []

        if let agentUserPageAction = agentUserPageSwipeAction(for: configuration) {
            swipeActions.append(agentUserPageAction)
        }

        //Article where link was made
        if let pageLinkToAction = pageLinkToAction {
            swipeActions.append(pageLinkToAction)
        }
        
        //Article you edited
        if let titleAction = titleSwipeAction(for: configuration) {
            swipeActions.append(titleAction)
        }

        if let diffAction = diffSwipeAction(for: configuration) {
            swipeActions.append(diffAction)
        }

        return swipeActions
    }

    func connectionWithWikidataActions(for configuration: Configuration) -> [SwipeAction] {
        var swipeActions: [SwipeAction] = []

        if let agentUserPageAction = agentUserPageSwipeAction(for: configuration) {
            swipeActions.append(agentUserPageAction)
        }

        if let titleAction = titleSwipeAction(for: configuration) {
            swipeActions.append(titleAction)
        }

        if let wikidataItemAction = wikidataItemAction {
            swipeActions.append(wikidataItemAction)
        }

        return swipeActions
    }

    func emailFromOtherUserActions(for configuration: Configuration) -> [SwipeAction] {
        if let agentUserPageAction = agentUserPageSwipeAction(for: configuration) {
            return [agentUserPageAction]
        }

        return []
    }

    func thanksActions(for configuration: Configuration) -> [SwipeAction] {
        var swipeActions: [SwipeAction] = []

        if let agentUserPageAction = agentUserPageSwipeAction(for: configuration) {
            swipeActions.append(agentUserPageAction)
        }

        if let titleAction = titleSwipeAction(for: configuration) {
            swipeActions.append(titleAction)
        }

        if let diffAction = diffSwipeAction(for: configuration) {
            swipeActions.append(diffAction)
        }

        return swipeActions
    }

    func loginActions(for configuration: Configuration) -> [SwipeAction] {
        var swipeActions: [SwipeAction] = []

        if let loginHelpAction = loginNotificationsSwipeAction(for: configuration) {
            swipeActions.append(loginHelpAction)
        }

        if let changePasswordSwipeAction = changePasswordSwipeAction(for: configuration) {
            swipeActions.append(changePasswordSwipeAction)
        }

        return swipeActions
    }

    func genericAlertActions(for configuration: Configuration) -> [SwipeAction] {
        var swipeActions: [SwipeAction] = []

        if let secondaryLinks = notification.secondaryLinks {
            let secondarySwipeActions = secondaryLinks.compactMap { swipeActionForGenericLink(link:$0, configuration:configuration) }
            swipeActions.append(contentsOf: secondarySwipeActions)
        }

        if let diffAction = diffSwipeAction(for: configuration) {
            swipeActions.append(diffAction)
        }

        if let primaryLink = notification.primaryLink,
           let primarySwipeAction = swipeActionForGenericLink(link: primaryLink, configuration: configuration) {
            swipeActions.append(primarySwipeAction)
        }

        return swipeActions
    }

    func genericActions(for configuration: Configuration) -> [SwipeAction] {
        var swipeActions: [SwipeAction] = []

        if let agentUserPageAction = agentUserPageSwipeAction(for: configuration) {
            swipeActions.append(agentUserPageAction)
        }

        if let diffAction = diffSwipeAction(for: configuration) {
            swipeActions.append(diffAction)
        }

        if let primaryLink = notification.primaryLink,
           let primarySwipeAction = swipeActionForGenericLink(link: primaryLink, configuration: configuration) {
            swipeActions.append(primarySwipeAction)
        }

        return swipeActions
    }
}

//MARK: Private Helpers - Individual Swipe Action methods

private extension NotificationsCenterCellViewModel {
    //Go to [Username]'s user page
    func agentUserPageSwipeAction(for configuration: Configuration) -> SwipeAction? {
        guard let agentName = notification.agentName,
              let url = customPrefixAgentNameURL(for: configuration, pageNamespace: .user) else {
            return nil
        }

        let format = WMFLocalizedString("notifications-center-go-to-user-page", value: "Go to %1$@'s user page", comment: "Button text in Notifications Center that routes to a web view of the user page of the sender that triggered the notification. %1$@ is replaced with the sender's username.")
        let text = String.localizedStringWithFormat(format, agentName)

        let data = SwipeActionData(text: text, url: url)

        return SwipeAction.custom(data)
    }

    //Go to diff
    func diffSwipeAction(for configuration: Configuration) -> SwipeAction? {
        guard let url = fullTitleDiffURL(for: configuration) else {
            return nil
        }

        let text = WMFLocalizedString("notifications-center-go-to-diff", value: "Go to diff", comment: "Button text in Notifications Center that routes to a diff screen of the revision that triggered the notification.")
        let data = SwipeActionData(text: text, url: url)
        return SwipeAction.custom(data)
    }

    //Go to [your?] talk page
    func titleTalkPageSwipeAction(for configuration: Configuration, yourPhrasing: Bool = false) -> SwipeAction? {
        
        guard let linkData = linkData(for: configuration),
              let namespace = linkData.titleNamespace,
              let talkEquivalent = namespace.talkEquivalent,
              let url = customPrefixTitleURL(for: configuration, pageNamespace: talkEquivalent) else {
            return nil
        }

        let text = yourPhrasing ? WMFLocalizedString("notifications-center-go-to-your-talk-page", value: "Go to your talk page", comment: "Button text in Notifications Center that routes to user's talk page.") : WMFLocalizedString("notifications-center-go-to-talk-page", value: "Go to talk page", comment: "Button text in Notifications Center that routes to a talk page.")

        let data = SwipeActionData(text: text, url: url)
        return SwipeAction.custom(data)
    }

    //Go to [Name of article]
    func titleSwipeAction(for configuration: Configuration) -> SwipeAction? {
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
        let data = SwipeActionData(text: text, url: url)
        return SwipeAction.custom(data)
    }

    //Go to [Article where link was made]
    var pageLinkToAction: SwipeAction? {
        guard let url = pageLinkToURL,
              let title = url.wmf_title else {
            return nil
        }

        let text = String.localizedStringWithFormat(CommonStrings.notificationsCenterGoToTitleFormat, title)
        let data = SwipeActionData(text: text, url: url)
        return SwipeAction.custom(data)
    }

    //Go to Wikidata item
    var wikidataItemAction: SwipeAction? {
        guard let url = connectionWithWikidataItemURL else {
            return nil
        }

        let text = WMFLocalizedString("notifications-center-go-to-wikidata-item", value: "Go to Wikidata item", comment: "Button text in Notifications Center that routes to a Wikidata item page.")
        let data = SwipeActionData(text: text, url: url)
        return SwipeAction.custom(data)
    }

    //Go to specific Special:UserGroupRights#{Type} page
    var specificUserGroupRightsSwipeAction: SwipeAction? {
        guard let url = specificUserGroupRightsURL,
              let type = url.fragment,
              let title = url.wmf_title else {
            return nil
        }

        let text = String.localizedStringWithFormat(CommonStrings.notificationsCenterGoToTitleFormat, "\(title)#\(type)")
        let data = SwipeActionData(text: text, url: url)
        return SwipeAction.custom(data)
    }

    //Go to Special:UserGroupRights
    func userGroupRightsSwipeAction(for configuration: Configuration) -> SwipeAction? {
        guard let url = userGroupRightsURL,
              let title = url.wmf_title else {
            return nil
        }

        let text = String.localizedStringWithFormat(CommonStrings.notificationsCenterGoToTitleFormat, title)
        let data = SwipeActionData(text: text, url: url)
        return SwipeAction.custom(data)
    }

    //Login Notifications
    func loginNotificationsSwipeAction(for configuration: Configuration) -> SwipeAction? {
        guard let url = loginNotificationsHelpURL else {
            return nil
        }

        let text = WMFLocalizedString("notifications-center-login-notifications", value: "Login Notifications", comment: "Button text in Notifications Center that routes user to login notifications help page in web view.")

        let data = SwipeActionData(text: text, url: url)
        return SwipeAction.custom(data)
    }

    //Change password
    func changePasswordSwipeAction(for configuration: Configuration) -> SwipeAction? {

        guard let url = changePasswordURL(for: configuration) else {
            return nil
        }

        let text = WMFLocalizedString("notifications-center-change-password", value: "Change Password", comment: "Button text in Notifications Center that routes user to change password screen.")

        let data = SwipeActionData(text: text, url: url)
        return SwipeAction.custom(data)
    }

    func swipeActionForGenericLink(link: RemoteNotificationLink, configuration: Configuration) -> SwipeAction? {
        guard let url = link.url,
              let text = link.label else {
            return nil
        }

        let data = SwipeActionData(text: text, url: url)
        return SwipeAction.custom(data)
    }
}
