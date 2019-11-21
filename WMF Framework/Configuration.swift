import Foundation

@objc(WMFConfiguration)
public class Configuration: NSObject {
    enum Stage {
        case production
        case labs
        case local
        
        static let current: Stage = {
            #if WMF_LOCAL
            return .local
            #elseif WMF_LABS
            return .labs
            #else
            return .production
            #endif
        }()
    }
    
    struct Scheme {
        static let http = "http"
        static let https = "https"
    }
    
    struct Domain {
        static let wikipedia = "wikipedia.org"
        static let wikidata = "wikidata.org"
        static let mediaWiki = "mediawiki.org"
        static let wmflabs = "wikipedia.beta.wmflabs.org"
        static let localhost = "localhost"
        static let englishWikipedia = "en.wikipedia.org"
        static let wikimedia = "wikimedia.org"
        static let metaWiki = "meta.wikimedia.org"
    }
    
    struct Path {
        static let wikiResource = "/wiki/"
        static let wResource = "/w/"
        static let indexPHP = "index.php"
        static let wikiResourceComponent = ["wiki"]
        static let mobileAppsServicesAPIComponents = ["api", "rest_v1"]
        static let mediaWikiAPIComponents = ["w", "api.php"]
        static let mediaWikiRestAPIComponents = ["w", "rest.php"]
    }
    
    let wikiResourceRegex = try! NSRegularExpression(pattern: "^\(Path.wikiResource)(.+)$", options: .caseInsensitive)
    let wResourceRegex = try! NSRegularExpression(pattern: "^\(Path.wResource)(.+)$", options: .caseInsensitive)
    // From https://github.com/wikimedia/mediawiki-title
    let namespaceRegex = try! NSRegularExpression(pattern: "^(.+?)_*:_*(.*)$")
    let mobilediffRegex = try! NSRegularExpression(pattern: "^mobilediff/([0-9]+)", options: .caseInsensitive)
    
    public struct APIURLComponentsBuilder {
        let hostComponents: URLComponents
        let basePathComponents: [String]
        
        func components(byAppending pathComponents: [String] = [], queryParameters: [String: Any]? = nil) -> URLComponents {
            var components = hostComponents
            components.replacePercentEncodedPathWithPathComponents(basePathComponents + pathComponents)
            components.replacePercentEncodedQueryWithQueryParameters(queryParameters)
            return components
        }
    }
   
    @objc public let defaultSiteDomain: String
    
    public let mediaWikiCookieDomain: String
    public let wikipediaCookieDomain: String
    public let wikidataCookieDomain: String
    public let wikimediaCookieDomain: String
    public let centralAuthCookieSourceDomain: String // copy cookies from
    public let centralAuthCookieTargetDomains: [String] // copy cookies to
    
    public let wikiResourceDomains: [String]
    
    required init(defaultSiteDomain: String, otherDomains: [String] = []) {
        self.defaultSiteDomain = defaultSiteDomain
        self.mediaWikiCookieDomain = Domain.mediaWiki.withDotPrefix
        self.wikimediaCookieDomain = Domain.wikimedia.withDotPrefix
        self.wikipediaCookieDomain = Domain.wikipedia.withDotPrefix
        self.wikidataCookieDomain = Domain.wikidata.withDotPrefix
        self.centralAuthCookieSourceDomain = self.wikipediaCookieDomain
        self.centralAuthCookieTargetDomains = [self.wikidataCookieDomain, self.mediaWikiCookieDomain, self.wikimediaCookieDomain]
        self.wikiResourceDomains = [defaultSiteDomain, Domain.mediaWiki] + otherDomains
    }
    
    func mobileAppsServicesAPIURLComponentsBuilderForHost(_ host: String? = nil) -> APIURLComponentsBuilder {
        switch Stage.current {
        case .local:
            let host = host ?? Domain.englishWikipedia
            let baseComponents = [host, "v1"] // "" to get a leading /
            var components = URLComponents()
            components.scheme = Scheme.http
            components.host = Domain.localhost
            components.port = 6927
            return APIURLComponentsBuilder(hostComponents: components, basePathComponents: baseComponents)
        default:
            var components = URLComponents()
            components.host = host ?? Domain.englishWikipedia
            components.scheme = Scheme.https
            return APIURLComponentsBuilder(hostComponents: components, basePathComponents: Path.mobileAppsServicesAPIComponents)
        }
    }
    
    func mediaWikiAPIURLComponentsBuilderForHost(_ host: String? = nil) -> APIURLComponentsBuilder {
        var components = URLComponents()
        components.host = host ?? Domain.metaWiki
        components.scheme = Scheme.https
        return APIURLComponentsBuilder(hostComponents: components, basePathComponents: Path.mediaWikiAPIComponents)
    }

