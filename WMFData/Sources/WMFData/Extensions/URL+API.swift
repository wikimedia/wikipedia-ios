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
        
        guard let siteURL = project.siteURL,
        var components = URLComponents(url: siteURL, resolvingAgainstBaseURL: false) else {
            return nil
        }
        
        components.path = baseMediaWikiAPIPathComponents
        
        return components.url
    }
    
    static func wikimediaRestAPIURL(project: WMFProject, additionalPathComponents: [String]) -> URL? {
        guard let siteURL = project.siteURL,
        var components = URLComponents(url: siteURL, resolvingAgainstBaseURL: false) else {
            return nil
        }
        
        components.path = baseWikimediaRestAPIPathComponents + additionalPathComponents.joined(separator: "/")
        
        return components.url
    }
    
    static func mediaWikiRestAPIURL(project: WMFProject, additionalPathComponents: [String]) -> URL? {
        guard let siteURL = project.siteURL,
        var components = URLComponents(url: siteURL, resolvingAgainstBaseURL: false) else {
            return nil
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
    
    static func metricsAPIURL() -> URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.path = baseWikimediaRestAPIPathComponents + "metrics"
        components.host = "wikimedia.org"

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
    
    static func fundraisingCampaignConfigURL(environment: WMFServiceEnvironment = WMFDataEnvironment.current.serviceEnvironment) -> URL? {
        
        var components = URLComponents()
        components.scheme = "https"
        components.path = "/wiki/MediaWiki:AppsCampaignConfig.json"
        
        switch environment {
        case .production:
            components.host = "donate.wikimedia.org"
        case .staging:
            components.host = "test.wikipedia.org"
        }
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
        }
    }
}
