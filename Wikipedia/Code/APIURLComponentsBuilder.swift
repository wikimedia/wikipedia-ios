import CocoaLumberjackSwift

enum APIURLComponentsBuilderError: Error {
    case failureConvertingJsonDataToString
}

/// APIURLComponentsBuilder stores API host components and the base path (/w/api.php, /api/rest_v1, etc) and builds URLs for various endpoints
public struct APIURLComponentsBuilder {
    let hostComponents: URLComponents
    let basePathComponents: [String]
    
    func components(byAppending pathComponents: [String] = [], queryParameters: [String: Any]? = nil) -> URLComponents {
        var components = hostComponents
        components.replacePercentEncodedPathWithPathComponents(basePathComponents + pathComponents)
        components.replacePercentEncodedQueryWithQueryParameters(queryParameters)
        return components
    }
    
    func components(byAssigningPayloadToPercentEncodedQuery payload: NSObject) throws -> URLComponents {
        guard JSONSerialization.isValidJSONObject(payload) else {
            throw APIURLComponentsBuilderError.failureConvertingJsonDataToString
        }
        let payloadJsonData = try JSONSerialization.data(withJSONObject:payload, options: [])
        
        guard let payloadString = String(data: payloadJsonData, encoding: .utf8) else {
            throw APIURLComponentsBuilderError.failureConvertingJsonDataToString
        }
        
        let encodedPayloadJsonString = payloadString.wmf_UTF8StringWithPercentEscapes()
        
        var components = hostComponents
        components.replacePercentEncodedPathWithPathComponents(basePathComponents)
        components.percentEncodedQuery = encodedPayloadJsonString
        return components
    }

    /// RESTBase is a set of REST APIs utilized by the app for the feed, page summaries, page content, and others
    /// They exist on most wikis - example doc for enwiki, change the domain for other wikis: https://en.wikipedia.org/api/rest_v1/
    struct RESTBase {
        
        public enum BuilderType {
            case production
            case stagingAppsLabsPCS
            case localPCS
            case localAnnouncements
            
            func builder(withWikiHost wikiHost: String? = nil) -> APIURLComponentsBuilder {
                switch self {
                case .production: return RESTBase.productionBuilder(withWikiHost: wikiHost)
                case .stagingAppsLabsPCS: return RESTBase.stagingBuilderForAppsLabsPCS(withWikiHost: wikiHost)
                case .localPCS: return RESTBase.localBuilderForPCS(withWikiHost: wikiHost)
                case .localAnnouncements: return RESTBase.localBuilderForAnnouncements(withWikiHost: wikiHost)
                }
            }
        }
        
        /// Returns a block that will return a builder for a given host. For production, the host is the host of the wiki: https://en.wikipedia.org/api/rest_v1/
        private static func productionBuilder(withWikiHost wikiHost: String? = nil) -> APIURLComponentsBuilder {
            var components = URLComponents()
            components.host = wikiHost ?? Configuration.Domain.englishWikipedia
            components.scheme = Configuration.Scheme.https
            return APIURLComponentsBuilder(hostComponents: components, basePathComponents: Configuration.Path.restBaseAPIComponents)
        }
 
        // For staging and local, the host is the staging host and the wiki host is in the path:
        // https://mobileapps.wmflabs.org/en.wikipedia.org/v1/
        private static func stagingBuilderForAppsLabsPCS(withWikiHost wikiHost: String? = nil) -> APIURLComponentsBuilder {
            var components = URLComponents()
            components.scheme = Configuration.Scheme.https
            components.host = Configuration.Domain.appsLabs

            let host = wikiHost ?? Configuration.Domain.metaWiki
            let baseComponents = [host, "v1"]
            return APIURLComponentsBuilder(hostComponents: components, basePathComponents: baseComponents)
        }
        
        //// For staging and local, the host is the staging host and the wiki host is in the path: http://localhost:8888/en.wikipedia.org/v1/
        private static func localBuilderForPCS(withWikiHost wikiHost: String? = nil) -> APIURLComponentsBuilder {
            var components = URLComponents()
            components.scheme = Configuration.Scheme.http
            components.host = Configuration.Domain.localhost
            components.port = 8888

            let host = wikiHost ?? Configuration.Domain.metaWiki
            let baseComponents = [host, "v1"]
            return APIURLComponentsBuilder(hostComponents: components, basePathComponents: baseComponents)
        }

