import UIKit
import NotificationCenter
import WMFUI
import WMFModel

class WMFTodayTopReadWidgetViewController: UIViewController, NCWidgetProviding {
    
    
    @IBOutlet weak var stackView: UIStackView!
    
    let cellReuseIdentifier = "articleList"
    let articlePreviewFetcher = WMFArticlePreviewFetcher()
    let mostReadFetcher = WMFMostReadTitleFetcher()
    var maximumSize = CGSizeZero
    var maximumRowCount = 3
    var results: [MWKSearchResult] = []
    var articlePreviewViewControllers: [WMFArticlePreviewViewController] = []
    var addedVCs: [WMFArticlePreviewViewController] = []
    var removedVCs: [WMFArticlePreviewViewController] = []
    
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
        
        for vc in addedVCs {
            vc.view.alpha = 0
        }
        
        for vc in removedVCs {
            vc.view.alpha = 1
        }
   
        coordinator.animateAlongsideTransition({ (context) in
            for vc in self.addedVCs {
                vc.view.alpha = 1
            }
            for vc in self.removedVCs {
                vc.view.alpha = 0
            }
            }) { (context) in
                self.addedVCs = []
                self.removedVCs = []
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
        while i < count {
            var vc: WMFArticlePreviewViewController
            if (i < articlePreviewViewControllers.count) {
                vc = articlePreviewViewControllers[i]
            } else {
                vc = WMFArticlePreviewViewController()
                articlePreviewViewControllers.append(vc)
            }
            if vc.parentViewController == nil {
                addedVCs.append(vc)
                addChildViewController(vc)
                stackView.addArrangedSubview(vc.view)
                vc.didMoveToParentViewController(self)
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
                removedVCs.append(vc)
                vc.willMoveToParentViewController(nil)
                vc.view.removeFromSuperview()
                stackView.removeArrangedSubview(vc.view)
                vc.removeFromParentViewController()
            }
            i += 1
        }
        
        var size = stackView.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize, withHorizontalFittingPriority: UILayoutPriorityRequired, verticalFittingPriority: UILayoutPriorityDefaultLow)
        size.width = maximumSize.width
        preferredContentSize = size
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
