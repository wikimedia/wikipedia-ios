@objc(WMFShareActivityController)
class ShareActivityController: UIActivityViewController {
    
    fileprivate let tracker = PiwikTracker.sharedInstance()
    
    init(with url: URL, userDataStore: MWKDataStore) {
        let article = userDataStore.fetchArticle(with: url)
        var items = [Any]()
        let text: String
        
        if let article = article, let title = article.displayTitle {
            text = "\"\(title)\" on @Wikipedia"
            items.append(text)
        }
        
        if NSURL.wmf_desktopURL(for: url) != nil {
            var components = URLComponents.init(url: url, resolvingAgainstBaseURL: false)
            
            let queryItem = URLQueryItem.init(name: "wprov", value: "sfsi1")
            components?.queryItems = [queryItem]
            
            if let componentsURL = components?.url {
                items.append(componentsURL)
            }
        }
        
        if let mapItem = article?.mapItem {
            items.append(mapItem)
        }
        
        super.init(activityItems: items, applicationActivities: [TUSafariActivity(), WMFOpenInMapsActivity(), WMFGetDirectionsInMapsActivity()])
        
    }
    
}
