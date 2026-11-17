import CryptoKit
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
        
        let encodedPathComponents = additionalPathComponents.compactMap { $0.addingPercentEncoding(withAllowedCharacters: .encodeURIComponentAllowed) }
        components.percentEncodedPath = baseMediaWikiRestAPIPathComponents + encodedPathComponents.joined(separator: "/")
        
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
    
    /// The URL of the original file of a Wikimedia Commons file page. Commons stores each original
    /// under a path that comes from the MD5 hash of the file name, so no API request is necessary.
    /// - Parameter fileName: The name without the "File:" prefix, for example "09 Sports.png".
    static func commonsUploadURL(fileName: String) -> URL? {
        let name = fileName.replacingOccurrences(of: " ", with: "_")
        let hash = Insecure.MD5.hash(data: Data(name.utf8)).map { String(format: "%02x", $0) }.joined()

        var components = URLComponents()
        components.scheme = "https"
        components.host = "upload.wikimedia.org"
        components.path = "/wikipedia/commons/\(hash.prefix(1))/\(hash.prefix(2))/\(name)"

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
