import UIKit
import WMF
import CocoaLumberjackSwift

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
    
    var session: Session {
        return dataStore.session
    }
    
    var configuration: Configuration {
        return dataStore.configuration
    }
    
    private var authManager: WMFAuthenticationManager {
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
    
    //BEGIN: Article As Living Doc properties
    private(set) var surveyTimerController: ArticleSurveyTimerController?
    
    lazy var articleAsLivingDocController = ArticleAsLivingDocController(delegate: self)
    
    var surveyAnnouncementResult: SurveyAnnouncementsController.SurveyAnnouncementResult? {
        SurveyAnnouncementsController.shared.activeSurveyAnnouncementResultForArticleURL(articleURL)
    }
    //END: Article As Living Doc properties
    
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
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        contentSizeObservation?.invalidate()
        messagingController.removeScriptMessageHandler()
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
    
    // MARK: Lead Image
    
    @objc func userDidTapLeadImage() {
        showLeadImage()
    }
    
    func loadLeadImage(with leadImageURL: URL) {
        leadImageHeightConstraint.constant = leadImageHeight
        leadImageView.wmf_setImage(with: leadImageURL, detectFaces: true, onGPU: true, failure: { (error) in
            DDLogError("Error loading lead image: \(error)")
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
        
        if (articleAsLivingDocController.shouldAttemptToShowArticleAsLivingDoc) {
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
        coordinator.animate(alongsideTransition: marginUpdater)
    }
    
    // MARK: Loading
    
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
    
    lazy private var fakeProgressController: FakeProgressController = {
        let progressController = FakeProgressController(progress: navigationBar, delegate: navigationBar)
        progressController.delay = 0.0
        return progressController
    }()
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        setup()
        super.viewDidLoad()
        setupToolbar() // setup toolbar needs to be after super.viewDidLoad because the superview owns the toolbar
        setupForStateRestorationIfNecessary()
        surveyTimerController?.timerFireBlock = { [weak self] in
            guard let self = self,
                  let result = self.surveyAnnouncementResult else {
                return
            }
            
            self.showSurveyAnnouncementPanel(surveyAnnouncementResult: result, linkState: self.articleAsLivingDocController.surveyLinkState)
        }
        if #available(iOS 14.0, *) {
            self.navigationItem.backButtonTitle = articleURL.wmf_title
            self.navigationItem.backButtonDisplayMode = .generic
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableOfContentsController.setup(with: traitCollection)
        toolbarController.update()
        loadIfNecessary()
        startSignificantlyViewedTimer()
        surveyTimerController?.viewWillAppear(withState: state)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        /// When jumping back to an article via long pressing back button (on iOS 14 or above), W button disappears. Couldn't find cause. It disappears between `viewWillAppear` and `viewDidAppear`, as setting this on the `viewWillAppear`doesn't fix the problem. If we can find source of this bad behavior, we can remove this next line.
        setupWButton()
        guard isFirstAppearance else {
            return
        }
        showAnnouncementIfNeeded()
        isFirstAppearance = false
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        tableOfContentsController.update(with: traitCollection)
        toolbarController.update()
    }
    
    override func wmf_removePeekableChildViewControllers() {
        super.wmf_removePeekableChildViewControllers()
        addToHistory()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cancelWIconPopoverDisplay()
        saveArticleScrollPosition()
        stopSignificantlyViewedTimer()
        surveyTimerController?.viewWillDisappear(withState: state)
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
            self.loadPage(cachePolicy: cachePolicy)
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
            
            self.articleAsLivingDocController.articleContentFinishedLoading()
            
            self.setupFooter()
            self.shareIfNecessary()
            self.restoreScrollStateIfNecessary()
            self.articleLoadWaitGroup = nil
        }
    }
    
    internal func loadSummary(oldState: ViewState) {
        guard let key = article.inMemoryKey else {
            return
        }
        
        articleLoadWaitGroup?.enter()
        let cachePolicy: URLRequest.CachePolicy? = oldState == .reloading ? .reloadRevalidatingCacheData : nil
        self.dataStore.articleSummaryController.updateOrCreateArticleSummaryForArticle(withKey: key, cachePolicy: cachePolicy) { (article, error) in
            defer {
                self.articleLoadWaitGroup?.leave()
                self.updateMenuItems()
            }
            guard let article = article else {
                return
            }
            self.article = article
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
        
        guard let request = try? fetcher.mobileHTMLRequest(articleURL: articleURL, revisionID: revisionID, scheme: schemeHandler.scheme, cachePolicy: cachePolicy, isPageView: true) else {
            showGenericError()
            state = .error
            return
        }

        articleAsLivingDocController.articleContentWillBeginLoading(traitCollection: traitCollection, theme: theme)

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
                        DDLogDebug("failed to synced resources for \(groupKey): \(error)")
                }
            }
        }
    }
    
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
            
            //HACK: Sometimes the `scroll_to_anchor` message is not triggered from the web view over the JS bridge, even after prepareForScrollToAnchor successfully goes through. This means the completion block above is queued to scrollToAnchorCompletions but never run. We are trying to scroll again here once more after a slight delay in hopes of triggering `scroll_to_anchor` again.
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.3) { [weak self] in
                
                guard let self = self else {
                    return
                }
                
                //This conditional check should target the bug a little closer, since scrollToAnchorCompletions are cleaned out after the last `scroll_to_anchor` message is received. Remaining scrollToAnchorCompletions at this point indicates that likely we're hitting the missing `scroll_to_anchor` message bug.
                if (self.scrollToAnchorCompletions.count > 0) {
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
                if (success || maxedAttempts) {
                    self?.setWebViewHidden(false, animated: true)
                }
            })
        } else if let fragment = article.viewedFragment {
            scrollRestorationState = .scrollToAnchor(fragment, completion: { [weak self] success, maxedAttempts in
                if (success || maxedAttempts) {
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
        showNavigationBar()
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

        articleAsLivingDocController.articleDidTriggerPullToRefresh()
        
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
    
    // MARK: Overrideable functionality
    
    internal func handleLink(with href: String) {
        guard let resolvedURL = articleURL.resolvingRelativeWikiHref(href) else {
            showGenericError()
            return
        }
        // Check if this is the same article by comparing in-memory keys
        guard resolvedURL.wmf_inMemoryKey == articleURL.wmf_inMemoryKey else {
            navigate(to: resolvedURL)
            return
        }
        // Check for a fragment - if this is the same article and there's no fragment just do nothing?
        guard let anchor = resolvedURL.fragment?.removingPercentEncoding else {
            return
        }
        
        articleAsLivingDocController.handleArticleAsLivingDocLinkForAnchor(anchor, articleURL: articleURL)
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
        if shouldPerformWebRefreshAfterScrollViewDeceleration {
            webView.scrollView.showsVerticalScrollIndicator = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                self.performWebViewRefresh()
            })
        }
    }
    
    // MARK: Analytics
    
    internal lazy var editFunnel: EditFunnel = EditFunnel.shared
    internal lazy var shareFunnel: WMFShareFunnel? = WMFShareFunnel(article: article)
    internal lazy var savedPagesFunnel: SavedPagesFunnel = SavedPagesFunnel()
    internal lazy var readingListsFunnel = ReadingListsFunnel.shared
}

private extension ArticleViewController {
    
    func setup() {
        setupWButton()
        setupSearchButton()
        addNotificationHandlers()
        setupWebView()
        setupMessagingController()
    }
    
    // MARK: Notifications
    
    func addNotificationHandlers() {
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveArticleUpdatedNotification), name: NSNotification.Name.WMFArticleUpdated, object: article)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillResignActive), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
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
    
    @objc func applicationWillResignActive(_ notification: Notification) {
        saveArticleScrollPosition()
        stopSignificantlyViewedTimer()
        surveyTimerController?.willResignActive(withState: state)
    }
    
    @objc func applicationDidBecomeActive(_ notification: Notification) {
        startSignificantlyViewedTimer()
        surveyTimerController?.didBecomeActive(withState: state)
    }
    
    func setupSearchButton() {
        navigationItem.rightBarButtonItem = AppSearchBarButtonItem.newAppSearchBarButtonItem
    }
    
    func setupMessagingController() {
        messagingController.delegate = self
    }
    
    func setupWebView() {
        // Add the stack view that contains the table of contents and the web view.
        // This stack view is owned by the tableOfContentsController to control presentation of the table of contents
        view.wmf_addSubviewWithConstraintsToEdges(tableOfContentsController.stackView)
        view.widthAnchor.constraint(equalTo: tableOfContentsController.inlineContainerView.widthAnchor, multiplier: 3).isActive = true
        
        // Prevent flash of white in dark mode
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        
        // Scroll view
        scrollView = webView.scrollView // so that content insets are inherited
        scrollView?.delegate = self
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
        
        articleAsLivingDocController.setupLeadImageView()
    }
    
    func setupPageContentServiceJavaScriptInterface(with completion: @escaping () -> Void) {
        guard let siteURL = articleURL.wmf_site else {
            DDLogError("Missing site for \(articleURL)")
            showGenericError()
            return
        }
        
        // Need user groups to let the Page Content Service know if the page is editable for this user
        authManager.getLoggedInUser(for: siteURL) { (result) in
            assert(Thread.isMainThread)
            switch result {
            case .success(let user):
                self.setupPageContentServiceJavaScriptInterface(with: user?.groups ?? [])
            case .failure:
                DDLogError("Error getting userinfo for \(siteURL)")
                self.setupPageContentServiceJavaScriptInterface(with: [])
            }
            completion()
        }
    }
    
    func setupPageContentServiceJavaScriptInterface(with userGroups: [String]) {
        let areTablesInitiallyExpanded = UserDefaults.standard.wmf_isAutomaticTableOpeningEnabled

        messagingController.shouldAttemptToShowArticleAsLivingDoc = articleAsLivingDocController.shouldAttemptToShowArticleAsLivingDoc

        messagingController.setup(with: webView, languageCode: articleLanguageCode, theme: theme, layoutMargins: articleMargins, leadImageHeight: leadImageHeight, areTablesInitiallyExpanded: areTablesInitiallyExpanded, userGroups: userGroups)
    }
    
    func setupToolbar() {
        enableToolbar()
        toolbarController.apply(theme: theme)
        toolbarController.setSavedState(isSaved: article.isAnyVariantSaved)
        setToolbarHidden(false, animated: false)
    }
    
}

