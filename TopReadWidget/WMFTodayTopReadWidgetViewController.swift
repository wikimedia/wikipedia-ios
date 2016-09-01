import UIKit
import NotificationCenter
import WMFUI
import WMFModel

class WMFTodayTopReadWidgetViewController: UIViewController, NCWidgetProviding {
    
    // Model
    let siteURL = NSURL.wmf_URLWithDefaultSiteAndCurrentLocale()
    var date = NSDate()
    var results: [MWKSearchResult] = []
    let articlePreviewFetcher = WMFArticlePreviewFetcher()
    let mostReadFetcher = WMFMostReadTitleFetcher()


    // Views & View State
    var snapshotView: UIView?
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var footerView: UIView!
    @IBOutlet weak var footerLabel: UILabel!
    
    
    @IBOutlet weak var stackView: UIStackView!
    
    let dateFormatter = NSDateFormatter.wmf_dayNameMonthNameDayOfMonthNumberDateFormatter()
    let cellReuseIdentifier = "articleList"
    
    var maximumSize = CGSizeZero
    var maximumRowCount = 3
    
    var footerHeight: CGFloat = 57
    var footerVisible = true
    
    var headerHeight: CGFloat = 44
    var headerVisible = true
    
    // Controllers
    var articlePreviewViewControllers: [WMFArticlePreviewViewController] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        let tapGR = UITapGestureRecognizer(target: self, action: #selector(self.handleTapGestureRecognizer(_:)))
        
        view.addGestureRecognizer(tapGR)
        
        if let context = self.extensionContext {
            context.widgetLargestAvailableDisplayMode = .Expanded
            let mode = context.widgetActiveDisplayMode
            let maxSize = context.widgetMaximumSizeForDisplayMode(mode)
            updateViewPropertiesForActiveDisplayMode(mode, maxSize: maxSize)
            layoutForSize(view.bounds.size)
        }
        
        widgetPerformUpdate { (result) in
            
        }
    }
    
    func layoutForSize(size: CGSize) {
        let headerOrigin = headerVisible ? CGPointZero : CGPointMake(0, 0 - headerHeight)
        let stackViewOrigin = headerVisible ? CGPointMake(0, headerHeight) : CGPointZero
        var stackViewHeight = size.height
        if headerVisible {
            stackViewHeight -= headerHeight
        }
        if footerVisible {
            stackViewHeight -= footerHeight
        }
        headerView.frame = CGRect(origin: headerOrigin, size: CGSize(width: size.width, height: headerHeight))
        footerView.frame = CGRect(origin: CGPoint(x: 0, y: footerVisible ? size.height - footerHeight : size.height), size: CGSize(width: size.width, height: footerHeight))
        
        stackView.frame = CGRect(origin: stackViewOrigin, size: CGSize(width: size.width, height: stackViewHeight))
        if var snapshotFrame = snapshotView?.frame {
            snapshotFrame.origin = headerVisible ? stackViewOrigin : headerOrigin
            snapshotView?.frame = snapshotFrame
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
    
    func updateViewPropertiesForActiveDisplayMode(activeDisplayMode: NCWidgetDisplayMode, maxSize: CGSize){
        headerVisible = activeDisplayMode != .Compact
        footerVisible = headerVisible
        maximumRowCount = activeDisplayMode == .Compact ? 1 : 3
        maximumSize = maxSize
    }
    
    func widgetActiveDisplayModeDidChange(activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        updateViewPropertiesForActiveDisplayMode(activeDisplayMode, maxSize: maxSize)
        updateView()
    }
    
    func updateView() {
        headerLabel.text = dateFormatter.stringFromDate(date).uppercaseString
        var i = 0
        let count = min(results.count, maximumRowCount)
        var didRemove = false
        var didAdd = false
        let newSnapshot = view.snapshotViewAfterScreenUpdates(false)
        stackView.removeArrangedSubview(footerView)
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
        if headerVisible {
            size.height += headerHeight
        }
        if footerVisible {
            size.height += footerHeight
        }
        preferredContentSize = size
        
        var stackViewFrame = stackView.frame
        stackViewFrame.size = size
        stackView.frame = stackViewFrame
        
        footerView.hidden = !footerVisible
        var footerViewFrame = footerView.frame
        footerViewFrame.origin = CGPoint(x:0, y:CGRectGetMaxY(stackView.frame))
        footerView.frame = footerViewFrame
    }
    
    func widgetPerformUpdate(completionHandler: ((NCUpdateResult) -> Void)) {
        let newDate = NSDate().wmf_bestMostReadFetchDate()
        
        if let interval = newDate?.timeIntervalSinceDate(date) where interval < 86400 && results.count > 0 {
            completionHandler(.NoData)
            return
        }
        
        date = NSDate().wmf_bestMostReadFetchDate()
        mostReadFetcher.fetchMostReadTitlesForSiteURL(siteURL, date: date).then { (result) -> AnyPromise in
            
            guard let mostReadTitlesResponse = result as? WMFMostReadTitlesResponseItem else {
                completionHandler(.NoData)
                return AnyPromise(value: nil)
            }
            
            let articleURLs = mostReadTitlesResponse.articles.map({ (article) -> NSURL in
                return self.siteURL.wmf_URLWithTitle(article.titleText)
            })
            
            return self.articlePreviewFetcher.fetchArticlePreviewResultsForArticleURLs(articleURLs, siteURL: self.siteURL, extractLength: 0, thumbnailWidth: UIScreen.mainScreen().wmf_listThumbnailWidthForScale().unsignedIntegerValue)
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
    
    func handleTapGestureRecognizer(gestureRecognizer: UITapGestureRecognizer) {
        guard let index = self.articlePreviewViewControllers.indexOf({ (vc) -> Bool in return CGRectContainsPoint(vc.view.frame, gestureRecognizer.locationInView(self.view)) }) where index < results.count else {
            return
        }
        
        let result = results[index]
        let URL = siteURL.wmf_URLWithTitle(result.displayTitle)
        self.extensionContext?.openURL(URL, completionHandler: { (success) in
            
        })
    }
    
}
