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
    
    struct Domain {
        static let wikipedia = "wikipedia.org"
        static let wikidata = "wikidata.org"
        static let mediawiki = "mediawiki.org"
        static let wmflabs = "wikipedia.beta.wmflabs.org"
        static let localhost = "localhost"
    }
    
    struct Path {
        static let wikiResource = "/wiki/"
    }
   
    @objc public let defaultSiteDomain: String

    @objc public let mobileAppsServicesDomain: String
    
    public let mediaWikiCookieDomain: String
    public let wikipediaCookieDomain: String
    public let wikidataCookieDomain: String
    public let centralAuthCookieSourceDomain: String // copy cookies from
    public let centralAuthCookieTargetDomains: [String] // copy cookies to
    
    public let wikiResourceDomains: [String]
    
    required init(defaultSiteDomain: String, mobileAppsServicesDomain: String? = nil, otherDomains: [String] = []) {
        self.defaultSiteDomain = defaultSiteDomain
        self.mobileAppsServicesDomain = mobileAppsServicesDomain ?? defaultSiteDomain

        self.mediaWikiCookieDomain = Domain.mediawiki.withDotPrefix
        self.wikipediaCookieDomain = Domain.wikipedia.withDotPrefix
        self.wikidataCookieDomain = Domain.wikipedia.withDotPrefix
        self.centralAuthCookieSourceDomain = self.wikipediaCookieDomain
        self.centralAuthCookieTargetDomains = [self.wikidataCookieDomain, self.mediaWikiCookieDomain]
        
        self.wikiResourceDomains = [defaultSiteDomain, Domain.mediawiki] + otherDomains
    }
    
    @objc public static let current: Configuration = {
        switch Stage.current {
        case .local:
            return Configuration(defaultSiteDomain: Domain.wikipedia, mobileAppsServicesDomain: Domain.localhost)
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
        for domain in wikiResourceDomains {
            if url?.host?.isDomainOrSubDomainOf(domain) ?? false {
                return true
            }
        }
        return false
    }
    
}



