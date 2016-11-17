import UIKit
import NotificationCenter
import YapDatabase
import WMFUI
import WMFModel

class WMFTodayTopReadWidgetViewController: UIViewController, NCWidgetProviding {
    
    // Model
    var siteURL: NSURL!
    var date = NSDate()
    var group: WMFContentGroup?
    var results: [WMFFeedTopReadArticlePreview] = []
    
    var feedContentFetcher = WMFFeedContentFetcher()
    
    var userStore: MWKDataStore!
    var contentStore: WMFContentGroupDataStore!
    var previewStore: WMFArticleDataStore!
    var contentSource: WMFFeedContentSource!

    
    let databaseDateFormatter = NSDateFormatter.wmf_englishUTCNonDelimitedYearMonthDayFormatter()
    let headerDateFormatter = NSDateFormatter.wmf_shortMonthNameDayOfMonthNumberDateFormatter()
    let daysToShowInSparkline: NSTimeInterval = 5
    
    @IBOutlet weak var footerLabelLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var headerLabelLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    #if DEBUG
    let skipCache = false
    #else
    let skipCache = false
    #endif
    
    // Views & View State
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var footerView: UIView!
    @IBOutlet weak var footerLabel: UILabel!
    
    @IBOutlet weak var footerViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var footerViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var headerViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var headerViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var stackViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet var stackViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var stackViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var footerSeparatorView: UIView!
    @IBOutlet weak var headerSeparatorView: UIView!
    
    @IBOutlet weak var stackView: UIStackView!
    
    let cellReuseIdentifier = "articleList"
    
    let maximumRowCount = 3
    
    var maximumSize = CGSizeZero
    var rowCount = 3
    
    var footerVisible = true
    
    var headerVisible = true
    
    var isExpanded: Bool = true
    
    // Controllers
    var articlePreviewViewControllers: [WMFArticlePreviewViewController] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        siteURL = MWKLanguageLinkController.sharedInstance().appLanguage.siteURL()
        userStore = SessionSingleton.sharedInstance().dataStore
        contentStore = WMFContentGroupDataStore(dataStore: userStore)
        previewStore = WMFArticleDataStore(dataStore: userStore)
        contentSource = WMFFeedContentSource(siteURL: siteURL, contentGroupDataStore: contentStore, articlePreviewDataStore: previewStore, userDataStore: userStore, notificationsController: nil)
        
