import WMF
import SwiftUI
import CocoaLumberjackSwift
import WMFComponents
import WMFData

@objc(WMFArticleViewController)
class ArticleViewController: ThemeableViewController, HintPresenting, UIScrollViewDelegate, WMFNavigationBarConfiguring, WMFNavigationBarHiding {
    enum ViewState {
        case initial
        case loading
        case reloading
        case loaded
        case error
    }
    
    internal lazy var toolbarController: ArticleToolbarController = {
        return ArticleToolbarController(toolbar: toolbar, delegate: self)
    }()
    
    // Watchlist properies
    internal lazy var watchlistController: WatchlistController = {
        return WatchlistController(delegate: self, context: .article)
    }()
    var needsWatchButton: Bool = false
    var needsUnwatchHalfButton: Bool = false
    var needsUnwatchFullButton: Bool = false
    
    /// Article holds article metadata (displayTitle, description, etc) and user state (isSaved, viewedDate, viewedFragment, etc)
    internal var article: WMFArticle
    internal var mediaList: MediaList?
    
    /// Use separate properties for URL and language code since they're optional on WMFArticle and to save having to re-calculate them
    @objc public var articleURL: URL
    let articleLanguageCode: String

    /// Set by the state restoration system
    /// Scroll to the last viewed scroll position in this case
    /// Also prioritize pulling data from cache (without revision/etag validation) so the user sees the article as quickly as possible
    var isRestoringState: Bool = false
    
    /// Called when initial load starts
    @objc public var loadCompletion: (() -> Void)?
    
    /// Called when initial JS setup is complete
    @objc public var initialSetupCompletion: (() -> Void)?
    
    internal let schemeHandler: SchemeHandler
    internal let dataStore: MWKDataStore
    
    private let cacheController: ArticleCacheController

    internal var willDisplayFundraisingBanner: Bool = false

    // Tootltips
    public var tooltipViewModels: [WMFTooltipViewModel] = []

    private lazy var tabsCoordinator: TabsOverviewCoordinator? = { [weak self] in
        guard let self, let nav = self.navigationController else { return nil }
        return TabsOverviewCoordinator(
            navigationController: nav,
            theme: self.theme,
            dataStore: self.dataStore
        )
    }()

    // Coordinator
    private var _profileCoordinator: ProfileCoordinator?
    private var profileCoordinator: ProfileCoordinator? {
        
        guard let navigationController,
        let yirCoordinator = self.yirCoordinator else {
            return nil
        }
        
        guard let existingProfileCoordinator = _profileCoordinator else {
            _profileCoordinator = ProfileCoordinator(navigationController: navigationController, theme: theme, dataStore: dataStore, donateSouce: .articleProfile(articleURL), logoutDelegate: self, sourcePage: ProfileCoordinatorSource.article, yirCoordinator: yirCoordinator)
            _profileCoordinator?.badgeDelegate = self
            return _profileCoordinator
        }
        
        return existingProfileCoordinator
    }

    private var yirDataController: WMFYearInReviewDataController? {
        return try? WMFYearInReviewDataController()
    }

    private var _yirCoordinator: YearInReviewCoordinator?
    var yirCoordinator: YearInReviewCoordinator? {
        
        guard let navigationController,
              let yirDataController else {
            return nil
        }

        guard let existingYirCoordinator = _yirCoordinator else {
            _yirCoordinator = YearInReviewCoordinator(navigationController: navigationController, theme: theme, dataStore: dataStore, dataController: yirDataController)
            _yirCoordinator?.badgeDelegate = self
            return _yirCoordinator
        }
        
        return existingYirCoordinator
    }

    var session: Session {
        return dataStore.session
    }
    
    var configuration: Configuration {
        return dataStore.configuration
    }
    
    var project: WikimediaProject? {
        guard let siteURL = articleURL.wmf_site,
              let project = WikimediaProject(siteURL: siteURL) else {
            return nil
        }
        return project
    }
    
    internal var authManager: WMFAuthenticationManager {
        return dataStore.authenticationManager
    }
    
    internal lazy var fetcher: ArticleFetcher = ArticleFetcher(session: session, configuration: configuration)

    private var leadImageHeight: CGFloat = 210

    private var contentSizeObservation: NSKeyValueObservation? = nil
    
    /// Current ETag of the web content response. Used to verify when content has changed on the server.
    var currentETag: String?

    /// Used to delay reloading the web view to prevent `UIScrollView` jitter
    fileprivate var shouldPerformWebRefreshAfterScrollViewDeceleration = false

