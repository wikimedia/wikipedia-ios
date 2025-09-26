import Foundation

extension URL {
    
    // https://www.mediawiki.org/wiki/API:Main_page
    private static let baseMediaWikiAPIPathComponents = "/w/api.php"
    private static let basePaymentWikiAPIPathComponents = "/api.php"
    
    // https://www.mediawiki.org/wiki/Wikimedia_REST_API
    private static let baseWikimediaRestAPIPathComponents = "/api/rest_v1/"
    
    // https://www.mediawiki.org/wiki/API:REST_API
    private static let baseMediaWikiRestAPIPathComponents = "/w/rest.php/"
    
    static func mediaWikiAPIURL(project: WMFProject) -> URL? {
        
        var components = URLComponents()
        switch WMFDataEnvironment.current.serviceEnvironment {
        case .local:
            components.scheme = "http"
            components.host = "127.0.0.1"
            components.port = 8080
            components.path = baseMediaWikiAPIPathComponents
        
        default:
            components.scheme = "https"
            components.path = baseMediaWikiAPIPathComponents
            
            switch project {
            case .wikipedia(let language):
                components.host = "\(language.languageCode).wikipedia.org"
            case .commons:
                components.host = "commons.wikimedia.org"
            case .wikidata:
                components.host = "www.wikidata.org"
            }
        }
        
        return components.url
        
    }
    
    static func wikimediaRestAPIURL(project: WMFProject, additionalPathComponents: [String]) -> URL? {
        var components = URLComponents()
        components.scheme = "https"
        
        switch project {
        case .wikipedia(let language):
            components.host = "\(language.languageCode).wikipedia.org"
        case .commons:
            components.host = "commons.wikimedia.org"
        case .wikidata:
            components.host = "www.wikidata.org"
        }
        
        components.path = baseWikimediaRestAPIPathComponents + additionalPathComponents.joined(separator: "/")
        
        return components.url
    }
    
    static func mediaWikiRestAPIURL(project: WMFProject, additionalPathComponents: [String]) -> URL? {
        var components = URLComponents()
        components.scheme = "https"
        
        switch project {
        case .wikipedia(let language):
            components.host = "\(language.languageCode).wikipedia.org"
        case .commons:
            components.host = "commons.wikimedia.org"
        case .wikidata:
            components.host = "www.wikidata.org"
        }
        
        components.path = baseMediaWikiRestAPIPathComponents + additionalPathComponents.joined(separator: "/")
        
        return components.url
    }
    
    static func paymentMethodsAPIURL(environment: WMFServiceEnvironment = WMFDataEnvironment.current.serviceEnvironment) -> URL? {
        
        var components = URLComponents()
        components.scheme = "https"
        components.path = basePaymentWikiAPIPathComponents
        components.host = "payments.wikimedia.org"

        return components.url
    }
    
    static func donatePaymentSubmissionURL(environment: WMFServiceEnvironment = WMFDataEnvironment.current.serviceEnvironment) -> URL? {
        
        var components = URLComponents()
        components.scheme = "https"
        components.path = basePaymentWikiAPIPathComponents
        components.host = "payments.wikimedia.org"
        
        return components.url
    }
    
    static func donateConfigURL(environment: WMFServiceEnvironment = WMFDataEnvironment.current.serviceEnvironment) -> URL? {
        
        var components = URLComponents()

        switch environment {
        case .production:
            components.host = "donate.wikimedia.org"
            components.scheme = "https"
        case .staging:
            components.host = "test.wikipedia.org"
            components.scheme = "https"
        case .local:
            components.host = "127.0.0.1"
            components.scheme = "http"
            components.port = 8080
        }
        
        components.path = "/wiki/MediaWiki:AppsDonationConfig.json"
        return components.url
    }
    
    static func fundraisingCampaignConfigURL(environment: WMFServiceEnvironment = WMFDataEnvironment.current.serviceEnvironment) -> URL? {
        
        var components = URLComponents()

        switch environment {
        case .production:
            components.host = "donate.wikimedia.org"
            components.scheme = "https"
        case .staging:
            components.host = "test.wikipedia.org"
            components.scheme = "https"
        case .local:
            components.host = "127.0.0.1"
            components.scheme = "http"
            components.port = 8080
        }
        
        components.path = "/wiki/MediaWiki:AppsCampaignConfig.json"
        return components.url
    }
    
    static func featureConfigURL(environment: WMFServiceEnvironment = WMFDataEnvironment.current.serviceEnvironment, project: WMFProject) -> URL? {
        
        switch environment {
        case .production:
            return wikimediaRestAPIURL(project: project, additionalPathComponents: ["feed","configuration"])
        case .staging:
            var components = URLComponents()
            components.scheme = "https"
            components.path = "/wiki/MediaWiki:AppsFeatureConfig.json"
            components.host = "test.wikipedia.org"
            components.queryItems = [URLQueryItem(name: "action", value: "raw")]
            return components.url
        case .local:
            var components = URLComponents()
            components.scheme = "http"
            components.path = "/wiki/MediaWiki:AppsFeatureConfig.json"
            components.host = "127.0.0.1"
            components.port = 8080
            components.queryItems = [URLQueryItem(name: "action", value: "raw")]
            return components.url
            
        }
    }
}
