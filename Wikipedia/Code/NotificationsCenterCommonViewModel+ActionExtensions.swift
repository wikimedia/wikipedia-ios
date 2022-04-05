import Foundation
import WMF

extension NotificationsCenterCommonViewModel {
    
    private func destinationText(for url: URL?) -> String? {
        
        guard let url = url else {
            return nil
        }
        
        return url.doesOpenInBrowser ? CommonStrings.notificationsCenterDestinationWeb : CommonStrings.notificationsCenterDestinationApp
    }
    
    // [Username]'s user page
    var agentUserPageAction: NotificationsCenterAction? {
        guard let agentName = notification.agentName,
              let url = customPrefixAgentNameURL(pageNamespace: .user) else {
            return nil
        }

        let format = WMFLocalizedString("notifications-center-go-to-user-page", value: "%1$@'s user page", comment: "Button text in Notifications Center that routes to a web view of the user page of the sender that triggered the notification. %1$@ is replaced with the sender's username.")
        let text = String.localizedStringWithFormat(format, agentName)

        let data = NotificationsCenterActionData(text: text, url: url, iconType: .person, destinationText: destinationText(for: url))

        return NotificationsCenterAction.custom(data)
    }

    //Go to diff
    var diffAction: NotificationsCenterAction? {
        guard let url = fullTitleDiffURL else {
            return nil
        }

        let text = WMFLocalizedString("notifications-center-go-to-diff", value: "Go to diff", comment: "Button text in Notifications Center that routes to a diff screen of the revision that triggered the notification.")
        let data = NotificationsCenterActionData(text: text, url: url, iconType: .diff, destinationText: destinationText(for: url))
        return NotificationsCenterAction.custom(data)
    }

    /// Outputs various actions based on the notification title payload.
    /// - Parameters:
    ///   - needsConvertToOrFromTalk: Pass true if you want to construct an action based on the talk-equivalent or main-equivalent of the title payload. For example, if the title payload indicates the notification sourced from an article talk page, passing true here will construct the action based on the main namespace, i.e. "Go to Cat" instead of "Go to Talk:Cat".`
    ///   - simplified: Pass true if you want a generic phrasing of the action, i.e., "Go to article" or "Go to talk page" instead of "Go to Cat" or "Go to Talk:Cat" respectively.
    /// - Returns: NotificationsCenterAction struct, for use in view models.
    func titleAction(needsConvertToOrFromTalk: Bool, simplified: Bool) -> NotificationsCenterAction? {

        guard let linkData = linkData,
              let normalizedTitle = linkData.title?.normalizedPageTitle,
              let sourceNamespace = linkData.titleNamespace else {
                  return nil
              }

        let namespace = needsConvertToOrFromTalk ? (sourceNamespace.convertedToOrFromTalk ?? sourceNamespace) : sourceNamespace

        guard !simplified else {

            //Go to [your] talk page
            //Go to talk page
            //Go to collaboration page
            //Go to discussion page
            //Go to article
            
            let simplifiedText = simplifiedTitleText(namespace: namespace, normalizedTitle: normalizedTitle) ?? titleText(namespace: namespace, normalizedTitle: normalizedTitle)
            return titleAction(text: simplifiedText, namespace: namespace, normalizedTitle: normalizedTitle)
        }

        //Go to [your] talk page
        //Go to [article] talk page
        //Go to [article] collaboration page
        //Go to [article] discussion page
        //Go to [article]
        
        let text = titleText(namespace: namespace, normalizedTitle: normalizedTitle)
        return titleAction(text: text, namespace: namespace, normalizedTitle: normalizedTitle)
    }
    
    private var goToTalkPageText: String {
        WMFLocalizedString("notifications-center-go-to-talk-page", value: "Go to talk page", comment: "Button text in Notifications Center that routes to a talk page.")
    }
    
    private var goToDiscussionPageText: String {
        WMFLocalizedString("notifications-center-go-to-discussion-page", value: "Go to discussion page", comment: "Button text in Notifications Center that routes to a discussion page.")
    }
    