    lazy var refreshControl: UIRefreshControl = {
        let rc = UIRefreshControl()
        rc.addTarget(self, action: #selector(refresh), for: .valueChanged)
        return rc
    }()
    
    lazy var referenceWebViewBackgroundTapGestureRecognizer: UITapGestureRecognizer = {
        let tapGR = UITapGestureRecognizer(target: self, action: #selector(tappedWebViewBackground))
        tapGR.delegate = self
        webView.scrollView.addGestureRecognizer(tapGR)
        tapGR.isEnabled = false
        return tapGR
    }()

    // Coordinator used to navigate a user to the donate form from campaign modal
    var donateCoordinator: DonateCoordinator?
    
    var topSafeAreaOverlayHeightConstraint: NSLayoutConstraint?
    var topSafeAreaOverlayView: UIView?
    
    private var tocStackViewTopConstraint: NSLayoutConstraint?
    private var searchBarIsAnimating = false

    internal var articleViewSource: ArticleSource
    
    // Properties related to tracking number of seconds this article is viewed.
    var pageViewObjectID: NSManagedObjectID?
    let previousPageViewObjectID: NSManagedObjectID?
    var beganViewingDate: Date?
    
    // Article Tabs-related properties
    var coordinator: ArticleTabCoordinating?
    var previousArticleTab: WMFArticleTabsDataController.WMFArticle? = nil
    var nextArticleTab: WMFArticleTabsDataController.WMFArticle? = nil
    let tabDataController = WMFArticleTabsDataController.shared
    
    private let needsFocusOnSearch: Bool
    
    private var isMainPage: Bool {
        articleURL.wmf_title == "Main Page"
    }

    @objc init?(articleURL: URL, dataStore: MWKDataStore, theme: Theme, source: ArticleSource, schemeHandler: SchemeHandler? = nil, previousPageViewObjectID: NSManagedObjectID? = nil, needsFocusOnSearch: Bool = false) {

        guard let article = dataStore.fetchOrCreateArticle(with: articleURL) else {
                return nil
        }
        let cacheController = dataStore.cacheController.articleCache

        self.articleURL = articleURL
        self.articleLanguageCode = articleURL.wmf_languageCode ?? Locale.current.language.languageCode?.identifier ?? "en"
        self.article = article
        
        self.dataStore = dataStore
        self.schemeHandler = schemeHandler ?? SchemeHandler(scheme: "app", session: dataStore.session)
        self.cacheController = cacheController
        self.articleViewSource = source
        self.previousPageViewObjectID = previousPageViewObjectID
        
        self.needsFocusOnSearch = needsFocusOnSearch

        super.init(nibName: nil, bundle: nil)
        self.theme = theme
        hidesBottomBarWhenPushed = true
        
    }
    
    deinit {
        contentSizeObservation?.invalidate()
        messagingController.removeScriptMessageHandler()
        articleLoadWaitGroup = nil
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: WebView
    
    static let webProcessPool = WKProcessPool()
    
    private(set) var messagingController = ArticleWebMessagingController()
    
    lazy var webViewConfiguration: WKWebViewConfiguration = {
        let configuration = WKWebViewConfiguration()
        configuration.processPool = ArticleViewController.webProcessPool
        configuration.setURLSchemeHandler(schemeHandler, forURLScheme: schemeHandler.scheme)
        return configuration
    }()
    
    lazy var toolbarContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    lazy var toolbar: UIToolbar = {
        let tb = UIToolbar()
        tb.translatesAutoresizingMaskIntoConstraints = false
        return tb
    }()
    
    lazy var webView: WKWebView = {
        let webView = WMFWebView(frame: .zero, configuration: webViewConfiguration)
        webView.translatesAutoresizingMaskIntoConstraints = false
#if DEBUG
        webView.isInspectable = true
#endif
        return webView
    }()
    
    // MARK: HintPresenting
    
    var hintController: HintController?
    
    // MARK: Find In Page
    
    var findInPage = ArticleFindInPageState()
    
    // MARK: Responder chain
    
    override var canBecomeFirstResponder: Bool {
        return findInPage.view != nil
    }
    
    override var inputAccessoryView: UIView? {
        return findInPage.view
    }
    
    override func buildMenu(with builder: any UIMenuBuilder) {
        
        let shareMenuItemTitle = CommonStrings.shareMenuTitle
        let shareAction = UIAction(title: shareMenuItemTitle) { [weak self] _ in
            self?.shareMenuItemTapped()
        }
        let editMenuItemTitle = CommonStrings.editContextMenuTitle
        let editAction = UIAction(title: editMenuItemTitle) { [weak self]  _ in
            self?.editMenuItemTapped()
        }
        
        builder.remove(menu: .share)
        let menu = UIMenu(title: String(), image: nil, identifier: nil, options: .displayInline, children: [shareAction, editAction])
        builder.insertSibling(menu, afterMenu: .standardEdit)
        
        super.buildMenu(with: builder)
    }
    
    // MARK: Lead Image
    
    @objc func userDidTapLeadImage() {
        showLeadImage()
    }
    
    func loadLeadImage(with leadImageURL: URL) {
        leadImageHeightConstraint.constant = leadImageHeight
        leadImageView.wmf_setImage(with: leadImageURL, detectFaces: true, onGPU: true, failure: { (error) in
            DDLogWarn("Error loading lead image: \(error)")
        }) {
            self.updateLeadImageMargins()
            self.updateArticleMargins()
            
            /// see implementation in `extension ArticleViewController: UIContextMenuInteractionDelegate`
            let interaction = UIContextMenuInteraction(delegate: self)
            self.leadImageView.addInteraction(interaction)
        }
    }
    
    lazy var leadImageLeadingMarginConstraint: NSLayoutConstraint = {
        return leadImageView.leadingAnchor.constraint(equalTo: leadImageContainerView.leadingAnchor)
    }()
    
    lazy var leadImageTrailingMarginConstraint: NSLayoutConstraint = {
        return leadImageContainerView.trailingAnchor.constraint(equalTo: leadImageView.trailingAnchor)
    }()
    
    lazy var leadImageHeightConstraint: NSLayoutConstraint = {
        return leadImageContainerView.heightAnchor.constraint(equalToConstant: 0)
    }()
    
    lazy var leadImageView: UIImageView = {
        let imageView = NoIntrinsicContentSizeImageView(frame: .zero)
        imageView.isUserInteractionEnabled = true
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.accessibilityIgnoresInvertColors = true
        let tapGR = UITapGestureRecognizer(target: self, action: #selector(userDidTapLeadImage))
        imageView.addGestureRecognizer(tapGR)
        return imageView
    }()
    
    lazy var leadImageBorderHeight: CGFloat = {
        let scale = UIScreen.main.scale
        return scale > 1 ? 0.5 : 1
    }()
    
    lazy var leadImageContainerView: UIView = {
        
        let height: CGFloat = 10
        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: height))
        containerView.clipsToBounds = true
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        let borderView = UIView(frame: CGRect(x: 0, y: height - leadImageBorderHeight, width: 1, height: leadImageBorderHeight))
        borderView.backgroundColor = UIColor(white: 0, alpha: 0.2)
        borderView.autoresizingMask = [.flexibleTopMargin, .flexibleWidth]
        
        leadImageView.frame = CGRect(x: 0, y: 0, width: 1, height: height - leadImageBorderHeight)
        containerView.addSubview(leadImageView)
        containerView.addSubview(borderView)
        return containerView
    }()

    lazy var refreshOverlay: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.alpha = 0
        view.backgroundColor = .black
        view.isUserInteractionEnabled = true
        return view
    }()

    override func updateViewConstraints() {
        super.updateViewConstraints()
        updateLeadImageMargins()
    }
    
    func updateLeadImageMargins() {
        let doesArticleUseLargeMargin = (tableOfContentsController.viewController.displayMode == .inline && !tableOfContentsController.viewController.isVisible)
        var marginWidth: CGFloat = 0
        if doesArticleUseLargeMargin {
            marginWidth = articleHorizontalMargin
        }
        leadImageLeadingMarginConstraint.constant = marginWidth
        leadImageTrailingMarginConstraint.constant = marginWidth
    }
    
    // MARK: Layout
    
    override func viewLayoutMarginsDidChange() {
        super.viewLayoutMarginsDidChange()
        updateArticleMargins()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        tableOfContentsController.updateVerticalPaddings(top: 10, bottom: 0)
    }
    
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        
        guard searchBarIsAnimating else {
            tocStackViewTopConstraint?.constant = 0
            view.layoutIfNeeded()
            return
        }
        
        tocStackViewTopConstraint?.constant = view.safeAreaInsets.top
        UIView.animate(withDuration: 0.2) {
            self.view.layoutIfNeeded()
        }
    }
    
    internal func updateArticleMargins() {
        
        let defaultUpdateBlock = {
            self.messagingController.updateMargins(with: self.articleMargins, leadImageHeight: self.leadImageHeightConstraint.constant)
        }
        
        defaultUpdateBlock()
        
        updateLeadImageMargins()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        stashOffsetPercentage()
        super.viewWillTransition(to: size, with: coordinator)
        let marginUpdater: ((UIViewControllerTransitionCoordinatorContext) -> Void) = { _ in self.updateArticleMargins() }
        
        coordinator.animate(alongsideTransition: marginUpdater) { [weak self] _ in
            
            // Upon rotation completion, recalculate more button popover position
            
            guard let self else {
                return
            }
            
            self.watchlistController.calculatePopoverPosition(sender: self.toolbarController.moreButton, sourceView: self.toolbarController.moreButtonSourceView, sourceRect: self.toolbarController.moreButtonSourceRect)
            self.calculateTopSafeAreaOverlayHeight()
        }
    }
    
    // MARK: Loading
    
