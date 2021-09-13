import Foundation


/// Configuration handles the current environment - production, beta, staging, labs
/// It has the functions that build URLs for the various APIs utilized by the app.
/// It also maintains the list of relevant domains - default domain, domains that require the CentralAuth cookies to be copied, etc.
@objc(WMFConfiguration)
public class Configuration: NSObject {
    
    public struct StagingOptions: OptionSet {
        public let rawValue: Int

        public static let appsLabsforPCS = StagingOptions(rawValue: 1 << 0)
        public static let deploymentLabsForEventLogging = StagingOptions(rawValue: 1 << 1)
        public static let betaCluster = StagingOptions(rawValue: 1 << 2) //note, this will force beta cluster for PCS (thus ignoring an appsLabsforPCS value if also set) and force deploymentLabsForEventLogging
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
    }
    
    public struct LocalOptions: OptionSet {
        public let rawValue: Int
        
        public static let localAnnouncements = LocalOptions(rawValue: 1 << 0)
        public static let localPCS = LocalOptions(rawValue: 1 << 1)
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
    }
    
    public enum Environment {
        case production
        case staging(StagingOptions)
        case local(LocalOptions)
    }
    
    public let environment: Environment
    
    @objc public static let current: Configuration = {
        #if WMF_LOCAL
        return Configuration.local(options: [.localPCS, .localAnnouncements])
        #elseif WMF_STAGING
		
		/* NOTE: .betaCluster attempts to point to the MediaWiki beta cluster for all possible endpoints.
		Change this to .appsLabsForPCS and/or .deploymentLabsForEventLogging for alternative staging environments.
		Example: Configuration.staging(options: [.appsLabsForPCS, .deploymentLabsForEventLogging])
			.appsLabsForPCS = Product Infrastructure team's labs instance for PCS endpoints
			.deploymentLabsForEventLogging = labs instance for testing event logging endpoints
			All other endpoints would point to production */
		
        return Configuration.staging(options: [.betaCluster])
        #else
        return .production
        #endif
    }()
    
    private let pageContentServiceAPIType: APIURLComponentsBuilder.RESTBase.BuilderType
    private let feedContentAPIType: APIURLComponentsBuilder.RESTBase.BuilderType
    private let announcementsAPIType: APIURLComponentsBuilder.RESTBase.BuilderType
    private let eventLoggingAPIType: APIURLComponentsBuilder.EventLogging.BuilderType
    private let mediaWikiRestAPIType = APIURLComponentsBuilder.MediaWiki.BuilderType.productionRest
    private let mediaWikiAPIType = APIURLComponentsBuilder.MediaWiki.BuilderType.production
    private let wikidataAPIType: APIURLComponentsBuilder.Wikidata.BuilderType
    private let commonsAPIType: APIURLComponentsBuilder.Commons.BuilderType
    private let metricsAPIType = APIURLComponentsBuilder.RESTBase.BuilderType.production
    
    // MARK: Configurations
    
    public static let production: Configuration = {
        return Configuration(
            environment: .production,
            defaultSiteDomain: Domain.wikipedia,
            wikipediaCookieDomain: Domain.wikipedia.withDotPrefix,
            wikidataCookieDomain: Domain.wikidata.withDotPrefix,
            commonsCookieDomain: Domain.commons.withDotPrefix,
            pageContentServiceAPIType: .production,
            feedContentAPIType: .production,
            announcementsAPIType: .production,
            wikidataAPIType: .production,
            commonsAPIType: .production,
            eventLoggingAPIType: .production)
    }()
    