extension ArticleViewController {
    func presentEmbedded(_ viewController: UIViewController, style: WMFThemeableNavigationControllerStyle) {
        let nc = WMFThemeableNavigationController(rootViewController: viewController, theme: theme, style: style)
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
        fakeProgressController.finish()
        if showEmptyView {
            wmf_showEmptyView(of: .articleDidNotLoad, theme: theme, frame: view.bounds)
        }
        showError(error)
        refreshControl.endRefreshing()
        updateRefreshOverlay(visible: false)
    }
    
    func articleLoadDidFail(with error: Error) {
        // Convert from mobileview if necessary
        guard article.isConversionFromMobileViewNeeded else {
            handleArticleLoadFailure(with: error, showEmptyView: !article.isSaved)
            return
        }
        dataStore.migrateMobileviewToMobileHTMLIfNecessary(article: article) { [weak self] (migrationError) in
            DispatchQueue.main.async {
                self?.oneOffArticleMigrationDidFinish(with: migrationError)
            }
        }
    }
    
    func oneOffArticleMigrationDidFinish(with migrationError: Error?) {
        if let error = migrationError {
            handleArticleLoadFailure(with: error, showEmptyView: true)
            return
        }
        guard !article.isConversionFromMobileViewNeeded else {
            handleArticleLoadFailure(with: RequestError.unexpectedResponse, showEmptyView: true)
            return
        }
        loadPage()
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

extension ViewController  { // Putting extension on ViewController rather than ArticleVC allows for re-use by EditPreviewVC

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

//MARK: Article As Living Doc Protocols

extension ArticleViewController: ArticleAsLivingDocViewControllerDelegate {
    func livingDocViewWillPush() {
        surveyTimerController?.livingDocViewWillPush(withState: state)
    }
    
    func livingDocViewWillAppear() {
        surveyTimerController?.livingDocViewWillAppear(withState: state)
    }
    
    var articleAsLivingDocViewModel: ArticleAsLivingDocViewModel? {
        return articleAsLivingDocController.articleAsLivingDocViewModel
    }
    
    func fetchNextPage(nextRvStartId: UInt, theme: Theme) {
        articleAsLivingDocController.fetchNextPage(nextRvStartId: nextRvStartId, traitCollection: traitCollection, theme: theme)
    }

    var isFetchingAdditionalPages: Bool {
        return articleAsLivingDocController.isFetchingAdditionalPages
    }
}

extension ArticleViewController: ArticleAsLivingDocControllerDelegate {
    var abTestsController: ABTestsController {
        return dataStore.abTestsController
    }
    
    var isInValidSurveyCampaignAndArticleList: Bool {
        surveyAnnouncementResult != nil
    }
    
    func extendTimerForPresentingModal() {
        surveyTimerController?.extendTimer()
    }
}

extension ArticleViewController: ArticleSurveyTimerControllerDelegate {
    var displayDelay: TimeInterval? {
        surveyAnnouncementResult?.displayDelay
    }
    
    var shouldAttemptToShowArticleAsLivingDoc: Bool {
        return articleAsLivingDocController.shouldAttemptToShowArticleAsLivingDoc
    }
    
    var userHasSeenSurveyPrompt: Bool {
        
        guard let identifier = surveyAnnouncementResult?.campaignIdentifier else {
            return false
        }
        
        return SurveyAnnouncementsController.shared.userHasSeenSurveyPrompt(forCampaignIdentifier: identifier)
    }
    
    var shouldShowArticleAsLivingDoc: Bool {
        return articleAsLivingDocController.shouldShowArticleAsLivingDoc
    }
    
    var livingDocSurveyLinkState: ArticleAsLivingDocSurveyLinkState {
        return articleAsLivingDocController.surveyLinkState
    }
    
    
}
