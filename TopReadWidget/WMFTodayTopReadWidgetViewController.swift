import UIKit
import NotificationCenter
import WMFUI
import WMFModel

class WMFTodayTopReadWidgetViewController: UIViewController, NCWidgetProviding {
    
    
    @IBOutlet weak var stackView: UIStackView!
    
    var snapshotView: UIView?
    
    let cellReuseIdentifier = "articleList"
    let articlePreviewFetcher = WMFArticlePreviewFetcher()
    let mostReadFetcher = WMFMostReadTitleFetcher()
    var maximumSize = CGSizeZero
    var maximumRowCount = 3
    var results: [MWKSearchResult] = []
    var articlePreviewViewControllers: [WMFArticlePreviewViewController] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let context = self.extensionContext {
            context.widgetLargestAvailableDisplayMode = .Expanded
            let mode = context.widgetActiveDisplayMode
            widgetActiveDisplayModeDidChange(mode, withMaximumSize: context.widgetMaximumSizeForDisplayMode(mode))
        }
        
        widgetPerformUpdate { (result) in
            
        }
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        
        guard let viewToFade = snapshotView else {
            return
        }
        coordinator.animateAlongsideTransition({ (context) in
            viewToFade.alpha = 0
            self.stackView.alpha = 1
            self.stackView.frame = CGRect(origin: CGPointZero, size: size)

            }) { (context) in
            viewToFade.removeFromSuperview()
            self.snapshotView = nil
        }
    }
    
    func widgetActiveDisplayModeDidChange(activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        maximumRowCount = activeDisplayMode == .Compact ? 1 : 3
        maximumSize = maxSize
        updateView()
    }
    
    func updateView() {
        var i = 0
        let count = min(results.count, maximumRowCount)
        var didRemove = false
        var didAdd = false
        let newSnapshot = view.snapshotViewAfterScreenUpdates(false)
        while i < count {
            var vc: WMFArticlePreviewViewController
            if (i < articlePreviewViewControllers.count) {
                vc = articlePreviewViewControllers[i]
            } else {
                vc = WMFArticlePreviewViewController()
                articlePreviewViewControllers.append(vc)
            }
            if vc.parentViewController == nil {
                addChildViewController(vc)
                stackView.addArrangedSubview(vc.view)
                vc.didMoveToParentViewController(self)
                didAdd = true
            }
            let result = results[i]
            vc.titleLabel.text = result.displayTitle
            vc.subtitleLabel.text = result.wikidataDescription
            vc.imageView.wmf_reset()

            if let imageURL = result.thumbnailURL {
                vc.imageView.wmf_setImageWithURL(imageURL, detectFaces: true, onGPU: true, failure: WMFIgnoreErrorHandler, success: WMFIgnoreSuccessHandler)
            }
            i += 1
        }
        while i < articlePreviewViewControllers.count {
            let vc = articlePreviewViewControllers[i]
            if vc.parentViewController != nil {
                vc.willMoveToParentViewController(nil)
                vc.view.removeFromSuperview()
                stackView.removeArrangedSubview(vc.view)
                vc.removeFromParentViewController()
                didRemove = true
            }
            i += 1
        }
        
        
        if let snapshot = newSnapshot where didRemove || didAdd {
            snapshot.frame = view.bounds
            view.addSubview(snapshot)
            snapshotView = snapshot
        }
        
        if didAdd {
            stackView.alpha = 0
        }
        
        var size = stackView.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize, withHorizontalFittingPriority: UILayoutPriorityRequired, verticalFittingPriority: UILayoutPriorityDefaultLow)
        size.width = maximumSize.width
        preferredContentSize = size
        
        stackView.frame = CGRect(origin: CGPointZero, size: size)
    }
    
    func widgetPerformUpdate(completionHandler: ((NCUpdateResult) -> Void)) {
        
        let siteURL = NSURL.wmf_URLWithDefaultSiteAndCurrentLocale()
        
        mostReadFetcher.fetchMostReadTitlesForSiteURL(siteURL, date: NSDate().wmf_bestMostReadFetchDate()).then { (result) -> AnyPromise in
            
            guard let mostReadTitlesResponse = result as? WMFMostReadTitlesResponseItem else {
                completionHandler(.NoData)
                return AnyPromise(value: nil)
            }
            
            let articleURLs = mostReadTitlesResponse.articles.map({ (article) -> NSURL in
                return siteURL.wmf_URLWithTitle(article.titleText)
            })
            
            return self.articlePreviewFetcher.fetchArticlePreviewResultsForArticleURLs(articleURLs, siteURL: siteURL, extractLength: 0, thumbnailWidth: UIScreen.mainScreen().wmf_listThumbnailWidthForScale().unsignedIntegerValue)
            }.then { (result) -> AnyPromise in
                guard let articlePreviewResponse = result as? [MWKSearchResult] else {
                    completionHandler(.NoData)
                    return AnyPromise(value: nil)
                }
                
                self.results = articlePreviewResponse.filter({ (result) -> Bool in
                    return result.articleID != 0
                })
                
                self.updateView()
                completionHandler(.NewData)
                return AnyPromise(value: articlePreviewResponse)
        }
        
    }
    
    
    
}
