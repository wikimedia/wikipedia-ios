import WMFComponents
import WMF
import CocoaLumberjackSwift
import WMFData

protocol AltTextDelegate: AnyObject {
    func didTapNext(altText: String, uiImage: UIImage?, articleViewController: ArticleViewController, viewModel: WMFAltTextExperimentViewModel)
}

@objc(WMFArticleViewController)
class ArticleViewController: ViewController, HintPresenting {
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
    internal lazy var watchlistController: WatchlistController = {
        return WatchlistController(delegate: self, context: .article)
    }()
    
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
    internal let cacheController: ArticleCacheController
    
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

    internal var leadImageHeight: CGFloat = 210
    internal var contentSizeObservation: NSKeyValueObservation? = nil
    
    /// Current ETag of the web content response. Used to verify when content has changed on the server.
    var currentETag: String?

    /// Used to delay reloading the web view to prevent `UIScrollView` jitter
    internal var shouldPerformWebRefreshAfterScrollViewDeceleration = false

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
    
    // BEGIN: Article As Living Doc properties
    private(set) var surveyTimerController: ArticleSurveyTimerController?
    
    lazy var articleAsLivingDocController = ArticleAsLivingDocController(delegate: self)
    
    var surveyAnnouncementResult: SurveyAnnouncementsController.SurveyAnnouncementResult? {
        SurveyAnnouncementsController.shared.activeSurveyAnnouncementResultForArticleURL(articleURL)
    }
    // END: Article As Living Doc properties

    // MARK: Alt-text experiment Properties

    private(set) var altTextBottomSheetViewModel: WMFAltTextExperimentModalSheetViewModel?
    private(set) var altTextExperimentViewModel: WMFAltTextExperimentViewModel?
    private(set) weak var altTextDelegate: AltTextDelegate?
    internal var needsAltTextExperimentSheet: Bool = false
    internal var isReturningFromFAQ = false
    var altTextExperimentAcceptDate: Date?
    var wasPresentingGalleryWhileInAltTextMode = false
    var didTapPreview: Bool = false /// Set when coming back from alt text preview
    var didTapAltTextFileName = false
    var didTapAltTextGalleryInfoButton = false
    var altTextArticleEditorOnboardingPresenter: AltTextArticleEditorOnboardingPresenter?
    var altTextGuidancePresenter: AltTextGuidancePresenter?
    internal weak var altTextBottomSheetViewController: WMFAltTextExperimentModalSheetViewController?

    convenience init?(articleURL: URL, dataStore: MWKDataStore, theme: Theme, schemeHandler: SchemeHandler? = nil, altTextExperimentViewModel: WMFAltTextExperimentViewModel, needsAltTextExperimentSheet: Bool, altTextBottomSheetViewModel: WMFAltTextExperimentModalSheetViewModel?, altTextDelegate: AltTextDelegate?) {
        self.init(articleURL: articleURL, dataStore: dataStore, theme: theme)
        self.altTextExperimentViewModel = altTextExperimentViewModel
        self.altTextBottomSheetViewModel = altTextBottomSheetViewModel
        self.needsAltTextExperimentSheet = needsAltTextExperimentSheet
        self.altTextDelegate = altTextDelegate
    }
    
    @objc init?(articleURL: URL, dataStore: MWKDataStore, theme: Theme, schemeHandler: SchemeHandler? = nil) {

        guard let article = dataStore.fetchOrCreateArticle(with: articleURL) else {
                return nil
        }
        let cacheController = dataStore.cacheController.articleCache

        self.articleURL = articleURL
        self.articleLanguageCode = articleURL.wmf_languageCode ?? Locale.current.languageCode ?? "en"
        self.article = article
        
        self.dataStore = dataStore
        self.schemeHandler = schemeHandler ?? SchemeHandler(scheme: "app", session: dataStore.session)
        self.cacheController = cacheController

        super.init(theme: theme)
        
        self.surveyTimerController = ArticleSurveyTimerController(delegate: self)

        // `viewDidLoad` isn't called when re-creating the navigation stack on an iPad, and hence a cold launch on iPad doesn't properly show article names when long-pressing the back button if this code is in `viewDidLoad`
        navigationItem.configureForEmptyNavBarTitle(backTitle: articleURL.wmf_title)
        
        hidesBottomBarWhenPushed = true
    }
    
