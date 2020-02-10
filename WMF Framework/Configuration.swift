import Foundation


/// Configuration handles the current environment - production, beta, staging, labs
/// It has the functions that build URLs for the various APIs utilized by the app.
/// It also maintains the list of relevant domains - default domain, domains that require the CentralAuth cookies to be copied, etc.
@objc(WMFConfiguration)
public class Configuration: NSObject {
    @objc public static let current: Configuration = {
        #if WMF_LOCAL
        return .local
        #elseif WMF_APPS_LABS
        return .appsLabs
        #elseif WMF_LABS
        return .betaLabs
        #else
        return .production
        #endif
    }()
    
    // MARK: Configurations
    
    public static let production: Configuration = {
        return Configuration(
            defaultSiteDomain: Domain.wikipedia,
            mobileAppsServicesAPIURLComponentsBuilderFactory: APIURLComponentsBuilder.MobileApps.getProductionBuilderFactory(),
            mediaWikiRestAPIURLComponentsBuilderFactory: APIURLComponentsBuilder.MediaWiki.getProductionBuilderFactory()
        )
    }()
    
    static let local: Configuration = {
        var mobileAppsServicesHostComponents = URLComponents()
        mobileAppsServicesHostComponents.scheme = Scheme.http
        mobileAppsServicesHostComponents.host = Domain.localhost
        mobileAppsServicesHostComponents.port = 8888
        return Configuration(
            defaultSiteDomain: Domain.wikipedia,
            mobileAppsServicesAPIURLComponentsBuilderFactory: APIURLComponentsBuilder.MobileApps.getStagingBuilderFactory(with: mobileAppsServicesHostComponents),
            mediaWikiRestAPIURLComponentsBuilderFactory: APIURLComponentsBuilder.MediaWiki.getLocalBuilderFactory()
        )
    }()
    
    public static let appsLabs: Configuration = {
        var appsLabsHostComponents = URLComponents()
        appsLabsHostComponents.scheme = Scheme.https
        appsLabsHostComponents.host = Domain.appsLabs
        return Configuration(
            defaultSiteDomain: Domain.wikipedia,
            otherDomains: [Domain.wikipedia],
            mobileAppsServicesAPIURLComponentsBuilderFactory: APIURLComponentsBuilder.MobileApps.getStagingBuilderFactory(with: appsLabsHostComponents),
            mediaWikiRestAPIURLComponentsBuilderFactory: APIURLComponentsBuilder.MediaWiki.getProductionBuilderFactory()
        )
    }()
    
    static let betaLabs: Configuration = {
        return Configuration(
            defaultSiteDomain: Domain.betaLabs,
            otherDomains: [Domain.wikipedia],
            mobileAppsServicesAPIURLComponentsBuilderFactory: APIURLComponentsBuilder.MobileApps.getProductionBuilderFactory(),
            mediaWikiRestAPIURLComponentsBuilderFactory: APIURLComponentsBuilder.MediaWiki.getProductionBuilderFactory()
        )
    }()
    
    // MARK: Constants
    
    struct Scheme {
        static let http = "http"
        static let https = "https"
    }
    
    public struct Domain {
        static let wikipedia = "wikipedia.org"
        static let wikidata = "wikidata.org"
        static let mediaWiki = "mediawiki.org"
        static let betaLabs = "wikipedia.beta.wmflabs.org"
        static let appsLabs = "apps.wmflabs.org" // Apps team's labs instance
        static let mobileAppsServicesLabs = "mobileapps.wmflabs.org" // Product Infrastructure team's labs instance
        static let localhost = "localhost"
        static let englishWikipedia = "en.wikipedia.org"
        static let wikimedia = "wikimedia.org"
        static let metaWiki = "meta.wikimedia.org"
        static let wikimediafoundation = "wikimediafoundation.org"
    }
   
    struct Path {
        static let wikiResourceComponent = ["wiki"]
        static let mobileAppsServicesAPIComponents = ["api", "rest_v1"]
        static let mediaWikiAPIComponents = ["w", "api.php"]
        static let mediaWikiRestAPIComponents = ["w", "rest.php"]
    }
    
    // MARK: State
    
    @objc public let defaultSiteDomain: String
    public let defaultSiteURL: URL
    
    public let mediaWikiCookieDomain: String
    public let wikipediaCookieDomain: String
    public let wikidataCookieDomain: String
    public let wikimediaCookieDomain: String
    public let centralAuthCookieSourceDomain: String // copy cookies from
    public let centralAuthCookieTargetDomains: [String] // copy cookies to
    
    public let wikiResourceDomains: [String]
    public let inAppLinkDomains: [String]

    @objc public lazy var router: Router = {
       return Router(configuration: self)
    }()

    required init(defaultSiteDomain: String, otherDomains: [String] = [], mobileAppsServicesAPIURLComponentsBuilderFactory: @escaping (String?) -> APIURLComponentsBuilder, mediaWikiRestAPIURLComponentsBuilderFactory: @escaping (String?) -> APIURLComponentsBuilder) {
        self.defaultSiteDomain = defaultSiteDomain
        var components = URLComponents()
        components.scheme = "https"
        components.host = defaultSiteDomain
        self.defaultSiteURL = components.url!
        self.mediaWikiCookieDomain = Domain.mediaWiki.withDotPrefix
        self.wikimediaCookieDomain = Domain.wikimedia.withDotPrefix
        self.wikipediaCookieDomain = Domain.wikipedia.withDotPrefix
        self.wikidataCookieDomain = Domain.wikidata.withDotPrefix
        self.centralAuthCookieSourceDomain = self.wikipediaCookieDomain
        self.centralAuthCookieTargetDomains = [self.wikidataCookieDomain, self.mediaWikiCookieDomain, self.wikimediaCookieDomain]
        self.wikiResourceDomains = [defaultSiteDomain] + otherDomains
        self.inAppLinkDomains = [defaultSiteDomain, Domain.mediaWiki, Domain.wikidata, Domain.wikimedia, Domain.wikimediafoundation] + otherDomains
        self.mobileAppsServicesAPIURLComponentsBuilderFactory = mobileAppsServicesAPIURLComponentsBuilderFactory
        self.mediaWikiRestAPIURLComponentsBuilderFactory = mediaWikiRestAPIURLComponentsBuilderFactory
    }
    
    let mobileAppsServicesAPIURLComponentsBuilderFactory: (String?) -> APIURLComponentsBuilder
    func mobileAppsServicesAPIURLComponentsBuilderForHost(_ host: String? = nil) -> APIURLComponentsBuilder {
        return mobileAppsServicesAPIURLComponentsBuilderFactory(host)
    }
    
    func mediaWikiAPIURLComponentsBuilderForHost(_ host: String? = nil) -> APIURLComponentsBuilder {
        var components = URLComponents()
        components.host = host ?? Domain.metaWiki
        components.scheme = Scheme.https
        return APIURLComponentsBuilder(hostComponents: components, basePathComponents: Path.mediaWikiAPIComponents)
    }

    let mediaWikiRestAPIURLComponentsBuilderFactory: (String?) -> APIURLComponentsBuilder
    func mediaWikiRestAPIURLComponentsBuilderForHost(_ host: String? = nil) -> APIURLComponentsBuilder {
        return mediaWikiRestAPIURLComponentsBuilderFactory(host)
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

    public func isWikipediaHost(_ host: String?) -> Bool {
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
    
    public func isInAppLinkHost(_ host: String?) -> Bool {
        guard let host = host else {
            return false
        }
        for domain in inAppLinkDomains {
            if host.isDomainOrSubDomainOf(domain) {
                return true
            }
        }
        return false
    }
}


