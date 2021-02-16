import Foundation


/// Configuration handles the current environment - production, beta, staging, labs
/// It has the functions that build URLs for the various APIs utilized by the app.
/// It also maintains the list of relevant domains - default domain, domains that require the CentralAuth cookies to be copied, etc.
@objc(WMFConfiguration)
public class Configuration: NSObject {
    @objc public static let current: Configuration = {
        #if WMF_LOCAL_PAGE_CONTENT_SERVICE
        return .localPageContentService
        #elseif WMF_APPS_LABS_PAGE_CONTENT_SERVICE
        return .appsLabsPageContentService
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
            pageContentServiceAPIURLComponentsBuilderFactory: APIURLComponentsBuilder.RESTBase.getProductionBuilderFactory(),
            mediaWikiRestAPIURLComponentsBuilderFactory: APIURLComponentsBuilder.MediaWiki.getProductionBuilderFactory()
        )
    }()
    
    static let localPageContentService: Configuration = {
        var pageContentServiceHostComponents = URLComponents()
        pageContentServiceHostComponents.scheme = Scheme.http
        pageContentServiceHostComponents.host = Domain.localhost
        pageContentServiceHostComponents.port = 8888
        return Configuration(
            defaultSiteDomain: Domain.wikipedia,
            pageContentServiceAPIURLComponentsBuilderFactory: APIURLComponentsBuilder.RESTBase.getStagingBuilderFactory(with: pageContentServiceHostComponents),
            wikiFeedsAPIURLComponentsBuilderFactory: APIURLComponentsBuilder.RESTBase.getProductionBuilderFactory(),
            mediaWikiRestAPIURLComponentsBuilderFactory: APIURLComponentsBuilder.MediaWiki.getLocalBuilderFactory()
        )
    }()
    
    /// Allows announcements to be run locally, doesn't work with the feed
    @objc static let localWikiFeeds: Configuration = {
        var wikiFeedsHostComponents = URLComponents()
        wikiFeedsHostComponents.scheme = Scheme.http
        wikiFeedsHostComponents.host = Domain.localhost
        wikiFeedsHostComponents.port = 8889
        return Configuration(
            defaultSiteDomain: Domain.wikipedia,
            pageContentServiceAPIURLComponentsBuilderFactory: APIURLComponentsBuilder.RESTBase.getProductionBuilderFactory(),
            wikiFeedsAPIURLComponentsBuilderFactory: APIURLComponentsBuilder.RESTBase.getStagingBuilderFactory(with: wikiFeedsHostComponents),
            mediaWikiRestAPIURLComponentsBuilderFactory: APIURLComponentsBuilder.MediaWiki.getLocalBuilderFactory()
        )
    }()
    
    public static let appsLabsPageContentService: Configuration = {
        var appsLabsHostComponents = URLComponents()
        appsLabsHostComponents.scheme = Scheme.https
        appsLabsHostComponents.host = Domain.appsLabs
        return Configuration(
            defaultSiteDomain: Domain.wikipedia,
            otherDomains: [Domain.wikipedia],
            pageContentServiceAPIURLComponentsBuilderFactory: APIURLComponentsBuilder.RESTBase.getStagingBuilderFactory(with: appsLabsHostComponents),
            wikiFeedsAPIURLComponentsBuilderFactory: APIURLComponentsBuilder.RESTBase.getProductionBuilderFactory(),
            mediaWikiRestAPIURLComponentsBuilderFactory: APIURLComponentsBuilder.MediaWiki.getProductionBuilderFactory()
        )
    }()
    
    static let betaLabs: Configuration = {
        return Configuration(
            defaultSiteDomain: Domain.betaLabs,
            otherDomains: [Domain.wikipedia],
            pageContentServiceAPIURLComponentsBuilderFactory: APIURLComponentsBuilder.RESTBase.getProductionBuilderFactory(),
            mediaWikiRestAPIURLComponentsBuilderFactory: APIURLComponentsBuilder.MediaWiki.getProductionBuilderFactory()
        )
    }()
    
    // MARK: Constants
    
    struct Scheme {
        static let http = "http"
        static let https = "https"
    }
    
    public struct Domain {
        public static let wikipedia = "wikipedia.org"
        public static let wikidata = "wikidata.org"
        public static let mediaWiki = "mediawiki.org"
        public static let betaLabs = "wikipedia.beta.wmflabs.org"
        public static let appsLabs = "mobileapps.wmflabs.org" // Product Infrastructure team's labs instance
        public static let localhost = "localhost"
        public static let englishWikipedia = "en.wikipedia.org"
        public static let wikimedia = "wikimedia.org"
        public static let metaWiki = "meta.wikimedia.org"
        public static let wikimediafoundation = "wikimediafoundation.org"
        public static let uploads = "upload.wikimedia.org"
    }
    
    struct Path {
        static let wikiResourceComponent = ["wiki"]
        static let restBaseAPIComponents = ["api", "rest_v1"]
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

    required init(defaultSiteDomain: String, otherDomains: [String] = [], pageContentServiceAPIURLComponentsBuilderFactory: @escaping (String?) -> APIURLComponentsBuilder, wikiFeedsAPIURLComponentsBuilderFactory: ((String?) -> APIURLComponentsBuilder)? = nil, mediaWikiRestAPIURLComponentsBuilderFactory: @escaping (String?) -> APIURLComponentsBuilder) {
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
        self.pageContentServiceAPIURLComponentsBuilderFactory = pageContentServiceAPIURLComponentsBuilderFactory
        self.wikiFeedsAPIURLComponentsBuilderFactory = wikiFeedsAPIURLComponentsBuilderFactory ?? pageContentServiceAPIURLComponentsBuilderFactory
        self.mediaWikiRestAPIURLComponentsBuilderFactory = mediaWikiRestAPIURLComponentsBuilderFactory
    }
    
    let pageContentServiceAPIURLComponentsBuilderFactory: (String?) -> APIURLComponentsBuilder
    func pageContentServiceAPIURLComponentsBuilderForHost(_ host: String? = nil) -> APIURLComponentsBuilder {
        return pageContentServiceAPIURLComponentsBuilderFactory(host)
    }
    
    private let wikiFeedsAPIURLComponentsBuilderFactory: (String?) -> APIURLComponentsBuilder
    private func wikiFeedsAPIURLComponentsBuilderForHost(_ host: String? = nil) -> APIURLComponentsBuilder {
        return wikiFeedsAPIURLComponentsBuilderFactory(host)
    }
    
    func mediaWikiAPIURLComponentsBuilderForHost(_ host: String? = nil) -> APIURLComponentsBuilder {
        var components = URLComponents()
        components.host = host ?? Domain.metaWiki
        components.scheme = Scheme.https
        return APIURLComponentsBuilder(hostComponents: components, basePathComponents: Path.mediaWikiAPIComponents)
    }

    private let mediaWikiRestAPIURLComponentsBuilderFactory: (String?) -> APIURLComponentsBuilder
    private func mediaWikiRestAPIURLComponentsBuilderForHost(_ host: String? = nil) -> APIURLComponentsBuilder {
        return mediaWikiRestAPIURLComponentsBuilderFactory(host)
    }
    
    func articleURLComponentsBuilder(for host: String) -> APIURLComponentsBuilder {
        var components = URLComponents()
        components.host = host
        components.scheme = Scheme.https
        return APIURLComponentsBuilder(hostComponents: components, basePathComponents: Path.wikiResourceComponent)
    }
    
    /// The Page Content Service includes mobile-html and the associated endpoints. It can be run locally with this repository: https://gerrit.wikimedia.org/r/admin/projects/mediawiki/services/mobileapps
    /// On production, it is run through RESTBase at  https://en.wikipedia.org/api/rest_v1/ (works for all language wikis)
    @objc(pageContentServiceAPIURLForURL:appendingPathComponents:)
    public func pageContentServiceAPIURLForURL(_ url: URL? = nil, appending pathComponents: [String] = [""]) -> URL? {
        let builder = pageContentServiceAPIURLComponentsBuilderForHost(url?.host)
        let components = builder.components(byAppending: pathComponents)
        return components.wmf_URLWithLanguageVariantCode(url?.wmf_languageVariantCode)
    }
    
    /// Returns the default request headers for Page Content Service API requests
    public func pageContentServiceHeaders(for url: URL) -> [String: String] {
        
        // If the language variants feature is not turned on, use the old behavior.
        // This ensures the existing language variant behavior continues working.
        // This guard statment can be removed when languageVariantsEnabled is removed.
        guard WikipediaLookup.languageVariantsEnabled else {
            guard let apiLanguage = url.wmf_language else {
                return [:]
            }
            guard let preferredLanguage = Locale.preferredWikipediaLanguageVariant(wmf_language: apiLanguage) else {
                return [:]
            }
            return ["Accept-Language": preferredLanguage]
        }
        
        // If the language supports variants, only send a single code with variant for that language.
        // This is a workaround for an issue with server-side Accept-Language header handling and
        // can be removed when https://phabricator.wikimedia.org/T256491 is fixed.
        // NOTE: In general it does not seem that most sites process multi-language Accept-Language headers.
        // For variants, sending a single Accept-Language header is sufficient and seems the least error-prone.
        if let languageVariantCode = url.wmf_languageVariantCode {
            return ["Accept-Language": languageVariantCode]
        } else {
            return [:]
        }
    }
    
    
    private let metricsAPIURLComponentsBuilder = APIURLComponentsBuilder.RESTBase.getProductionBuilderFactory()(Domain.wikimedia)
    /// The metrics API lives only on wikimedia.org: https://wikimedia.org/api/rest_v1/
    @objc(metricsAPIURLComponentsAppendingPathComponents:)
    public func metricsAPIURLComponents(appending pathComponents: [String] = [""]) -> URLComponents {
        
        return metricsAPIURLComponentsBuilder.components(byAppending: ["metrics"] + pathComponents)
    }
    
    /// Wikifeeds includes feed content and announcements. It can be run locally with this repository: https://gerrit.wikimedia.org/r/admin/projects/mediawiki/services/wikifeeds
    /// On production, it is run through RESTBase at  https://en.wikipedia.org/api/rest_v1/ (works for all language wikis)
    @objc(wikiFeedsAPIURLForURL:appendingPathComponents:)
    public func wikiFeedsAPIURLForURL(_ url: URL?, appending pathComponents: [String] = [""]) -> URL? {
        let builder = wikiFeedsAPIURLComponentsBuilderForHost(url?.host)
        let components = builder.components(byAppending: pathComponents)
        return components.wmf_URLWithLanguageVariantCode(url?.wmf_languageVariantCode)
    }
    
    @objc(mediaWikiAPIURLForURL:withQueryParameters:)
    public func mediaWikiAPIURLForURL(_ url: URL?, with queryParameters: [String: Any]? = nil) -> URL? {
        let components = mediaWikiAPIURLForHost(url?.host, with: queryParameters)
        return components.wmf_URLWithLanguageVariantCode(url?.wmf_languageVariantCode)
    }
    
    private func mediaWikiAPIURLForHost(_ host: String? = nil, with queryParameters: [String: Any]? = nil) -> URLComponents {
        let builder = mediaWikiAPIURLComponentsBuilderForHost(host)
        guard let queryParameters = queryParameters else {
            return builder.components()
        }
        return builder.components(queryParameters: queryParameters)
    }

    public func mediaWikiRestAPIURLForURL(_ url: URL? = nil, appending pathComponents: [String] = [""], queryParameters: [String: Any]? = nil) -> URL? {
        let builder = mediaWikiRestAPIURLComponentsBuilderForHost(url?.host)
        let components = builder.components(byAppending: pathComponents, queryParameters: queryParameters)
        return components.wmf_URLWithLanguageVariantCode(url?.wmf_languageVariantCode)
    }
    
    public func articleURLForHost(_ host: String, languageVariantCode: String?, appending pathComponents: [String]) -> URL? {
        let builder = articleURLComponentsBuilder(for: host)
        let components = builder.components(byAppending: pathComponents)
        return components.wmf_URLWithLanguageVariantCode(languageVariantCode)
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


