@objc(WMFShareActivityController)
class ShareActivityController: UIActivityViewController {
    
    init(articleURL: URL, userDataStore: MWKDataStore, context: AnalyticsContextProviding) {
        let article = userDataStore.fetchArticle(with: articleURL)
        var items = [Any]()
        
        if let article = article {
            if let title = article.displayTitle {
                let text = "\"\(title)\" on @Wikipedia"
                items.append(text)
            }
            let tracker = PiwikTracker.sharedInstance()
            tracker?.wmf_logActionShare(inContext: context, contentType: article)
        }
        
        var components = URLComponents(url: articleURL, resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "wprov", value: "sfti1")]

        if let url = components?.url {
            items.append(url)
        }
        
        if let mapItem = article?.mapItem {
            items.append(mapItem)
        }
        
        super.init(activityItems: items, applicationActivities: [TUSafariActivity(), WMFOpenInMapsActivity(), WMFGetDirectionsInMapsActivity()])
    }
    
    init(article: WMFArticle, context: AnalyticsContextProviding) {
        let tracker = PiwikTracker.sharedInstance()
        tracker?.wmf_logActionShare(inContext: context, contentType: article)
        
        var items = [Any]()
        
        if let title = article.displayTitle {
            let text = "\"\(title)\" on @Wikipedia"
            items.append(text)
        }
        
        if let articleURL = article.url {
            var components = URLComponents(url: articleURL, resolvingAgainstBaseURL: false)
            components?.queryItems = [URLQueryItem(name: "wprov", value: "sfti1")]
            
            if let url = components?.url {
                items.append(url)
            }
            
        }

        if let mapItem = article.mapItem {
            items.append(mapItem)
        }
        
        super.init(activityItems: items, applicationActivities: [TUSafariActivity(), WMFOpenInMapsActivity(), WMFGetDirectionsInMapsActivity()])
    }
    
    init(article: MWKArticle, textActivitySource: WMFArticleTextActivitySource) {
        var items = [Any]()
        items.append(textActivitySource)
        
        if let articleURL = article.url {
            var components = URLComponents(url: articleURL, resolvingAgainstBaseURL: false)
            components?.queryItems = [URLQueryItem(name: "wprov", value: "sfti1")]
            
            if let url = components?.url {
                items.append(url)
            }
            
        }
        
        if let mapItem = article.mapItem {
            items.append(mapItem)
        }
        
        super.init(activityItems: items, applicationActivities: [TUSafariActivity(), WMFOpenInMapsActivity(), WMFGetDirectionsInMapsActivity()])
    }
    
    init(article: MWKArticle, image: UIImage?, title: String) {
        var queryItem: URLQueryItem
        var items = [Any]()
        
        items.append(title)
        
        if let image = image {
            queryItem = URLQueryItem(name: "wprov", value: "sfii1")
            items.append(image)
        } else {
            queryItem = URLQueryItem(name: "wprov", value: "sfti1")
        }
        
        if let articleURL = article.url {
            var components = URLComponents(url: articleURL, resolvingAgainstBaseURL: false)
            components?.queryItems = [queryItem]
            
            if let url = components?.url {
                items.append(url)
            }
            
        }
        
        super.init(activityItems: items, applicationActivities: [])
    }
    
    init(imageInfo: MWKImageInfo, imageDownload: ImageDownload) {
        var items = [Any]()
        
        items.append(contentsOf: [WMFImageTextActivitySource(info: imageInfo),WMFImageURLActivitySource(info: imageInfo), imageDownload.image.staticImage])
        
        super.init(activityItems: items, applicationActivities: [])
    }
    
}
