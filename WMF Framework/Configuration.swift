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
        static let mediawiki = "mediawiki.org"
        static let wmflabs = "wikipedia.beta.wmflabs.org"
        static let localhost = "localhost"
        static let englishWikipedia = "en.wikipedia.org"
    }
    
    struct Path {
        static let wikiResource = "/wiki/"
        static let mobileAppsServicesAPIComponents = ["/api", "rest_v1"]
    }
    
    public struct API {
        let hostComponents: URLComponents
        let basePathComponents: [String]
    }
   
    @objc public let defaultSiteDomain: String
    
    public let mediaWikiCookieDomain: String
    public let wikipediaCookieDomain: String
    public let wikidataCookieDomain: String
    public let centralAuthCookieSourceDomain: String // copy cookies from
    public let centralAuthCookieTargetDomains: [String] // copy cookies to
    
    public let wikiResourceDomains: [String]
    
    required init(defaultSiteDomain: String, otherDomains: [String] = []) {
        self.defaultSiteDomain = defaultSiteDomain
        self.mediaWikiCookieDomain = Domain.mediawiki.withDotPrefix
        self.wikipediaCookieDomain = Domain.wikipedia.withDotPrefix
        self.wikidataCookieDomain = Domain.wikipedia.withDotPrefix
        self.centralAuthCookieSourceDomain = self.wikipediaCookieDomain
        self.centralAuthCookieTargetDomains = [self.wikidataCookieDomain, self.mediaWikiCookieDomain]
        self.wikiResourceDomains = [defaultSiteDomain, Domain.mediawiki] + otherDomains
    }
    
    func mobileAppsServicesAPIForHost(_ host: String? = nil) -> API {
        switch Stage.current {
        case .local:
            let host = host ?? Domain.englishWikipedia
            let baseComponents = ["/", host, "v1"]
            var components = URLComponents()
            components.scheme = Scheme.http
            components.host = Domain.localhost
            components.port = 6927
            return API(hostComponents: components, basePathComponents: baseComponents)
        default:
            var components = URLComponents()
            components.host = host ?? Domain.englishWikipedia
            components.scheme = Scheme.https
            return API(hostComponents: components, basePathComponents: Path.mobileAppsServicesAPIComponents)
        }
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
    
    @objc public func isWikiResource(_ url: URL?) -> Bool {
        guard url?.path.contains(Path.wikiResource) ?? false else {
            return false
        }
        guard let host = url?.host else { // relative paths should work
            return true
        }
        for domain in wikiResourceDomains {
            if host.isDomainOrSubDomainOf(domain) {
                return true
            }
        }
        return false
    }
    
}



