import UIKit
import NotificationCenter
import WMFUI
import WMFModel

class WMFTodayTopReadWidgetViewController: UIViewController, NCWidgetProviding {
    
    @IBOutlet weak var headerView: UIView!
    
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var stackView: UIStackView!
    
    var snapshotView: UIView?
    
    let dateFormatter = NSDateFormatter.wmf_dayNameMonthNameDayOfMonthNumberDateFormatter()
    var date = NSDate()
    let cellReuseIdentifier = "articleList"
    let articlePreviewFetcher = WMFArticlePreviewFetcher()
    let mostReadFetcher = WMFMostReadTitleFetcher()
    var maximumSize = CGSizeZero
    var maximumRowCount = 3
    var results: [MWKSearchResult] = []
    var articlePreviewViewControllers: [WMFArticlePreviewViewController] = []
    var headerHeight: CGFloat = 44
    var headerVisible = false
    
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
    
    func layoutForSize(size: CGSize) {
        let headerOrigin = headerVisible ? CGPointZero : CGPointMake(0, 0 - headerHeight)
        let stackViewOrigin = headerVisible ? CGPointMake(0, headerHeight) : CGPointZero
        let stackViewHeight = headerVisible ? size.height : size.height - headerHeight
        self.headerView.frame = CGRect(origin: headerOrigin, size: CGSize(width: size.width, height: headerHeight))
        
        
        self.stackView.frame = CGRect(origin: stackViewOrigin, size: CGSize(width: size.width, height: stackViewHeight))
        if var snapshotFrame = self.snapshotView?.frame {
            snapshotFrame.origin = headerVisible ? stackViewOrigin : headerOrigin
            self.snapshotView?.frame = snapshotFrame
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
            self.layoutForSize(size)
            }) { (context) in
            viewToFade.removeFromSuperview()
            self.snapshotView = nil
        }
    }
    
    func widgetActiveDisplayModeDidChange(activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        headerVisible = activeDisplayMode != .Compact
        maximumRowCount = activeDisplayMode == .Compact ? 1 : 3
        maximumSize = maxSize
        updateView()
    }
    
    func updateView() {
        headerLabel.text = dateFormatter.stringFromDate(date).uppercaseString
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
            if i == (count - 1) {
                vc.separatorView.hidden = true
            } else {
                vc.separatorView.hidden = false
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
        size.height += headerHeight
        preferredContentSize = size
        
        var stackViewFrame = stackView.frame
        stackViewFrame.size = size
        stackView.frame = stackViewFrame
    }
    
    func widgetPerformUpdate(completionHandler: ((NCUpdateResult) -> Void)) {
        
        let siteURL = NSURL.wmf_URLWithDefaultSiteAndCurrentLocale()
        date = NSDate().wmf_bestMostReadFetchDate()
        mostReadFetcher.fetchMostReadTitlesForSiteURL(siteURL, date: date).then { (result) -> AnyPromise in
            
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