    private var goToCollaborationPageText: String {
        WMFLocalizedString("notifications-center-go-to-collaboration-page", value: "Go to collaboration page", comment: "Button text in Notifications Center that routes to a collaboration page.")
    }
    
    private var goToYourTalkPageText: String {
        WMFLocalizedString("notifications-center-go-to-your-talk-page", value: "Go to your talk page", comment: "Button text in Notifications Center that routes to user's talk page.")
    }
    
    private var goToArticleText: String {
        WMFLocalizedString("notifications-center-go-to-article", value: "Go to article", comment: "Button text in Notifications Center that routes to article.")
    }
    
    private var goToTitleFormat: String {
        WMFLocalizedString("notifications-center-go-to-title-format", value: "Go to %1$@", comment: "Button text in Notifications Center that routes to a particular article. %1$@ is replaced with page title.")
    }
    
    private var goToUserPageFormat: String {
        WMFLocalizedString("notifications-center-go-to-user-page-format", value: "Go to %1$@'s user page", comment: "Button text in Notifications Center that routes to a particular user page. %1$@ is replaced with the username.")
    }
    
    private var goToArticleTalkFormat: String {
        WMFLocalizedString("notifications-center-go-to-article-talk-format", value: "Go to %1$@ talk page", comment: "Button text in Notifications Center that routes to a particular article talk page. %1$@ is replaced with page title.")
    }
    
    private var goToArticleDiscussionFormat: String {
        WMFLocalizedString("notifications-center-go-to-article-discussion-format", value: "Go to %1$@ discussion page", comment: "Button text in Notifications Center that routes to a particular article discussion page. %1$@ is replaced with page title.")
    }
    
    private var goToArticleCollaborationFormat: String {
        WMFLocalizedString("notifications-center-go-to-article-collaboration-format", value: "Go to %1$@ collaboration page", comment: "Button text in Notifications Center that routes to a particular article collaboration page. %1$@ is replaced with page title.")
    }
    
    private func simplifiedTitleText(namespace: PageNamespace, normalizedTitle: String) -> String? {
        
        if notification.type == .userTalkPageMessage {
            
            return goToYourTalkPageText
            
        } else if namespace == .userTalk {
            
            return goToTalkPageText
            
        } else if namespace == .talk {

            switch project {
            case .wikipedia:
                return goToTalkPageText
            case .wikinews:
                return goToCollaborationPageText
            default:
                return goToDiscussionPageText
            }

        } else if namespace == .main {

            switch project {
            case .wikipedia:
                return goToArticleText
            default:
                break
            }
        }
        
        return nil
    }
    
    private func titleText(namespace: PageNamespace, normalizedTitle: String) -> String {
        if notification.type == .userTalkPageMessage {
            
            return goToYourTalkPageText
            
        } else if namespace == .userTalk {
            
            return goToTalkPageText
            
        } else if namespace == .talk {

            switch project {
            case .wikipedia:
                return String.localizedStringWithFormat(goToArticleTalkFormat, normalizedTitle)
            case .wikinews:
                return String.localizedStringWithFormat(goToArticleCollaborationFormat, normalizedTitle)
            default:
                return String.localizedStringWithFormat(goToArticleDiscussionFormat, normalizedTitle)
            }

        } else {

            let prefix = namespace != .main ? "\(namespace.canonicalName):" : ""
            return String.localizedStringWithFormat(goToTitleFormat, "\(prefix)\(normalizedTitle)")
            
        }
    }

    private func titleAction(text: String, namespace: PageNamespace, normalizedTitle: String) -> NotificationsCenterAction {

        let url = customPrefixTitleURL(pageNamespace: namespace)
        let data = NotificationsCenterActionData(text: text, url: url, iconType: .document, destinationText: destinationText(for: url))
        return NotificationsCenterAction.custom(data)
    }

