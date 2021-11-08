
import Foundation

extension NotificationsCenterCellViewModel {

    //MARK: Public
    
    func primaryURL(for configuration: Configuration) -> URL? {

        //First try to explicitly generate urls based on notification type to limit url side effects
        var calculatedURL: URL? = nil

        switch notification.type {
        case .userTalkPageMessage,
             .mentionInTalkPage,
             .failedMention,
             .pageReviewed,
             .pageLinked,
             .editMilestone,
             .successfulMention:
            calculatedURL = fullTitleURL(for: configuration)
        case .mentionInEditSummary,
             .editReverted,
             .thanks:
            calculatedURL = fullTitleDiffURL(for: configuration)
        case .userRightsChange:
            calculatedURL = userGroupRightsURL
        case .connectionWithWikidata:
            calculatedURL = connectionWithWikidataItemURL
        case .emailFromOtherUser:
            calculatedURL = customPrefixAgentNameURL(for: configuration, pageNamespace: .user)
        case .welcome:
            calculatedURL = gettingStartedURL(for: configuration)
        case .translationMilestone:

            //purposefully not allowing default to primaryLinkURL from server below
            //business requirements are that there are no destination links for translations notification.
            return nil

        case .loginFailUnknownDevice,
             .loginFailKnownDevice,
             .loginSuccessUnknownDevice:
            calculatedURL = changePasswordURL(for: configuration)

        case .unknownSystemAlert,
             .unknownSystemNotice,
             .unknownAlert,
             .unknownNotice,
             .unknown:
            break
        }

        //If unable to calculate url, default to primary url returned from server
        return (calculatedURL ?? notification.primaryLinkURL)
    }
    
    func secondaryURL(for configuration: Configuration) -> URL? {
        var calculatedURL: URL? = nil

        switch notification.type {
        case .userTalkPageMessage,
             .mentionInTalkPage,
             .mentionInEditSummary,
             .editReverted,
             .userRightsChange,
             .pageReviewed,
             .pageLinked,
             .connectionWithWikidata,
             .thanks,
             .unknownAlert,
             .unknownNotice:
            calculatedURL = customPrefixAgentNameURL(for: configuration, pageNamespace: .user)
        case .loginFailUnknownDevice,
             .loginFailKnownDevice,
             .loginSuccessUnknownDevice:
            calculatedURL = loginNotificationsHelpURL
        case .failedMention,
             .successfulMention,
             .emailFromOtherUser,
             .translationMilestone,
             .editMilestone,
             .welcome,
             .unknownSystemAlert,
             .unknownSystemNotice,
             .unknown:
            break
        }

        return calculatedURL
    }
}

//MARK: Private Helpers - LinkData

extension NotificationsCenterCellViewModel {

    //common data used throughout url generation helpers
    struct LinkData {
        let host: String
        let wiki: String
        let title: String? //ex: Cat
        let fullTitle: String? //ex: Talk:Cat
        let primaryLinkFragment: String?
        let agentName: String?
        let revisionID: String?
        let titleNamespace: PageNamespace?
        let languageVariantCode: String?
    }

    func linkData(for configuration: Configuration) -> LinkData? {

        guard let host = notification.primaryLinkHost ?? configuration.defaultSiteURL.host,
              let wiki = notification.wiki else {
            return nil
        }

        let title = notification.titleText?.denormalizedPageTitle?.percentEncodedPageTitleForPathComponents
        let fullTitle = notification.titleFull?.denormalizedPageTitle?.percentEncodedPageTitleForPathComponents
        let agentName = notification.agentName?.denormalizedPageTitle?.percentEncodedPageTitleForPathComponents
        let titleNamespace = PageNamespace(namespaceValue: Int(notification.titleNamespaceKey))
        let revisionID = notification.revisionID
        let primaryLinkFragment = notification.primaryLinkFragment

        return LinkData(host: host, wiki: wiki, title: title, fullTitle: fullTitle, primaryLinkFragment: primaryLinkFragment, agentName: agentName, revisionID: revisionID, titleNamespace: titleNamespace, languageVariantCode: project.languageVariantCode)

    }
}

//MARK: Helpers - URL Generation Methods

extension NotificationsCenterCellViewModel {

    /// Generates a wiki url with the full (i.e. already prefixed) title from the notification
    func fullTitleURL(for configuration: Configuration) -> URL? {

        guard let data = linkData(for: configuration),
              let fullTitle = data.fullTitle else {
            return nil
        }

        guard let url = configuration.articleURLForHost(data.host, languageVariantCode: data.languageVariantCode, appending: [fullTitle]) else {
            return nil
        }

        guard let namespace = data.titleNamespace,
              namespace == .userTalk,
              var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return url
        }

