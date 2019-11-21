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
    
    // From https://github.com/wikimedia/mediawiki-title
    private let namespaceRegex = try! NSRegularExpression(pattern: "^(.+?)_*:_*(.*)$")
    private let mobilediffRegexSingle = try! NSRegularExpression(pattern: "^mobilediff/([0-9]+)", options: .caseInsensitive)
    private let mobilediffRegexCompare = try! NSRegularExpression(pattern: "^mobilediff/([0-9]+)\\.\\.\\.([0-9]+)", options: .caseInsensitive)
    
     internal func destinationForWikiResourceURL(_ url: URL) -> Destination? {
        
        if configuration.isWResource(url) {
            if let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems {
                let maybeTitle = queryItems.first(where: { $0.name == "title" })?.value
                let maybeDiff = queryItems.first(where: { $0.name == "diff" })?.value
                let maybeOldID = queryItems.first(where: { $0.name == "oldid" })?.value
                let maybeType = queryItems.first(where: { $0.name == "type" })?.value
                let maybeAction = queryItems.first(where: { $0.name == "action" })?.value
                let maybeDir = queryItems.first(where: { $0.name == "dir" })?.value
                let maybeLimit = queryItems.first(where: { $0.name == "limit" })?.value
                
                guard let title = maybeTitle else {
                    return nil
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
            }
            
            return nil
        }
        
        guard let path = configuration.wikiResourcePath(url.path) else {
             return nil
         }
         let language = url.wmf_language ?? "en"
         let articleActivity = Destination.article(url)
         if let namespaceMatch = namespaceRegex.firstMatch(in: path, options: [], range: NSMakeRange(0, path.count)) {
             let namespaceString = namespaceRegex.replacementString(for: namespaceMatch, in: path, offset: 0, template: "$1")
             let title = namespaceRegex.replacementString(for: namespaceMatch, in: path, offset: 0, template: "$2")
             let namespace = WikipediaURLTranslations.commonNamespace(for: namespaceString, in: language)
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
                 } else {
                    return inAppLinkActivity
                 }
             case nil: // if the string before the : isn't a namespace, it's likely part of an article title
                 return articleActivity
             default:
                 return inAppLinkActivity
             }
         }
         return articleActivity
     }
     
     internal func destinationForWResourceURL(_ url: URL) -> Destination? {
        guard let path = configuration.wResourcePath(url.path) else {
             return nil
         }
         let defaultActivity = Destination.inAppLink(url)
         guard var components = URLComponents(string: path) else {
             return defaultActivity
         }
         components.query = url.query
         guard components.path.lowercased() == Configuration.Path.indexPHP else {
             return defaultActivity
         }
         guard let queryItems = components.queryItems else {
             return defaultActivity
         }
         for item in queryItems {
             if item.name.lowercased() == "search" {
                return .search(url, term:item.value)
             }
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
