import Foundation

extension URL {
    
    private static let baseMediaWikiAPIPathComponents = "/w/api.php"
    
    static func mediaWikiAPIURL(project: WKProject) -> URL? {
        var components = URLComponents()
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
        
        return components.url
    }
    
    static func paymentMethodsAPIURL(environment: WKServiceEnvironment = WKDataEnvironment.current.serviceEnvironment) -> URL? {
        
        var components = URLComponents()
        components.scheme = "https"
        components.path = baseMediaWikiAPIPathComponents
        
        switch environment {
        case .production:
            components.host = "payments.wikimedia.org"
            return nil
        case .staging:
            components.host = "paymentstest4.wmcloud.org"
        }
        
        return components.url
    }
    
    static func donatePaymentSubmissionURL(environment: WKServiceEnvironment = WKDataEnvironment.current.serviceEnvironment) -> URL? {
        
        var components = URLComponents()
        components.scheme = "https"
        components.path = baseMediaWikiAPIPathComponents
        
        switch environment {
        case .production:
            components.host = "payments.wikimedia.org"
        case .staging:
            components.host = "paymentstest4.wmcloud.org"
        }
        
        return components.url
    }
    
    static func donateConfigURL(environment: WKServiceEnvironment = WKDataEnvironment.current.serviceEnvironment) -> URL? {
        
        var components = URLComponents()
        components.scheme = "https"
        components.path = "/wiki/MediaWiki:AppsDonationConfig.json"
        
        switch environment {
        case .production:
            components.host = "donate.wikimedia.org"
        case .staging:
            components.host = "test.wikipedia.org"
        }
        return components.url
    }
}