    var state: ViewState = .initial {
        didSet {
            switch state {
            case .initial:
                break
            case .reloading:
                fallthrough
            case .loading, .loaded:
                rethemeWebViewIfNecessary()
            case .error:
                break
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setup()

        setupForStateRestorationIfNecessary()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableOfContentsController.setup(with: traitCollection)
        toolbarController.update()
        loadIfNecessary()
        startSignificantlyViewedTimer()
        
        if !(UIDevice.current.userInterfaceIdiom == .pad) || !(traitCollection.horizontalSizeClass == .regular) {
            configureNavigationBar()
        }
    }
    
    var isFirstAppearance = true
    var needsTabsIconImpressonOnCancel = false
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        presentModalsIfNeeded()
        trackBeganViewingDate()
        coordinator?.syncTabsOnArticleAppearance()
        loadNextAndPreviousArticleTabs()
        
        let focusingOnSearch = false
        
        if let project {
            if isMainPage {
                if !focusingOnSearch {
                    ArticleTabsFunnel.shared.logIconImpression(interface: .mainPage, project: project)
                }
            } else {
                ArticleTabsFunnel.shared.logIconImpression(interface: .article, project: project)
            }
        }
        
        if UIDevice.current.userInterfaceIdiom == .pad && traitCollection.horizontalSizeClass == .regular {
            configureNavigationBar()
        }
    }
    
    @objc func userDidTapProfile() {
        guard let languageCode = dataStore.languageLinkController.appLanguage?.languageCode,
        let metricsID = DonateCoordinator.metricsID(for: .articleProfile(articleURL), languageCode: languageCode),
        let project else { return }
        
        DonateFunnel.shared.logArticleProfile(project: project, metricsID: metricsID)
        profileCoordinator?.start()
    }

    var showTabsOverview: (() -> Void)?

    @objc func userDidTapTabs() {
        tabsCoordinator?.start()
        if let wikimediaProject = WikimediaProject(siteURL: articleURL) {
            if isMainPage {
                ArticleTabsFunnel.shared.logIconClick(interface: .mainPage, project: wikimediaProject)
            } else {
                ArticleTabsFunnel.shared.logIconClick(interface: .article, project: wikimediaProject)
            }
        }
    }

    /// Catch-all method for deciding what is the best modal to present on top of Article at this point. This method needs careful if-else logic so that we do not present two modals at the same time, which may unexpectedly suppress one.
    private func presentModalsIfNeeded() {

        // Year in Review modal presentations
        if needsYearInReviewAnnouncement() {
            updateProfileButton()
            presentYearInReviewAnnouncement()
        
        // Campaign modal presentations
        } else {
            showFundraisingCampaignAnnouncementIfNeeded()
        }
    }
    
    @objc private func wButtonTapped(_ sender: UIButton) {
        navigationController?.popToRootViewController(animated: true)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        tableOfContentsController.update(with: traitCollection)
        toolbarController.update()
        
        if #available(iOS 18, *) {
            if UIDevice.current.userInterfaceIdiom == .pad {
                if previousTraitCollection?.horizontalSizeClass != traitCollection.horizontalSizeClass {
                    configureNavigationBar()
                }
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cancelWIconPopoverDisplay()
        saveArticleScrollPosition()
        stopSignificantlyViewedTimer()
        persistPageViewedSecondsForWikipediaInReview()
        
        if let tooltips = presentedViewController as? WMFTooltipViewController {
            tooltips.dismiss(animated: true)
        }
        
        
        guard #available(iOS 18.0, *),
              UIDevice.current.userInterfaceIdiom == .pad else {
            return
        }
        
        self.tabBarController?.setTabBarHidden(false, animated: true)
    }

    // MARK: Article load
    
    var articleLoadWaitGroup: DispatchGroup?

    func loadIfNecessary() {
        guard state == .initial else {
            return
        }
        load()
    }
    
    func load() {
        state = .loading
        
        setupPageContentServiceJavaScriptInterface {
            let cachePolicy: WMFCachePolicy? = self.isRestoringState ? .foundation(.returnCacheDataElseLoad) : nil
            self.loadPage(cachePolicy: cachePolicy, revisionID: nil)
        }
    }
    
    /// Waits for the article and article summary to finish loading (or re-loading) and performs post load actions
    private func setupArticleLoadWaitGroup() {
        assert(Thread.isMainThread)

        guard articleLoadWaitGroup == nil else {
            return
        }
        
        articleLoadWaitGroup = DispatchGroup()
        articleLoadWaitGroup?.enter() // will leave on setup complete
        articleLoadWaitGroup?.notify(queue: DispatchQueue.main) { [weak self] in
            
            guard let self = self else {
                return
            }
            
            self.setupFooter()
            self.shareIfNecessary()
            self.restoreScrollStateIfNecessary()
            self.logPageViewAfterArticleLoad()
            self.articleLoadWaitGroup = nil
        }
    }
    
    private func logPageViewAfterArticleLoad() {
        guard let pageID = article.pageID,
        let siteURL = self.articleURL.wmf_site,
              let project = WikimediaProject(siteURL: siteURL) else {
            return
        }
        
        ArticleLinkInteractionFunnel.shared.logArticleView(pageID: pageID.intValue, project: project, source: articleViewSource)
    }
    
    // Loads various additional data about the article from MediaWiki
    func loadMediaWikiInfoAndUpdateToolbar() {
        
        guard let title = articleURL.wmf_title,
            let siteURL = articleURL.wmf_site,
            let project = WikimediaProject(siteURL: siteURL)?.wmfProject else {
                return
        }
        
        let needsCategories = !isMainPage
        guard let request = try? WMFArticleDataController.ArticleInfoRequest(needsWatchedStatus: self.dataStore.authenticationManager.authStateIsPermanent, needsRollbackRights: false, needsCategories: needsCategories) else {
            self.needsWatchButton = false
            self.needsUnwatchFullButton = false
            self.needsUnwatchHalfButton = false
            self.toolbarController.updateMoreButton(needsWatchButton: self.needsWatchButton, needsUnwatchHalfButton: self.needsUnwatchHalfButton, needsUnwatchFullButton: self.needsUnwatchFullButton, previousArticleTab: self.previousArticleTab, nextArticleTab: self.nextArticleTab)
            return
        }
        
        WMFArticleDataController().fetchArticleInfo(title: title, project: project, request: request) { [weak self] result in
            
            guard let self else { return }
            
            switch result {
            case .success(let info):
                
                DispatchQueue.main.async {
                    self.needsWatchButton = !info.watched
                    self.needsUnwatchHalfButton = info.watched && info.watchlistExpiry != nil
                    self.needsUnwatchFullButton = info.watched && info.watchlistExpiry == nil
                    
                    self.toolbarController.updateMoreButton(needsWatchButton: self.needsWatchButton, needsUnwatchHalfButton: self.needsUnwatchHalfButton, needsUnwatchFullButton: self.needsUnwatchFullButton, previousArticleTab: self.previousArticleTab, nextArticleTab: self.nextArticleTab)
                    
                    if needsCategories {
                        self.saveCategories(categories: info.categories, articleTitle: title, project: project)
                    }
                }
                
            case .failure(let error):
                DDLogError("Error fetching article MediaWiki info: \(error)")
            }
        }
    }
    
    func loadNextAndPreviousArticleTabs() {
        Task { [weak self] in
            guard let self else { return }

            if let tabIdentifier = self.coordinator?.tabIdentifier {
                self.previousArticleTab = try? await tabDataController.getAdjacentArticleInTab(tabIdentifier: tabIdentifier, isPrev: true)
                self.nextArticleTab = try? await tabDataController.getAdjacentArticleInTab(tabIdentifier: tabIdentifier, isPrev: false)
            }
            
            Task { @MainActor in
                self.toolbarController.updateMoreButton(needsWatchButton: self.needsWatchButton, needsUnwatchHalfButton: self.needsUnwatchHalfButton, needsUnwatchFullButton: self.needsUnwatchFullButton, previousArticleTab: self.previousArticleTab, nextArticleTab: self.nextArticleTab)
            }
        }
    }
    
    internal func loadSummary(oldState: ViewState) {
        guard let key = article.inMemoryKey else {
            return
        }
        
        var oldFeedPreview: WMFFeedArticlePreview?
        if isWidgetCachedFeaturedArticle {
            oldFeedPreview = article.feedArticlePreview()
        }
        
        articleLoadWaitGroup?.enter()
        let cachePolicy: URLRequest.CachePolicy? = oldState == .reloading ? .reloadRevalidatingCacheData : nil
        
        self.dataStore.articleSummaryController.updateOrCreateArticleSummaryForArticle(withKey: key, cachePolicy: cachePolicy) { (article, error) in
            defer {
                self.articleLoadWaitGroup?.leave()
            }
            guard let article = article else {
                return
            }
            self.article = article
            
            if let oldFeedPreview,
               let newFeedPreview = article.feedArticlePreview(),
            oldFeedPreview != newFeedPreview {
                SharedContainerCacheClearFeaturedArticleWrapper.clearOutFeaturedArticleWidgetCache()
                WidgetController.shared.reloadFeaturedArticleWidgetIfNecessary()
            }
            
            // Handle redirects
            guard let newKey = article.inMemoryKey, newKey != key, let newURL = article.url else {
                return
            }
            self.articleURL = newURL
            self.addToHistory()
        }
    }
    
    func loadPage(cachePolicy: WMFCachePolicy? = nil, revisionID: UInt64? = nil) {
        defer {
            callLoadCompletionIfNecessary()
        }
        
        guard var request = try? fetcher.mobileHTMLRequest(articleURL: articleURL, revisionID: revisionID, scheme: schemeHandler.scheme, cachePolicy: cachePolicy, isPageView: true) else {
            showGenericError()
            state = .error
            return
        }

        // Add the URL fragment to request, if the fragment exists
        if let articleFragment = URLComponents(url: articleURL, resolvingAgainstBaseURL: true)?.fragment,
           let url = request.url,
           var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true) {
            urlComponents.fragment = articleFragment
            request.url = urlComponents.url
        }

        webView.load(request)
    }
    
    func syncCachedResourcesIfNeeded() {
        guard let groupKey = articleURL.wmf_databaseKey else {
            return
        }
        
        fetcher.isCached(articleURL: articleURL) { [weak self] (isCached) in
            
            guard let self = self,
                isCached else {
                    return
            }
            
            self.cacheController.syncCachedResources(url: self.articleURL, groupKey: groupKey) { (result) in
                switch result {
                case .success(let itemKeys):
                    DDLogDebug("successfully synced \(itemKeys.count) resources")
                case .failure(let error):
                    DDLogError("failed to synced resources for \(groupKey): \(error)")
                }
            }
        }
    }
    
    // MARK: Navigation Bar
    
    private func configureNavigationBar() {

        let wButton = UIButton(type: .custom)
        wButton.setImage(UIImage(named: "W"), for: .normal)
        wButton.addTarget(self, action: #selector(wButtonTapped(_:)), for: .touchUpInside)
        
        var titleConfig: WMFNavigationBarTitleConfig = WMFNavigationBarTitleConfig(title: articleURL.wmf_title ?? "", customView: wButton, alignment: .centerCompact)
        
        if #available(iOS 18, *) {
            if UIDevice.current.userInterfaceIdiom == .pad && traitCollection.horizontalSizeClass == .regular {
                titleConfig = WMFNavigationBarTitleConfig(title: articleURL.wmf_title ?? "", customView: nil, alignment: .hidden)
            }
        }
        
        let backButtonConfig = WMFNavigationBarBackButtonConfig(needsCustomTruncateBackButtonTitle: true)
        
        let profileButtonConfig = profileButtonConfig(target: self, action: #selector(userDidTapProfile), dataStore: dataStore, yirDataController: yirDataController, leadingBarButtonItem: nil)

        let tabsButtonConfig = tabsButtonConfig(target: self, action: #selector(userDidTapTabs), dataStore: dataStore)
        
        let searchViewController = SearchViewController(source: .article, customArticleCoordinatorNavigationController: navigationController)
        searchViewController.dataStore = dataStore
        searchViewController.theme = theme
        searchViewController.shouldBecomeFirstResponder = true
        searchViewController.customTabConfigUponArticleNavigation = .appendArticleAndAssignCurrentTabAndCleanoutFutureArticles
        
        let populateSearchBarWithTextAction: (String) -> Void = { [weak self] searchTerm in
            self?.navigationItem.searchController?.searchBar.text = searchTerm
            self?.navigationItem.searchController?.searchBar.becomeFirstResponder()
        }
        
        searchViewController.populateSearchBarWithTextAction = populateSearchBarWithTextAction
        
        let searchBarConfig = WMFNavigationBarSearchConfig(searchResultsController: searchViewController, searchControllerDelegate: self, searchResultsUpdater: self, searchBarDelegate: nil, searchBarPlaceholder: CommonStrings.searchBarPlaceholder, showsScopeBar: false, scopeButtonTitles: nil)

        configureNavigationBar(titleConfig: titleConfig, backButtonConfig: backButtonConfig, closeButtonConfig: nil, profileButtonConfig: profileButtonConfig, tabsButtonConfig: tabsButtonConfig, searchBarConfig: searchBarConfig, hideNavigationBarOnScroll: true)
    }
    
    private func updateProfileButton() {

        let config = self.profileButtonConfig(target: self, action: #selector(userDidTapProfile), dataStore: dataStore, yirDataController: yirDataController, leadingBarButtonItem: nil)

        updateNavigationBarProfileButton(needsBadge: config.needsBadge, needsBadgeLabel: CommonStrings.profileButtonBadgeTitle, noBadgeLabel: CommonStrings.profileButtonTitle)
    }
    
    // MARK: History

    func addToHistory() {
        try? article.addToReadHistory()
    }
    
    var significantlyViewedTimer: Timer?
    
    func startSignificantlyViewedTimer() {
        guard significantlyViewedTimer == nil, !article.wasSignificantlyViewed else {
            return
        }
        
        significantlyViewedTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: false, block: { [weak self] (timer) in
            
            guard let self else {
                return
            }
            
            self.article.wasSignificantlyViewed = true
            self.stopSignificantlyViewedTimer()
        })
    }
    
    func stopSignificantlyViewedTimer() {
        significantlyViewedTimer?.invalidate()
        significantlyViewedTimer = nil
    }
    
    // MARK: Scroll State Restoration
    
    /// Tracks desired scroll restoration.
    /// This occurs when a user is re-opening the app and expects the article to be scrolled to the last position they were reading at or when a user taps on a link that goes to a particular section in another article.
    /// The state needs to be preserved because the given offset or anchor will not be availble until after the page fully loads.
    /// `scrollToOffset` and `scrollToAnchor` will track attempts made after each `webView.contentSize` change, hoping the requested offset or anchor is available. After a certain number of attempts, it's assumed that the value is invalid and the restoration logic gives up.
    private enum ScrollRestorationState {
        case none
        /// Scroll to absolute Y offset
        case scrollToOffset(_ offsetY: CGFloat, animated: Bool, attempt: Int = 1, maxAttempts: Int = 5, completion: ((Bool, Bool) -> Void)? = nil)
        /// Scroll to percentage Y offset
        case scrollToPercentage(_ percentageOffsetY: CGFloat)
        /// Scroll to anchor, an id of an element on the page
        case scrollToAnchor(_ anchor: String, attempt: Int = 1, maxAttempts: Int = 5, completion: ((Bool, Bool) -> Void)? = nil)
    }
    
    private var scrollRestorationState: ScrollRestorationState = .none
    
    /// Checks scrollRestorationState and performs the necessary scroll restoration
    private func restoreScrollStateIfNecessary() {
        switch scrollRestorationState {
        case .none:
            break
        case .scrollToOffset(let offset, let animated, let attempt, let maxAttempts, let completion):
            scrollRestorationState = .none
            self.scroll(to: CGPoint(x: 0, y: offset), animated: animated) { [weak self] (success) in
                guard !success, attempt < maxAttempts else {
                    completion?(success, attempt >= maxAttempts)
                    return
                }
                self?.scrollRestorationState = .scrollToOffset(offset, animated: animated, attempt: attempt + 1, maxAttempts: maxAttempts, completion: completion)
            }
        case .scrollToPercentage(let verticalOffsetPercentage):
            scrollRestorationState = .none
            webView.scrollView.verticalOffsetPercentage = verticalOffsetPercentage
        case .scrollToAnchor(let anchor, let attempt, let maxAttempts, let completion):
            scrollRestorationState = .none
            self.scroll(to: anchor, animated: true) { [weak self] (success) in
                guard !success, attempt < maxAttempts else {
                    completion?(success, attempt >= maxAttempts)
                    return
                }
                self?.scrollRestorationState = .scrollToAnchor(anchor, attempt: attempt + 1, maxAttempts: maxAttempts, completion: completion)
            }
            
            // HACK: Sometimes the `scroll_to_anchor` message is not triggered from the web view over the JS bridge, even after prepareForScrollToAnchor successfully goes through. This means the completion block above is queued to scrollToAnchorCompletions but never run. We are trying to scroll again here once more after a slight delay in hopes of triggering `scroll_to_anchor` again.
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.3) { [weak self] in
                
                guard let self = self else {
                    return
                }
                
                // This conditional check should target the bug a little closer, since scrollToAnchorCompletions are cleaned out after the last `scroll_to_anchor` message is received. Remaining scrollToAnchorCompletions at this point indicates that likely we're hitting the missing `scroll_to_anchor` message bug.
                if self.scrollToAnchorCompletions.count > 0 {
                    self.scroll(to: anchor, animated: false)
                }
            }
        }
    }
    
    internal func stashOffsetPercentage() {
        let offset = webView.scrollView.verticalOffsetPercentage
        // negative and 0 offsets make small errors in scrolling, allow it to automatically handle those cases
        if offset > 0 {
            scrollRestorationState = .scrollToPercentage(offset)
        }
    }
    
    private func checkForScrollToAnchor(in response: HTTPURLResponse) {
        guard let fragment = response.url?.fragment else {
            return
        }
        scrollRestorationState = .scrollToAnchor(fragment, attempt: 1)
    }
    
    // MARK: Article State Restoration
    
    /// Save article scroll position for restoration later
    func saveArticleScrollPosition() {
        getVisibleSection { (sectionId, anchor) in
            assert(Thread.isMainThread)
            self.article.viewedScrollPosition = Double(self.webView.scrollView.contentOffset.y)
            self.article.viewedFragment = anchor
            try? self.article.managedObjectContext?.save()
        }
    }
    
    /// Perform any necessary initial configuration for state restoration
    func setupForStateRestorationIfNecessary() {
        guard isRestoringState else {
            return
        }
        setWebViewHidden(true, animated: false)
    }
    
    /// Translates an article's viewedScrollPosition or viewedFragment values to a scrollRestorationState. These values are saved to the article object when the ArticleVC disappears,the app is backgrounded, or an edit is made and the article is reloaded.
    func assignScrollStateFromArticleFlagsIfNecessary() {
        guard isRestoringState else {
            return
        }
        isRestoringState = false
        let scrollPosition = CGFloat(article.viewedScrollPosition)
        if scrollPosition > 0 {
            scrollRestorationState = .scrollToOffset(scrollPosition, animated: false, completion: { [weak self] success, maxedAttempts in
                if success || maxedAttempts {
                    self?.setWebViewHidden(false, animated: true)
                }
            })
        } else if let fragment = article.viewedFragment {
            scrollRestorationState = .scrollToAnchor(fragment, completion: { [weak self] success, maxedAttempts in
                if success || maxedAttempts {
                    self?.setWebViewHidden(false, animated: true)
                }
            })
        } else {
            setWebViewHidden(false, animated: true)
        }
    }
    
    func setWebViewHidden(_ hidden: Bool, animated: Bool, completion: ((Bool) -> Void)? = nil) {
        let block = {
            self.webView.alpha = hidden ? 0 : 1
        }
        guard animated else {
            block()
            completion?(true)
            return
        }
        UIView.animate(withDuration: 0.3, animations: block, completion: completion)
    }
    
    func callLoadCompletionIfNecessary() {
        loadCompletion?()
        loadCompletion = nil
    }
    
    // MARK: Theme
    
    lazy var themesPresenter: ReadingThemesControlsArticlePresenter = {
        return ReadingThemesControlsArticlePresenter(readingThemesControlsViewController: themesViewController, wkWebView: webView, readingThemesControlsToolbarItem: toolbarController.themeButton)
    }()
    
    private lazy var themesViewController: ReadingThemesControlsViewController = {
        return ReadingThemesControlsViewController(nibName: ReadingThemesControlsViewController.nibName, bundle: nil)
    }()
    
    override func apply(theme: Theme) {
        super.apply(theme: theme)

        guard viewIfLoaded != nil else {
            return
        }
        
        view.backgroundColor = theme.colors.paperBackground
        webView.scrollView.indicatorStyle = theme.scrollIndicatorStyle
        toolbarController.apply(theme: theme)
        tableOfContentsController.apply(theme: theme)
        findInPage.view?.apply(theme: theme)
        if state == .loaded {
            messagingController.updateTheme(theme)
        }
        yirCoordinator?.theme = theme
        profileCoordinator?.theme = theme
        
        updateProfileButton()
        
        themeNavigationBarCustomCenteredTitleView()
        themeTopSafeAreaOverlay()
        
        if let searchVC = navigationItem.searchController?.searchResultsController as? SearchViewController {
            searchVC.theme = theme
            searchVC.apply(theme: theme)
        }
        
        toolbarContainerView.backgroundColor = theme.colors.paperBackground
        toolbar.setBackgroundImage(theme.navigationBarBackgroundImage, forToolbarPosition: .any, barMetrics: .default)
        toolbar.isTranslucent = false
        
        messagingController.updateDarkModeMainPageIfNeeded(articleURL: articleURL, theme: theme)
    }
    
    private func rethemeWebViewIfNecessary() {
        // Sometimes the web view theme and article theme is out if sync
        // The last call to update the theme comes before the web view is fully loaded to accept a theme change
        // In this case we are checking and triggering a web view theme change once more after the JS bridge indicates it's loaded
        // https://phabricator.wikimedia.org/T275239
        if let webViewTheme = messagingController.parameters?.theme,
           webViewTheme != self.theme.webName {
            messagingController.updateTheme(theme)
        }
    }
    
    // MARK: Sharing
    
    private var isSharingWhenReady = false
    
    @objc public func shareArticleWhenReady() {
        isSharingWhenReady = true
    }
    
    func shareIfNecessary() {
        guard isSharingWhenReady else {
            return
        }
        isSharingWhenReady = false
        shareArticle()
    }
    
    // MARK: Navigation
    
    @objc(showAnchor:)
    func show(anchor: String) {
        dismiss(animated: false)
        scroll(to: anchor, animated: true)
    }
    
    // MARK: Refresh
    
    @objc public func refresh() {
        state = .reloading
        if !shouldPerformWebRefreshAfterScrollViewDeceleration {
            updateRefreshOverlay(visible: true)
        }
        shouldPerformWebRefreshAfterScrollViewDeceleration = true
    }
    
    /// Preserves the current scroll position, loads the provided revisionID or waits for a change in etag on the mobile-html response, then refreshes the page and restores the prior scroll position
    internal func waitForNewContentAndRefresh(_ revisionID: UInt64? = nil) {
        state = .reloading
        saveArticleScrollPosition()
        isRestoringState = true
        setupForStateRestorationIfNecessary()
        // If a revisionID was provided, just load that revision
        if let revisionID = revisionID {
            performWebViewRefresh(revisionID)
            return
        }
        // If no revisionID was provided, wait for the ETag to change
        guard let eTag = currentETag else {
            performWebViewRefresh()
            return
        }
        fetcher.waitForMobileHTMLChange(articleURL: articleURL, eTag: eTag, maxAttempts: 5) { (result) in
            DispatchQueue.main.async {
                switch result {
                case .failure(let error):
                    self.showError(error, sticky: true)
                    fallthrough
                default:
                    self.performWebViewRefresh()
                }
            }
        }
    }

    internal func performWebViewRefresh(_ revisionID: UInt64? = nil) {

        switch Configuration.current.environment {
        case .local(let options):
            if options.contains(.localPCS) {
                webView.reloadFromOrigin()
            } else {
                loadPage(cachePolicy: .noPersistentCacheOnError, revisionID: revisionID)
            }
        default:
            loadPage(cachePolicy: .noPersistentCacheOnError, revisionID: revisionID)
        }
    }

    internal func updateRefreshOverlay(visible: Bool, animated: Bool = true) {
        let duration = animated ? (visible ? 0.15 : 0.1) : 0.0
        let alpha: CGFloat = visible ? 0.3 : 0.0
        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: duration, delay: 0, options: [.curveEaseIn], animations: {
            self.refreshOverlay.alpha = alpha
        })
        toolbarController.setToolbarButtons(enabled: !visible)
    }
    
    internal func performWebRefreshAfterScrollViewDecelerationIfNeeded() {
        guard shouldPerformWebRefreshAfterScrollViewDeceleration else {
            return
        }
        webView.scrollView.showsVerticalScrollIndicator = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
            self.performWebViewRefresh()
        })
    }
    
    // MARK: Overrideable functionality
    
    internal func handleLink(with href: String) {

        guard let resolvedURL = articleURL.resolvingRelativeWikiHref(href) else {
            showGenericError()
            return
        }
        // Check if this is the same article by comparing in-memory keys
        guard resolvedURL.wmf_inMemoryKey == articleURL.wmf_inMemoryKey else {
            
            let legacyNavigateAction = { [weak self] in
                let userInfo: [AnyHashable : Any] = [RoutingUserInfoKeys.source: RoutingUserInfoSourceValue.article.rawValue]
                self?.navigate(to: resolvedURL, userInfo: userInfo)
            }
            
            // first try to navigate using LinkCoordinator. If it fails, use the legacy approach.
            if let navigationController {
                
                let linkCoordinator = LinkCoordinator(navigationController: navigationController, url: resolvedURL, dataStore: dataStore, theme: theme, articleSource: .internal_link, previousPageViewObjectID: pageViewObjectID, tabConfig: .appendArticleAndAssignCurrentTabAndCleanoutFutureArticles)
                let success = linkCoordinator.start()
                guard success else {
                    legacyNavigateAction()
                    return
                }
            } else {
                legacyNavigateAction()
            }
            
            return
        }
        // Check for a fragment - if this is the same article and there's no fragment just do nothing?
        guard let anchor = resolvedURL.fragment?.removingPercentEncoding else {
            return
        }

        scroll(to: anchor, animated: true)
    }
    
    // MARK: Table of contents
    
    lazy var tableOfContentsController: ArticleTableOfContentsDisplayController = ArticleTableOfContentsDisplayController(articleView: webView, delegate: self, theme: theme)
    
    var tableOfContentsItems: [TableOfContentsItem] = [] {
        didSet {
            tableOfContentsController.viewController.reload()
        }
    }
    
    var previousContentOffsetYForTOCUpdate: CGFloat = 0
    
    func updateTableOfContentsHighlightIfNecessary() {
        guard tableOfContentsController.viewController.displayMode == .inline, tableOfContentsController.viewController.isVisible else {
            return
        }
        let scrollView = webView.scrollView
        guard abs(previousContentOffsetYForTOCUpdate - scrollView.contentOffset.y) > 15 else {
            return
        }
        guard scrollView.isTracking || scrollView.isDragging || scrollView.isDecelerating else {
            return
        }
        updateTableOfContentsHighlight()
    }
    
    func updateTableOfContentsHighlight() {
        previousContentOffsetYForTOCUpdate = webView.scrollView.contentOffset.y
        getVisibleSection { (sectionId, _) in
            self.tableOfContentsController.selectAndScroll(to: sectionId, animated: true)
        }
    }
    
    func updateTableOfContentsInsets() {
        let tocScrollView = tableOfContentsController.viewController.tableView
        let topOffsetY = 0 - tocScrollView.contentInset.top
        let wasAtTop = tocScrollView.contentOffset.y <= topOffsetY
        switch tableOfContentsController.viewController.displayMode {
        case .inline:
            tocScrollView.contentInset = webView.scrollView.contentInset
            tocScrollView.verticalScrollIndicatorInsets = webView.scrollView.verticalScrollIndicatorInsets
        case .modal:
            tocScrollView.contentInset = UIEdgeInsets(top: view.safeAreaInsets.top, left: 0, bottom: view.safeAreaInsets.bottom, right: 0)
            tocScrollView.scrollIndicatorInsets = tocScrollView.contentInset
        }
        guard wasAtTop else {
            return
        }
        tocScrollView.contentOffset = CGPoint(x: 0, y: topOffsetY)
    }
    
    // MARK: Scroll

    var scrollToAnchorCompletions: [ScrollToAnchorCompletion] = []
    var scrollViewAnimationCompletions: [() -> Void] = []

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateTableOfContentsHighlightIfNecessary()

        calculateNavigationBarHiddenState(scrollView: webView.scrollView)
        
        guard #available(iOS 18.0, *),
              UIDevice.current.userInterfaceIdiom == .pad else {
            return
        }

        let velocity = scrollView.panGestureRecognizer.velocity(in: scrollView).y

        if velocity < 0 { // Scrolling down
            tabBarController?.setTabBarHidden(true, animated: true)
        } else if velocity > 0 { // Scrolling up
            tabBarController?.setTabBarHidden(false, animated: true)
        }
    }
    
    func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        updateTableOfContentsHighlight()
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        dismissReferencesPopover()
        hintController?.dismissHintDueToUserInteraction()
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        performWebRefreshAfterScrollViewDecelerationIfNeeded()
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if velocity == .zero {
            performWebRefreshAfterScrollViewDecelerationIfNeeded()
        }
    }
    
    // MARK: Analytics
    
    internal lazy var readingListsFunnel = ReadingListsFunnel.shared
}

