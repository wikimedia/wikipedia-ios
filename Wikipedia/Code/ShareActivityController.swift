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
}

extension ShareableArticlesProvider where Self: UIViewController & EventLoggingEventValuesProviding {
    func share(article: WMFArticle?, articleURL: URL?, at indexPath: IndexPath, dataStore: MWKDataStore, theme: Theme, eventLoggingCategory: EventLoggingCategory? = nil, eventLoggingLabel: EventLoggingLabel? = nil, sourceView: UIView?) -> Bool {
        if let article = article {
            return createAndPresentShareActivityController(for: article, at: indexPath, dataStore: dataStore, theme: theme, eventLoggingCategory: eventLoggingCategory, eventLoggingLabel: eventLoggingLabel, sourceView: sourceView)
        } else if let articleURL = articleURL, let key = articleURL.wmf_inMemoryKey {
            dataStore.articleSummaryController.updateOrCreateArticleSummaryForArticle(withKey: key) { (article, _) in
                guard let article = article else {
                    return
                }
                let _ = self.createAndPresentShareActivityController(for: article, at: indexPath, dataStore: dataStore, theme: theme, eventLoggingCategory: eventLoggingCategory, eventLoggingLabel: eventLoggingLabel, sourceView: sourceView)
            }
            return true
        }
        return false
    }
    
    fileprivate func createAndPresentShareActivityController(for article: WMFArticle, at indexPath: IndexPath, dataStore: MWKDataStore, theme: Theme, eventLoggingCategory: EventLoggingCategory?, eventLoggingLabel: EventLoggingLabel?, sourceView: UIView?) -> Bool {
        var customActivities: [UIActivity] = []
        let addToReadingListActivity = AddToReadingListActivity {
            let addArticlesToReadingListViewController = AddArticlesToReadingListViewController(with: dataStore, articles: [article], theme: theme)
            let navigationController = WMFThemeableNavigationController(rootViewController: addArticlesToReadingListViewController, theme: theme)
            navigationController.isNavigationBarHidden = true
            if let category = eventLoggingCategory, let label = eventLoggingLabel {
                addArticlesToReadingListViewController.eventLogAction = { ReadingListsFunnel.shared.logSave(category: category, label: label, articleURL: article.url) }
            }
            self.present(navigationController, animated: true, completion: nil)
        }
        customActivities.append(addToReadingListActivity)
        
        if let readingListDetailVC = self as? ReadingListDetailViewController {
            let moveToReadingListActivity = MoveToReadingListActivity {
                let addArticlesToReadingListViewController = AddArticlesToReadingListViewController(with: dataStore, articles: [article], moveFromReadingList: readingListDetailVC.readingList, theme: theme)
                let navigationController = WMFThemeableNavigationController(rootViewController: addArticlesToReadingListViewController, theme: theme)
                navigationController.isNavigationBarHidden = true
                self.present(navigationController, animated: true, completion: nil)
            }
            customActivities.append(moveToReadingListActivity)
        }
        
        let shareActivityController = ShareActivityController(article: article, customActivities: customActivities)
        if UIDevice.current.userInterfaceIdiom == .pad {
            shareActivityController.popoverPresentationController?.sourceView = sourceView ?? view
            shareActivityController.popoverPresentationController?.sourceRect = sourceView?.bounds ?? view.bounds
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
    
    @objc init(article: WMFArticle, customActivities: [UIActivity]) {

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
    
    @objc init(customActivity: UIActivity, article: WMFArticle, textActivitySource: WMFArticleTextActivitySource) {
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
    
    @objc init(article: WMFArticle, textActivitySource: WMFArticleTextActivitySource) {
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
    
    @objc init(article: WMFArticle, image: UIImage?, title: String) {
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
