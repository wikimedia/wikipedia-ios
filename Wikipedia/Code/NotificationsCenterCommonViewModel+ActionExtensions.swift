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

        let data = NotificationsCenterActionData(text: text, url: url, iconType: .person, destinationText: destinationText(for: url), actionType: .senderPage)

        return NotificationsCenterAction.custom(data)
    }

    // Diff
    var diffAction: NotificationsCenterAction? {
        guard let url = fullTitleDiffURL else {
            return nil
        }

        let text = WMFLocalizedString("notifications-center-go-to-diff", value: "Diff", comment: "Button text in Notifications Center that routes to a diff screen of the revision that triggered the notification.")
        let data = NotificationsCenterActionData(text: text, url: url, iconType: .diff, destinationText: destinationText(for: url), actionType: .diff)
        return NotificationsCenterAction.custom(data)
    }

    /// Outputs various actions based on the notification title payload.
    /// - Parameters:
    ///   - needsConvertToOrFromTalk: Pass true if you want to construct an action based on the talk-equivalent or main-equivalent of the title payload. For example, if the title payload indicates the notification sourced from an article talk page, passing true here will construct the action based on the main namespace, i.e. "Cat" instead of "Talk:Cat".`
    ///   - simplified: Pass true if you want a generic phrasing of the action, i.e., "Article" or "Talk page" instead of "Cat" or "Talk:Cat" respectively.
    /// - Returns: NotificationsCenterAction struct, for use in view models.
    func titleAction(needsConvertToOrFromTalk: Bool, simplified: Bool) -> NotificationsCenterAction? {

        guard let linkData = linkData,
              let normalizedTitle = linkData.title?.normalizedPageTitle,
              let sourceNamespace = linkData.titleNamespace else {
                  return nil
              }

        let namespace = needsConvertToOrFromTalk ? (sourceNamespace.convertedToOrFromTalk ?? sourceNamespace) : sourceNamespace

        guard !simplified else {

            // [your] talk page
            // Talk page
            // Article
            
            let simplifiedText = simplifiedTitleText(namespace: namespace, normalizedTitle: normalizedTitle) ?? titleText(namespace: namespace, normalizedTitle: normalizedTitle)
            return titleAction(text: simplifiedText, namespace: namespace, normalizedTitle: normalizedTitle)
        }

        // [your] talk page
        // [article] talk page
        // [article]
        
        let text = titleText(namespace: namespace, normalizedTitle: normalizedTitle)
        return titleAction(text: text, namespace: namespace, normalizedTitle: normalizedTitle)
    }
    
    private var goToTalkPageText: String {
        WMFLocalizedString("notifications-center-go-to-talk-page", value: "Talk page", comment: "Button text in Notifications Center that routes to a talk page.")
    }
    
    private var goToYourTalkPageText: String {
        WMFLocalizedString("notifications-center-go-to-your-talk-page", value: "Your talk page", comment: "Button text in Notifications Center that routes to user's talk page.")
    }
    
    private var goToArticleText: String {
        WMFLocalizedString("notifications-center-go-to-article", value: "Article", comment: "Button text in Notifications Center that routes to article.")
    }

    private var goToArticleTalkFormat: String {
        WMFLocalizedString("notifications-center-go-to-article-talk-format", value: "%1$@ talk page", comment: "Button text in Notifications Center that routes to a particular article talk page. %1$@ is replaced with page title.")
    }
    
    private func simplifiedTitleText(namespace: PageNamespace, normalizedTitle: String) -> String? {
        
        if notification.type == .userTalkPageMessage {
            
            return goToYourTalkPageText
            
        } else if namespace == .userTalk || namespace == .talk {
            
            return goToTalkPageText
            
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

            return String.localizedStringWithFormat(goToArticleTalkFormat, normalizedTitle)

        } else {

            let prefix = namespace != .main ? "\(namespace.canonicalName):" : ""
            return "\(prefix)\(normalizedTitle)"
            
        }
    }
    private func getActionType(namespace: PageNamespace) -> NotificationsCenterActionData.LoggingLabel? {
        if namespace == .userTalk {
            return .userTalk
        } else if namespace == .talk {
            return .articleTalk
        } else if namespace == .user {
            return .senderPage
        } else if namespace == .main {
            return .article
        } else {
            return .link(namespace)
        }
    }
    
    private func titleAction(text: String, namespace: PageNamespace, normalizedTitle: String) -> NotificationsCenterAction {
        let url = customPrefixTitleURL(pageNamespace: namespace)
        let actionType = getActionType(namespace: namespace)
        let data = NotificationsCenterActionData(text: text, url: url, iconType: .document, destinationText: destinationText(for: url), actionType: actionType)
        return NotificationsCenterAction.custom(data)
    }

    // [Article where link was made]
    var pageLinkFromAction: NotificationsCenterAction? {
        guard let url = pageLinkToURL,
              let title = url.wmf_title else {
            return nil
        }

        let data = NotificationsCenterActionData(text: title, url: url, iconType: .document, destinationText: destinationText(for: url), actionType: .linkedFromArticle)
        return NotificationsCenterAction.custom(data)
    }

    // Wikidata item
    var wikidataItemAction: NotificationsCenterAction? {
        guard let url = connectionWithWikidataItemURL else {
            return nil
        }

        let text = WMFLocalizedString("notifications-center-go-to-wikidata-item", value: "Wikidata item", comment: "Button text in Notifications Center that routes to a Wikidata item page.")
        let data = NotificationsCenterActionData(text: text, url: url, iconType: .wikidata, destinationText: destinationText(for: url), actionType: .wikidataItem)
        return NotificationsCenterAction.custom(data)
    }

    // Specific Special:UserGroupRights#{Type} page
    var specificUserGroupRightsAction: NotificationsCenterAction? {
        guard let url = specificUserGroupRightsURL,
              let type = url.fragment,
              let title = url.wmf_title else {
            return nil
        }

        let text = "\(title)#\(type)"
        let data = NotificationsCenterActionData(text: text, url: url, iconType: .document, destinationText: destinationText(for: url), actionType: .listGroupRights)
        return NotificationsCenterAction.custom(data)
    }

    // Special:UserGroupRights
    var userGroupRightsAction: NotificationsCenterAction? {
        guard let url = userGroupRightsURL,
              let title = url.wmf_title else {
            return nil
        }

        let data = NotificationsCenterActionData(text: title, url: url, iconType: .document, destinationText: destinationText(for: url), actionType: .listGroupRights)
        return NotificationsCenterAction.custom(data)
    }
    
    // Help:GettingStarted
    var gettingStartedAction: NotificationsCenterAction? {
        guard let url = gettingStartedURL,
              let title = url.wmf_title else {
            return nil
        }

        let data = NotificationsCenterActionData(text: title, url: url, iconType: .document, destinationText: destinationText(for: url), actionType: .gettingStarted)
        return NotificationsCenterAction.custom(data)
    }

    // Login Notifications
    private var loginNotificationsText: String {
        WMFLocalizedString("notifications-center-login-notifications", value: "Login notifications", comment: "Button text in Notifications Center that routes user to login notifications help page in web view.")
    }
    var loginNotificationsAction: NotificationsCenterAction? {
        guard let url = loginNotificationsHelpURL else {
            return nil
        }

        let data = NotificationsCenterActionData(text: loginNotificationsText, url: url, iconType: .document, destinationText: destinationText(for: url), actionType: .login)
        return NotificationsCenterAction.custom(data)
    }
    
    // Login Notifications
    var loginNotificationsGoToAction: NotificationsCenterAction? {
        guard let url = loginNotificationsHelpURL else {
            return nil
        }

        let data = NotificationsCenterActionData(text: loginNotificationsText, url: url, iconType: .document, destinationText: destinationText(for: url), actionType: .login)
        return NotificationsCenterAction.custom(data)
    }

    // Change password
    var changePasswordAction: NotificationsCenterAction? {

        guard let url = changePasswordURL else {
            return nil
        }

        let text = CommonStrings.notificationsChangePassword

        let data = NotificationsCenterActionData(text: text, url: url, iconType: .lock, destinationText: destinationText(for: url), actionType: .changePassword)
        return NotificationsCenterAction.custom(data)
    }

    func actionForGenericLink(link: RemoteNotificationLink) -> NotificationsCenterAction? {
        guard let url = link.url,
              let text = link.label else {
            return nil
        }

        let data = NotificationsCenterActionData(text: text, url: url, iconType: .link, destinationText: destinationText(for: url), actionType: .linkNonspecific)
        return NotificationsCenterAction.custom(data)
    }
}
