@objc(WMFRouter)
public class Router: NSObject {
    public enum Destination: Equatable {
        case inAppLink(_: URL)
        case externalLink(_: URL)
        case article(_: URL)
        case articleHistory(_: URL, articleTitle: String)
        case articleDiffCompare(_: URL, fromRevID: Int?, toRevID: Int?)
        case articleDiffSingle(_: URL, fromRevID: Int?, toRevID: Int?)
        case userTalk(_: URL)
        case search(_: URL, term: String?)
    }
    
    unowned let configuration: Configuration
    required init(configuration: Configuration) {
        self.configuration = configuration
    }
    
    private let mobilediffRegexCompare = try! NSRegularExpression(pattern: "^mobilediff/([0-9]+)\\.\\.\\.([0-9]+)", options: .caseInsensitive)
    private let mobilediffRegexSingle = try! NSRegularExpression(pattern: "^mobilediff/([0-9]+)", options: .caseInsensitive)
    private let historyRegex = try! NSRegularExpression(pattern: "^history/(.*)", options: .caseInsensitive)
    
    internal func destinationForWikiResourceURL(_ url: URL) -> Destination? {
        guard let path = url.wikiResourcePath else {
            return nil
        }
        let language = url.wmf_language ?? "en"
        let articleActivity = Destination.article(url)
        if let namespaceAndTitle = path.namespaceAndTitleFromWikiResourcePath(with: language) {
            let namespace = namespaceAndTitle.0
            let title = namespaceAndTitle.1
            let inAppLinkActivity = Destination.inAppLink(url)
            switch namespace {
            case .userTalk:
                return .userTalk(url)
            case .special:
                if let compareDiffMatch = mobilediffRegexCompare.firstMatch(in: title, options: [], range: NSMakeRange(0, title.count)),
                    let fromRevID = Int(mobilediffRegexCompare.replacementString(for: compareDiffMatch, in: title, offset: 0, template: "$1")),
                    let toRevID = Int(mobilediffRegexCompare.replacementString(for: compareDiffMatch, in: title, offset: 0, template: "$2")) {
                    
                    return .articleDiffCompare(url, fromRevID: fromRevID, toRevID: toRevID)
                }
                if let singleDiffMatch = mobilediffRegexSingle.firstMatch(in: title, options: [], range: NSMakeRange(0, title.count)),
                    let toRevID = Int(mobilediffRegexSingle.replacementString(for: singleDiffMatch, in: title, offset: 0, template: "$1")) {
                    return .articleDiffSingle(url, fromRevID: nil, toRevID: toRevID)
                }
                
                if let historyMatch = historyRegex.firstMatch(in: title, options: [], range: NSMakeRange(0, title.count)) {
                    let articleTitle = mobilediffRegexSingle.replacementString(for: historyMatch, in: title, offset: 0, template: "$1")
                    return .articleHistory(url, articleTitle: articleTitle.wmf_normalizedPageTitle())
                }
                
                return inAppLinkActivity
            case nil: // if the string before the : isn't a namespace, it's likely part of an article title
                return articleActivity
            default:
                return inAppLinkActivity
            }
        }
        return articleActivity
    }
    
    internal func destinationForWResourceURL(_ url: URL) -> Destination? {
        guard let path = url.wResourcePath else {
            return nil
        }
        
        let defaultActivity = Destination.inAppLink(url)
        
        guard var components = URLComponents(string: path) else {
            return defaultActivity
        }
        components.query = url.query
        guard components.path.lowercased() == "index.php" else {
            return defaultActivity
        }
        guard let queryItems = components.queryItems else {
            return defaultActivity
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
            return defaultActivity
        }
        
        if let _ = maybeLimit,
            let _ = maybeDir,
            let action = maybeAction,
            action == "history" {
            //TODO: push history 'slice'
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
            return .articleDiffCompare(url, fromRevID: fromRevID, toRevID: toRevID)
        } else if let diff = maybeDiff,
            diff == "prev",
            let oldIDString = maybeOldID,
            let toRevID = Int(oldIDString) {
            return .articleDiffCompare(url, fromRevID: nil, toRevID: toRevID)
        } else if let diff = maybeDiff,
            diff == "next",
            let oldIDString = maybeOldID,
            let fromRevID = Int(oldIDString) {
            return .articleDiffCompare(url, fromRevID: fromRevID, toRevID: nil)
        } else if let oldIDString = maybeOldID,
            let toRevID = Int(oldIDString) {
            return .articleDiffSingle(url, fromRevID: nil, toRevID: toRevID)
        }
        
        return defaultActivity
    }
    
    internal func destinationForWikiHostURL(_ url: URL) -> Destination {
        let canonicalURL = url.canonical
        
        if let wikiResourcePathInfo = destinationForWikiResourceURL(canonicalURL) {
            return wikiResourcePathInfo
        }
        
        if let wResourcePathInfo = destinationForWResourceURL(canonicalURL) {
            return wResourcePathInfo
        }
        
        // keep mobile URLs for in app links
        return .inAppLink(url)
    }
    
    public func destination(for url: URL?) throws -> Destination {
        guard let url = url else {
            throw RequestError.invalidParameters
        }
        
        guard configuration.isWikiHost(url.host) else {
            return .externalLink(url)
        }
        
        return destinationForWikiHostURL(url)
    }
}
