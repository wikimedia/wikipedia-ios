import UIKit
import NotificationCenter
import WMF

class WMFTodayTopReadWidgetViewController: UIViewController, NCWidgetProviding {
    
    // Model
    var siteURL: URL!
    var groupURL: URL?
    var results: [WMFFeedTopReadArticlePreview] = []
    
    var feedContentFetcher = WMFFeedContentFetcher()
    
    var userStore: MWKDataStore!
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
    
    var isExpanded: Bool?
    
    // Controllers
    var articlePreviewViewControllers: [WMFArticlePreviewViewController] = []

    var theme: Theme = .widget

    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let appLanguage = MWKLanguageLinkController.sharedInstance().appLanguage else {
            return
        }
    
        siteURL = appLanguage.siteURL()
        userStore = SessionSingleton.sharedInstance().dataStore
        contentSource = WMFFeedContentSource(siteURL: siteURL, userDataStore: userStore, notificationsController: nil)

        let tapGR = UITapGestureRecognizer(target: self, action: #selector(self.handleTapGestureRecognizer(_:)))
        view.addGestureRecognizer(tapGR)
        
        extensionContext?.widgetLargestAvailableDisplayMode = .expanded
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
        coordinator.animate(alongsideTransition: { (context) in
            self.layoutForSize(size)
        }) { (context) in
            if (!context.isAnimated) {
                self.layoutForSize(size)
            }
        }
    }
    
