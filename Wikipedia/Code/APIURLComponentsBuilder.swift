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

    /// RESTBase is a set of REST APIs utilized by the app for the feed, page summaries, page content, and others
    /// They exist on most wikis - example doc for enwiki, change the domain for other wikis: https://en.wikipedia.org/api/rest_v1/
    struct RESTBase {
        /// Returns a block that will return a builder for a given host. For production, the host is the host of the wiki: https://en.wikipedia.org/api/rest_v1/
        static func getProductionBuilderFactory() -> (String?) -> APIURLComponentsBuilder {
            return { (wikiHost: String?) in
                var components = URLComponents()
                components.host = wikiHost ?? Configuration.Domain.englishWikipedia
                components.scheme = Configuration.Scheme.https
                return APIURLComponentsBuilder(hostComponents: components, basePathComponents: Configuration.Path.restBaseAPIComponents)
            }
        }
        /// Returns a block that will return a staging builder for a given host. For staging, the host is the staging host and the wiki host is in the path: https://mobileapps.wmflabs.org/en.wikipedia.org/v1/
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
    
    /// MediaWiki API
    /// Doc for each wiki usually available at the API sandbox. Alter the domain for other wikis: https://en.wikipedia.org/wiki/Special:ApiSandbox
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
