import UIKit
import WMF

@objc(WMFArticleViewController)
class ArticleViewController: ViewController {    
    enum ViewState {
        case initial
        case loading
        case loaded
        case error
    }
    
    internal lazy var toolbarController: ArticleToolbarController = {
        return ArticleToolbarController(toolbar: toolbar, delegate: self)
    }()
    
    /// Article holds article metadata (displayTitle, description, etc) and user state (isSaved, viewedDate, viewedFragment, etc)
    internal var article: WMFArticle
    internal var mediaList: MediaList?
    
    /// Use separate properties for URL and language since they're optional on WMFArticle and to save having to re-calculate them
    @objc public var articleURL: URL
    let articleLanguage: String
    
    /// Set by the state restoration system
    /// Scroll to the last viewed scroll position in this case
    var isRestoringState: Bool = false
    /// Set internally to wait for content size changes to chill before restoring the scroll offset
    var isRestoringStateOnNextContentSizeChange: Bool = false
    
    /// Called when initial load starts
    @objc public var loadCompletion: (() -> Void)?
    
    internal let schemeHandler: SchemeHandler
    internal let dataStore: MWKDataStore
    
    private let authManager: WMFAuthenticationManager = WMFAuthenticationManager.sharedInstance
    private let cacheController: ArticleCacheController
    
    let session = Session.shared
    let configuration = Configuration.current
    
    internal lazy var fetcher: ArticleFetcher = ArticleFetcher(session: session, configuration: configuration)
    internal lazy var imageFetcher: ImageFetcher = ImageFetcher(session: session, configuration: configuration)

    private var leadImageHeight: CGFloat = 210

    //tells calls to try pulling from cache first so the user sees the article as quickly as possible
    internal var fromNavStateRestoration: Bool = false

    private var contentSizeObservation: NSKeyValueObservation? = nil
    lazy var refreshControl: UIRefreshControl = {
        let rc = UIRefreshControl()
        rc.addTarget(self, action: #selector(refresh), for: .valueChanged)
        return rc
    }()
    
    @objc init?(articleURL: URL, dataStore: MWKDataStore, theme: Theme, fromNavStateRestoration: Bool = false) {
        guard
            let article = dataStore.fetchOrCreateArticle(with: articleURL),
            let cacheController = ArticleCacheController.shared
            else {
                return nil
        }
        
        self.articleURL = articleURL
        self.articleLanguage = articleURL.wmf_language ?? Locale.current.languageCode ?? "en"
        self.article = article
        
        self.dataStore = dataStore

        self.schemeHandler = SchemeHandler.shared
        
        self.fromNavStateRestoration = fromNavStateRestoration

        self.cacheController = cacheController
        
        super.init(theme: theme)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        contentSizeObservation?.invalidate()
    }
    
    // MARK: WebView
    
    static let webProcessPool = WKProcessPool()
    
    lazy var messagingController: ArticleWebMessagingController = ArticleWebMessagingController(delegate: self)
    
    lazy var webViewConfiguration: WKWebViewConfiguration = {
        let configuration = WKWebViewConfiguration()
        configuration.processPool = ArticleViewController.webProcessPool
        configuration.setURLSchemeHandler(schemeHandler, forURLScheme: schemeHandler.scheme)
        return configuration
    }()
    
    lazy var webView: WKWebView = {
        return WMFWebView(frame: view.bounds, configuration: webViewConfiguration)
    }()
    
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
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
        updateLeadImageMargins()
    }
    