        if #available(iOSApplicationExtension 10.0, *) {
            headerLabel.textColor = UIColor.wmf_darkGray()
            footerLabel.textColor = UIColor.wmf_darkGray()
        } else {
            headerLabel.textColor = UIColor(white: 1, alpha: 0.7)
            footerLabel.textColor = UIColor(white: 1, alpha: 0.7)
            headerLabelLeadingConstraint.constant = 0
            footerLabelLeadingConstraint.constant = 0
        }
        
        headerLabel.text = nil
        footerLabel.text = nil
        
        let tapGR = UITapGestureRecognizer(target: self, action: #selector(self.handleTapGestureRecognizer(_:)))
        
        view.addGestureRecognizer(tapGR)
        
        if let context = self.extensionContext {
            if #available(iOSApplicationExtension 10.0, *) {
                context.widgetLargestAvailableDisplayMode = .Expanded
                isExpanded = context.widgetActiveDisplayMode == .Expanded
                maximumSize = context.widgetMaximumSizeForDisplayMode(context.widgetActiveDisplayMode)
            } else {
                isExpanded = true
                maximumSize = UIScreen.mainScreen().bounds.size
                headerViewHeightConstraint.constant = 40
                footerViewHeightConstraint.constant = 40
            }
            updateViewPropertiesForIsExpanded(isExpanded)
            layoutForSize(view.bounds.size)
        }
        
        widgetPerformUpdate { (result) in
            
        }
    }
    
    func layoutForSize(size: CGSize) {
        let headerHeight = headerViewHeightConstraint.constant
        headerViewTopConstraint.constant = headerVisible ? 0 : 0 - headerHeight
        stackViewTopConstraint.constant = headerVisible ? headerHeight : 0
        stackViewWidthConstraint.constant = size.width
        
        var i = 0
        for vc in articlePreviewViewControllers {
            vc.view.alpha = i < rowCount ? 1 : 0
            if i == 0 {
                vc.separatorView.alpha = rowCount == 1 ? 0 : 1
            }
            i += 1
        }
        
        footerView.alpha = footerVisible ? 1 : 0
        headerView.alpha = headerVisible ? 1 : 0
        
        view.layoutIfNeeded()
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        
        if #available(iOSApplicationExtension 10.0, *) {
            coordinator.animateAlongsideTransition({ (context) in
                self.layoutForSize(size)
            }) { (context) in
                if (!context.isAnimated()) {
                    self.layoutForSize(size)
                }
            }
        } else {
            layoutForSize(size)
        }
    }
    
    func updateViewPropertiesForIsExpanded(isExpanded: Bool){
        self.isExpanded = isExpanded
        headerVisible = isExpanded
        footerVisible = headerVisible
        rowCount = isExpanded ? maximumRowCount : 1
    }
    
    @available(iOSApplicationExtension 10.0, *)
    func widgetActiveDisplayModeDidChange(activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        maximumSize = maxSize
        let activeIsExpanded = activeDisplayMode == .Expanded
        if (activeIsExpanded != isExpanded) {
            updateViewPropertiesForIsExpanded(activeIsExpanded)
            updateView()
        }
    }
    
    func updateView() {
        
        let count = min(results.count, maximumRowCount)
        guard count > 0 else {
            return
        }
        
        var language: String? = nil
        if let languageCode = siteURL.wmf_language {
            language = NSLocale.currentLocale().wmf_localizedLanguageNameForCode(languageCode)
        }
        
        var headerText = ""
        
        if let language = language {
            headerText = localizedStringForKeyFallingBackOnEnglish("top-read-header-with-language").stringByReplacingOccurrencesOfString("$1", withString: language)
        } else {
            headerText = localizedStringForKeyFallingBackOnEnglish("top-read-header-generic")
        }
        
        headerLabel.text = headerText.uppercaseString
        headerLabel.isAccessibilityElement = false
        footerLabel.text = localizedStringForKeyFallingBackOnEnglish("top-read-see-more").uppercaseString
        
        var dataValueMin = CGFloat.max
        var dataValueMax = CGFloat.min
        for result in results[0...maximumRowCount] {
            let articlePreview = self.previewStore.itemForURL(result.articleURL)
            guard let dataValues = articlePreview?.pageViews else {
                continue
            }
            for (_, dataValue) in dataValues {
                let floatValue = CGFloat(dataValue.doubleValue)
                if (floatValue < dataValueMin) {
                    dataValueMin = floatValue
                }
                if (floatValue > dataValueMax) {
                    dataValueMax = floatValue
                }
            }
        }
        
        var i = 0
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
            }
            let result = results[i]
            
            vc.titleLabel.text = result.displayTitle
            vc.subtitleLabel.text = result.snippet ?? result.wikidataDescription
            vc.imageView.wmf_reset()
            let rankString = NSNumberFormatter.localizedThousandsStringFromNumber(i + 1)
            vc.rankLabel.text = rankString
            vc.rankLabel.accessibilityLabel = localizedStringForKeyFallingBackOnEnglish("rank-accessibility-label").stringByReplacingOccurrencesOfString("$1", withString: rankString)
            if let articlePreview = self.previewStore.itemForURL(result.articleURL) {
                if let viewCounts = articlePreview.pageViewsSortedByDate where viewCounts.count > 0 {
                    vc.sparklineView.minDataValue = dataValueMin
                    vc.sparklineView.maxDataValue = dataValueMax
                    vc.sparklineView.dataValues = viewCounts
                    
                    if let count = viewCounts.last {
                        vc.viewCountLabel.text = NSNumberFormatter.localizedThousandsStringFromNumber(count)
                        if let numberString = NSNumberFormatter.threeSignificantDigitWholeNumberFormatter?.stringFromNumber(count) {
                            let format = localizedStringForKeyFallingBackOnEnglish("readers-accessibility-label")
                            vc.viewCountLabel.accessibilityLabel = format.stringByReplacingOccurrencesOfString("$1", withString: numberString)
                        }
                    } else {
                        vc.viewCountLabel.accessibilityLabel = nil
                        vc.viewCountLabel.text = nil
                    }
                    
                    vc.viewCountAndSparklineContainerView.hidden = false
                } else {
                    vc.viewCountAndSparklineContainerView.hidden = true
                }
            } else {
                vc.viewCountAndSparklineContainerView.hidden = true
            }
            
            if #available(iOSApplicationExtension 10.0, *) {
                if let imageURL = result.thumbnailURL {
                    vc.imageView.wmf_setImageWithURL(imageURL, detectFaces: true, onGPU: true, failure: { (error) in
                        vc.collapseImageAndWidenLabels = true
                    }) {
                        vc.collapseImageAndWidenLabels = false
                    }
                } else {
                    vc.collapseImageAndWidenLabels = true
                }
            } else {
                vc.collapseImageAndWidenLabels = true
            }
            
            if i == (count - 1) {
                vc.separatorView.hidden = true
            } else {
                vc.separatorView.hidden = false
            }
            if #available(iOSApplicationExtension 10.0, *) {
                
            } else {
                vc.marginWidthConstraint.constant = 0
                vc.titleLabel.textColor = UIColor(white: 1, alpha: 1)
                vc.subtitleLabel.textColor = UIColor(white: 1, alpha: 1)
                vc.rankLabel.textColor = UIColor(white: 1, alpha: 0.7)
                vc.viewCountLabel.textColor = UIColor(white: 1, alpha: 0.7)
                vc.viewCountAndSparklineContainerView.backgroundColor = UIColor(white: 0.3, alpha: 0.3)
            }
            
            i += 1
        }
        
        stackViewHeightConstraint.active = false
        stackViewWidthConstraint.constant = maximumSize.width
        var sizeToFit = UILayoutFittingCompressedSize
        sizeToFit.width = maximumSize.width
        var size = stackView.systemLayoutSizeFittingSize(sizeToFit, withHorizontalFittingPriority: UILayoutPriorityRequired, verticalFittingPriority: UILayoutPriorityDefaultLow)
        size.width = maximumSize.width
        stackViewHeightConstraint.active = true
        
        stackViewHeightConstraint.constant = size.height
        
        view.layoutIfNeeded()
        
        let headerHeight = headerViewHeightConstraint.constant
        let footerHeight = footerViewHeightConstraint.constant
        
        if headerVisible {
            size.height += headerHeight
        }
        
        if footerVisible {
            size.height += footerHeight
        }
        
        preferredContentSize = rowCount == 1 ? articlePreviewViewControllers[0].view.frame.size : size
        
        activityIndicatorHidden = true
    }
    
    var activityIndicatorHidden: Bool = false {
        didSet {
            activityIndicatorView.hidden = activityIndicatorHidden
            if activityIndicatorHidden {
                activityIndicatorView.stopAnimating()
            } else {
                activityIndicatorView.startAnimating()
            }
            
            headerView.hidden = !activityIndicatorHidden
            footerView.hidden = !activityIndicatorHidden
            stackView.hidden = !activityIndicatorHidden
        }
    }
    
    func widgetPerformUpdate(completionHandler: ((NCUpdateResult) -> Void)) {
        fetchForDate(NSDate(), attempt: 1, completionHandler: completionHandler)
    }
    
    func updateUIWithTopReadFromContentStoreForDate(date: NSDate) -> Bool {
        if let topRead = self.contentStore.firstGroupOfKind(.TopRead, forDate: date) {
            if let content = topRead.content as? [WMFFeedTopReadArticlePreview] {
                self.group = topRead
                self.results = content
                self.updateView()
                return true
            }
        }
        return false
    }
    
    
    
    func fetchForDate(date: NSDate, attempt: Int, completionHandler: ((NCUpdateResult) -> Void)) {
        guard !updateUIWithTopReadFromContentStoreForDate(date) else {
            completionHandler(.NewData)
            return
        }
        
        guard attempt < 3 else {
            completionHandler(.NoData)
            return
        }
        
        contentSource.loadNewContentForce(false) {
            dispatch_async(dispatch_get_main_queue(), {
                guard self.updateUIWithTopReadFromContentStoreForDate(date) else {
                    guard let previousDate = NSCalendar.wmf_gregorianCalendar().dateByAddingUnit(.Day, value: -1, toDate: date, options: .MatchStrictly) else {
                        completionHandler(.NoData)
                        return
                    }
                    
                    self.fetchForDate(previousDate, attempt: attempt + 1, completionHandler: completionHandler)
                    return
                }
                
                completionHandler(.NewData)
            })
        }
    }
    
    func showAllTopReadInApp() {
        guard let URL = group?.URL else {
            return
        }
        self.extensionContext?.openURL(URL, completionHandler: { (success) in
            
        })
    }
    
    func handleTapGestureRecognizer(gestureRecognizer: UITapGestureRecognizer) {
        guard let index = self.articlePreviewViewControllers.indexOf({ (vc) -> Bool in
            let convertedRect = self.view.convertRect(vc.view.frame, fromView: vc.view.superview)
            return CGRectContainsPoint(convertedRect, gestureRecognizer.locationInView(self.view))
        }) where index < results.count else {
            showAllTopReadInApp()
            return
        }
        
        let result = results[index]
        let displayTitle = result.displayTitle
        guard let URL = siteURL.wmf_wikipediaSchemeURLWithTitle(displayTitle) else {
            return
        }
        self.extensionContext?.openURL(URL, completionHandler: { (success) in
            
        })
    }
    
}