    func updateViewPropertiesForIsExpanded(_ isExpanded: Bool) {
        self.isExpanded = isExpanded
        headerVisible = isExpanded
        footerVisible = headerVisible
        rowCount = isExpanded ? maximumRowCount : 1
    }

    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        debounceViewUpdate()
    }

    func debounceViewUpdate() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(updateView), object: nil)
        perform(#selector(updateView), with: nil, afterDelay: 0.1)
    }
    
    @objc func updateView() {
        guard viewIfLoaded != nil else {
            return
        }
        if let context = self.extensionContext {
            var updatedIsExpanded: Bool?
            updatedIsExpanded = context.widgetActiveDisplayMode == .expanded
            maximumSize = context.widgetMaximumSize(for: context.widgetActiveDisplayMode)
            if isExpanded != updatedIsExpanded {
                isExpanded = updatedIsExpanded
                updateViewPropertiesForIsExpanded(isExpanded ?? false)
                layoutForSize(view.bounds.size)
            }
        }

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
            headerText = String.localizedStringWithFormat(WMFLocalizedString("top-read-header-with-language", value:"%1$@ Wikipedia", comment: "%1$@ Wikipedia - for example English Wikipedia\n{{Identical|Wikipedia}}"), language)
        } else {
            headerText = WMFLocalizedString("top-read-header-generic", value:"Wikipedia", comment: "Wikipedia\n{{Identical|Wikipedia}}")
        }

        headerLabel.textColor = theme.colors.primaryText
        headerLabel.text = headerText.uppercased()
        headerLabel.isAccessibilityElement = false
        footerLabel.text = WMFLocalizedString("top-read-see-more", value:"See more top read", comment: "Text for footer button allowing the user to see more top read articles").uppercased()
        footerLabel.textColor = theme.colors.primaryText
        
        var dataValueMin = CGFloat.greatestFiniteMagnitude
        var dataValueMax = CGFloat.leastNormalMagnitude
        for result in results[0...(maximumRowCount - 1)] {
            let articlePreview = self.userStore.fetchArticle(with: result.articleURL)
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

        headerSeparatorView.backgroundColor = theme.colors.border
        footerSeparatorView.backgroundColor = theme.colors.border

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
                addChild(vc)
                stackView.addArrangedSubview(vc.view)
                vc.didMove(toParent: self)
            }
            let result = results[i]
            
            vc.titleTextColor = theme.colors.primaryText
            vc.subtitleLabel.textColor = theme.colors.secondaryText
            vc.rankLabel.textColor = theme.colors.secondaryText
            vc.viewCountLabel.textColor =  theme.colors.overlayText

            vc.titleHTML = result.displayTitleHTML
            if let wikidataDescription = result.wikidataDescription {
                vc.subtitleLabel.text = wikidataDescription.wmf_stringByCapitalizingFirstCharacter(usingWikipediaLanguage: siteURL.wmf_language)
            }else{
                vc.subtitleLabel.text = result.snippet
            }
            vc.imageView.wmf_reset()
            let rankString = NumberFormatter.localizedThousandsStringFromNumber(NSNumber(value: i + 1))
            vc.rankLabel.text = rankString
            vc.rankLabel.accessibilityLabel = String.localizedStringWithFormat(WMFLocalizedString("rank-accessibility-label", value:"Number %1$@", comment: "Accessibility label read aloud to sight impared users to indicate a ranking - Number 1, Number 2, etc. %1$@ is replaced with the ranking\n{{Identical|Number}}"), rankString)
            if let articlePreview = self.userStore.fetchArticle(with: result.articleURL) {
                vc.viewCountAndSparklineContainerView.backgroundColor = theme.colors.overlayBackground
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
                            let format = WMFLocalizedString("readers-accessibility-label", value:"%1$@ readers", comment: "Accessibility label read aloud to sight impared users to indicate number of readers for a given article - %1$@ is replaced with the number of readers\n{{Identical|Reader}}")
                            vc.viewCountLabel.accessibilityLabel = String.localizedStringWithFormat(format,numberString)
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
            
            if let imageURL = result.thumbnailURL {
                vc.imageView.wmf_setImage(with: imageURL, detectFaces: true, onGPU: true, failure: { (error) in
                    vc.collapseImageAndWidenLabels = true
                }) {
                    vc.collapseImageAndWidenLabels = false
                }
            } else {
                vc.collapseImageAndWidenLabels = true
            }
            
            if i == (count - 1) {
                vc.separatorView.isHidden = true
            } else {
                vc.separatorView.isHidden = false
            }
            vc.separatorView.backgroundColor = theme.colors.border
            
            i += 1
        }
        
        stackViewHeightConstraint.isActive = false
        stackViewWidthConstraint.constant = maximumSize.width
        var sizeToFit = UIView.layoutFittingCompressedSize
        sizeToFit.width = maximumSize.width
        var size = stackView.systemLayoutSizeFitting(sizeToFit, withHorizontalFittingPriority: UILayoutPriority.required, verticalFittingPriority: UILayoutPriority.defaultLow)
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

    func widgetPerformUpdate(completionHandler: @escaping (NCUpdateResult) -> Void) {
        fetch(siteURL: siteURL, date:Date(), attempt: 1, completionHandler: completionHandler)
    }
    
    func updateUIWithTopReadFromContentStoreForSiteURL(siteURL: URL, date: Date) -> NCUpdateResult {
        if let topRead = self.userStore.viewContext.group(of: .topRead, for: date, siteURL: siteURL) {
            if let content = topRead.contentPreview as? [WMFFeedTopReadArticlePreview] {
                if let previousGroupURL = self.groupURL,
                    let topReadURL = topRead.url,
                    self.results.count > 0,
                    previousGroupURL == topReadURL {
                    return .noData
                }
                self.groupURL = topRead.url
                self.results = content
                self.updateView()
                return .newData
            }
        }
        return .failed
    }
    
    
    
    func fetch(siteURL: URL, date: Date, attempt: Int, completionHandler: @escaping ((NCUpdateResult) -> Void)) {
        let result = updateUIWithTopReadFromContentStoreForSiteURL(siteURL: siteURL, date: date)
        guard result == .failed else {
            completionHandler(result)
            return
        }

        guard attempt < 4 else {
            completionHandler(.noData)
            return
        }
        contentSource.loadContent(for: date, in: userStore.viewContext, force: false) {
            DispatchQueue.main.async(execute: {
                let result = self.updateUIWithTopReadFromContentStoreForSiteURL(siteURL: siteURL, date: date)
                guard result != .failed else {
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
                completionHandler(result)
            })
        }
    }
    
    func showAllTopReadInApp() {
        guard let URL = groupURL else {
            return
        }
        self.extensionContext?.open(URL)
    }
    
    @objc func handleTapGestureRecognizer(_ gestureRecognizer: UITapGestureRecognizer) {
        guard let index = self.articlePreviewViewControllers.index(where: { (vc) -> Bool in
            let convertedRect = self.view.convert(vc.view.frame, from: vc.view.superview)
            return convertedRect.contains(gestureRecognizer.location(in: self.view))
        }), index < results.count else {
            showAllTopReadInApp()
            return
        }
        
        let result = results[index]
        self.extensionContext?.open(result.articleURL)
    }
    
}