    func updateLeadImageMargins() {
        let imageSize = leadImageView.image?.size ?? .zero
        let isImageNarrow = imageSize.height < 1 ? false : imageSize.width / imageSize.height < 2
        var marginWidth: CGFloat = 0
        if isImageNarrow && tableOfContentsController.viewController.displayMode == .inline && !tableOfContentsController.viewController.isVisible {
            marginWidth = 32
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
    
    private func updateArticleMargins() {
        messagingController.updateMargins(with: articleMargins, leadImageHeight: leadImageHeightConstraint.constant)
    }
    
    // MARK: Loading
    
    internal var state: ViewState = .initial {
        didSet {
            switch state {
            case .initial:
                break
            case .loading:
                fakeProgressController.start()
            case .loaded:
                fakeProgressController.stop()
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
        apply(theme: theme)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableOfContentsController.setup(with: traitCollection)
        toolbarController.update()
        loadIfNecessary()
        startSignificantlyViewedTimer()
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
    }
    
    // MARK: Article load
    
    var footerLoadGroup: DispatchGroup?

    func loadIfNecessary() {
        guard state == .initial else {
            return
        }
        load()
    }
    
    func load() {
        state = .loading
        
        setupPageContentServiceJavaScriptInterface {
            let cachePolicy: WMFCachePolicy? = self.fromNavStateRestoration ? .foundation(.returnCacheDataElseLoad) : nil
            self.loadPage(cachePolicy: cachePolicy)
        }
    }
    
    func loadPage(cachePolicy: WMFCachePolicy? = nil) {
        defer {
            callLoadCompletionIfNecessary()
        }
        
        guard var request = try? fetcher.mobileHTMLRequest(articleURL: articleURL, scheme: schemeHandler.scheme, cachePolicy: cachePolicy) else {

            showGenericError()
            state = .error
            return
        }
        
        footerLoadGroup = DispatchGroup()
        footerLoadGroup?.enter() // will leave on setup complete
        footerLoadGroup?.notify(queue: DispatchQueue.main) { [weak self] in
            self?.setupFooter()
            self?.shareIfNecessary()
            self?.footerLoadGroup = nil
        }
        
        webView.load(request)
        
        guard let key = article.key else {
            showGenericError()
            state = .error
            return
        }
        footerLoadGroup?.enter()
        dataStore.articleSummaryController.updateOrCreateArticleSummaryForArticle(withKey: key) { (article, error) in
            defer {
                self.footerLoadGroup?.leave()
                self.updateMenuItems()
            }
            // Handle redirects
            guard let article = article, let newKey = article.key, newKey != key, let newURL = article.url else {
                return
            }
            self.article = article
            self.articleURL = newURL
            self.addToHistory()
        }
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
    
    // MARK: State Restoration
    
    func saveArticleScrollPosition() {
        getVisibleSection { (sectionId, anchor) in
            assert(Thread.isMainThread)
            self.article.viewedScrollPosition = Double(self.webView.scrollView.contentOffset.y)
            self.article.viewedFragment = anchor
            try? self.article.managedObjectContext?.save()
            
        }
    }
    
    func restoreStateIfNecessary() {
        guard isRestoringState else {
            return
        }
        isRestoringState = false
        isRestoringStateOnNextContentSizeChange = true
        perform(#selector(restoreState), with: nil, afterDelay: 0.5) // failsafe, attempt to restore state after half a second regardless
    }
    
    func restoreStateIfNecessaryOnContentSizeChange() {
        guard isRestoringStateOnNextContentSizeChange else {
            return
        }
        let scrollPosition = CGFloat(article.viewedScrollPosition)
        guard scrollPosition < webView.scrollView.bottomOffsetY else {
            return
        }
        isRestoringStateOnNextContentSizeChange = false
        restoreState()
    }
    
    @objc func restoreState() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(restoreState), object: nil)
        let scrollPosition = CGFloat(article.viewedScrollPosition)
        if scrollPosition > 0 && scrollPosition < webView.scrollView.bottomOffsetY {
            scroll(to: CGPoint(x: 0, y: scrollPosition), animated: false)
        } else if let anchor = article.viewedFragment {
            scroll(to: anchor, animated: false)
        }
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
        loadPage(cachePolicy: .noPersistentCacheOnError)
    }
    
    // MARK: Overrideable functionality
    
    internal func handleLink(with href: String) {
        let urlComponentsString: String
        if href.hasPrefix(".") || href.hasPrefix("/") {
            urlComponentsString = href.addingPercentEncoding(withAllowedCharacters: .relativePathAndFragmentAllowed) ?? href
        } else {
            urlComponentsString = href
        }
        let components = URLComponents(string: urlComponentsString)
        // Resolve relative URLs
        guard let resolvedURL = components?.url(relativeTo: articleURL)?.absoluteURL else {
            showGenericError()
            return
        }
        // Check if this is the same article by comparing database keys
        guard resolvedURL.wmf_databaseKey == articleURL.wmf_databaseKey else {
            navigate(to: resolvedURL)
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
            tocScrollView.scrollIndicatorInsets = webView.scrollView.scrollIndicatorInsets
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
    
    func isBoundingClientRectVisible(_ rect: CGRect) -> Bool {
        let scrollView = webView.scrollView
        return rect.minY > scrollView.contentInset.top && rect.maxY < scrollView.bounds.size.height - scrollView.contentInset.bottom
    }
    
    /// Used to wait for the callback that the anchor is ready for scrollin'
    typealias ScrollToAnchorCompletion = (_ anchor: String, _ rect: CGRect) -> Void
    var scrollToAnchorCompletions: [ScrollToAnchorCompletion] = []

    func scroll(to anchor: String, centered: Bool = false, highlighted: Bool = false, animated: Bool, completion: (() -> Void)? = nil) {
        guard !anchor.isEmpty else {
            webView.scrollView.scrollRectToVisible(CGRect(x: 0, y: 1, width: 1, height: 1), animated: animated)
            completion?()
            return
        }
        
        messagingController.prepareForScroll(to: anchor, highlight: highlighted) { (result) in
            assert(Thread.isMainThread)
            switch result {
            case .failure(let error):
                self.showError(error)
                completion?()
            case .success:
                let scrollCompletion: ScrollToAnchorCompletion = { (anchor, rect) in
                    let point = CGPoint(x: self.webView.scrollView.contentOffset.x, y: rect.origin.y + self.webView.scrollView.contentOffset.y)
                    self.scroll(to: point, centered: centered, animated: animated, completion: completion)
                }
                self.scrollToAnchorCompletions.insert(scrollCompletion, at: 0)
            }
        }
    }
    
    var scrollViewAnimationCompletions: [() -> Void] = []
    func scroll(to offset: CGPoint, centered: Bool = false, animated: Bool, completion: (() -> Void)? = nil) {
        assert(Thread.isMainThread)
        let scrollView = webView.scrollView
        guard !offset.x.isNaN && !offset.x.isInfinite && !offset.y.isNaN && !offset.y.isInfinite else {
            completion?()
            return
        }
        let overlayTop = self.webView.iOS12yOffsetHack + self.navigationBar.hiddenHeight
        let adjustmentY: CGFloat
        if centered {
            let overlayBottom = self.webView.scrollView.contentInset.bottom
            let height = self.webView.scrollView.bounds.height
            adjustmentY = -0.5 * (height - overlayTop - overlayBottom)
        } else {
            adjustmentY = overlayTop
        }
        let minY = 0 - scrollView.contentInset.top
        let maxY = scrollView.contentSize.height - scrollView.bounds.height + scrollView.contentInset.bottom
        let boundedY = min(maxY,  max(minY, offset.y + adjustmentY))
        let boundedOffset = CGPoint(x: scrollView.contentOffset.x, y: boundedY)
        guard WMFDistanceBetweenPoints(boundedOffset, scrollView.contentOffset) >= 2 else {
            scrollView.flashScrollIndicators()
            completion?()
            return
        }
        guard animated else {
            scrollView.setContentOffset(boundedOffset, animated: false)
            completion?()
            return
        }
        /*
         Setting scrollView.contentOffset inside of an animation block
         results in a broken animation https://phabricator.wikimedia.org/T232689
         Calling [scrollView setContentOffset:offset animated:YES] inside
         of an animation block fixes the animation but doesn't guarantee
         the content offset will be updated when the animation's completion
         block is called.
         It appears the only reliable way to get a callback after the default
         animation is to use scrollViewDidEndScrollingAnimation
         */
        if let completion = completion {
            scrollViewAnimationCompletions.insert(completion, at: 0)
        }
        scrollView.setContentOffset(boundedOffset, animated: true)
    }
    
    override func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        super.scrollViewDidEndScrollingAnimation(scrollView)
        // call the first completion
        scrollViewAnimationCompletions.popLast()?()
    }
    
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
    
    func contentSizeDidChange() {
        tableOfContentsController.restoreOffsetPercentageIfNecessary()
        // debounce
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(debouncedContentSizeDidChange), object: nil)
        perform(#selector(debouncedContentSizeDidChange), with: nil, afterDelay: 0.1)
    }
    
    @objc func debouncedContentSizeDidChange() {
        restoreStateIfNecessaryOnContentSizeChange()
    }
    
    @objc func didReceiveArticleUpdatedNotification(_ notification: Notification) {
        toolbarController.setSavedState(isSaved: article.isSaved)
    }
    
    @objc func applicationWillResignActive(_ notification: Notification) {
        saveArticleScrollPosition()
        stopSignificantlyViewedTimer()
    }
    
    @objc func applicationDidBecomeActive(_ notification: Notification) {
        startSignificantlyViewedTimer()
    }
    
    func setupSearchButton() {
        navigationItem.rightBarButtonItem = AppSearchBarButtonItem.newAppSearchBarButtonItem
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
        
        // Delegates
        webView.uiDelegate = self
        webView.navigationDelegate = self
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
        messagingController.setup(with: webView, language: articleLanguage, theme: theme, layoutMargins: articleMargins, leadImageHeight: leadImageHeight, areTablesInitiallyExpanded: areTablesInitiallyExpanded, userGroups: userGroups)
    }
    
    func setupToolbar() {
        enableToolbar()
        toolbarController.apply(theme: theme)
        toolbarController.setSavedState(isSaved: article.isSaved)
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
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        articleLoadDidFail(with: error)
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        articleLoadDidFail(with: error)
    }
}

extension ViewController {
    /// Allows for re-use by edit preview VC
    var articleMargins: UIEdgeInsets {
        var margins = navigationController?.view.layoutMargins ?? view.layoutMargins // view.layoutMargins is zero here so check nav controller first
        margins.top = 8
        margins.bottom = 0
        return margins
    }
}
