
import Foundation
import WMF

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
    
    var sheetActions: [SheetAction] {
        
        var sheetActions: [SheetAction] = []
        let markAsReadText = CommonStrings.notificationsCenterMarkAsRead
        let markAsUnreadText = CommonStrings.notificationsCenterMarkAsUnread
        let markAsReadOrUnreadText = isRead ? markAsUnreadText : markAsReadText
        let markAsReadOrUnreadActionData = SheetActionData(text: markAsReadOrUnreadText, url: nil)
        sheetActions.append(.markAsReadOrUnread(markAsReadOrUnreadActionData))
        
        switch notification.type {
        case .userTalkPageMessage:
            sheetActions.append(contentsOf: userTalkPageActions)
        case .mentionInTalkPage,
             .editReverted:
            sheetActions.append(contentsOf: mentionInTalkAndEditRevertedPageActions)
        case .mentionInEditSummary:
            sheetActions.append(contentsOf: mentionInEditSummaryActions)
        case .successfulMention,
             .failedMention:
            sheetActions.append(contentsOf: successfulAndFailedMentionActions)
        case .userRightsChange:
            sheetActions.append(contentsOf: userGroupRightsActions)
        case .pageReviewed:
            sheetActions.append(contentsOf: pageReviewedActions)
        case .pageLinked:
            sheetActions.append(contentsOf: pageLinkActions)
        case .connectionWithWikidata:
            sheetActions.append(contentsOf: connectionWithWikidataActions)
        case .emailFromOtherUser:
            sheetActions.append(contentsOf: emailFromOtherUserActions)
        case .thanks:
            sheetActions.append(contentsOf: thanksActions)
        case .translationMilestone,
             .editMilestone,
             .welcome:
            break
        case .loginFailKnownDevice,
             .loginFailUnknownDevice,
             .loginSuccessUnknownDevice:
            sheetActions.append(contentsOf: loginActions)

        case .unknownAlert,
             .unknownSystemAlert:
            sheetActions.append(contentsOf: genericAlertActions)

        case .unknownSystemNotice,
             .unknownNotice,
             .unknown:
            sheetActions.append(contentsOf: genericActions)

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
    var userTalkPageActions: [SheetAction] {
        var sheetActions: [SheetAction] = []

        if let agentUserPageAction = agentUserPageSheetAction {
            sheetActions.append(agentUserPageAction)
        }

        if let diffAction = diffSheetAction {
            sheetActions.append(diffAction)
        }

        if let talkPageAction = titleTalkPageSheetAction(yourPhrasing: true) {
            sheetActions.append(talkPageAction)
        }

        return sheetActions
    }

    var mentionInTalkAndEditRevertedPageActions: [SheetAction] {
        var sheetActions: [SheetAction] = []

        if let agentUserPageAction = agentUserPageSheetAction {
            sheetActions.append(agentUserPageAction)
        }

        if let diffAction = diffSheetAction {
            sheetActions.append(diffAction)
        }

        if let titleTalkPageAction = titleTalkPageSheetAction(yourPhrasing: false) {
            sheetActions.append(titleTalkPageAction)
        }

        if let titleAction = titleSheetAction {
            sheetActions.append(titleAction)
        }

        return sheetActions
    }

    var mentionInEditSummaryActions: [SheetAction] {
        var sheetActions: [SheetAction] = []

        if let agentUserPageAction = agentUserPageSheetAction {
            sheetActions.append(agentUserPageAction)
        }

        if let diffAction = diffSheetAction {
            sheetActions.append(diffAction)
        }

        if let titleAction = titleSheetAction {
            sheetActions.append(titleAction)
        }

        return sheetActions
    }

    var successfulAndFailedMentionActions: [SheetAction] {
        if let titleAction = titleSheetAction {
            return [titleAction]
        }

        return []
    }

    var userGroupRightsActions: [SheetAction] {
        var sheetActions: [SheetAction] = []

        if let specificUserGroupRightsAction = specificUserGroupRightsSheetAction {
            sheetActions.append(specificUserGroupRightsAction)
        }

        if let agentUserPageAction = agentUserPageSheetAction {
            sheetActions.append(agentUserPageAction)
        }

        if let userGroupRightsAction = userGroupRightsSheetAction {
            sheetActions.append(userGroupRightsAction)
        }

        return sheetActions
    }

    var pageReviewedActions: [SheetAction] {
        var sheetActions: [SheetAction] = []

        if let agentUserPageAction = agentUserPageSheetAction {
            sheetActions.append(agentUserPageAction)
        }

        if let titleAction = titleSheetAction {
            sheetActions.append(titleAction)
        }

        return sheetActions
    }

    var pageLinkActions: [SheetAction] {
        var sheetActions: [SheetAction] = []

        if let agentUserPageAction = agentUserPageSheetAction {
            sheetActions.append(agentUserPageAction)
        }

        //Article where link was made
        if let pageLinkToAction = pageLinkToAction {
            sheetActions.append(pageLinkToAction)
        }
        
        //Article you edited
        if let titleAction = titleSheetAction {
            sheetActions.append(titleAction)
        }

        if let diffAction = diffSheetAction {
            sheetActions.append(diffAction)
        }

        return sheetActions
    }

    var connectionWithWikidataActions: [SheetAction] {
        var sheetActions: [SheetAction] = []

        if let agentUserPageAction = agentUserPageSheetAction {
            sheetActions.append(agentUserPageAction)
        }

        if let titleAction = titleSheetAction {
            sheetActions.append(titleAction)
        }

        if let wikidataItemAction = wikidataItemAction {
            sheetActions.append(wikidataItemAction)
        }

        return sheetActions
    }

    var emailFromOtherUserActions: [SheetAction] {
        if let agentUserPageAction = agentUserPageSheetAction {
            return [agentUserPageAction]
        }

        return []
    }

    var thanksActions: [SheetAction] {
        var sheetActions: [SheetAction] = []

        if let agentUserPageAction = agentUserPageSheetAction {
            sheetActions.append(agentUserPageAction)
        }

        if let titleAction = titleSheetAction {
            sheetActions.append(titleAction)
        }

        if let diffAction = diffSheetAction {
            sheetActions.append(diffAction)
        }

        return sheetActions
    }

    var loginActions: [SheetAction] {
        var sheetActions: [SheetAction] = []

        if let loginHelpAction = loginNotificationsSheetAction {
            sheetActions.append(loginHelpAction)
        }

        if let changePasswordSheetAction = changePasswordSheetAction {
            sheetActions.append(changePasswordSheetAction)
        }

        return sheetActions
    }

    var genericAlertActions: [SheetAction] {
        var sheetActions: [SheetAction] = []

        if let secondaryLinks = notification.secondaryLinks {
            let secondarySheetActions = secondaryLinks.compactMap { sheetActionForGenericLink(link:$0) }
            sheetActions.append(contentsOf: secondarySheetActions)
        }

        if let diffAction = diffSheetAction {
            sheetActions.append(diffAction)
        }

        if let primaryLink = notification.primaryLink,
           let primarySheetAction = sheetActionForGenericLink(link: primaryLink) {
            sheetActions.append(primarySheetAction)
        }

        return sheetActions
    }

    var genericActions: [SheetAction] {
        var sheetActions: [SheetAction] = []

        if let agentUserPageAction = agentUserPageSheetAction {
            sheetActions.append(agentUserPageAction)
        }

        if let diffAction = diffSheetAction {
            sheetActions.append(diffAction)
        }

        if let primaryLink = notification.primaryLink,
           let primarySheetAction = sheetActionForGenericLink(link: primaryLink) {
            sheetActions.append(primarySheetAction)
        }

        return sheetActions
    }
}

//MARK: Private Helpers - Individual Swipe Action methods

private extension NotificationsCenterCellViewModel {
    //Go to [Username]'s user page
    var agentUserPageSheetAction: SheetAction? {
        guard let agentName = notification.agentName,
              let url = customPrefixAgentNameURL(pageNamespace: .user) else {
            return nil
        }

        let format = WMFLocalizedString("notifications-center-go-to-user-page", value: "Go to %1$@'s user page", comment: "Button text in Notifications Center that routes to a web view of the user page of the sender that triggered the notification. %1$@ is replaced with the sender's username.")
        let text = String.localizedStringWithFormat(format, agentName)

        let data = SheetActionData(text: text, url: url)

        return SheetAction.custom(data)
    }

    //Go to diff
    var diffSheetAction: SheetAction? {
        guard let url = fullTitleDiffURL else {
            return nil
        }

        let text = WMFLocalizedString("notifications-center-go-to-diff", value: "Go to diff", comment: "Button text in Notifications Center that routes to a diff screen of the revision that triggered the notification.")
        let data = SheetActionData(text: text, url: url)
        return SheetAction.custom(data)
    }

    //Go to [your?] talk page
    func titleTalkPageSheetAction(yourPhrasing: Bool = false) -> SheetAction? {
        
        guard let linkData = linkData,
              let namespace = linkData.titleNamespace,
              let talkEquivalent = namespace.talkEquivalent,
              let url = customPrefixTitleURL(pageNamespace: talkEquivalent) else {
            return nil
        }

        let text = yourPhrasing ? WMFLocalizedString("notifications-center-go-to-your-talk-page", value: "Go to your talk page", comment: "Button text in Notifications Center that routes to user's talk page.") : WMFLocalizedString("notifications-center-go-to-talk-page", value: "Go to talk page", comment: "Button text in Notifications Center that routes to a talk page.")

        let data = SheetActionData(text: text, url: url)
        return SheetAction.custom(data)
    }

    //Go to [Name of article]
    var titleSheetAction: SheetAction? {
        guard let linkData = linkData,
              let url = fullTitleURL,
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
    var userGroupRightsSheetAction: SheetAction? {
        guard let url = userGroupRightsURL,
              let title = url.wmf_title else {
            return nil
        }

        let text = String.localizedStringWithFormat(CommonStrings.notificationsCenterGoToTitleFormat, title)
        let data = SheetActionData(text: text, url: url)
        return SheetAction.custom(data)
    }

    //Login Notifications
    var loginNotificationsSheetAction: SheetAction? {
        guard let url = loginNotificationsHelpURL else {
            return nil
        }

        let text = WMFLocalizedString("notifications-center-login-notifications", value: "Login Notifications", comment: "Button text in Notifications Center that routes user to login notifications help page in web view.")

        let data = SheetActionData(text: text, url: url)
        return SheetAction.custom(data)
    }

    //Change password
    var changePasswordSheetAction: SheetAction? {

        guard let url = changePasswordURL else {
            return nil
        }

        let text = WMFLocalizedString("notifications-center-change-password", value: "Change Password", comment: "Button text in Notifications Center that routes user to change password screen.")

        let data = SheetActionData(text: text, url: url)
        return SheetAction.custom(data)
    }

    func sheetActionForGenericLink(link: RemoteNotificationLink) -> SheetAction? {
        guard let url = link.url,
              let text = link.label else {
            return nil
        }

        let data = SheetActionData(text: text, url: url)
        return SheetAction.custom(data)
    }
}
