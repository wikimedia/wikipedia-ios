@objc(WMFRouter)
public class Router: NSObject {
    public enum Destination: Equatable {
        case inAppLink(_: URL)
        case externalLink(_: URL)
        case article(_: URL)
        case articleHistory(_: URL, articleTitle: String)
        case articleDiff(_: URL, fromRevID: Int?, toRevID: Int?)
        case talk(_: URL)
        case userTalk(_: URL)
        case search(_: URL, term: String?)
        case audio(_: URL)
        case onThisDay(_: Int?)
        case readingListsImport(encodedPayload: String)
        case login
        case watchlist
    }
    
    unowned let configuration: Configuration
    
    required init(configuration: Configuration) {
        self.configuration = configuration
    }
    
    // MARK: Public
    
    /// Gets the appropriate in-app destination for a given URL
    public func destination(for url: URL, permanentUsername: String?) -> Destination {
        
        guard let siteURL = url.wmf_site,
        let project = WikimediaProject(siteURL: siteURL) else {
            
            guard url.isWikimediaHostedAudioFileLink else {
                return webViewDestinationForHostURL(url)
            }
            
            return .audio(url.byMakingAudioFileCompatibilityAdjustments)
        }
        
        return destinationForHostURL(url, project: project, permanentUsername: permanentUsername)
    }

    public func doesOpenInBrowser(for url: URL, permanentUsername: String?) -> Bool {
        return [.externalLink(url), .inAppLink(url)].contains(destination(for: url, permanentUsername: permanentUsername))
    }
    
    
    // MARK: Internal and Private
    
    private let mobilediffRegexMultiRevisionID = try! NSRegularExpression(pattern: "^mobilediff/([0-9]+)\\.\\.\\.([0-9]+)", options: .caseInsensitive)
    private let mobilediffRegexSingleRevisionID = try! NSRegularExpression(pattern: "^mobilediff/([0-9]+)", options: .caseInsensitive)
    private let historyRegex = try! NSRegularExpression(pattern: "^history/(.*)", options: .caseInsensitive)
    
    internal func destinationForWikiResourceURL(_ url: URL, project: WikimediaProject, permanentUsername: String?) -> Destination? {
        guard let path = url.wikiResourcePath else {
            return nil
        }
        
        let language = project.languageCode ?? "en"
        let namespaceAndTitle = path.namespaceAndTitleOfWikiResourcePath(with: language)
        let namespace = namespaceAndTitle.0
        let title = namespaceAndTitle.1
        
        switch namespace {
        case .talk:
            if project.supportsNativeUserTalkPages {
                return .talk(url)
            } else {
                return nil
            }
        case .userTalk:
            return project.supportsNativeUserTalkPages ? .userTalk(url) : nil
        case .special:
            
            // TODO: Fix to work across languages, not just EN. Fetch special page aliases per site and add to a set of local json files.
            // https://en.wikipedia.org/w/api.php?action=query&format=json&meta=siteinfo&formatversion=2&siprop=specialpagealiases
            if language.uppercased() == "EN" || language.uppercased() == "TEST",
                title == "MyTalk",
               let username = permanentUsername,
               let newURL = url.wmf_URL(withTitle: "User_talk:\(username)") {
                return .userTalk(newURL)
            }
            
            if language.uppercased() == "EN" || language.uppercased() == "TEST",
                title == "MyContributions",
               let username = permanentUsername,
               let newURL = url.wmf_URL(withPath: "/wiki/Special:Contributions/\(username)", isMobile: true) {
                return .inAppLink(newURL)
            }
            
            if language.uppercased() == "EN" || language.uppercased() == "TEST",
               title == "UserLogin" {
                return .login
            }
            
            if title == "ReadingLists",
               let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let firstQueryItem = components.queryItems?.first,
               firstQueryItem.name == "limport",
               let encodedPayload = firstQueryItem.value {

                return .readingListsImport(encodedPayload: encodedPayload)
            }
            
            if title == "Watchlist" {
                return .watchlist
            }
            
            guard project.supportsNativeDiffPages else {
                return nil
            }
            
            if let multiRevisionIdDiffMatch = mobilediffRegexMultiRevisionID.firstMatch(in: title),
                let fromRevID = Int(mobilediffRegexMultiRevisionID.replacementString(for: multiRevisionIdDiffMatch, in: title, offset: 0, template: "$1")),
                let toRevID = Int(mobilediffRegexMultiRevisionID.replacementString(for: multiRevisionIdDiffMatch, in: title, offset: 0, template: "$2")) {
                
                return .articleDiff(url, fromRevID: fromRevID, toRevID: toRevID)
            }
            if let singleRevisionIdDiffMatch = mobilediffRegexSingleRevisionID.firstReplacementString(in: title),
                let toRevID = Int(singleRevisionIdDiffMatch) {
                return .articleDiff(url, fromRevID: nil, toRevID: toRevID)
            }
            
            if let articleTitle = historyRegex.firstReplacementString(in: title)?.normalizedPageTitle {
                return .articleHistory(url, articleTitle: articleTitle)
            }
            
            return nil
        case .main:
            
            guard project.mainNamespaceGoesToNativeArticleView else {
                return nil
            }
            
            guard let host = url.host,
                  host != "thankyou.wikipedia.org" else {
                return nil
            }
            
            return WikipediaURLTranslations.isMainpageTitle(title, in: language) ? nil : Destination.article(url)
        case .wikipedia:
            
            guard project.considersWResourcePathsForRouting else {
                return nil
            }
            
            let onThisDayURLSnippet = "On_this_day"
            if title.uppercased().contains(onThisDayURLSnippet.uppercased()) {
                // URL in form of https://en.wikipedia.org/wiki/Wikipedia:On_this_day/Today?3. Take bit past question mark.
                if let selected = url.query {
                    return .onThisDay(Int(selected))
                } else {
                    return .onThisDay(nil)
                }
            } else {
                fallthrough
            }
        default:
            return nil
        }
    }
    