        // For staging and local, the host is the staging host and the wiki host is in the path: http://localhost:8889/en.wikipedia.org/v1/
        private static func localBuilderForAnnouncements(withWikiHost wikiHost: String? = nil) -> APIURLComponentsBuilder {
            var components = URLComponents()
            components.scheme = Configuration.Scheme.http
            components.host = Configuration.Domain.localhost
            components.port = 8889

            let host = wikiHost ?? Configuration.Domain.metaWiki
            let baseComponents = [host, "v1"]
            return APIURLComponentsBuilder(hostComponents: components, basePathComponents: baseComponents)
        }
    }
    
    /// MediaWiki API
    /// Doc for each wiki usually available at the API sandbox. Alter the domain for other wikis: https://en.wikipedia.org/wiki/Special:ApiSandbox
    struct MediaWiki {
        
        public enum BuilderType {
            case productionRest
            case production
            
            func builder(withWikiHost wikiHost: String? = nil) -> APIURLComponentsBuilder {
                switch self {
                case .productionRest:
                    return MediaWiki.productionRestBuilder(withWikiHost: wikiHost)
                case .production:
                    return MediaWiki.productionBuilder(withWikiHost: wikiHost)
                }
            }
        }
        
        private static func productionRestBuilder(withWikiHost wikiHost: String? = nil) -> APIURLComponentsBuilder {
            var components = URLComponents()
            components.host = wikiHost ?? Configuration.Domain.englishWikipedia
            components.scheme = Configuration.Scheme.https
            return APIURLComponentsBuilder(hostComponents: components, basePathComponents: Configuration.Path.mediaWikiRestAPIComponents)
        }
        
        private static func productionBuilder(withWikiHost wikiHost: String? = nil) -> APIURLComponentsBuilder {
            var components = URLComponents()
            components.host = wikiHost ?? Configuration.Domain.metaWiki
            components.scheme = Configuration.Scheme.https
            return APIURLComponentsBuilder(hostComponents: components, basePathComponents: Configuration.Path.mediaWikiAPIComponents)
        }
    }
    
    // This is still the MediaWiki API, but because there is no associated language, the calls to build these urls need to be slightly different.
    struct Wikidata {
        
        public enum BuilderType {
            case production
            case betaLabs
            
            func builder() -> APIURLComponentsBuilder {
                switch self {
                case .production:
                    return Wikidata.productionBuilder()
                case .betaLabs:
                    return Wikidata.betaLabsBuilder()
                }
            }
        }
        
        private static func productionBuilder() -> APIURLComponentsBuilder {
            var components = URLComponents()
            components.host =  "www.\(Configuration.Domain.wikidata)"
            components.scheme = Configuration.Scheme.https
            return APIURLComponentsBuilder(hostComponents: components, basePathComponents: Configuration.Path.mediaWikiAPIComponents)
        }
        
        private static func betaLabsBuilder() -> APIURLComponentsBuilder {
            var components = URLComponents()
            components.host = Configuration.Domain.wikidataBetaLabs
            components.scheme = Configuration.Scheme.https
            return APIURLComponentsBuilder(hostComponents: components, basePathComponents: Configuration.Path.mediaWikiAPIComponents)
        }
    }
    
    // This is still the MediaWiki API, but because there is no associated language, the calls to build these urls need to be slightly different.
    struct Commons {
        
        public enum BuilderType {
            case production
            case betaLabs
            
            func builder() -> APIURLComponentsBuilder {
                switch self {
                case .production:
                    return Commons.productionBuilder()
                case .betaLabs:
                    return Commons.betaLabsBuilder()
                }
            }
        }
        
        private static func productionBuilder() -> APIURLComponentsBuilder {
            var components = URLComponents()
            components.host =  "commons.\(Configuration.Domain.wikimedia)"
            components.scheme = Configuration.Scheme.https
            return APIURLComponentsBuilder(hostComponents: components, basePathComponents: Configuration.Path.mediaWikiAPIComponents)
        }
        
        private static func betaLabsBuilder() -> APIURLComponentsBuilder {
            var components = URLComponents()
            components.host = Configuration.Domain.commonsBetaLabs
            components.scheme = Configuration.Scheme.https
            return APIURLComponentsBuilder(hostComponents: components, basePathComponents: Configuration.Path.mediaWikiAPIComponents)
        }
    }
}
