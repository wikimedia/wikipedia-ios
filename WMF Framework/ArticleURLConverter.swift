
//helper methods to convert article URLs to and from desktop to mobile-html

import Foundation

public class ArticleURLConverter {
    
    public static func desktopURL(host: String, title: String, configuration: Configuration = Configuration.current, scheme: String? = nil) -> URL? {
        guard let encodedTitle = title.percentEncodedPageTitleForPathComponents else {
            return nil
        }
        var components = configuration.articleURLForHost(host, appending: [encodedTitle])
        
        if let scheme = scheme {
            components.scheme = scheme
        }
        
        return components.url
    }

    public static func mobileHTMLURL(desktopURL:  URL, endpointType: ArticleFetcher.EndpointType, configuration: Configuration = Configuration.current, scheme: String? = nil) -> URL? {
        
        guard (desktopURL as NSURL).wmf_isWikiResource else {
            return nil
        }
        
        guard let title = desktopURL.wmf_title,
            let siteURL = desktopURL.wmf_site else {
                return nil
        }
        
        return mobileHTMLURL(siteURL: siteURL, articleTitle: title, endpointType: endpointType, configuration: configuration, scheme: scheme)
    }

    public static func mobileHTMLURL(siteURL: URL, articleTitle: String, endpointType: ArticleFetcher.EndpointType, configuration: Configuration = Configuration.current, scheme: String? = nil) -> URL? {
        guard let host = siteURL.host,
            let percentEncodedUrlTitle = articleTitle.percentEncodedPageTitleForPathComponents
        else {
            return nil
        }
        
        let pathComponents = ["page", endpointType.rawValue, percentEncodedUrlTitle]
        var components = configuration.wikipediaMobileAppsServicesAPIURLComponentsForHost(host, appending: pathComponents)
        if let scheme = scheme {
            components.scheme = scheme
        }
        return components.url
    }
}
