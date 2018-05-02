@objc(WMFCustomShareActivity)
class CustomShareActivity: UIActivity {
    let title: String
    let imageName: String
    let action: () -> Void
    
    @objc public init(title: String, imageName: String, action: @escaping () -> Void) {
        self.title = title
        self.imageName = imageName
        self.action = action
    }
    
    override var activityTitle: String? {
        return title
    }
    
    override var activityImage: UIImage? {
        return UIImage(named: imageName)
    }
    
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        return true
    }
    
    override func perform() {
        action()
    }
    
}

protocol ShareableArticlesProvider: NSObjectProtocol {
    func share(article: WMFArticle?, articleURL: URL?, at indexPath: IndexPath, dataStore: MWKDataStore, theme: Theme) -> Bool
}

extension ShareableArticlesProvider where Self: ColumnarCollectionViewController & AnalyticsContextProviding {
    func share(article: WMFArticle?, articleURL: URL?, at indexPath: IndexPath, dataStore: MWKDataStore, theme: Theme) -> Bool {
        if let article = article {
            return createAndPresentShareActivityController(for: article, at: indexPath, dataStore: dataStore, theme: theme)
        } else if let articleURL = articleURL {
            dataStore.viewContext.wmf_updateOrCreateArticleSummariesForArticles(withURLs: [articleURL], completion: { (articles) in
                guard let first = articles.first else {
                    return
                }
                let _ = self.createAndPresentShareActivityController(for: first, at: indexPath, dataStore: dataStore, theme: theme)
            })
            return true
        }
        return false
    }
    
    fileprivate func createAndPresentShareActivityController(for article: WMFArticle, at indexPath: IndexPath, dataStore: MWKDataStore, theme: Theme) -> Bool {
        var customActivities: [UIActivity] = []
        let addToReadingListActivity = AddToReadingListActivity {
            let addArticlesToReadingListViewController = AddArticlesToReadingListViewController(with: dataStore, articles: [article], theme: theme)
            self.present(addArticlesToReadingListViewController, animated: true, completion: nil)
        }
        customActivities.append(addToReadingListActivity)
        
        if let readingListDetailVC = self as? ReadingListDetailViewController {
            let moveToReadingListActivity = MoveToReadingListActivity {
                let addArticlesToReadingListViewController = AddArticlesToReadingListViewController(with: dataStore, articles: [article], moveFromReadingList: readingListDetailVC.readingList, theme: theme)
                self.present(addArticlesToReadingListViewController, animated: true, completion: nil)
            }
            customActivities.append(moveToReadingListActivity)
        }
        
        let shareActivityController = ShareActivityController(article: article, context: self, customActivities: customActivities)
        if UIDevice.current.userInterfaceIdiom == .pad {
            let cell = collectionView.cellForItem(at: indexPath)
            shareActivityController.popoverPresentationController?.sourceView = cell ?? view
            shareActivityController.popoverPresentationController?.sourceRect = cell?.bounds ?? view.bounds
        }
        shareActivityController.excludedActivityTypes = [.addToReadingList]
        present(shareActivityController, animated: true, completion: nil)
        return true
    }
}

@objc(WMFAddToReadingListActivity)
class AddToReadingListActivity: UIActivity {
    private let action: () -> Void
    
    @objc init(action: @escaping () -> Void) {
        self.action = action
    }
    
    override var activityTitle: String? {
        return CommonStrings.addToReadingListActionTitle
    }
    
    override var activityImage: UIImage? {
        return UIImage(named: "add-to-reading-list")
    }
    
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        return true
    }
    
    override func perform() {
        action()
    }
}

@objc(WMFMoveToReadingListActivity)
class MoveToReadingListActivity: UIActivity {
    private let action: () -> Void
    
    @objc init(action: @escaping () -> Void) {
        self.action = action
    }
    
    override var activityTitle: String? {
        return CommonStrings.moveToReadingListActionTitle
    }
    
    override var activityImage: UIImage? {
        return UIImage(named: "move-to-reading-list")
    }
    
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        return true
    }
    
    override func perform() {
        action()
    }
}

@objc(WMFShareActivityController)
class ShareActivityController: UIActivityViewController {
    
    private var articleApplicationActivities: [UIActivity] = [TUSafariActivity(), WMFOpenInMapsActivity(), WMFGetDirectionsInMapsActivity()]
    
    @objc init(article: WMFArticle, context: AnalyticsContextProviding, customActivities: [UIActivity]) {
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
        
        articleApplicationActivities.append(contentsOf: customActivities)
        super.init(activityItems: items, applicationActivities: articleApplicationActivities)
    }
    
    @objc init(customActivity: UIActivity, article: MWKArticle, textActivitySource: WMFArticleTextActivitySource) {
        var items = [Any]()
        items.append(textActivitySource)
        
        if let shareURL = article.url?.wmf_URLForTextSharing {
            items.append(shareURL)
        }
        
        if let mapItem = article.mapItem {
            items.append(mapItem)
        }
        
        articleApplicationActivities.append(customActivity)
        super.init(activityItems: items, applicationActivities: articleApplicationActivities)
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
        
        super.init(activityItems: items, applicationActivities: articleApplicationActivities)
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

        let image = imageDownload.image
        let imageToShare: Any = image.animatedImage?.data ?? image.staticImage

        items.append(contentsOf: [WMFImageTextActivitySource(info: imageInfo), WMFImageURLActivitySource(info: imageInfo), imageToShare])
        
        super.init(activityItems: items, applicationActivities: [])
    }
    
}