    func mediaWikiRestAPIURLComponentsBuilderForHost(_ host: String? = nil) -> APIURLComponentsBuilder {
        switch Stage.current {
        case .local:
            var components = URLComponents()
            components.host = host ?? Domain.englishWikipedia
            components.scheme = Scheme.http
            components.host = Domain.localhost
            components.port = 8080
            return APIURLComponentsBuilder(hostComponents: components, basePathComponents: Path.mediaWikiRestAPIComponents)
        default:
            var components = URLComponents()
            components.host = host ?? Domain.englishWikipedia
            components.scheme = Scheme.https
            return APIURLComponentsBuilder(hostComponents: components, basePathComponents: Path.mediaWikiRestAPIComponents)
        }
    }
    
    func articleURLComponentsBuilder(for host: String) -> APIURLComponentsBuilder {
        var components = URLComponents()
        components.host = host
        components.scheme = Scheme.https
        return APIURLComponentsBuilder(hostComponents: components, basePathComponents: Path.wikiResourceComponent)
    }
    @objc(wikipediaMobileAppsServicesAPIURLComponentsForHost:appendingPathComponents:)
    public func wikipediaMobileAppsServicesAPIURLComponentsForHost(_ host: String? = nil, appending pathComponents: [String] = [""]) -> URLComponents {
        let builder = mobileAppsServicesAPIURLComponentsBuilderForHost(host)
        return builder.components(byAppending: pathComponents)
    }
    
    @objc(wikimediaMobileAppsServicesAPIURLComponentsAppendingPathComponents:)
    public func wikimediaMobileAppsServicesAPIURLComponents(appending pathComponents: [String] = [""]) -> URLComponents {
        let builder = mobileAppsServicesAPIURLComponentsBuilderForHost(Domain.wikimedia)
        return builder.components(byAppending: pathComponents)
    }
    
    public func mediaWikiAPIURForHost(_ host: String? = nil, appending pathComponents: [String] = [""]) -> URLComponents {
        let builder = mediaWikiAPIURLComponentsBuilderForHost(host)
        return builder.components(byAppending: pathComponents)
    }
    
    @objc(mediaWikiAPIURLComponentsForHost:withQueryParameters:)
    public func mediaWikiAPIURLForHost(_ host: String? = nil, with queryParameters: [String: Any]? = nil) -> URLComponents {
        let builder = mediaWikiAPIURLComponentsBuilderForHost(host)
        guard let queryParameters = queryParameters else {
            return builder.components()
        }
        return builder.components(queryParameters: queryParameters)
    }

    public func mediaWikiRestAPIURLForHost(_ host: String? = nil, appending pathComponents: [String] = [""], queryParameters: [String: Any]? = nil) -> URLComponents {
        let builder = mediaWikiRestAPIURLComponentsBuilderForHost(host)
        return builder.components(byAppending: pathComponents, queryParameters: queryParameters)
    }
    
    public func articleURLForHost(_ host: String, appending pathComponents: [String]) -> URLComponents {
        let builder = articleURLComponentsBuilder(for: host)
        return builder.components(byAppending: pathComponents)
    }
    
    public func mediaWikiAPIURLForWikiLanguage(_ wikiLanguage: String? = nil, with queryParameters: [String: Any]?) -> URLComponents {
        guard let wikiLanguage = wikiLanguage else {
            return mediaWikiAPIURLForHost(nil, with: queryParameters)
        }
        let host = "\(wikiLanguage).\(Domain.wikipedia)"
        return mediaWikiAPIURLForHost(host, with: queryParameters)
    }
    
    public func wikidataAPIURLComponents(with queryParameters: [String: Any]?) -> URLComponents {
        let builder = mediaWikiAPIURLComponentsBuilderForHost("www.\(Domain.wikidata)")
        return builder.components(queryParameters: queryParameters)
    }

    @objc(commonsAPIURLComponentsWithQueryParameters:)
    public func commonsAPIURLComponents(with queryParameters: [String: Any]?) -> URLComponents {
        let builder = mediaWikiAPIURLComponentsBuilderForHost("commons.\(Domain.wikimedia)")
        return builder.components(queryParameters: queryParameters)
    }

    @objc public static let current: Configuration = {
        switch Stage.current {
        case .local:
            return Configuration(defaultSiteDomain: Domain.wikipedia)
        case .labs:
            return Configuration(defaultSiteDomain: Domain.wmflabs, otherDomains: [Domain.wikipedia])
        case .production:
            return Configuration(defaultSiteDomain: Domain.wikipedia)

        }
    }()

