import UIKit
import NotificationCenter
import YapDatabase
import WMFUI
import WMFModel

class WMFTodayTopReadWidgetViewController: UIViewController, NCWidgetProviding {
    
    // Model
    var siteURL: NSURL {
        get {
             return MWKLanguageLinkController.sharedInstance().appLanguage.siteURL()
        }
    }
    var date = NSDate()
    var results: [MWKSearchResult] = []
    let articlePreviewFetcher = WMFArticlePreviewFetcher()
    let mostReadFetcher = WMFMostReadTitleFetcher()
    let dataStore: MWKDataStore = SessionSingleton.sharedInstance().dataStore
    let databaseDateFormatter = NSDateFormatter.wmf_englishUTCNonDelimitedYearMonthDayFormatter()
    let headerDateFormatter = NSDateFormatter.wmf_shortMonthNameDayOfMonthNumberDateFormatter()
    let numberFormatter = NSNumberFormatter()
    let daysToShowInSparkline: NSTimeInterval = 5
    
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
    
    @IBOutlet weak var stackView: UIStackView!
    
    let cellReuseIdentifier = "articleList"
    
    let maximumRowCount = 3
    
    var maximumSize = CGSizeZero
    var rowCount = 3
    
    var footerVisible = true
    
    var headerVisible = true
    
    var displayMode: NCWidgetDisplayMode = .Expanded
    
    // Controllers
    var articlePreviewViewControllers: [WMFArticlePreviewViewController] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        numberFormatter.numberStyle = .DecimalStyle
        numberFormatter.maximumFractionDigits = 1
        headerLabel.text = nil
        footerLabel.text = nil
        headerLabel.textColor = UIColor.wmf_darkGray()
        footerLabel.textColor = UIColor.wmf_darkGray()
        