    internal func destinationForWResourceURL(_ url: URL, project: WikimediaProject) -> Destination? {
        
        guard project.considersWResourcePathsForRouting,
              let path = url.wResourcePath else {
            return nil
        }
        
        guard var components = URLComponents(string: path) else {
            return nil
        }
        components.query = url.query
        guard components.path.lowercased() == "index.php" else {
            return nil
        }
        guard let queryItems = components.queryItems else {
            return nil
        }
        
        var params: [String: String] = [:]
        params.reserveCapacity(queryItems.count)
        for item in queryItems {
            params[item.name] = item.value
        }
        
        if let search = params["search"] {
            return .search(url, term: search)
        }
        
        let maybeTitle = params["title"]
        let maybeDiff = params["diff"]
        let maybeOldID = params["oldid"]
        let maybeType = params["type"]
        let maybeAction = params["action"]
        let maybeDir = params["dir"]
        let maybeLimit = params["limit"]
        
        guard let title = maybeTitle else {
            return nil
        }
        
        let language = project.languageCode ?? "en"
        
        if language.uppercased() == "EN" || language.uppercased() == "TEST",
           title == "Special:UserLogin" {
            return .login
        }
        
        if maybeLimit != nil,
            maybeDir != nil,
            let action = maybeAction,
            action == "history" {
            // TODO: push history 'slice'
            return .articleHistory(url, articleTitle: title)
        } else if let action = maybeAction,
            action == "history" {
            return .articleHistory(url, articleTitle: title)
        } else if let type = maybeType,
            type == "revision",
            let diffString = maybeDiff,
            let oldIDString = maybeOldID,
            let toRevID = Int(diffString),
            let fromRevID = Int(oldIDString) {
            return .articleDiff(url, fromRevID: fromRevID, toRevID: toRevID)
        } else if let diff = maybeDiff,
            diff == "prev",
            let oldIDString = maybeOldID,
            let toRevID = Int(oldIDString) {
            return .articleDiff(url, fromRevID: nil, toRevID: toRevID)
        } else if let diff = maybeDiff,
            diff == "next",
            let oldIDString = maybeOldID,
                  let fromRevID = Int(oldIDString) {
            return .articleDiff(url, fromRevID: fromRevID, toRevID: nil)
        } else if let diff = maybeDiff,
                  let toRevID = Int(diff) {
            var fromRevID: Int? = nil
            if let maybeOldID {
                fromRevID = Int(maybeOldID)
            }
            return .articleDiff(url, fromRevID: fromRevID, toRevID: toRevID)
        } else if let oldIDString = maybeOldID,
            let toRevID = Int(oldIDString) {
            return .articleDiff(url, fromRevID: nil, toRevID: toRevID)
        }
        
        return nil
    }
    
    internal func destinationForHostURL(_ url: URL, project: WikimediaProject, permanentUsername: String?) -> Destination {
        let canonicalURL = url.canonical
        
        if let wikiResourcePathInfo = destinationForWikiResourceURL(canonicalURL, project: project, permanentUsername: permanentUsername) {
            return wikiResourcePathInfo
        }
        
        if let wResourcePathInfo = destinationForWResourceURL(canonicalURL, project: project) {
            return wResourcePathInfo
        }
        
        return webViewDestinationForHostURL(url)
    }
    
    internal func webViewDestinationForHostURL(_ url: URL) -> Destination {
        let canonicalURL = url.canonical
        
        if configuration.hostCanRouteToInAppWebView(url.host) {
            return .inAppLink(canonicalURL)
        } else {
            return .externalLink(url)
        }
    }
}