    @objc public func isWikiHost(_ host: String?) -> Bool {
        guard let host = host else {
            return false
        }
        for domain in wikiResourceDomains {
            if host.isDomainOrSubDomainOf(domain) {
                return true
            }
        }
        return false
    }
    
    // Remainder of the path after /wiki/
    @objc public func wikiResourcePath(_ path: String?) -> String? {
        guard let path = path else {
            return nil
        }
        guard let match = wikiResourceRegex.firstMatch(in: path, options: [], range: NSMakeRange(0, path.count)) else {
            return nil
        }
        return wikiResourceRegex.replacementString(for: match, in: path, offset: 0, template: "$1")
        
    }
    
    // Remainder of the path after /w/
    @objc public func wResourcePath(_ path: String?) -> String? {
        guard let path = path else {
            return nil
        }
        guard let match = wResourceRegex.firstMatch(in: path, options: [], range: NSMakeRange(0, path.count)) else {
            return nil
        }
        return wResourceRegex.replacementString(for: match, in: path, offset: 0, template: "$1")
        
    }
    
    @objc public func isWikiResource(_ url: URL?) -> Bool {
        guard wikiResourcePath(url?.path) != nil else {
            return false
        }
        guard let host = url?.host else { // relative paths should work
            return true
        }
        return isWikiHost(host)
    }
    
    internal func activityInfoForWikiResourceURL(_ url: URL) -> UserActivityInfo? {
        guard let path = wikiResourcePath(url.path) else {
            return nil
        }
        let language = url.wmf_language ?? "en"
        if let namespaceMatch = namespaceRegex.firstMatch(in: path, options: [], range: NSMakeRange(0, path.count)) {
            let namespace = namespaceRegex.replacementString(for: namespaceMatch, in: path, offset: 0, template: "$1")
            let title = namespaceRegex.replacementString(for: namespaceMatch, in: path, offset: 0, template: "$2")
            let canonicalNamespace = namespace.uppercased().replacingOccurrences(of: "_", with: " ")
            let defaultActivity = UserActivityInfo(.inAppLink, url: url)
            // TODO: replace with lookup table
            switch canonicalNamespace {
            case "USER TALK":
                return UserActivityInfo(.userTalk, url: url, title: title, language: language)
            case "SPECIAL":
                if let diffMatch = mobilediffRegex.firstMatch(in: title, options: [], range: NSMakeRange(0, title.count)) {
                    let oldid = mobilediffRegex.replacementString(for: diffMatch, in: title, offset: 0, template: "$1")
                    return UserActivityInfo(.articleDiff, url: url, queryItems: [URLQueryItem(name: "diff", value: "prev"), URLQueryItem(name: "oldid", value: oldid)])
                } else {
                   return defaultActivity
                }
            default:
                return defaultActivity
            }
        }
        return UserActivityInfo(.article, url: url, title: path, language: language)
    }
    
    internal func activityInfoForWResourceURL(_ url: URL) -> UserActivityInfo? {
        guard let path = wResourcePath(url.path) else {
            return nil
        }
        let defaultActivity = UserActivityInfo(.inAppLink, url: url)
        guard var components = URLComponents(string: path) else {
            return defaultActivity
        }
        components.query = url.query
        guard components.path.lowercased() == Path.indexPHP else {
            return defaultActivity
        }
        guard let queryItems = components.queryItems else {
            return defaultActivity
        }
        for item in queryItems {
            if item.name.lowercased() == "search" {
                return UserActivityInfo(.searchResults, url: url, queryItems: queryItems)
            }
        }
        return defaultActivity
    }
    
    @objc public func activityInfoForWikiHostURL(_ url: URL?) -> UserActivityInfo? {
        guard let url = url else {
            return nil
        }
        
        if let wikiResourcePathInfo = activityInfoForWikiResourceURL(url) {
            return wikiResourcePathInfo
        }
        
        if let wResourcePathInfo = activityInfoForWResourceURL(url) {
             return wResourcePathInfo
        }
      
        return UserActivityInfo(.inAppLink, url: url)
    }
}

@objc(WMFUserActivityInfo)
public class UserActivityInfo: NSObject {
    @objc public let type: WMFUserActivityType
    @objc public let url: URL?
    @objc public let title: String?
    @objc public let language: String?
    @objc public let queryItems: [URLQueryItem]?
    
    required init(_ type: WMFUserActivityType, url: URL, title: String? = nil, language: String? = nil, queryItems: [URLQueryItem]? = nil) {
        self.type = type
        self.url = url
        self.title = title
        self.language = language
        self.queryItems = queryItems
    }
}
