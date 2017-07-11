@objc(WMFShareActivityController)
class ShareActivityController: UIActivityViewController {
    
    init(url: URL, userDataStore: MWKDataStore) {
        let article = userDataStore.fetchArticle(with: url)
        var items = [Any]()
        let text: String
        
        if let article = article, let title = article.displayTitle {
            text = "\"\(title)\" on @Wikipedia"
            items.append(text)
        }
        
        items.append(url)
        
        if let mapItem = article?.mapItem {
            items.append(mapItem)
        }
        
        super.init(activityItems: items, applicationActivities: [TUSafariActivity(), WMFOpenInMapsActivity(), WMFGetDirectionsInMapsActivity()])
        
    }
    
    init(url: URL, userDataStore: MWKDataStore, context: AnalyticsContextProviding) {
        let article = userDataStore.fetchArticle(with: url)
        var items = [Any]()
        let text: String
        
        if let article = article {
            if let title = article.displayTitle {
                text = "\"\(title)\" on @Wikipedia"
                items.append(text)
            }
            let tracker = PiwikTracker.sharedInstance()
            tracker?.wmf_logActionShare(inContext: context, contentType: article)
        }
        
        items.append(url)
        
        
        if let mapItem = article?.mapItem {
            items.append(mapItem)
        }
        
        super.init(activityItems: items, applicationActivities: [TUSafariActivity(), WMFOpenInMapsActivity(), WMFGetDirectionsInMapsActivity()])
        
    }
    
    init(article: WMFArticle, context: AnalyticsContextProviding) {
        //        guard let url = article.url else {
        //            return
        //        }
        
        let tracker = PiwikTracker.sharedInstance()
        tracker?.wmf_logActionShare(inContext: context, contentType: article)
        
        var items = [Any]()
        let text: String
        
        if let title = article.displayTitle {
            text = "\"\(title)\" on @Wikipedia"
            items.append(text)
        }
        
        if let url = article.url {
            items.append(url)
        }
        
        if let mapItem = article.mapItem {
            items.append(mapItem)
        }
        
        super.init(activityItems: items, applicationActivities: [TUSafariActivity(), WMFOpenInMapsActivity(), WMFGetDirectionsInMapsActivity()])
        
    }
    
}