    private static func staging(options: StagingOptions) -> Configuration {
        
        let defaultSiteDomain = options.contains(.betaCluster) ? Domain.wikipediaBetaLabs : Domain.wikipedia
        let wikipediaCookieDomain = options.contains(.betaCluster) ? Domain.wikipediaBetaLabs.withDotPrefix : Domain.wikipedia.withDotPrefix
        let wikidataCookieDomain = options.contains(.betaCluster) ? Domain.wikidataBetaLabs.withDotPrefix : Domain.wikidata.withDotPrefix
        let commonsCookieDomain = options.contains(.betaCluster) ? Domain.commonsBetaLabs.withDotPrefix : Domain.commons.withDotPrefix
        let pcsApiType: APIURLComponentsBuilder.RESTBase.BuilderType = options.contains(.appsLabsforPCS) && !options.contains(.betaCluster) ? .stagingAppsLabsPCS : .production
        let wikidataApiType: APIURLComponentsBuilder.Wikidata.BuilderType = options.contains(.betaCluster) ? .betaLabs : .production
        let commonsApiType: APIURLComponentsBuilder.Commons.BuilderType = options.contains(.betaCluster) ? .betaLabs : .production
        let eventLoggingApiType: APIURLComponentsBuilder.EventLogging
            .BuilderType = options.contains(.deploymentLabsForEventLogging) || options.contains(.betaCluster) ? .staging : .production
        
        return Configuration(
            environment: .staging(options),
            defaultSiteDomain: defaultSiteDomain,
            wikipediaCookieDomain: wikipediaCookieDomain,
            wikidataCookieDomain: wikidataCookieDomain,
            commonsCookieDomain: commonsCookieDomain,
            pageContentServiceAPIType: pcsApiType,
            feedContentAPIType: .production,
            announcementsAPIType: .production,
            wikidataAPIType: wikidataApiType,
            commonsAPIType: commonsApiType,
            eventLoggingAPIType: eventLoggingApiType
        )
    }
    
    private static func local(options: LocalOptions) -> Configuration {
        
        let pcsApiType: APIURLComponentsBuilder.RESTBase.BuilderType = options.contains(.localPCS) ? .localPCS : .production
        let announcementsApiType: APIURLComponentsBuilder.RESTBase.BuilderType = options.contains(.localAnnouncements) ? .localAnnouncements : .production
        
        return Configuration(
            environment: .local(options),
            defaultSiteDomain: Domain.wikipedia,
            wikipediaCookieDomain: Domain.wikipedia.withDotPrefix,
            wikidataCookieDomain: Domain.wikidata.withDotPrefix,
            commonsCookieDomain: Domain.commons.withDotPrefix,
            pageContentServiceAPIType: pcsApiType,
            feedContentAPIType: .production,
            announcementsAPIType: announcementsApiType,
            wikidataAPIType: .production,
            commonsAPIType: .production,
            eventLoggingAPIType: .production)
    }
    
    // MARK: Constants
    
    struct Scheme {
        static let http = "http"
        static let https = "https"
    }
    
    public struct Domain {
        public static let wikipedia = "wikipedia.org"
        public static let wikipediaBetaLabs = "wikipedia.beta.wmflabs.org"
        public static let wikidata = "wikidata.org"
        public static let wikidataBetaLabs = "wikidata.beta.wmflabs.org"
        public static let commons = "commons.wikimedia.org"
        public static let commonsBetaLabs = "commons.wikimedia.beta.wmflabs.org"
        public static let mediaWiki = "mediawiki.org"
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
    public let commonsCookieDomain: String
    public let wikimediaCookieDomain: String
    public let centralAuthCookieSourceDomain: String // copy cookies from
    public let centralAuthCookieTargetDomains: [String] // copy cookies to
    
    public let wikiResourceDomains: [String]
    public let inAppLinkDomains: [String]

    @objc public lazy var router: Router = {
       return Router(configuration: self)
    }()

