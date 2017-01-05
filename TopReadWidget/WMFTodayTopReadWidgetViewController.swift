import UIKit
import NotificationCenter
import WMF

class WMFTodayTopReadWidgetViewController: UIViewController, NCWidgetProviding {
    
    // Model
    var siteURL: URL!
    var group: WMFContentGroup?
    var results: [WMFFeedTopReadArticlePreview] = []
    
    var feedContentFetcher = WMFFeedContentFetcher()
    
    var userStore: MWKDataStore!
    var contentStore: WMFContentGroupDataStore!
    var previewStore: WMFArticleDataStore!
    var contentSource: WMFFeedContentSource!

    
    let databaseDateFormatter = DateFormatter.wmf_englishUTCNonDelimitedYearMonthDay()
    let headerDateFormatter = DateFormatter.wmf_shortMonthNameDayOfMonthNumber()
    let daysToShowInSparkline = 5
    
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
    
    var maximumSize = CGSize.zero
    var rowCount = 3
    
    var footerVisible = true
    
    var headerVisible = true
    
    var isExpanded: Bool = true
    
    // Controllers
    var articlePreviewViewControllers: [WMFArticlePreviewViewController] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let appLanguage = MWKLanguageLinkController.sharedInstance().appLanguage else {
            return
        }

        siteURL = appLanguage.siteURL()
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
                context.widgetLargestAvailableDisplayMode = .expanded
                isExpanded = context.widgetActiveDisplayMode == .expanded
                maximumSize = context.widgetMaximumSize(for: context.widgetActiveDisplayMode)
            } else {
                isExpanded = true
                maximumSize = UIScreen.main.bounds.size
                headerViewHeightConstraint.constant = 40
                footerViewHeightConstraint.constant = 40
            }
            updateViewPropertiesForIsExpanded(isExpanded)
            layoutForSize(view.bounds.size)
        }
        
        widgetPerformUpdate { (result) in
            
        }
    }
    
    func layoutForSize(_ size: CGSize) {
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
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        if #available(iOSApplicationExtension 10.0, *) {
            coordinator.animate(alongsideTransition: { (context) in
                self.layoutForSize(size)
            }) { (context) in
                if (!context.isAnimated) {
                    self.layoutForSize(size)
                }
            }
        } else {
            layoutForSize(size)
        }
    }
    
    func updateViewPropertiesForIsExpanded(_ isExpanded: Bool){
        self.isExpanded = isExpanded
        headerVisible = isExpanded
        footerVisible = headerVisible
        rowCount = isExpanded ? maximumRowCount : 1
    }
    
    @available(iOSApplicationExtension 10.0, *)
    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        maximumSize = maxSize
        let activeIsExpanded = activeDisplayMode == .expanded
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
        let siteURL = self.siteURL as NSURL
        if let languageCode = siteURL.wmf_language {
            language = (Locale.current as NSLocale).wmf_localizedLanguageNameForCode(languageCode)
        }
        
        var headerText = ""
        
        if let language = language {
            headerText = localizedStringForKeyFallingBackOnEnglish("top-read-header-with-language").replacingOccurrences(of: "$1", with: language)
        } else {
            headerText = localizedStringForKeyFallingBackOnEnglish("top-read-header-generic")
        }
        
        headerLabel.text = headerText.uppercased()
        headerLabel.isAccessibilityElement = false
        footerLabel.text = localizedStringForKeyFallingBackOnEnglish("top-read-see-more").uppercased()
        
        var dataValueMin = CGFloat.greatestFiniteMagnitude
        var dataValueMax = CGFloat.leastNormalMagnitude
        for result in results[0...(maximumRowCount - 1)] {
            let articlePreview = self.previewStore.item(for: result.articleURL)
            guard let dataValues = articlePreview?.pageViews else {
                continue
            }
            for (_, dataValue) in dataValues {
                guard let number = dataValue as? NSNumber else {
                    continue
                }
                let floatValue = CGFloat(number.doubleValue)
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
            if vc.parent == nil {
                addChildViewController(vc)
                stackView.addArrangedSubview(vc.view)
                vc.didMove(toParentViewController: self)
            }
            let result = results[i]
            
            vc.titleLabel.text = result.displayTitle
            if let wikidataDescription = result.wikidataDescription {
                vc.subtitleLabel.text = wikidataDescription.wmf_stringByCapitalizingFirstCharacter()
            }else{
                vc.subtitleLabel.text = result.snippet
            }
            vc.imageView.wmf_reset()
            let rankString = NumberFormatter.localizedThousandsStringFromNumber(NSNumber(value: i + 1))
            vc.rankLabel.text = rankString
            vc.rankLabel.accessibilityLabel = localizedStringForKeyFallingBackOnEnglish("rank-accessibility-label").replacingOccurrences(of: "$1", with: rankString)
            if let articlePreview = self.previewStore.item(for: result.articleURL) {
                if var viewCounts = articlePreview.pageViewsSortedByDate, viewCounts.count >= daysToShowInSparkline {
                    vc.sparklineView.minDataValue = dataValueMin
                    vc.sparklineView.maxDataValue = dataValueMax
                    let countToRemove = viewCounts.count - daysToShowInSparkline
                    if countToRemove > 0 {
                        viewCounts.removeFirst(countToRemove)
                    }
                    vc.sparklineView.dataValues = viewCounts
                    
                    if let count = viewCounts.last {
                        vc.viewCountLabel.text = NumberFormatter.localizedThousandsStringFromNumber(count)
                        if let numberString = NumberFormatter.threeSignificantDigitWholeNumberFormatter.string(from: count) {
                            let format = localizedStringForKeyFallingBackOnEnglish("readers-accessibility-label")
                            vc.viewCountLabel.accessibilityLabel = format.replacingOccurrences(of: "$1", with: numberString)
                        }
                    } else {
                        vc.viewCountLabel.accessibilityLabel = nil
                        vc.viewCountLabel.text = nil
                    }
                    
                    vc.viewCountAndSparklineContainerView.isHidden = false
                } else {
                    vc.viewCountAndSparklineContainerView.isHidden = true
                }
            } else {
                vc.viewCountAndSparklineContainerView.isHidden = true
            }
            
            if #available(iOSApplicationExtension 10.0, *) {
                if let imageURL = result.thumbnailURL {
                    vc.imageView.wmf_setImage(with: imageURL, detectFaces: true, onGPU: true, failure: { (error) in
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
                vc.separatorView.isHidden = true
            } else {
                vc.separatorView.isHidden = false
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
        
        stackViewHeightConstraint.isActive = false
        stackViewWidthConstraint.constant = maximumSize.width
        var sizeToFit = UILayoutFittingCompressedSize
        sizeToFit.width = maximumSize.width
        var size = stackView.systemLayoutSizeFitting(sizeToFit, withHorizontalFittingPriority: UILayoutPriorityRequired, verticalFittingPriority: UILayoutPriorityDefaultLow)
        size.width = maximumSize.width
        stackViewHeightConstraint.isActive = true
        
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
            activityIndicatorView.isHidden = activityIndicatorHidden
            if activityIndicatorHidden {
                activityIndicatorView.stopAnimating()
            } else {
                activityIndicatorView.startAnimating()
            }
            
            headerView.isHidden = !activityIndicatorHidden
            footerView.isHidden = !activityIndicatorHidden
            stackView.isHidden = !activityIndicatorHidden
        }
    }
    
    func widgetPerformUpdate(_ completionHandler: @escaping ((NCUpdateResult) -> Void)) {
        fetch(siteURL: siteURL, date:Date(), attempt: 1, completionHandler: completionHandler)
    }
    
    func updateUIWithTopReadFromContentStoreForSiteURL(siteURL: URL, date: Date) -> Bool {
        if let topRead = self.contentStore.firstGroup(of: .topRead, for: date, siteURL: siteURL) {
            if let content = topRead.content as? [WMFFeedTopReadArticlePreview] {
                self.group = topRead
                self.results = content
                self.updateView()
                return true
            }
        }
        return false
    }
    
    
    
    func fetch(siteURL: URL, date: Date, attempt: Int, completionHandler: @escaping ((NCUpdateResult) -> Void)) {
        guard !updateUIWithTopReadFromContentStoreForSiteURL(siteURL: siteURL, date: date) else {
            completionHandler(.newData)
            return
        }
        
        guard attempt < 4 else {
            completionHandler(.noData)
            return
        }
        contentSource.loadContent(for: date, force: false) {
            DispatchQueue.main.async(execute: {
                guard self.updateUIWithTopReadFromContentStoreForSiteURL(siteURL: siteURL, date: date) else {
                    if (attempt == 1) {
                        let todayUTC = (date as NSDate).wmf_midnightLocalDateForEquivalentUTC as Date
                        self.fetch(siteURL: siteURL, date: todayUTC, attempt: attempt + 1, completionHandler: completionHandler)
                    } else {
                        guard let previousDate = NSCalendar.wmf_gregorian().date(byAdding: .day, value: -1, to: date, options: .matchStrictly) else {
                            completionHandler(.noData)
                            return
                        }
                         self.fetch(siteURL: siteURL, date: previousDate, attempt: attempt + 1, completionHandler: completionHandler)
                    }
                    return
                }
                
                completionHandler(.newData)
            })
        }
    }
    
    func showAllTopReadInApp() {
        guard let URL = group?.url else {
            return
        }
        self.extensionContext?.open(URL, completionHandler: { (success) in
            
        })
    }
    
    func handleTapGestureRecognizer(_ gestureRecognizer: UITapGestureRecognizer) {
        guard let index = self.articlePreviewViewControllers.index(where: { (vc) -> Bool in
            let convertedRect = self.view.convert(vc.view.frame, from: vc.view.superview)
            return convertedRect.contains(gestureRecognizer.location(in: self.view))
        }), index < results.count else {
            showAllTopReadInApp()
            return
        }
        
        let result = results[index]
        let displayTitle = result.displayTitle
        let siteURL = self.siteURL as NSURL
        guard let URL = siteURL.wmf_wikipediaSchemeURL(withTitle: displayTitle) else {
            return
        }
        self.extensionContext?.open(URL, completionHandler: { (success) in
            
        })
    }
    
}