private extension ArticleViewController {
    
    func setup() {
        addNotificationHandlers()
        setupToolbar()
        setupWebView()
        setupMessagingController()
        
        setupTopSafeAreaOverlay(scrollView: webView.scrollView)
    }

    // MARK: Notifications
    
    func addNotificationHandlers() {
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveArticleUpdatedNotification), name: NSNotification.Name.WMFArticleUpdated, object: article)
        NotificationCenter.default.addObserver(self, selector: #selector(self.textSizeChanged(notification:)), name: NSNotification.Name(rawValue: FontSizeSliderViewController.WMFArticleFontSizeUpdatedNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillResignActive), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(coreDataStoreSetup), name: WMFNSNotification.coreDataStoreSetup, object: nil)
        contentSizeObservation = webView.scrollView.observe(\.contentSize) { [weak self] (scrollView, change) in
            self?.contentSizeDidChange()
        }
    }
    
    /// Track and debounce `contentSize` changes to wait for a desired scroll position to become available. See `ScrollRestorationState` for more information.
    func contentSizeDidChange() {
        // debounce
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(debouncedContentSizeDidChange), object: nil)
        perform(#selector(debouncedContentSizeDidChange), with: nil, afterDelay: 0.1)
    }
    
    @objc func debouncedContentSizeDidChange() {
        restoreScrollStateIfNecessary()
    }
    
    @objc func didReceiveArticleUpdatedNotification(_ notification: Notification) {
        toolbarController.setSavedState(isSaved: article.isAnyVariantSaved)
    }
    
    @objc func textSizeChanged(notification: Notification) {
        if let multiplier = notification.userInfo?[FontSizeSliderViewController.WMFArticleFontSizeMultiplierKey] as? Int {
            messagingController.updateTextSizeAdjustmentPercentage(multiplier)
        }
    }
    
    @objc func applicationWillResignActive(_ notification: Notification) {
        saveArticleScrollPosition()
        stopSignificantlyViewedTimer()
        persistPageViewedSecondsForWikipediaInReview()
    }
    
    @objc func applicationDidBecomeActive(_ notification: Notification) {
        startSignificantlyViewedTimer()
        trackBeganViewingDate()
    }
    
    @objc func coreDataStoreSetup(_ notification: Notification) {
        configureNavigationBar()

        // Sometimes there is a race condition where the Core Data store isn't yet ready to persist tabs information (for example, deep linking to an article when in a terminated state). We are trying again here.
        if coordinator?.tabIdentifier == nil || coordinator?.tabItemIdentifier == nil {
            Task {
                await coordinator?.trackArticleTab(articleViewController: self)
            }
        }
    }
    
    func setupMessagingController() {
        messagingController.delegate = self
    }
    
    func setupWebView() {

        // Add the stack view that contains the table of contents and the web view.
        // This stack view is owned by the tableOfContentsController to control presentation of the table of contents
        tableOfContentsController.stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableOfContentsController.stackView)
        let stackViewTopConstraint = tableOfContentsController.stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0)
        NSLayoutConstraint.activate([
            stackViewTopConstraint,
            view.safeAreaLayoutGuide.leadingAnchor.constraint(equalTo: tableOfContentsController.stackView.leadingAnchor),
            view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: tableOfContentsController.stackView.trailingAnchor),
            toolbarContainerView.topAnchor.constraint(equalTo: tableOfContentsController.stackView.bottomAnchor)
        ])
        
        self.tocStackViewTopConstraint = stackViewTopConstraint
        
        view.widthAnchor.constraint(equalTo: tableOfContentsController.inlineContainerView.widthAnchor, multiplier: 3).isActive = true

        // Prevent flash of white in dark mode
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        
        // Scroll view
        webView.scrollView.delegate = self
        webView.scrollView.keyboardDismissMode = .interactive
        webView.scrollView.refreshControl = refreshControl
        
        // Lead image
        setupLeadImageView()

        // Add overlay to prevent interaction while reloading
        webView.wmf_addSubviewWithConstraintsToEdges(refreshOverlay)
        
        // Delegates
        webView.uiDelegate = self
        webView.navigationDelegate = self
        
        // User Agent
        webView.customUserAgent = WikipediaAppUtils.versionedUserAgent()
    }
    
    /// Adds the lead image view to the web view's scroll view and configures the associated constraints
    func setupLeadImageView() {
        webView.scrollView.addSubview(leadImageContainerView)

        let leadingConstraint =  leadImageContainerView.leadingAnchor.constraint(equalTo: webView.leadingAnchor)
        let trailingConstraint =  webView.trailingAnchor.constraint(equalTo: leadImageContainerView.trailingAnchor)
        let topConstraint = webView.scrollView.topAnchor.constraint(equalTo: leadImageContainerView.topAnchor)
        let imageTopConstraint = leadImageView.topAnchor.constraint(equalTo:  leadImageContainerView.topAnchor)
        imageTopConstraint.priority = UILayoutPriority(rawValue: 999)
        let imageBottomConstraint = leadImageContainerView.bottomAnchor.constraint(equalTo: leadImageView.bottomAnchor, constant: leadImageBorderHeight)
        NSLayoutConstraint.activate([topConstraint, leadingConstraint, trailingConstraint, leadImageHeightConstraint, imageTopConstraint, imageBottomConstraint, leadImageLeadingMarginConstraint, leadImageTrailingMarginConstraint])
    }
    
    func setupPageContentServiceJavaScriptInterface(with completion: @escaping () -> Void) {
        guard let siteURL = articleURL.wmf_site else {
            DDLogError("Missing site for \(articleURL)")
            showGenericError()
            return
        }
        
        // Need user groups to let the Page Content Service know if the page is editable for this user
        let user = authManager.permanentUser(siteURL: siteURL)
        setupPageContentServiceJavaScriptInterface(with: user?.groups ?? [])
        completion()
    }
    
    func setupPageContentServiceJavaScriptInterface(with userGroups: [String]) {
        let areTablesInitiallyExpanded = UserDefaults.standard.wmf_isAutomaticTableOpeningEnabled

        messagingController.setup(with: webView, languageCode: articleLanguageCode, theme: theme, layoutMargins: articleMargins, leadImageHeight: leadImageHeight, areTablesInitiallyExpanded: areTablesInitiallyExpanded, userGroups: userGroups)
    }
    
    func setupToolbar() {
        toolbarContainerView.addSubview(toolbar)
        view.addSubview(toolbarContainerView)
        
        NSLayoutConstraint.activate([
            toolbarContainerView.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: toolbar.bottomAnchor),
            toolbarContainerView.leadingAnchor.constraint(equalTo: toolbar.leadingAnchor),
            toolbarContainerView.trailingAnchor.constraint(equalTo: toolbar.trailingAnchor),
            toolbarContainerView.topAnchor.constraint(equalTo: toolbar.topAnchor),
            view.bottomAnchor.constraint(equalTo: toolbarContainerView.bottomAnchor),
            view.leadingAnchor.constraint(equalTo: toolbarContainerView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: toolbarContainerView.trailingAnchor)
        ])
    }
    
    var isWidgetCachedFeaturedArticle: Bool {
        let sharedCache = SharedContainerCache(fileName: SharedContainerCacheCommonNames.widgetCache)
        
        let cache = sharedCache.loadCache() ?? WidgetCache(settings: .default, featuredContent: nil)
        guard let widgetFeaturedArticleURLString = cache.featuredContent?.featuredArticle?.contentURL.desktop.page,
              let widgetFeaturedArticleURL = URL(string: widgetFeaturedArticleURLString) else {
            return false
        }
        
        return widgetFeaturedArticleURL == articleURL
    }
    
}

