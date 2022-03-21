
import Foundation

extension NotificationsCenterCommonViewModel {
    //Go to [Username]'s user page
    var agentUserPageAction: NotificationsCenterAction? {
        guard let agentName = notification.agentName,
              let url = customPrefixAgentNameURL(pageNamespace: .user) else {
            return nil
        }

        let format = WMFLocalizedString("notifications-center-go-to-user-page", value: "Go to %1$@'s user page", comment: "Button text in Notifications Center that routes to a web view of the user page of the sender that triggered the notification. %1$@ is replaced with the sender's username.")
        let text = String.localizedStringWithFormat(format, agentName)

        let data = NotificationsCenterActionData(text: text, url: url)

        return NotificationsCenterAction.custom(data)
    }

    //Go to diff
    var diffAction: NotificationsCenterAction? {
        guard let url = fullTitleDiffURL else {
            return nil
        }

        let text = WMFLocalizedString("notifications-center-go-to-diff", value: "Go to diff", comment: "Button text in Notifications Center that routes to a diff screen of the revision that triggered the notification.")
        let data = NotificationsCenterActionData(text: text, url: url)
        return NotificationsCenterAction.custom(data)
    }

    //Go to [your?] talk page
    func titleTalkPageAction(yourPhrasing: Bool = false) -> NotificationsCenterAction? {
        
        guard let linkData = linkData,
              let namespace = linkData.titleNamespace,
              let talkEquivalent = namespace.talkEquivalent,
              let url = customPrefixTitleURL(pageNamespace: talkEquivalent) else {
            return nil
        }

        let text = yourPhrasing ? WMFLocalizedString("notifications-center-go-to-your-talk-page", value: "Go to your talk page", comment: "Button text in Notifications Center that routes to user's talk page.") : WMFLocalizedString("notifications-center-go-to-talk-page", value: "Go to talk page", comment: "Button text in Notifications Center that routes to a talk page.")

        let data = NotificationsCenterActionData(text: text, url: url)
        return NotificationsCenterAction.custom(data)
    }

    //Go to [Name of article]
    var titleAction: NotificationsCenterAction? {
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
        let data = NotificationsCenterActionData(text: text, url: url)
        return NotificationsCenterAction.custom(data)
    }

    //Go to [Article where link was made]
    var pageLinkToAction: NotificationsCenterAction? {
        guard let url = pageLinkToURL,
              let title = url.wmf_title else {
            return nil
        }

        let text = String.localizedStringWithFormat(CommonStrings.notificationsCenterGoToTitleFormat, title)
        let data = NotificationsCenterActionData(text: text, url: url)
        return NotificationsCenterAction.custom(data)
    }

    //Go to Wikidata item
    var wikidataItemAction: NotificationsCenterAction? {
        guard let url = connectionWithWikidataItemURL else {
            return nil
        }

        let text = WMFLocalizedString("notifications-center-go-to-wikidata-item", value: "Go to Wikidata item", comment: "Button text in Notifications Center that routes to a Wikidata item page.")
        let data = NotificationsCenterActionData(text: text, url: url)
        return NotificationsCenterAction.custom(data)
    }

    //Go to specific Special:UserGroupRights#{Type} page
    var specificUserGroupRightsAction: NotificationsCenterAction? {
        guard let url = specificUserGroupRightsURL,
              let type = url.fragment,
              let title = url.wmf_title else {
            return nil
        }

        let text = String.localizedStringWithFormat(CommonStrings.notificationsCenterGoToTitleFormat, "\(title)#\(type)")
        let data = NotificationsCenterActionData(text: text, url: url)
        return NotificationsCenterAction.custom(data)
    }

    //Go to Special:UserGroupRights
    var userGroupRightsAction: NotificationsCenterAction? {
        guard let url = userGroupRightsURL,
              let title = url.wmf_title else {
            return nil
        }

        let text = String.localizedStringWithFormat(CommonStrings.notificationsCenterGoToTitleFormat, title)
        let data = NotificationsCenterActionData(text: text, url: url)
        return NotificationsCenterAction.custom(data)
    }

    //Login Notifications
    var loginNotificationsAction: NotificationsCenterAction? {
        guard let url = loginNotificationsHelpURL else {
            return nil
        }

        let text = WMFLocalizedString("notifications-center-login-notifications", value: "Login Notifications", comment: "Button text in Notifications Center that routes user to login notifications help page in web view.")

        let data = NotificationsCenterActionData(text: text, url: url)
        return NotificationsCenterAction.custom(data)
    }

    //Change password
    var changePasswordAction: NotificationsCenterAction? {

        guard let url = changePasswordURL else {
            return nil
        }

        let text = WMFLocalizedString("notifications-center-change-password", value: "Change Password", comment: "Button text in Notifications Center that routes user to change password screen.")

        let data = NotificationsCenterActionData(text: text, url: url)
        return NotificationsCenterAction.custom(data)
    }

    func actionForGenericLink(link: RemoteNotificationLink) -> NotificationsCenterAction? {
        guard let url = link.url,
              let text = link.label else {
            return nil
        }

        let data = NotificationsCenterActionData(text: text, url: url)
        return NotificationsCenterAction.custom(data)
    }
}
