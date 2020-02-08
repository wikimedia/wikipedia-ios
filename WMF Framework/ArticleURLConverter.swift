
//helper methods to convert article URLs to and from desktop to mobile-html

import Foundation

public class ArticleURLConverter {
    
    public static func desktopURL(mobileHTMLURL: URL, configuration: Configuration = Configuration.appsLabs, scheme: String? = nil) -> URL? {
            
        let pathComponents = mobileHTMLURL.pathComponents
        
        //validation - confirm 2nd to last component containts 'mobile-html'
        guard let mobileHTMLPathComponent = pathComponents[safeIndex: pathComponents.count - 2],
            mobileHTMLPathComponent == ArticleFetcher.EndpointType.mobileHTML.rawValue else {
                return nil
        }
        
        guard let stagingHost = pathComponents[safeIndex: 1],
            let title = pathComponents.last else {
            return nil
        }
        
        return desktopURL(host: stagingHost, title: title, configuration: configuration, scheme: scheme)
    }
    
    public static func desktopURL(host: String, title: String, configuration: Configuration = Configuration.appsLabs, scheme: String? = nil) -> URL? {
        guard let encodedTitle = title.percentEncodedPageTitleForPathComponents else {
            return nil
        }
        var components = configuration.articleURLForHost(host, appending: [encodedTitle])
        
        if let scheme = scheme {
            components.scheme = scheme
        }
        
        return components.url
    }

    public static func mobileHTMLURL(desktopURL:  URL, endpointType: ArticleFetcher.EndpointType, configuration: Configuration = Configuration.appsLabs, scheme: String? = nil) -> URL? {
        
        guard (desktopURL as NSURL).wmf_isWikiResource else {
            return nil
        }
        
        guard let title = desktopURL.wmf_title,
            let siteURL = desktopURL.wmf_site else {
                return nil
        }
        
        return mobileHTMLURL(siteURL: siteURL, articleTitle: title, endpointType: endpointType, configuration: configuration, scheme: scheme)
    }

    public static func mobileHTMLURL(siteURL: URL, articleTitle: String, endpointType: ArticleFetcher.EndpointType, configuration: Configuration = Configuration.appsLabs, scheme: String? = nil) -> URL? {
        guard let host = siteURL.host,
            let percentEncodedUrlTitle = articleTitle.percentEncodedPageTitleForPathComponents
        else {
            return nil
        }
        
        //tonitodo: use wmf_normalizedPageTitle instead for an error-state redirect test
        let pathComponents = ["page", endpointType.rawValue, percentEncodedUrlTitle]
        var components = configuration.wikipediaMobileAppsServicesAPIURLComponentsForHost(host, appending: pathComponents)
        if let scheme = scheme {
            components.scheme = scheme
        }
        return components.url
    }
    
    public static func mobileHTMLPreviewRequest(desktopURL:  URL, wikitext: String) throws -> URLRequest {
        guard
            let articleTitle = desktopURL.wmf_title,
            let percentEncodedTitle = articleTitle.percentEncodedPageTitleForPathComponents,
            let url = Configuration.appsLabs.wikipediaMobileAppsServicesAPIURLComponentsForHost(desktopURL.host, appending: ["transform", "wikitext", "to", "mobile-html", percentEncodedTitle]).url
        else {
            throw RequestError.invalidParameters
        }
        let params: [String: String] = ["wikitext": wikitext]
        let paramsJSON = try JSONEncoder().encode(params)
        var request = URLRequest(url: url)
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = paramsJSON
        request.httpMethod = "POST"
        return request
    }
}