        let tapGR = UITapGestureRecognizer(target: self, action: #selector(self.handleTapGestureRecognizer(_:)))
        
        view.addGestureRecognizer(tapGR)
        
        if let context = self.extensionContext {
            context.widgetLargestAvailableDisplayMode = .Expanded
            displayMode = context.widgetActiveDisplayMode
            maximumSize = context.widgetMaximumSizeForDisplayMode(displayMode)
            updateViewPropertiesForActiveDisplayMode(displayMode)
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
        
        coordinator.animateAlongsideTransition({ (context) in
            self.layoutForSize(size)
            }) { (context) in
                if (!context.isAnimated()) {
                    self.layoutForSize(size)
                }
            }
    }
    
    func updateViewPropertiesForActiveDisplayMode(activeDisplayMode: NCWidgetDisplayMode){
        displayMode = activeDisplayMode
        headerVisible = activeDisplayMode != .Compact
        footerVisible = headerVisible
        rowCount = activeDisplayMode == .Compact ? 1 : maximumRowCount
    }
    
    func widgetActiveDisplayModeDidChange(activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        maximumSize = maxSize
        if (activeDisplayMode != displayMode) {
            updateViewPropertiesForActiveDisplayMode(activeDisplayMode)
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
        footerLabel.text = localizedStringForKeyFallingBackOnEnglish("top-read-see-more").uppercaseString
        
        var dataValueMin = CGFloat.max
        var dataValueMax = CGFloat.min
        for result in results[0...maximumRowCount] {
            guard let dataValues = result.viewCounts else {
                continue
            }
            for dataValue in dataValues {
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
            vc.subtitleLabel.text = result.extract ?? result.wikidataDescription
            vc.imageView.wmf_reset()
            vc.rankLabel.text = numberFormatter.stringFromNumber(i + 1)
            if let viewCounts = result.viewCounts where viewCounts.count > 0 {
                vc.sparklineView.minDataValue = dataValueMin
                vc.sparklineView.maxDataValue = dataValueMax
                vc.sparklineView.dataValues = viewCounts

                if let doubleValue = viewCounts.last?.doubleValue, let viewCountsString = numberFormatter.stringFromNumber(NSNumber(double: doubleValue/1000)) {
                    let format = localizedStringForKeyFallingBackOnEnglish("top-read-reader-count-thousands")
                    vc.viewCountLabel.text = format.stringByReplacingOccurrencesOfString("$1", withString: viewCountsString)
                } else {
                    vc.viewCountLabel.text = nil
                }
                
                vc.viewCountAndSparklineContainerView.hidden = false
            } else {
                vc.viewCountAndSparklineContainerView.hidden = true
            }
            if let imageURL = result.thumbnailURL {
                vc.imageView.wmf_setImageWithURL(imageURL, detectFaces: true, onGPU: true, failure: { (error) in
                    vc.collapseImageAndWidenLabels = true
                }) {
                    vc.collapseImageAndWidenLabels = false
                }
            } else {
                vc.collapseImageAndWidenLabels = true
            }
            if i == (count - 1) {
                vc.separatorView.hidden = true
            } else {
                vc.separatorView.hidden = false
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

    }

    func widgetPerformUpdate(completionHandler: ((NCUpdateResult) -> Void)) {
        date = NSDate().wmf_bestMostReadFetchDate()
        fetchForDate(date, siteURL: siteURL, completionHandler: completionHandler)
    }
    
    func fetchForDate(date: NSDate, siteURL: NSURL, completionHandler: ((NCUpdateResult) -> Void)) {
        guard let host = siteURL.host else {
            completionHandler(.NoData)
            return
        }
        let databaseKey = databaseDateFormatter.stringFromDate(date)
        let databaseCollection = "wmftopread:\(host)"
        
        guard !skipCache else {
            self.fetchRemotelyAndStoreInDatabaseCollection(databaseCollection, databaseKey: databaseKey, completionHandler: completionHandler)
            return
        }
        
        dataStore.readWithBlock { (transaction) in
            guard let results = transaction.objectForKey(databaseKey, inCollection: databaseCollection) as? [MWKSearchResult] else {
                dispatch_async(dispatch_get_main_queue(), {
                    self.fetchRemotelyAndStoreInDatabaseCollection(databaseCollection, databaseKey: databaseKey, completionHandler: completionHandler)
                    })
                return
            }
            
            dispatch_async(dispatch_get_main_queue(), {
                self.results = results
                self.updateView()
                completionHandler(.NewData)
            })
        }
    }
    
    func fetchRemotelyAndStoreInDatabaseCollection(databaseCollection: String, databaseKey: String, completionHandler: ((NCUpdateResult) -> Void)) {
        let siteURL = self.siteURL
        mostReadFetcher.fetchMostReadTitlesForSiteURL(siteURL, date: date).then { (result) -> AnyPromise in
            
            guard let mostReadTitlesResponse = result as? WMFMostReadTitlesResponseItem else {
                completionHandler(.NoData)
                return AnyPromise(value: nil)
            }
            
            let articleURLs = mostReadTitlesResponse.articles.map({ (article) -> NSURL in
                return siteURL.wmf_URLWithTitle(article.titleText)
            })

            return self.articlePreviewFetcher.fetchArticlePreviewResultsForArticleURLs(articleURLs, siteURL: siteURL, extractLength: WMFNumberOfExtractCharacters, thumbnailWidth: UIScreen.mainScreen().wmf_listThumbnailWidthForScale().unsignedIntegerValue)
            }.then { (result) -> AnyPromise in
                guard let articlePreviewResponse = result as? [MWKSearchResult] else {
                    completionHandler(.NoData)
                    return AnyPromise(value: nil)
                }
                
                let results =  articlePreviewResponse.filter({ (result) -> Bool in
                    return result.articleID != 0
                })
                
                let group = WMFTaskGroup()                
                let resultsThatNeedASparkline = results[0...self.maximumRowCount]
                for result in resultsThatNeedASparkline {
                    guard let displayTitle = result.displayTitle else {
                        continue
                    }
                    group.enter()
                    let startDate = self.date.dateByAddingTimeInterval(-86400*self.daysToShowInSparkline)
                    let endDate = self.date.dateByAddingTimeInterval(86400) // One Day after
                    let URL = siteURL.wmf_URLWithTitle(displayTitle)
                    self.mostReadFetcher.fetchPageviewsForURL(URL, startDate: startDate, endDate: endDate, failure: { (error) in
                        group.leave()
                        }, success: { (results) in
                            result.viewCounts = results
                            group.leave()
                    })
                }
                
                group.waitInBackgroundWithCompletion({ 
                    self.results = results
                    
                    self.updateView()
                    completionHandler(.NewData)
                    
                    self.dataStore.readWriteWithBlock({ (conn) in
                        conn.setObject(results, forKey: databaseKey, inCollection: databaseCollection)
                    })
                });

                return AnyPromise(value: articlePreviewResponse)
        }
    }
    
    func showAllTopReadInApp() {
        guard let siteURLString = siteURL.absoluteString, let URL = NSUserActivity.wmf_URLForActivityOfType(.TopRead, parameters: ["timestamp": date.timeIntervalSince1970, "siteURL":siteURLString]) else {
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
        guard let displayTitle = result.displayTitle else {
            showAllTopReadInApp()
            return
        }
        
        let URL = siteURL.wmf_wikipediaSchemeURLWithTitle(displayTitle)
        self.extensionContext?.openURL(URL, completionHandler: { (success) in
            
        })
    }
    
}
