import UIKit
import WMF
import WMFComponents
import WMFData

@objc(WMFArticlePeekPreviewViewController)
class ArticlePeekPreviewViewController: UIViewController {
    
    let articleURL: URL
    private(set) var article: WMFArticle?
    fileprivate let dataStore: MWKDataStore
    fileprivate var theme: Theme
    fileprivate let activityIndicatorView: UIActivityIndicatorView = UIActivityIndicatorView(style: .large)
    fileprivate let expandedArticleView = ArticleFullWidthImageCollectionViewCell()
    private let needsEmptyContextMenuItems: Bool
    let needsRandomOnPush: Bool
    
    var project: WikimediaProject? {
        guard let siteURL = articleURL.wmf_site,
              let project = WikimediaProject(siteURL: siteURL) else {
            return nil
        }
        return project
    }
    
    // MARK: Previewing
    
    public weak var articlePreviewingDelegate: ArticlePreviewingDelegate?

    @objc required init(articleURL: URL, article: WMFArticle?, dataStore: MWKDataStore, theme: Theme, articlePreviewingDelegate: ArticlePreviewingDelegate?, needsEmptyContextMenuItems: Bool = false, needsRandomOnPush: Bool = false) {
        self.articleURL = articleURL
        self.article = article
        self.dataStore = dataStore
        self.theme = theme
        self.articlePreviewingDelegate = articlePreviewingDelegate
        self.needsEmptyContextMenuItems = needsEmptyContextMenuItems
        self.needsRandomOnPush = needsRandomOnPush
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        return nil
    }
    
    private var isFetched = false
    @objc func fetchArticle(_ completion:(() -> Void)? = nil ) {
        assert(Thread.isMainThread)
        guard !isFetched else {
            completion?()
            return
        }
        isFetched = true
        guard let key = articleURL.wmf_inMemoryKey else {
            completion?()
            return
        }
        dataStore.articleSummaryController.updateOrCreateArticleSummaryForArticle(withKey: key) { (article, _) in
            defer {
                completion?()
            }
            guard let article = article else {
                self.activityIndicatorView.stopAnimating()
                return
            }
            self.article = article
            self.updateView(with: article)
        }
    }
    
    func updatePreferredContentSize(for contentWidth: CGFloat) {
        var updatedContentSize = expandedArticleView.sizeThatFits(CGSize(width: contentWidth, height: UIView.noIntrinsicMetric), apply: true)
        updatedContentSize.width = contentWidth // extra protection to ensure this stays == width
        parent?.preferredContentSize = updatedContentSize
        preferredContentSize = updatedContentSize
    }
    