    //Go to [Article where link was made]
    var pageLinkToAction: NotificationsCenterAction? {
        guard let url = pageLinkToURL,
              let title = url.wmf_title else {
            return nil
        }

        let text = String.localizedStringWithFormat(goToTitleFormat, title)
        let data = NotificationsCenterActionData(text: text, url: url, iconType: .document, destinationText: destinationText(for: url))
        return NotificationsCenterAction.custom(data)
    }

    //Go to Wikidata item
    var wikidataItemAction: NotificationsCenterAction? {
        guard let url = connectionWithWikidataItemURL else {
            return nil
        }

        let text = WMFLocalizedString("notifications-center-go-to-wikidata-item", value: "Go to Wikidata item", comment: "Button text in Notifications Center that routes to a Wikidata item page.")
        let data = NotificationsCenterActionData(text: text, url: url, iconType: .wikidata, destinationText: destinationText(for: url))
        return NotificationsCenterAction.custom(data)
    }

    //Go to specific Special:UserGroupRights#{Type} page
    var specificUserGroupRightsAction: NotificationsCenterAction? {
        guard let url = specificUserGroupRightsURL,
              let type = url.fragment,
              let title = url.wmf_title else {
            return nil
        }

        let text = String.localizedStringWithFormat(goToTitleFormat, "\(title)#\(type)")
        let data = NotificationsCenterActionData(text: text, url: url, iconType: .document, destinationText: destinationText(for: url))
        return NotificationsCenterAction.custom(data)
    }

    //Go to Special:UserGroupRights
    var userGroupRightsAction: NotificationsCenterAction? {
        guard let url = userGroupRightsURL,
              let title = url.wmf_title else {
            return nil
        }

        let text = String.localizedStringWithFormat(goToTitleFormat, title)
        let data = NotificationsCenterActionData(text: text, url: url, iconType: .document, destinationText: destinationText(for: url))
        return NotificationsCenterAction.custom(data)
    }
    
    //"Go to Help:GettingStarted"
    var gettingStartedAction: NotificationsCenterAction? {
        guard let url = gettingStartedURL,
              let title = url.wmf_title else {
            return nil
        }

        let text = String.localizedStringWithFormat(goToTitleFormat, title)
        let data = NotificationsCenterActionData(text: text, url: url, iconType: .document, destinationText: destinationText(for: url))
        return NotificationsCenterAction.custom(data)
    }

    //Login Notifications
    private var loginNotificationsText: String {
        WMFLocalizedString("notifications-center-login-notifications", value: "Login notifications", comment: "Button text in Notifications Center that routes user to login notifications help page in web view.")
    }
    var loginNotificationsAction: NotificationsCenterAction? {
        guard let url = loginNotificationsHelpURL else {
            return nil
        }

        let data = NotificationsCenterActionData(text: loginNotificationsText, url: url, iconType: .document, destinationText: destinationText(for: url))
        return NotificationsCenterAction.custom(data)
    }
    
    //"Go to Login Notifications"
    var loginNotificationsGoToAction: NotificationsCenterAction? {
        guard let url = loginNotificationsHelpURL else {
            return nil
        }

        let text = String.localizedStringWithFormat(goToTitleFormat, loginNotificationsText)
        let data = NotificationsCenterActionData(text: text, url: url, iconType: .document, destinationText: destinationText(for: url))
        return NotificationsCenterAction.custom(data)
    }

    //Change password
    var changePasswordAction: NotificationsCenterAction? {

        guard let url = changePasswordURL else {
            return nil
        }

        let text = CommonStrings.notificationsChangePassword

        let data = NotificationsCenterActionData(text: text, url: url, iconType: .lock, destinationText: destinationText(for: url))
        return NotificationsCenterAction.custom(data)
    }

    func actionForGenericLink(link: RemoteNotificationLink) -> NotificationsCenterAction? {
        guard let url = link.url,
              let text = link.label else {
            return nil
        }

        let data = NotificationsCenterActionData(text: text, url: url, iconType: .link, destinationText: destinationText(for: url))
        return NotificationsCenterAction.custom(data)
    }
}
