
//helper methods to convert article URLs to and from desktop to mobile-html

import Foundation

public class ArticleURLConverter {
    
    public static func desktopURL(mobileHTMLURL: URL, configuration: Configuration = Configuration.current, scheme: String? = nil) -> URL? {
            
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
    
    public static func desktopURL(host: String, title: String, configuration: Configuration = Configuration.current, scheme: String? = nil) -> URL? {
        
        var components = configuration.articleURLForHost(host, appending: [title])
        
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
            let percentEncodedUrlTitle = (articleTitle as NSString)
                .wmf_denormalizedPageTitle()
                .addingPercentEncoding(withAllowedCharacters: .wmf_articleTitlePathComponentAllowed) else {
            return nil
        }
        
        //tonitodo: use wmf_normalizedPageTitle instead for an error-state redirect test
        
        //let pathComponents = ["page", endpointType.rawValue, percentEncodedUrlTitle]
        
        let stagingPathComponents = [host, "v1", "page", endpointType.rawValue, percentEncodedUrlTitle]
        var stagingURLComponents = URLComponents()
        stagingURLComponents.host = "apps.wmflabs.org"
        stagingURLComponents.path = "/\(stagingPathComponents.joined(separator: "/"))"
        guard let stagingUrl = stagingURLComponents.url else {
            return nil
        }
        
        //Staging: app://apps.wmflabs.org/en.wikipedia.org/v1/page/mobile-html/Brothers_Poem
        //Prod: app://en.wikipedia.org/api/rest_v1/page/mobile-html/Dog
        print(stagingUrl)
        
    //        guard let url: URL = configuration.wikipediaMobileAppsServicesAPIURLComponentsForHost(host, appending: pathComponents).url else {
    //            return nil
    //        }
        
        if let scheme = scheme {
            
            var urlComponents = URLComponents(url: stagingUrl, resolvingAgainstBaseURL: false)
            urlComponents?.scheme = scheme
            
            return urlComponents?.url
        }
        
        return stagingUrl
    }
}
