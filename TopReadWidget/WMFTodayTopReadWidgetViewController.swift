import UIKit
import NotificationCenter
import WMF
import CocoaLumberjackSwift

class WMFTodayTopReadWidgetViewController: ExtensionViewController, NCWidgetProviding {
    
    // Model
    var groupURL: URL?
    var results: [WMFFeedTopReadArticlePreview] = []

    @IBOutlet weak var chevronImageView: UIImageView!
    
    let databaseDateFormatter = DateFormatter.wmf_englishUTCNonDelimitedYearMonthDay()
    let headerDateFormatter = DateFormatter.wmf_shortMonthNameDayOfMonthNumber()
    let daysToShowInSparkline = 5
    
    @IBOutlet weak var footerLabelLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var headerLabelLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    let skipCache = false
    
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

    override func viewDidLoad() {
        super.viewDidLoad()
    
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
    
    override func apply(theme: Theme) {
        super.apply(theme: theme)
        guard viewIfLoaded != nil else {
            return
        }
        footerLabel.textColor = theme.colors.secondaryText
        headerLabel.textColor = theme.colors.primaryText
        headerSeparatorView.backgroundColor = theme.colors.border
        footerSeparatorView.backgroundColor = theme.colors.border
        for vc in articlePreviewViewControllers {
            vc.apply(theme: theme)
        }
        chevronImageView.tintColor = theme.colors.secondaryText
    }

    @objc func updateView() {
        let completion = { (result: Bool) in
            DDLogDebug("Widget did finish")
        }
        WidgetController.shared.startWidgetUpdateTask(completion) { (dataStore, updateTaskCompletion) in
            self.updateViewAsync(with: dataStore, completion: updateTaskCompletion)
        }
    }
    
    func updateViewAsync(with dataStore: MWKDataStore, completion: @escaping (Bool) -> Void) {
        guard viewIfLoaded != nil else {
            completion(false)
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
            completion(false)
            return
        }
        
        var language: String? = nil
        let siteURL = dataStore.primarySiteURL
        if let languageCode = siteURL?.wmf_language {
            language = Locale.current.localizedString(forLanguageCode: languageCode)
        }
        
        var headerText = ""
        
        if let language = language {
            headerText = String.localizedStringWithFormat(WMFLocalizedString("top-read-header-with-language", value:"%1$@ Wikipedia", comment: "%1$@ Wikipedia - for example English Wikipedia {{Identical|Wikipedia}}"), language)
        } else {
            headerText = WMFLocalizedString("top-read-header-generic", value:"Wikipedia", comment: "Wikipedia {{Identical|Wikipedia}}")
        }


        headerLabel.text = headerText.uppercased()
        headerLabel.isAccessibilityElement = false
        footerLabel.text = WMFLocalizedString("top-read-see-more", value:"See more top read", comment: "Text for footer button allowing the user to see more top read articles").uppercased()

        var dataValueMin = CGFloat.greatestFiniteMagnitude
        var dataValueMax = CGFloat.leastNormalMagnitude
        for result in results[0...(maximumRowCount - 1)] {
            let articlePreview = dataStore.fetchArticle(with: result.articleURL)
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
        let group = DispatchGroup()
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
            vc.apply(theme: theme)

            vc.titleHTML = result.displayTitleHTML
            if let wikidataDescription = result.wikidataDescription {
                vc.subtitleLabel.text = wikidataDescription.wmf_stringByCapitalizingFirstCharacter(usingWikipediaLanguage: siteURL?.wmf_language)
            } else {
                vc.subtitleLabel.text = result.snippet
            }
            vc.imageView.wmf_imageController = dataStore.cacheController
            vc.imageView.wmf_reset()
            let rankString = NumberFormatter.localizedThousandsStringFromNumber(NSNumber(value: i + 1))
            vc.rankLabel.text = rankString
            vc.rankLabel.accessibilityLabel = String.localizedStringWithFormat(WMFLocalizedString("rank-accessibility-label", value:"Number %1$@", comment: "Accessibility label read aloud to sight impared users to indicate a ranking - Number 1, Number 2, etc. %1$@ is replaced with the ranking {{Identical|Number}}"), rankString)
            if let articlePreview = dataStore.fetchArticle(with: result.articleURL) {
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
                            let format = WMFLocalizedString("readers-accessibility-label", value:"%1$@ readers", comment: "Accessibility label read aloud to sight impared users to indicate number of readers for a given article - %1$@ is replaced with the number of readers {{Identical|Reader}}")
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
                group.enter()
                vc.imageView.wmf_setImage(with: imageURL, detectFaces: true, onGPU: true, failure: { (error) in
                    group.leave()
                    vc.collapseImageAndWidenLabels = true
                }) {
                    group.leave()
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
        group.notify(queue: .main) {
            completion(true)
        }
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
        WidgetController.shared.startWidgetUpdateTask(completionHandler) { (dataStore, updateTaskCompletion) in
            self.updateUIWithTopRead(with: dataStore, moc: dataStore.viewContext, completionHandler: updateTaskCompletion)
        }
    }
    
    func updateUIWithTopRead(with dataStore: MWKDataStore, moc: NSManagedObjectContext, completionHandler: @escaping ((NCUpdateResult) -> Void)) {
        WidgetController.shared.fetchNewestWidgetContentGroup(with: .topRead, in: dataStore, isNetworkFetchAllowed: true) { (contentGroup) in
            guard let topRead = contentGroup,
                  let content = topRead.contentPreview as? [WMFFeedTopReadArticlePreview]
            else {
                completionHandler(.failed)
                return
            }
            if let previousGroupURL = self.groupURL,
                let topReadURL = topRead.url,
                !self.results.isEmpty,
                previousGroupURL == topReadURL {
                completionHandler(.noData)
                return
            }
            self.groupURL = topRead.url
            self.results = content
            self.updateViewAsync(with: dataStore) { didUpdate in
                completionHandler(didUpdate ? .newData : .noData)
            }
        }
    }
    
    func showAllTopReadInApp() {
        openApp(with: groupURL)
    }
    
    @objc func handleTapGestureRecognizer(_ gestureRecognizer: UITapGestureRecognizer) {
        guard let index = self.articlePreviewViewControllers.firstIndex(where: { (vc) -> Bool in
            let convertedRect = self.view.convert(vc.view.frame, from: vc.view.superview)
            return convertedRect.contains(gestureRecognizer.location(in: self.view))
        }), index < results.count else {
            showAllTopReadInApp()
            return
        }
        openApp(with: results[index].articleURL, fallback: groupURL)
    }
    
}