extension ArticleViewController {
    func presentEmbedded(_ viewController: UIViewController) {
        let nc = WMFComponentNavigationController(rootViewController: viewController, modalPresentationStyle: .overFullScreen)
        present(nc, animated: true)
    }
}

extension ArticleViewController: ReadingThemesControlsResponding {
    func updateWebViewTextSize(textSize: Int) {
        messagingController.updateTextSizeAdjustmentPercentage(textSize)
    }
    
    func toggleSyntaxHighlighting(_ controller: ReadingThemesControlsViewController) {
        // no-op here, syntax highlighting shouldnt be displayed
    }
}

extension ArticleViewController: ImageScaleTransitionProviding {
    var imageScaleTransitionView: UIImageView? {
        return leadImageView
    }
    
    func prepareViewsForIncomingImageScaleTransition(with imageView: UIImageView?) {
        guard let imageView = imageView, let image = imageView.image else {
            return
        }
        
        leadImageHeightConstraint.constant = leadImageHeight
        leadImageView.image = image
        leadImageView.layer.contentsRect = imageView.layer.contentsRect
        
        view.layoutIfNeeded()
    }
    
}

// MARK: - Article Load Errors

extension ArticleViewController {
    func handleArticleLoadFailure(with error: Error, showEmptyView: Bool) {
        if showEmptyView {
            wmf_showEmptyView(of: .articleDidNotLoad, theme: theme, frame: view.bounds)
        }
        showError(error)
        refreshControl.endRefreshing()
        updateRefreshOverlay(visible: false)
    }
    