    required init(environment: Environment, defaultSiteDomain: String,
                  wikipediaCookieDomain: String,
                  wikidataCookieDomain: String,
                  commonsCookieDomain: String,
                  otherDomains: [String] = [],
                  pageContentServiceAPIType: APIURLComponentsBuilder.RESTBase.BuilderType,
                  feedContentAPIType: APIURLComponentsBuilder.RESTBase.BuilderType,
                  announcementsAPIType: APIURLComponentsBuilder.RESTBase.BuilderType,
                  wikidataAPIType: APIURLComponentsBuilder.Wikidata.BuilderType,
                  commonsAPIType: APIURLComponentsBuilder.Commons.BuilderType,
                  eventLoggingAPIType: APIURLComponentsBuilder.EventLogging.BuilderType) {
        self.environment = environment
        self.defaultSiteDomain = defaultSiteDomain
        var components = URLComponents()
        components.scheme = "https"
        components.host = defaultSiteDomain
        self.defaultSiteURL = components.url!
        self.mediaWikiCookieDomain = Domain.mediaWiki.withDotPrefix
        self.wikimediaCookieDomain = Domain.wikimedia.withDotPrefix
        self.wikipediaCookieDomain = wikipediaCookieDomain
        self.wikidataCookieDomain = wikidataCookieDomain
        self.commonsCookieDomain = commonsCookieDomain
        self.centralAuthCookieSourceDomain = self.wikipediaCookieDomain
        self.centralAuthCookieTargetDomains = [self.wikidataCookieDomain, self.mediaWikiCookieDomain, self.wikimediaCookieDomain, self.commonsCookieDomain]
        self.wikiResourceDomains = [defaultSiteDomain] + otherDomains
        self.inAppLinkDomains = [defaultSiteDomain, Domain.mediaWiki, Domain.wikidata, Domain.wikimedia, Domain.wikimediafoundation] + otherDomains
        self.pageContentServiceAPIType = pageContentServiceAPIType
        self.feedContentAPIType = feedContentAPIType
        self.announcementsAPIType = announcementsAPIType
        self.wikidataAPIType = wikidataAPIType
        self.commonsAPIType = commonsAPIType
        self.eventLoggingAPIType = eventLoggingAPIType
    }
    
    //MARK: Page Content Service
    
    public func pageContentServiceBuilder(withWikiHost wikiHost: String? = nil) -> APIURLComponentsBuilder {
        let builder = pageContentServiceAPIType.builder(withWikiHost: wikiHost)
        return builder
    }
    
    /// The Page Content Service includes mobile-html and the associated endpoints. It can be run locally with this repository: https://gerrit.wikimedia.org/r/admin/projects/mediawiki/services/mobileapps
    /// On production, it is run through RESTBase at  https://en.wikipedia.org/api/rest_v1/ (works for all language wikis)
    @objc(pageContentServiceAPIURLForURL:appendingPathComponents:)
    public func pageContentServiceAPIURLForURL(_ url: URL? = nil, appending pathComponents: [String] = [""]) -> URL? {
        let builder = pageContentServiceAPIType.builder(withWikiHost: url?.host)
        let components = builder.components(byAppending: pathComponents)
        return components.wmf_URLWithLanguageVariantCode(url?.wmf_languageVariantCode)
    }
    
