import Foundation

// MARK: Private Helpers - LinkData

extension NotificationsCenterCommonViewModel {

    // common data used throughout url generation helpers
    struct LinkData {
        let host: String
        let wiki: String
        let title: String? // ex: Cat
        let fullTitle: String? // ex: Talk:Cat
        let primaryLinkFragment: String?
        let legacyPrimaryLinkFragment: String?
        let agentName: String?
        let revisionID: String?
        let titleNamespace: PageNamespace?
        let languageVariantCode: String?
    }

    var linkData: LinkData? {

        guard let host = notification.linkHost,
              let wiki = notification.wiki else {
            return nil
        }

        let title = notification.titleText?.denormalizedPageTitle?.percentEncodedPageTitleForPathComponents
        let fullTitle = notification.titleFull?.denormalizedPageTitle?.percentEncodedPageTitleForPathComponents
        let agentName = notification.agentName?.denormalizedPageTitle?.percentEncodedPageTitleForPathComponents
        let titleNamespace = PageNamespace(namespaceValue: Int(notification.titleNamespaceKey))
        let revisionID = notification.revisionID
        let primaryLinkFragment = notification.primaryLinkFragment?.removingPercentEncoding
        let legacyPrimaryLinkFragment = notification.legacyPrimaryLinkFragment?.removingPercentEncoding

        return LinkData(host: host, wiki: wiki, title: title, fullTitle: fullTitle, primaryLinkFragment: primaryLinkFragment, legacyPrimaryLinkFragment: legacyPrimaryLinkFragment, agentName: agentName, revisionID: revisionID, titleNamespace: titleNamespace, languageVariantCode: project.languageVariantCode)

    }
}

// MARK: Helpers - URL Generation Methods

extension NotificationsCenterCommonViewModel {
    
    /// Generates a wiki url with the titleText value from the notification
    /// Prefixes titleText text with PageNamespace parameter
    func customPrefixTitleURL(pageNamespace: PageNamespace) -> URL? {
        guard let data = linkData,
              let title = data.title,
              let denormalizedNamespace = pageNamespace.canonicalName.denormalizedPageTitle else {
            return nil
        }
        
        let prefix = pageNamespace != .main ? "\(denormalizedNamespace):" : ""

        guard let url = configuration.articleURLForHost(data.host, languageVariantCode: data.languageVariantCode, appending: ["\(prefix + title)"]) else {
            return nil
        }

        return fragementedURL(pageNamespace: pageNamespace, url: url, linkData: data)
    }
    
    /// Seeks out and appends the url fragment from the primary link to a generated url parameter
    /// Only does this for user talk page types, to allow deep linking into a particular topic
    private func fragementedURL(pageNamespace: PageNamespace, url: URL, linkData: LinkData) -> URL? {
        guard pageNamespace == .userTalk || pageNamespace == .talk,
              var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return url
        }

        // primaryLinkFragment sometimes returns user's talk signature within in, which messes up deep linking to a talk page topic. Prefer legacyPrimaryLinkFragment which seems to not have this signature.
        components.fragment = linkData.legacyPrimaryLinkFragment ?? linkData.primaryLinkFragment
        return components.url
    }
    
    /// Generates a wiki url with the agentName from the notification
    /// Prefixes agentName text with PageNamespace parameter
    func customPrefixAgentNameURL(pageNamespace: PageNamespace) -> URL? {
        guard let data = linkData,
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
    var fullTitleDiffURL: URL? {
        guard let data = linkData,
              let fullTitle = data.fullTitle,
              let revisionID = data.revisionID else {
            return nil
        }

        guard let url = configuration.expandedArticleURLForHost(data.host, languageVariantCode: data.languageVariantCode, queryParameters: ["title": fullTitle, "oldid": revisionID]) else {
            return nil
        }

        return url
    }
    
    // https://en.wikipedia.org/wiki/Special:ChangeCredentials
    var changePasswordURL: URL? {
        guard let data = linkData else {
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
    
    // https://www.mediawiki.org/wiki/Special:UserGroupRights
    var userGroupRightsURL: URL? {
        // Note: Sample notification json indicates that translated user group link we want is listed as the primary URL
        // Ex. https://en.wikipedia.org/wiki/Special:ListGroupRights?markasread=nnnnnnnn&markasreadwiki=enwiki#confirmed
        
        guard let url = primaryLinkMinusQueryItemsURL,
              var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }

        components.fragment = nil
        return components.url
    }
    
    var specificUserGroupRightsURL: URL? {
        // Note: Sample notification json indicates that specific user group link we want is listed as the primary URL + fragment
        // Ex. https://en.wikipedia.org/wiki/Special:ListGroupRights?markasread=nnnnnnnn&markasreadwiki=enwiki#confirmed
        return primaryLinkMinusQueryItemsURL
    }
    
    // For a page link notification type (FROM page > TO page), this is the url of the TO page
    var pageLinkToURL: URL? {
        // Note: Sample notification json indicates that the url we want is listed as the primary URL
        // Ex. https://en.wikipedia.org/wiki/Cat?markasread=nnnnnnnn&markasreadwiki=enwiki
        return primaryLinkMinusQueryItemsURL
    }
    
    var connectionWithWikidataItemURL: URL? {

        // Note: Sample notification json indicates that the wikidata item link is the second secondary link.
        // Return this link if we're fairly certain it's what we think it is
        
        guard let secondaryLinks = notification.secondaryLinks,
              secondaryLinks.indices.contains(1),
              let wikidataItemURL = secondaryLinks[1].url else {
            return nil
        }

        // Confirm host is a Wikidata environment.
        guard let host = wikidataItemURL.host,
              host.contains("wikidata") else {
            return nil
        }

        // see if any part of path contains a Q identifier
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
    
    // https://en.wikipedia.org/wiki/Help:Getting_started
    var gettingStartedURL: URL? {

        guard let data = linkData else {
            return nil
        }

        var components = URLComponents()
        components.host = data.host
        components.scheme = "https"
        components.path = "/wiki/Help:Getting_started"
        return components.url
    }
    
    // https://www.mediawiki.org/wiki/Help:Login_notifications
    var loginNotificationsHelpURL: URL? {
        var components = URLComponents()
        components.host = Configuration.Domain.mediaWiki
        components.scheme = "https"
        components.path = "/wiki/Help:Login_notifications"
        return components.url
    }
}
