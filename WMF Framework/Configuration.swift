import Foundation

/// Configuration handles the current environment - production, beta, staging, labs
/// It has the functions that build requests for the various APIs utilized by the app.
/// It maintains the list of relevant domains for those requests - default domain, domains that require the CentralAuth cookies to be copied, etc.
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
        return productionConfiguration(with: Locale.preferredLanguages)
    }()
    
    /// - Parameter preferredLanguageCodesFromSystemSettings: An array, in order from most to least preferred, of the user's preferred language codes from the iOS system settings.
    public static func productionConfiguration(with preferredLanguageCodesFromSystemSettings: [String]) -> Configuration {
        return Configuration(
            defaultSiteDomain: Domain.wikipedia,
            pageContentServiceAPIURLComponentsBuilderFactory: APIURLComponentsBuilder.RESTBase.getProductionBuilderFactory(),
            mediaWikiRestAPIURLComponentsBuilderFactory: APIURLComponentsBuilder.MediaWiki.getProductionBuilderFactory(),
            preferredLanguageCodesFromSystemSettings: preferredLanguageCodesFromSystemSettings
        )
    }
    
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

    /// - Parameter defaultSiteDomain: Default domain for constructing requests and for
    /// - Parameter otherDomains: Other domains to consider valid Wikipedia hosts and valid hosts for links to handle in the app instead of an external browser
    /// - Parameter pageContentServiceAPIURLComponentsBuilderFactory: block that takes a host string as an input and returns an `APIURLComponentsBuilder` for the [Page Content Servce](https://www.mediawiki.org/wiki/Page_Content_Service)
    /// - Parameter wikiFeedsAPIURLComponentsBuilderFactory: block that takes a host string as an input and returns an `APIURLComponentsBuilder` for [Wikifeeds](https://www.mediawiki.org/wiki/Wikifeeds). Useful when running wikifeeds locally or in staging at a separate host from the Page Content Service. Defaults to the `pageContentServiceAPIURLComponentsBuilderFactory`
    /// - Parameter mediaWikiRestAPIURLComponentsBuilderFactory: block that takes a host string as an input and returns an `APIURLComponentsBuilder` for the [MediaWiki Rest API](https://www.mediawiki.org/wiki/API:REST_API)
    /// - Parameter preferredLanguageCodesFromSystemSettings: An array, in order from most to least preferred, of the user's preferred language codes. Defaults to `Locale.preferredLanguages`, which is that list from the user's iOS system settings.
    required init(defaultSiteDomain: String, otherDomains: [String] = [], pageContentServiceAPIURLComponentsBuilderFactory: @escaping (String?) -> APIURLComponentsBuilder, wikiFeedsAPIURLComponentsBuilderFactory: ((String?) -> APIURLComponentsBuilder)? = nil, mediaWikiRestAPIURLComponentsBuilderFactory: @escaping (String?) -> APIURLComponentsBuilder, preferredLanguageCodesFromSystemSettings: [String] = Locale.preferredLanguages) { // When preferred languages changes, the app is restarted and Locale.preferredLanguages will be re-read
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
        self.preferredLanguageCodesFromSystemSettings = preferredLanguageCodesFromSystemSettings
        self.preferredWikipediaLanguagesFromSystemSettings = Configuration.uniqueWikipediaLanguages(with: preferredLanguageCodesFromSystemSettings)
        self.preferredWikipediaLanguagesWithVariantsFromSystemSettings = Configuration.uniqueWikipediaLanguages(with: preferredLanguageCodesFromSystemSettings, includingLanguagesWithoutVariants: false) // cache this filtered view as it is used to calculate request headers
        self.defaultAcceptLanguageHeader = Configuration.acceptLanguageHeader(with: preferredLanguageCodesFromSystemSettings)
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
    @objc(pageContentServiceAPIURLComponentsForHost:appendingPathComponents:)
    public func pageContentServiceAPIURLComponentsForHost(_ host: String? = nil, appending pathComponents: [String] = [""]) -> URLComponents {
        let builder = pageContentServiceAPIURLComponentsBuilderForHost(host)
        return builder.components(byAppending: pathComponents)
    }
    

    /// Returns the default request headers for Page Content Service API requests
    public func pageContentServiceHeaders(for wikipediaLanguage: String? = nil) -> [String: String] {
        // If the language supports variants, only send a single code with variant for that language.
        // This is a workaround for an issue with server-side Accept-Language header handling and
        // can be removed when https://phabricator.wikimedia.org/T256491 is fixed.
        guard let preferredLanguage = preferredWikipediaLanguageVariant(for: wikipediaLanguage) else {
            return [:]
        }
        return ["Accept-Language": preferredLanguage]
    }
    
    private let metricsAPIURLComponentsBuilder = APIURLComponentsBuilder.RESTBase.getProductionBuilderFactory()(Domain.wikimedia)
    /// The metrics API lives only on wikimedia.org: https://wikimedia.org/api/rest_v1/
    @objc(metricsAPIURLComponentsAppendingPathComponents:)
    public func metricsAPIURLComponents(appending pathComponents: [String] = [""]) -> URLComponents {
        
        return metricsAPIURLComponentsBuilder.components(byAppending: ["metrics"] + pathComponents)
    }
    
    /// Wikifeeds includes feed content and announcements. It can be run locally with this repository: https://gerrit.wikimedia.org/r/admin/projects/mediawiki/services/wikifeeds
    /// On production, it is run through RESTBase at  https://en.wikipedia.org/api/rest_v1/ (works for all language wikis)
    @objc(wikiFeedsAPIURLComponentsForHost:appendingPathComponents:)
    public func wikiFeedsAPIURLComponentsForHost(_ host: String? = nil, appending pathComponents: [String] = [""]) -> URLComponents {
        let builder = wikiFeedsAPIURLComponentsBuilderForHost(host)
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
    
    // MARK: - Preferred Languages

    let preferredLanguageCodesFromSystemSettings: [String]
    
    @objc public let preferredWikipediaLanguagesFromSystemSettings: [String]
    /// List of Wikipedia languages with variants in the order that the user preferrs them. Currently only supports zh and sr.
    @objc public let preferredWikipediaLanguagesWithVariantsFromSystemSettings: [String]
    
    let defaultAcceptLanguageHeader: String
    
    /// - Parameter wikiLanguage: The language to check
    /// - Parameter preferredLanguages: The list of preferred languages to check. Defaults to a list of the user's preferred Wikipedia languages that support variants.
    /// - Returns: The first preferred language variant for a given URL, or nil if the URL is for a Wikipedia with a language that doesn't support variants
    public func preferredWikipediaLanguageVariant(for wikiLanguage: String?) -> String? {
        guard let wikiLanguage = wikiLanguage else {
            return nil
        }
        let prefix = wikiLanguage + "-"
        return preferredWikipediaLanguagesFromSystemSettings.first { $0.hasPrefix(prefix) }
    }
    
    /// - Parameter languageIdentifiers: List of `Locale` language identifers
    /// - Parameter includingLanguagesWithoutVariants: Pass true to include Wikipedias without variants, passing false will only return languages with variants (currently only supporting zh and sr)
    /// - Returns: An array of preferred Wikipedia languages based on the provided array of language identifiers
    public static func uniqueWikipediaLanguages(with languageIdentifiers: [String], includingLanguagesWithoutVariants: Bool = true) -> [String] {
        var uniqueLanguageCodes = [String]()
        for languageIdentifier in languageIdentifiers {
            let locale = Locale(identifier: languageIdentifier)
            if let languageCode = locale.languageCode?.lowercased() {
                if let scriptLookup = wmf_mediaWikiCodeLookupGlobal[languageCode] {
                    let scriptCode = locale.scriptCode?.lowercased() ?? wmf_mediaWikiCodeLookupDefaultKeyGlobal
                    if let regionLookup = scriptLookup[scriptCode] ?? scriptLookup[wmf_mediaWikiCodeLookupDefaultKeyGlobal] {
                        let regionCode = locale.regionCode?.lowercased() ?? wmf_mediaWikiCodeLookupDefaultKeyGlobal
                        if let mediaWikiCode = regionLookup[regionCode] ?? regionLookup[wmf_mediaWikiCodeLookupDefaultKeyGlobal] {
                            if !uniqueLanguageCodes.contains(mediaWikiCode) {
                                uniqueLanguageCodes.append(mediaWikiCode)
                            }
                            continue
                        }
                    }
                }
                if includingLanguagesWithoutVariants {
                    let lowercased = languageIdentifier.lowercased()
                    if !uniqueLanguageCodes.contains(lowercased) {
                        uniqueLanguageCodes.append(lowercased)
                    }
                }
            }
        }
        return uniqueLanguageCodes
    }
    
    /// Calculates an accept language header given a list of preferred language codes
    /// - Parameter preferredLanguageCodes: Array of preferred language codes in preferential order from most preferred to least preferred
    /// - Returns: An accept language header value
    static func acceptLanguageHeader(with preferredLanguageCodes: [String]) -> String {
        let count: Double = Double(preferredLanguageCodes.count)
        var q: Double = 1.0
        let qDelta = 1.0/count
        var acceptLanguageString = ""
        for languageCode in preferredLanguageCodes {
            if q < 1.0 {
                acceptLanguageString += ", "
            }
            acceptLanguageString += languageCode
            if q < 1.0 {
                acceptLanguageString += String(format: ";q=%.2g", q)
            }
            q -= qDelta
        }
        return acceptLanguageString
    }
}


