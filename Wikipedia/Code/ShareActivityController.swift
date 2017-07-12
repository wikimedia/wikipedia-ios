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
        
        if let url = URL(string: "\(articleURL.absoluteString)?wprov=sfti1") {
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
        
        if let articleURL = article.url, let url = URL(string: "\(articleURL.absoluteString)?wprov=sfti1") {
            items.append(url)
        }
        
        if let mapItem = article.mapItem {
            items.append(mapItem)
        }
        
        super.init(activityItems: items, applicationActivities: [TUSafariActivity(), WMFOpenInMapsActivity(), WMFGetDirectionsInMapsActivity()])
    }
    
    init(article: MWKArticle, textActivitySource: WMFArticleTextActivitySource) {
        var items = [Any]()
        items.append(textActivitySource)
        
        if let articleURL = article.url, let url = URL(string: "\(articleURL.absoluteString)?wprov=sfti1") {
            items.append(url)
        }
        
        if let mapItem = article.mapItem {
            items.append(mapItem)
        }
        
        super.init(activityItems: items, applicationActivities: [TUSafariActivity(), WMFOpenInMapsActivity(), WMFGetDirectionsInMapsActivity()])
    }
    
    init(article: MWKArticle, image: UIImage?, title: String) {
        var param: String
        var items = [Any]()
        
        items.append(title)
        
        if let image = image {
            param = "wprov=sfii1"
            items.append(image)
        } else {
            param = "wprov=sfti1"
        }
        
        if article.url != nil, let url = URL(string: "\(article.url.absoluteString)?\(param)") {
            items.append(url)
        }
        
        super.init(activityItems: items, applicationActivities: [])
    }
    
    init(imageInfo: MWKImageInfo, imageDownload: ImageDownload) {
        var items = [Any]()
        
        items.append(contentsOf: [WMFImageTextActivitySource(info: imageInfo),WMFImageURLActivitySource(info: imageInfo), imageDownload.image.staticImage])
        
        super.init(activityItems: items, applicationActivities: [])
    }
    
}