    deinit {
        contentSizeObservation?.invalidate()
        messagingController.removeScriptMessageHandler()
        articleLoadWaitGroup = nil
        altTextBottomSheetViewModel = nil
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
    
    lazy var webView: WKWebView = {
        let webView = WMFWebView(frame: view.bounds, configuration: webViewConfiguration)
        view.addSubview(webView)
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
    
    // Mark: Loading
    
    var state: ViewState = .initial {
        didSet {
            switch state {
            case .initial:
                break
            case .reloading:
                fallthrough
            case .loading:
                fakeProgressController.start()
            case .loaded:
                fakeProgressController.stop()
                rethemeWebViewIfNecessary()
            case .error:
                fakeProgressController.stop()
            }
        }
    }
    
    lazy internal var fakeProgressController: FakeProgressController = {
        let progressController = FakeProgressController(progress: navigationBar, delegate: navigationBar)
        progressController.delay = 0.0
        return progressController
    }()
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Lead image
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
    
    
    // MARK: Previewing
    
    public var articlePreviewingDelegate: ArticlePreviewingDelegate?
    
    // MARK: Layout
    
    override func scrollViewInsetsDidChange() {
        super.scrollViewInsetsDidChange()
        updateTableOfContentsInsets()
    }
    
    override func viewLayoutMarginsDidChange() {
        super.viewLayoutMarginsDidChange()
        updateArticleMargins()
    }
    
    internal func updateArticleMargins() {
        
        let defaultUpdateBlock = {
            self.messagingController.updateMargins(with: self.articleMargins, leadImageHeight: self.leadImageHeightConstraint.constant)
        }
        
        if articleAsLivingDocController.shouldAttemptToShowArticleAsLivingDoc {
            messagingController.customUpdateMargins(with: articleMargins, leadImageHeight: self.leadImageHeightConstraint.constant)
        } else {
            defaultUpdateBlock()
        }
        
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
        }
    }
    
    // MARK: Article load
    
    var articleLoadWaitGroup: DispatchGroup?

    // MARK: History

    func addToHistory() {
        // Don't add to history if we're in peek/pop
        guard self.wmf_PeekableChildViewController == nil else {
            return
        }
        try? article.addToReadHistory()
    }
    
    var significantlyViewedTimer: Timer?
    
    func startSignificantlyViewedTimer() {
        guard significantlyViewedTimer == nil, !article.wasSignificantlyViewed else {
            return
        }
        significantlyViewedTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: false, block: { [weak self] (timer) in
            self?.article.wasSignificantlyViewed = true
            self?.stopSignificantlyViewedTimer()
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
    internal enum ScrollRestorationState {
        case none
        /// Scroll to absolute Y offset
        case scrollToOffset(_ offsetY: CGFloat, animated: Bool, attempt: Int = 1, maxAttempts: Int = 5, completion: ((Bool, Bool) -> Void)? = nil)
        /// Scroll to percentage Y offset
        case scrollToPercentage(_ percentageOffsetY: CGFloat)
        /// Scroll to anchor, an id of an element on the page
        case scrollToAnchor(_ anchor: String, attempt: Int = 1, maxAttempts: Int = 5, completion: ((Bool, Bool) -> Void)? = nil)
    }
    
    internal var scrollRestorationState: ScrollRestorationState = .none
    
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
    
    // MARK: Overrideable functionality
    
    internal func handleLink(with href: String) {
        
        guard altTextExperimentViewModel == nil else {
            return
        }
        
        guard let resolvedURL = articleURL.resolvingRelativeWikiHref(href) else {
            showGenericError()
            return
        }
        // Check if this is the same article by comparing in-memory keys
        guard resolvedURL.wmf_inMemoryKey == articleURL.wmf_inMemoryKey else {
            
            let userInfo: [AnyHashable : Any] = [RoutingUserInfoKeys.source: RoutingUserInfoSourceValue.article.rawValue]
            navigate(to: resolvedURL, userInfo: userInfo)
            
            return
        }
        // Check for a fragment - if this is the same article and there's no fragment just do nothing?
        guard let anchor = resolvedURL.fragment?.removingPercentEncoding else {
            return
        }
        
        articleAsLivingDocController.handleArticleAsLivingDocLinkForAnchor(anchor, articleURL: articleURL)
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
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        super.scrollViewDidScroll(scrollView)
        updateTableOfContentsHighlightIfNecessary()
    }
    
    override func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        super.scrollViewDidScrollToTop(scrollView)
        updateTableOfContentsHighlight()
    }
    
    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        super.scrollViewWillBeginDragging(scrollView)
        dismissReferencesPopover()
        hintController?.dismissHintDueToUserInteraction()
    }

    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        super.scrollViewDidEndDecelerating(scrollView)
        performWebRefreshAfterScrollViewDecelerationIfNeeded()
    }
    
    override func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        super.scrollViewWillEndDragging(scrollView, withVelocity: velocity, targetContentOffset: targetContentOffset)

        if velocity == .zero {
            performWebRefreshAfterScrollViewDecelerationIfNeeded()
        }
    }

    // MARK: Notifications
    internal lazy var readingListsFunnel = ReadingListsFunnel.shared
}