    fileprivate func updateView(with article: WMFArticle) {
        expandedArticleView.configure(article: article, displayType: .pageWithPreview, index: 0, theme: theme, layoutOnly: false)
        expandedArticleView.isSaveButtonHidden = true
        expandedArticleView.extractLabel?.numberOfLines = 5
        expandedArticleView.frame = view.bounds
        expandedArticleView.isHeaderBackgroundViewHidden = false
        expandedArticleView.headerBackgroundColor = theme.colors.midBackground
        expandedArticleView.isHidden = false

        activityIndicatorView.stopAnimating()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = theme.colors.paperBackground
        activityIndicatorView.color = theme.isDark ? .white : .gray
        activityIndicatorView.startAnimating()
        view.addSubview(activityIndicatorView)
        expandedArticleView.isHidden = true
        view.addSubview(expandedArticleView)
        expandedArticleView.updateFonts(with: traitCollection)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchArticle {
            self.updatePreferredContentSize(for: self.view.bounds.width)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        expandedArticleView.frame = view.bounds
        activityIndicatorView.center = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard viewIfLoaded != nil else {
            return
        }
        expandedArticleView.updateFonts(with: traitCollection)
    }
    
    var contextMenuItems: [UIAction] {
        guard !needsEmptyContextMenuItems else {
            return []
        }
        
        // Open action
        let openActionTitle = WMFLocalizedString("article-preview-menu-open", value: "Open", comment: "Button text displayed in a menu after long pressing an article link.")
        let openAction = UIAction(title: openActionTitle, image: WMFSFSymbolIcon.for(symbol: .book), handler: { (action) in
            self.articlePreviewingDelegate?.readMoreArticlePreviewActionSelected(with: self)
        })
        
        // Open in new tab action
        let openInNewTabActionTitle = WMFLocalizedString("article-preview-menu-open-new-tab", value: "Open in new tab", comment: "Button text displayed in a menu after long pressing an article link.")
        let openInNewTabAction = UIAction(title: openInNewTabActionTitle, image: WMFSFSymbolIcon.for(symbol: .tabs), handler: { [weak self] (action) in
            
                guard let self,
                let title = articleURL.wmf_title,
                let project = project?.wmfProject else {
                    return
                }
            
               let article = WMFData.Tab.Article(title: title, project: project)
               let newTab = WMFData.Tab(article: article)
               TabsDataController.shared.addTab(tab: newTab)
        })

        var actions = [openAction, openInNewTabAction]

        // Save action
        let logReadingListsSaveIfNeeded = { [weak self] in
            guard let delegate = self?.articlePreviewingDelegate as? MEPEventsProviding else {
                return
            }
            ReadingListsFunnel.shared.logSave(category: delegate.eventLoggingCategory, label: delegate.eventLoggingLabel, articleURL: self?.articleURL)
        }
        if articleURL.namespace == .main,
        let article {
            let saveActionTitle = article.isAnyVariantSaved ? WMFLocalizedString("button-saved-remove", value: "Remove from saved", comment: "Remove from saved button text used in various places.") : CommonStrings.saveTitle
            let saveAction = UIAction(title: saveActionTitle, image: WMFSFSymbolIcon.for(symbol: article.isAnyVariantSaved ? .bookmarkFill : .bookmark), handler: { (action) in
                let isSaved = self.dataStore.savedPageList.toggleSavedPage(for: self.articleURL)
                let notification = isSaved ? CommonStrings.accessibilitySavedNotification : CommonStrings.accessibilityUnsavedNotification
                UIAccessibility.post(notification: .announcement, argument: notification)
                self.articlePreviewingDelegate?.saveArticlePreviewActionSelected(with: self, didSave: isSaved, articleURL: self.articleURL)
            })
            actions.append(saveAction)
        }

        // Location action
        if let article,
           article.location != nil {
            let placeActionTitle = WMFLocalizedString("page-location", value: "View on a map", comment: "Label for button used to show an article on the map")
            let placeAction = UIAction(title: placeActionTitle, image: WMFSFSymbolIcon.for(symbol: .map), handler: { (action) in
                self.articlePreviewingDelegate?.viewOnMapArticlePreviewActionSelected(with: self)
            })
            actions.append(placeAction)
        }

        // Share action
        let shareActionTitle = CommonStrings.shareMenuTitle
        let shareAction = UIAction(title: shareActionTitle, image: WMFSFSymbolIcon.for(symbol: .squareAndArrowUp), handler: { (action) in
            guard let presenter = self.articlePreviewingDelegate as? UIViewController else {
                return
            }
            let customActivity = self.addToReadingListActivity(with: presenter, eventLogAction: logReadingListsSaveIfNeeded)
            guard let shareActivityViewController = self.sharingActivityViewController(with: nil, button: nil, customActivities: [customActivity]) else {
                return
            }
            self.articlePreviewingDelegate?.shareArticlePreviewActionSelected(with: self, shareActivityController: shareActivityViewController)
        })

        actions.append(shareAction)

        return actions
    }
    
    func addToReadingListActivity(with presenter: UIViewController, eventLogAction: @escaping () -> Void) -> UIActivity {
        let addToReadingListActivity = AddToReadingListActivity {
            guard let article = self.article else { return }
            let vc = AddArticlesToReadingListViewController(with: self.dataStore, articles: [article], theme: self.theme)
            vc.eventLogAction = eventLogAction
            let navigationController = WMFComponentNavigationController(rootViewController: vc, modalPresentationStyle: .overFullScreen)
            presenter.present(navigationController, animated: true)
        }
        return addToReadingListActivity
    }
    
    func sharingActivityViewController(with textSnippet: String?, button: UIBarButtonItem?, customActivities: [UIActivity]?) -> ShareActivityController? {
        guard let article else {
            return nil
        }
        let vc: ShareActivityController
        let textActivitySource = WMFArticleTextActivitySource(article: article, shareText: textSnippet)
        if let customActivities = customActivities, !customActivities.isEmpty {
            vc = ShareActivityController(customActivities: customActivities, article: article, textActivitySource: textActivitySource)
        } else {
            vc = ShareActivityController(article: article, textActivitySource: textActivitySource)
        }
        vc.popoverPresentationController?.barButtonItem = button
        return vc
    }

}
