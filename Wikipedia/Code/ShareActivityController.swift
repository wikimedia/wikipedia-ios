@objc(WMFShareActivityController)
class ShareActivityController: UIActivityViewController {
    
    @objc init(articleURL: URL, userDataStore: MWKDataStore, context: AnalyticsContextProviding) {
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
        
        items.append(articleURL.wmf_URLForTextSharing)
        
        if let mapItem = article?.mapItem {
            items.append(mapItem)
        }
        
        super.init(activityItems: items, applicationActivities: [TUSafariActivity(), WMFOpenInMapsActivity(), WMFGetDirectionsInMapsActivity()])
    }
    
    @objc init(article: WMFArticle, context: AnalyticsContextProviding) {
        let tracker = PiwikTracker.sharedInstance()
        tracker?.wmf_logActionShare(inContext: context, contentType: article)
        
        var items = [Any]()
        
        if let title = article.displayTitle {
            let text = "\"\(title)\" on @Wikipedia"
            items.append(text)
        }
        
        if let shareURL = article.url?.wmf_URLForTextSharing {
            items.append(shareURL)
        }

        if let mapItem = article.mapItem {
            items.append(mapItem)
        }
        
        super.init(activityItems: items, applicationActivities: [TUSafariActivity(), WMFOpenInMapsActivity(), WMFGetDirectionsInMapsActivity()])
    }
    
    @objc init(article: MWKArticle, textActivitySource: WMFArticleTextActivitySource) {
        var items = [Any]()
        items.append(textActivitySource)
        
        if let shareURL = article.url?.wmf_URLForTextSharing {
            items.append(shareURL)
        }
        
        if let mapItem = article.mapItem {
            items.append(mapItem)
        }
        
        super.init(activityItems: items, applicationActivities: [TUSafariActivity(), WMFOpenInMapsActivity(), WMFGetDirectionsInMapsActivity()])
    }
    
    @objc init(article: MWKArticle, image: UIImage?, title: String) {
        var items = [Any]()
        
        items.append(title)
        
        let shareURL: URL?
        if let image = image {
            items.append(image)
            shareURL = article.url?.wmf_URLForImageSharing
        } else {
            shareURL = article.url?.wmf_URLForTextSharing
        }
        
        if let shareURL = shareURL {
            items.append(shareURL)
        }
        
        super.init(activityItems: items, applicationActivities: [])
    }
    
    @objc init(imageInfo: MWKImageInfo, imageDownload: ImageDownload) {
        var items = [Any]()
        
        items.append(contentsOf: [WMFImageTextActivitySource(info: imageInfo),WMFImageURLActivitySource(info: imageInfo), imageDownload.image.staticImage])
        
        super.init(activityItems: items, applicationActivities: [])
    }
    
}
