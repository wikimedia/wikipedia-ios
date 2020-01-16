public struct APIURLComponentsBuilder {
    let hostComponents: URLComponents
    let basePathComponents: [String]
    
    func components(byAppending pathComponents: [String] = [], queryParameters: [String: Any]? = nil) -> URLComponents {
        var components = hostComponents
        components.replacePercentEncodedPathWithPathComponents(basePathComponents + pathComponents)
        components.replacePercentEncodedQueryWithQueryParameters(queryParameters)
        return components
    }
    
    struct MobileApps {
        static func getProductionBuilderFactory() -> (String?) -> APIURLComponentsBuilder {
            return { (wikiHost: String?) in
                var components = URLComponents()
                components.host = wikiHost ?? Configuration.Domain.englishWikipedia
                components.scheme = Configuration.Scheme.https
                return APIURLComponentsBuilder(hostComponents: components, basePathComponents: Configuration.Path.mobileAppsServicesAPIComponents)
            }
        }
        static func getStagingBuilderFactory(with hostComponents: URLComponents) -> (String?) -> APIURLComponentsBuilder {
            return { (wikiHost: String?) in
                let host = wikiHost ?? Configuration.Domain.metaWiki
                let baseComponents = [host, "v1"]
                var components = URLComponents()
                components.scheme = hostComponents.scheme
                components.host = hostComponents.host
                components.port = hostComponents.port
                return APIURLComponentsBuilder(hostComponents: components, basePathComponents: baseComponents)
            }
        }
    }
    
    struct MediaWiki {
        static func getProductionBuilderFactory() -> (String?) -> APIURLComponentsBuilder {
            return { (wikiHost: String?) in
                var components = URLComponents()
                components.host = wikiHost ?? Configuration.Domain.englishWikipedia
                components.scheme = Configuration.Scheme.https
                return APIURLComponentsBuilder(hostComponents: components, basePathComponents: Configuration.Path.mediaWikiRestAPIComponents)
            }
        }
        static func getLocalBuilderFactory() -> (String?) -> APIURLComponentsBuilder {
            return { (wikiHost: String?) in
                var components = URLComponents()
                components.host = wikiHost ?? Configuration.Domain.englishWikipedia
                components.scheme = Configuration.Scheme.http
                components.host = Configuration.Domain.localhost
                components.port = 8080
                return APIURLComponentsBuilder(hostComponents: components, basePathComponents: Configuration.Path.mediaWikiRestAPIComponents)
            }
        }
    }
}