    /// Returns the default request headers for Page Content Service API requests
    public func pageContentServiceHeaders(for url: URL) -> [String: String] {
        
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
    
    //MARK: Metrics
    
    /// The metrics API lives only on wikimedia.org: https://wikimedia.org/api/rest_v1/
    @objc(metricsAPIURLComponentsAppendingPathComponents:)
    public func metricsAPIURLComponents(appending pathComponents: [String] = [""]) -> URLComponents {
        let builder = metricsAPIType.builder(withWikiHost: Domain.wikimedia)
        return builder.components(byAppending: ["metrics"] + pathComponents)
    }
    
    //MARK: Wikifeeds (Feed Content and Announcements)
    
    /// Feed content is located in the wikifeeds repository. It can be run locally with: https://gerrit.wikimedia.org/r/admin/projects/mediawiki/services/wikifeeds
    /// On production, it is run through RESTBase at  https://en.wikipedia.org/api/rest_v1/ (works for all language wikis)
    @objc(feedContentAPIURLForURL:appendingPathComponents:)
    public func feedContentAPIURLForURL(_ url: URL?, appending pathComponents: [String] = [""]) -> URL? {
        let builder = feedContentAPIType.builder(withWikiHost: url?.host)
        let components = builder.components(byAppending: pathComponents)
        return components.wmf_URLWithLanguageVariantCode(url?.wmf_languageVariantCode)
    }
    
    /// Announcements are located in the wikifeeds repository. It can be run locally with: https://gerrit.wikimedia.org/r/admin/projects/mediawiki/services/wikifeeds
    /// On production, it is run through RESTBase at  https://en.wikipedia.org/api/rest_v1/ (works for all language wikis)
    @objc(announcementsAPIURLForURL:appendingPathComponents:)
    public func announcementsAPIURLForURL(_ url: URL?, appending pathComponents: [String] = [""]) -> URL? {
        let builder = announcementsAPIType.builder(withWikiHost: url?.host)
        let components = builder.components(byAppending: pathComponents)
        return components.wmf_URLWithLanguageVariantCode(url?.wmf_languageVariantCode)
    }
    
    //MARK: Event Logging
    
    @objc(eventLoggingAPIURLWithPayload:)
    public func eventLoggingAPIURL(with payload: NSObject) -> URL? {
        let builder = eventLoggingAPIType.builder()
        let components = try? builder.components(byAssigningPayloadToPercentEncodedQuery: payload)
        return components?.url
    }
    
    //MARK: MediaWiki Rest
    
    public func mediaWikiRestAPIURLForURL(_ url: URL? = nil, appending pathComponents: [String] = [""], queryParameters: [String: Any]? = nil) -> URL? {
        let builder = mediaWikiRestAPIType.builder(withWikiHost: url?.host)
        let components = builder.components(byAppending: pathComponents, queryParameters: queryParameters)
        return components.wmf_URLWithLanguageVariantCode(url?.wmf_languageVariantCode)
    }
    
    //MARK: MediaWiki
    
    @objc(mediaWikiAPIURLForURL:withQueryParameters:)
    public func mediaWikiAPIURLForURL(_ url: URL?, with queryParameters: [String: Any]? = nil) -> URL? {
        let components = mediaWikiAPIURLForHost(url?.host, with: queryParameters)
        return components.wmf_URLWithLanguageVariantCode(url?.wmf_languageVariantCode)
    }
    
    private func mediaWikiAPIURLForHost(_ host: String? = nil, with queryParameters: [String: Any]? = nil) -> URLComponents {
        let builder = mediaWikiAPIType.builder(withWikiHost: host)
        guard let queryParameters = queryParameters else {
            return builder.components()
        }
        return builder.components(queryParameters: queryParameters)
    }
    
    public func mediaWikiAPIURLForLanguageCode(_ languageCode: String? = nil, with queryParameters: [String: Any]?) -> URLComponents {
        guard let languageCode = languageCode else {
            return mediaWikiAPIURLForHost(nil, with: queryParameters)
        }
        let host = "\(languageCode).\(defaultSiteDomain)"
        return mediaWikiAPIURLForHost(host, with: queryParameters)
    }
    
    //MARK: Wikidata
    
    public func wikidataAPIURLComponents(with queryParameters: [String: Any]?) -> URLComponents {
        let builder = wikidataAPIType.builder()
        return builder.components(queryParameters: queryParameters)
    }
    
    //MARK: Commons

    @objc(commonsAPIURLComponentsWithQueryParameters:)
    public func commonsAPIURLComponents(with queryParameters: [String: Any]?) -> URLComponents {
        let builder = commonsAPIType.builder()
        return builder.components(queryParameters: queryParameters)
    }
    
    //MARK: Article URLs
    
    func articleURLComponentsBuilder(for host: String) -> APIURLComponentsBuilder {
        var components = URLComponents()
        components.host = host
        components.scheme = Scheme.https
        return APIURLComponentsBuilder(hostComponents: components, basePathComponents: Path.wikiResourceComponent)
    }
    
    public func articleURLForHost(_ host: String, languageVariantCode: String?, appending pathComponents: [String]) -> URL? {
        let builder = articleURLComponentsBuilder(for: host)
        let components = builder.components(byAppending: pathComponents)
        return components.wmf_URLWithLanguageVariantCode(languageVariantCode)
    }
    
    //MARK: Routing Helpers

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