    func articleLoadDidFail(with error: Error) {
        handleArticleLoadFailure(with: error, showEmptyView: !article.isSaved)
    }
}

extension ArticleViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        switch navigationAction.navigationType {
        case .reload:
            fallthrough
        case .other:
            setupArticleLoadWaitGroup()
            decisionHandler(.allow)
        default:
            decisionHandler(.cancel)
        }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, preferences: WKWebpagePreferences, decisionHandler: @escaping (WKNavigationActionPolicy, WKWebpagePreferences) -> Void) {
        switch navigationAction.navigationType {
        case .reload:
            fallthrough
        case .other:
            setupArticleLoadWaitGroup()
            decisionHandler(.allow, preferences)
        default:
            decisionHandler(.cancel, preferences)
        }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        defer {
            decisionHandler(.allow)
        }
        guard let response = navigationResponse.response as? HTTPURLResponse else {
            return
        }
        currentETag = response.allHeaderFields[HTTPURLResponse.etagHeaderKey] as? String
        checkForScrollToAnchor(in: response)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        articleLoadDidFail(with: error)
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        articleLoadDidFail(with: error)
    }
    
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        // On process did terminate, the WKWebView goes blank
        // Re-load the content in this case to show it again
        webView.reload()
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        if shouldPerformWebRefreshAfterScrollViewDeceleration {
            updateRefreshOverlay(visible: false)
            webView.scrollView.showsVerticalScrollIndicator = true
            shouldPerformWebRefreshAfterScrollViewDeceleration = false
        }
    }
}

