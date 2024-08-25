import WMFComponents
import WMF
import CocoaLumberjackSwift
import WMFData

// MARK: - ArticleViewController + Notifications

extension ArticleViewController {
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
        let areTablesInitiallyExpanded = altTextExperimentViewModel != nil ? true : UserDefaults.standard.wmf_isAutomaticTableOpeningEnabled

        messagingController.shouldAttemptToShowArticleAsLivingDoc = articleAsLivingDocController.shouldAttemptToShowArticleAsLivingDoc

        messagingController.setup(with: webView, languageCode: articleLanguageCode, theme: theme, layoutMargins: articleMargins, leadImageHeight: leadImageHeight, areTablesInitiallyExpanded: areTablesInitiallyExpanded, userGroups: userGroups)
    }
    
    func setupToolbar() {
        enableToolbar()
        toolbarController.apply(theme: theme)
        toolbarController.setSavedState(isSaved: article.isAnyVariantSaved)
        setToolbarHidden(false, animated: false)
    }
    
    var isWidgetCachedFeaturedArticle: Bool {
        let sharedCache = SharedContainerCache<WidgetCache>(fileName: SharedContainerCacheCommonNames.widgetCache)
        
        let cache = sharedCache.loadCache() ?? WidgetCache(settings: .default, featuredContent: nil)
        guard let widgetFeaturedArticleURLString = cache.featuredContent?.featuredArticle?.contentURL.desktop.page,
              let widgetFeaturedArticleURL = URL(string: widgetFeaturedArticleURLString) else {
            return false
        }
        
        return widgetFeaturedArticleURL == articleURL
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