        components.fragment = data.primaryLinkFragment
        return components.url
    }
    
    /// Generates a wiki url with the titleText value from the notification
    /// Prefixes titleText text with PageNamespace parameter
    func customPrefixTitleURL(for configuration: Configuration, pageNamespace: PageNamespace) -> URL? {
        guard let data = linkData(for: configuration),
              let title = data.title,
              let prefix = pageNamespace.canonicalName.denormalizedPageTitle else {
            return nil
        }

        guard let url = configuration.articleURLForHost(data.host, languageVariantCode: data.languageVariantCode, appending: ["\(prefix):\(title)"]) else {
            return nil
        }

        return url
    }
    
    /// Generates a wiki url with the agentName from the notification
    /// Prefixes agentName text with PageNamespace parameter
    func customPrefixAgentNameURL(for configuration: Configuration, pageNamespace: PageNamespace) -> URL? {
        guard let data = linkData(for: configuration),
              let agentName = data.agentName else {
            return nil
        }

        let prefix = pageNamespace.canonicalName

        guard let url = configuration.articleURLForHost(data.host, languageVariantCode: data.languageVariantCode, appending: ["\(prefix):\(agentName)"]) else {
            return nil
        }

        return url
    }
    
    /// Generates a wiki diff url with the full (i.e. already prefixed) title from the notification
    func fullTitleDiffURL(for configuration: Configuration) -> URL? {
        guard let data = linkData(for: configuration),
              let fullTitle = data.fullTitle,
              let revisionID = data.revisionID else {
            return nil
        }

        guard let url = configuration.expandedArticleURLForHost(data.host, languageVariantCode: data.languageVariantCode, queryParameters: ["title": fullTitle, "oldid": revisionID]) else {
            return nil
        }

        return url
    }
    
    //https://en.wikipedia.org/wiki/Special:ChangeCredentials
    func changePasswordURL(for configuration: Configuration) -> URL? {
        guard let data = linkData(for: configuration) else {
            return nil
        }

        var components = URLComponents()
        components.host = data.host
        components.scheme = "https"
        components.path = "/wiki/Special:ChangeCredentials"
        return components.url
    }
    
    var primaryLinkMinusQueryItemsURL: URL? {
        guard let url = notification.primaryLinkURL,
              var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }

        components.queryItems?.removeAll()
        return components.url
    }
    
    //https://www.mediawiki.org/wiki/Special:UserGroupRights
    var userGroupRightsURL: URL? {
        //Note: Sample notification json indicates that translated user group link we want is listed as the primary URL
        //Ex. https://en.wikipedia.org/wiki/Special:ListGroupRights?markasread=nnnnnnnn&markasreadwiki=enwiki#confirmed
        
        guard let url = primaryLinkMinusQueryItemsURL,
              var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }

        components.fragment = nil
        return components.url
    }
    
    var specificUserGroupRightsURL: URL? {
        //Note: Sample notification json indicates that specific user group link we want is listed as the primary URL + fragment
        //Ex. https://en.wikipedia.org/wiki/Special:ListGroupRights?markasread=nnnnnnnn&markasreadwiki=enwiki#confirmed
        return primaryLinkMinusQueryItemsURL
    }
    
    //For a page link notification type (FROM page > TO page), this is the url of the TO page
    var pageLinkToURL: URL? {
        //Note: Sample notification json indicates that the url we want is listed as the primary URL
        //Ex. https://en.wikipedia.org/wiki/Cat?markasread=nnnnnnnn&markasreadwiki=enwiki
        return primaryLinkMinusQueryItemsURL
    }
    
    var connectionWithWikidataItemURL: URL? {

        //Note: Sample notification json indicates that the wikidata item link is the second secondary link.
        //Return this link if we're fairly certain it's what we think it is
        
        guard let secondaryLinks = notification.secondaryLinks,
              secondaryLinks.indices.contains(1),
              let wikidataItemURL = secondaryLinks[1].url else {
            return nil
        }

        //Confirm host is a Wikidata environment.
        guard let host = wikidataItemURL.host,
              host.contains("wikidata") else {
            return nil
        }

        //see if any part of path contains a Q identifier
        let path = wikidataItemURL.path
        let range = NSRange(location: 0, length: path.count)

        guard let regex = try? NSRegularExpression(pattern: "Q[1-9]\\d*") else {
            return nil
        }

        guard regex.firstMatch(in: path, options: [], range: range) != nil else {
            return nil
        }

        return wikidataItemURL
    }
    
    //https://en.wikipedia.org/wiki/Help:Getting_started
    func gettingStartedURL(for configuration: Configuration) -> URL? {

        guard let data = linkData(for: configuration) else {
            return nil
        }

        var components = URLComponents()
        components.host = data.host
        components.scheme = "https"
        components.path = "/wiki/Help:Getting_started"
        return components.url
    }
    
    //https://www.mediawiki.org/wiki/Help:Login_notifications
    var loginNotificationsHelpURL: URL? {
        var components = URLComponents()
        components.host = Configuration.Domain.mediaWiki
        components.scheme = "https"
        components.path = "/wiki/Help:Login_notifications"
        return components.url
    }
}