extension ThemeableViewController { // Putting extension on ViewController rather than ArticleVC allows for re-use by EditPreviewVC

    var articleMargins: UIEdgeInsets {
        return UIEdgeInsets(top: 8, left: articleHorizontalMargin, bottom: 0, right: articleHorizontalMargin)
    }

    var articleHorizontalMargin: CGFloat {
        let viewForCalculation: UIView = navigationController?.view ?? view

        if let tableOfContentsVC = (self as? ArticleViewController)?.tableOfContentsController.viewController, tableOfContentsVC.isVisible {
            // full width
            return viewForCalculation.layoutMargins.left
        } else {
            // If (is EditPreviewVC) or (is TOC OffScreen) then use readableContentGuide to make text inset from screen edges.
            // Since readableContentGuide has no effect on compact width, both paths of this `if` statement result in an identical result for smaller screens.
            return viewForCalculation.readableContentGuide.layoutFrame.minX
        }
    }
}

// LogoutCoordinatorDelegate

extension ArticleViewController: LogoutCoordinatorDelegate {
    func didTapLogout() {
        wmf_showKeepSavedArticlesOnDevicePanelIfNeeded(triggeredBy: .logout, theme: theme) {
            self.dataStore.authenticationManager.logout(initiatedBy: .user)
        }
    }
}

extension ArticleViewController: YearInReviewBadgeDelegate {
    func updateYIRBadgeVisibility() {
        updateProfileButton()
    }
}

extension ArticleViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let text = searchController.searchBar.text else {
            return
        }
        
        guard let searchViewController = navigationItem.searchController?.searchResultsController as? SearchViewController else {
            return
        }
        
        if text.isEmpty {
            searchViewController.searchTerm = nil
            searchViewController.updateRecentlySearchedVisibility(searchText: nil)
        } else {
            searchViewController.searchTerm = text
            searchViewController.updateRecentlySearchedVisibility(searchText: text)
            searchViewController.search()
        }
    }
}

extension ArticleViewController: UISearchControllerDelegate {
        
    func willPresentSearchController(_ searchController: UISearchController) {
        navigationController?.hidesBarsOnSwipe = false
        searchBarIsAnimating = true
    }
    
    func didDismissSearchController(_ searchController: UISearchController) {
        navigationController?.hidesBarsOnSwipe = true
        searchBarIsAnimating = false
        SearchFunnel.shared.logSearchCancel(source: "article")
    }
}
