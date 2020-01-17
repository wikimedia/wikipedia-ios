
import UIKit
import WMF

private extension CharacterSet {
    static let pathComponentAllowed: CharacterSet = {
        var allowed = CharacterSet.urlPathAllowed
        allowed.remove(charactersIn: "/.")
        return allowed
    }()
}

@objc(WMFArticleContainerViewController)
class ArticleContainerViewController: ViewController {
    
    enum ViewState {
        case unknown
        case loading
        case data
    }
    
    private lazy var toolbarController: ArticleToolbarController = {
        return ArticleToolbarController(toolbar: toolbar, delegate: self)
    }()

    private let schemeHandler: SchemeHandler
    private let dataStore: MWKDataStore
    private let authManager: WMFAuthenticationManager = WMFAuthenticationManager.sharedInstance // TODO: DI?
    private let alertManager: WMFAlertManager = WMFAlertManager.sharedInstance
    private let cacheController: CacheController
    private let articleURL: URL
    private let article: WMFArticle
    private let language: String
    
    private var leadImageHeight: CGFloat = 210
    
    @objc convenience init?(articleURL: URL, dataStore: MWKDataStore, theme: Theme) {
        
        guard let cacheController = dataStore.articleCacheControllerWrapper.cacheController else {
            return nil
        }
        
        self.init(articleURL: articleURL, dataStore: dataStore, cacheController: cacheController, theme: theme)
    }
    
    init?(articleURL: URL, dataStore: MWKDataStore, schemeHandler: SchemeHandler = SchemeHandler.shared, cacheController: CacheController, theme: Theme) {
        guard
            let language = articleURL.wmf_language,
            let article = dataStore.fetchOrCreateArticle(with: articleURL)
        else {
            return nil
        }
        
        self.articleURL = articleURL
        self.dataStore = dataStore
        self.article = article
        self.language = language
        self.schemeHandler = schemeHandler
        self.schemeHandler.articleCacheController = cacheController
        self.cacheController = cacheController
        
        super.init(theme: theme)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: WebView
    
    static let webProcessPool = WKProcessPool()
    
    lazy var messagingController: ArticleWebMessagingController = ArticleWebMessagingController(delegate: self)
    
    lazy var webViewConfiguration: WKWebViewConfiguration = {
        let configuration = WKWebViewConfiguration()
        configuration.processPool = ArticleContainerViewController.webProcessPool
        configuration.setURLSchemeHandler(schemeHandler, forURLScheme: schemeHandler.scheme)
        return configuration
    }()
    
    lazy var webView: WKWebView = {
        return WKWebView(frame: view.bounds, configuration: webViewConfiguration)
    }()
    
    
    // MARK: Lead Image
    
    @objc func userDidTapLeadImage() {
        
    }
    
    func loadLeadImage(with leadImageURL: URL) {
        leadImageHeightConstraint.constant = leadImageHeight
        leadImageView.wmf_setImage(with: leadImageURL, detectFaces: true, onGPU: true, failure: { (error) in
            DDLogError("Error loading lead image: \(error)")
            self.showWebView()
        }) {
            self.layoutLeadImage()
            self.showWebView()
        }
    }
    
    lazy var leadImageHeightConstraint: NSLayoutConstraint = {
        return leadImageContainerView.heightAnchor.constraint(equalToConstant: 0)
    }()
    
    lazy var leadImageView: UIImageView = {
        let imageView = FLAnimatedImageView(frame: .zero)
        imageView.isUserInteractionEnabled = true
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.accessibilityIgnoresInvertColors = true
        let tapGR = UITapGestureRecognizer(target: self, action: #selector(userDidTapLeadImage))
        imageView.addGestureRecognizer(tapGR)
        return imageView
    }()
    
    lazy var leadImageContainerView: UIView = {
        let scale = UIScreen.main.scale
        let borderHeight: CGFloat = scale > 1 ? 0.5 : 1
        let height: CGFloat = 10
        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: height))
        containerView.clipsToBounds = true
        
        let borderView = UIView(frame: CGRect(x: 0, y: height - borderHeight, width: 1, height: borderHeight))
        borderView.backgroundColor = UIColor(white: 0, alpha: 0.2)
        borderView.autoresizingMask = [.flexibleTopMargin, .flexibleWidth]
        
        leadImageView.frame = CGRect(x: 0, y: 0, width: 1, height: height - borderHeight)
        containerView.addSubview(leadImageView)
        containerView.addSubview(borderView)
        return containerView
    }()
    
    var leadImageTransitionView: UIView?
    
    func layoutLeadImage() {
        let containerBounds = leadImageContainerView.bounds
//        // TODO: iPad margin handling after ToC is implemented

//        let imageSize = leadImageView.image?.size ?? .zero
//        let isImageNarrow = imageSize.height < 1 ? false : imageSize.width / imageSize.height < 2
        let marginWidth: CGFloat = 0
//        if isImageNarrow { // TODO: && self.tableOfContentsDisplayState == WMFTableOfContentsDisplayStateInlineHidden) {
//            marginWidth = 32
//        }
        leadImageView.frame = CGRect(x: marginWidth, y: 0, width: containerBounds.size.width - 2 * marginWidth, height: CGFloat(leadImageHeight))
    }
    
    
    // MARK: Layout
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutLeadImage()
    }
    
    // MARK: Loading
    
    private var state: ViewState = .loading {
        didSet {
            switch state {
            case .unknown:
                fakeProgressController.stop()
            case .loading:
                fakeProgressController.start()
            case .data:
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
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cancelWIconPopoverDisplay()
    }
    
    // MARK: Theme
    
    private lazy var themesPresenter: ReadingThemesControlsArticlePresenter = {
        return ReadingThemesControlsArticlePresenter(readingThemesControlsViewController: themesViewController, wkWebView: webView, readingThemesControlsToolbarItem: toolbarController.themeButton)
    }()
    
    private lazy var themesViewController: ReadingThemesControlsViewController = {
        return ReadingThemesControlsViewController(nibName: ReadingThemesControlsViewController.nibName, bundle: nil)
    }()
    
    override func apply(theme: Theme) {
        super.apply(theme: theme)
        view.backgroundColor = theme.colors.paperBackground
        webView.backgroundColor = theme.colors.paperBackground
        toolbarController.apply(theme: theme)
        if state == .data {
            messagingController.updateTheme(theme)
        }
    }
}

private extension ArticleContainerViewController {
    
    func setup() {
        setupWButton()
        setupSearchButton()
        addNotificationHandlers()
        setupWebView()
        load()
    }
    
    func addNotificationHandlers() {
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveArticleUpdatedNotification), name: NSNotification.Name.WMFArticleUpdated, object: article)
    }
    
    @objc func didReceiveArticleUpdatedNotification(_ notification: Notification) {
        toolbarController.setSavedState(isSaved: article.isSaved)
    }
    
    func setupSearchButton() {
        navigationItem.rightBarButtonItem = AppSearchBarButtonItem.newAppSearchBarButtonItem
    }
    
    func setupWebView() {
        view.wmf_addSubviewWithConstraintsToEdges(webView)
        scrollView = webView.scrollView // so that content insets are inherited

        leadImageContainerView.translatesAutoresizingMaskIntoConstraints = false
        webView.scrollView.addSubview(leadImageContainerView)
            
        let leadingConstraint = webView.leadingAnchor.constraint(equalTo: leadImageContainerView.leadingAnchor)
        let trailingConstraint = webView.trailingAnchor.constraint(equalTo: leadImageContainerView.trailingAnchor)
        let topConstraint = webView.scrollView.topAnchor.constraint(equalTo: leadImageContainerView.topAnchor)
        NSLayoutConstraint.activate([topConstraint, leadingConstraint, trailingConstraint, leadImageHeightConstraint])
        
        guard let siteURL = articleURL.wmf_site else {
            DDLogError("Missing site for \(articleURL)")
            alertManager.showErrorAlert(RequestError.invalidParameters, sticky: true, dismissPreviousAlerts: true)
            return
        }
        
        // Need user groups to let the Page Content Service know if the page is editable for this user
        authManager.getLoggedInUser(for: siteURL) { (result) in
            switch result {
            case .success(let user):
                self.setupPageContentServiceJavaScriptInterface(with: user?.groups ?? [])
            case .failure(let error):
                self.showWebView()
                self.alertManager.showErrorAlert(error, sticky: true, dismissPreviousAlerts: true)
            }
        }
    }
    
    func setupPageContentServiceJavaScriptInterface(with userGroups: [String]) {
        let areTablesInitiallyExpanded = UserDefaults.wmf.wmf_isAutomaticTableOpeningEnabled
        let textSizeAdjustment = UserDefaults.wmf.wmf_articleFontSizeMultiplier() as? Int ?? 100
        messagingController.setup(with: webView, language: language, theme: theme, leadImageHeight: Int(leadImageHeight), areTablesInitiallyExpanded: areTablesInitiallyExpanded, textSizeAdjustment: textSizeAdjustment, userGroups: userGroups)
    }
    
    func load() {
        state = .loading
        if let leadImageURL = article.imageURL(forWidth: traitCollection.wmf_leadImageWidth) {
            loadLeadImage(with: leadImageURL)
        }
        guard let mobileHTMLURL = ArticleURLConverter.mobileHTMLURL(desktopURL: articleURL, endpointType: .mobileHTML, scheme: WMFURLSchemeHandlerScheme) else {
            WMFAlertManager.sharedInstance.showErrorAlert(RequestError.invalidParameters as NSError, sticky: true, dismissPreviousAlerts: true)
            return
        }
        let request = URLRequest(url: mobileHTMLURL)
        webView.load(request)
    }
    
    func showWebView() {
        guard webView.alpha > 0 else {
            return
        }
        let transitionView = leadImageTransitionView
        leadImageTransitionView = nil
        UIView.animate(withDuration: 0.2, animations: {
            self.webView.alpha = 1
        }) { (finished) in
            transitionView?.removeFromSuperview()
        }
    }
    
    func setupToolbar() {
        enableToolbar()
        toolbarController.apply(theme: theme)
        toolbarController.setSavedState(isSaved: article.isSaved)
        setToolbarHidden(false, animated: false)
    }
}

extension ArticleContainerViewController: ArticleWebMessageHandling {
    func didTapLink(messagingController: ArticleWebMessagingController, title: String) {

        guard let host = articleURL.host,
            let newArticleURL = ArticleURLConverter.desktopURL(host: host, title: title),
            let newArticleVC = ArticleContainerViewController(articleURL: newArticleURL, dataStore: dataStore, schemeHandler: schemeHandler, cacheController: cacheController, theme: theme) else {
            assertionFailure("Failure initializing new Article VC")
            //tonitodo: error state
            return
        }
        
        navigationController?.pushViewController(newArticleVC, animated: true)
    }
    
    func didSetup(messagingController: ArticleWebMessagingController) {
        state = .data
        showWebView()
        webView.becomeFirstResponder()
        showWIconPopoverIfNecessary()
    }
    
    func didGetLeadImage(messagingcontroller: ArticleWebMessagingController, source: String, width: Int?, height: Int?) {
        guard leadImageView.image == nil && leadImageView.wmf_imageURLToFetch == nil else {
            return
        }
        guard let leadImageURLToRequest = WMFArticle.imageURL(forTargetImageWidth: traitCollection.wmf_leadImageWidth, fromImageSource: source, withOriginalWidth: width ?? 0) else {
            return
        }
        loadLeadImage(with: leadImageURLToRequest)
    }
}

extension ArticleContainerViewController: ArticleToolbarHandling {
    
    func toggleSave(from viewController: ArticleToolbarController, shouldSave: Bool) {
        article.isSaved = shouldSave
        try? article.managedObjectContext?.save()
    }
    
    func showThemePopover(from controller: ArticleToolbarController) {
        themesPresenter.showReadingThemesControlsPopup(on: self, responder: self, theme: theme)
    }
    
    func saveButtonWasLongPressed(from controller: ArticleToolbarController) {
        let addArticlesToReadingListVC = AddArticlesToReadingListViewController(with: dataStore, articles: [article], theme: theme)
        let nc = WMFThemeableNavigationController(rootViewController: addArticlesToReadingListVC, theme: theme)
        nc.setNavigationBarHidden(false, animated: false)
        present(nc, animated: true)
    }
}

extension ArticleContainerViewController: ReadingThemesControlsResponding {
    func updateWebViewTextSize(textSize: Int) {
        messagingController.updateTextSizeAdjustmentPercentage(textSize)
    }
    
    func toggleSyntaxHighlighting(_ controller: ReadingThemesControlsViewController) {
        // no-op here, syntax highlighting shouldnt be displayed
    }
}

extension ArticleContainerViewController: ImageScaleTransitionProviding {
    var imageScaleTransitionView: UIImageView? {
        return leadImageView
    }
    
    func prepareViewsForIncomingImageScaleTransition(with imageView: UIImageView?) {
        guard let imageView = imageView, let image = imageView.image else {
            return
        }
        
        let transitionView = UIImageView(frame: leadImageView.frame)
        transitionView.translatesAutoresizingMaskIntoConstraints = false
        transitionView.image = image
        transitionView.layer.contentsRect = imageView.layer.contentsRect
        transitionView.contentMode = imageView.contentMode
        transitionView.clipsToBounds = true
        view.insertSubview(transitionView, aboveSubview: webView)
    
        let top = transitionView.topAnchor.constraint(equalTo: navigationBar.bottomAnchor)
        let leading = transitionView.leadingAnchor.constraint(equalTo: leadImageView.leadingAnchor)
        let trailing = transitionView.trailingAnchor.constraint(equalTo: leadImageView.trailingAnchor)
        let height = transitionView.heightAnchor.constraint(equalToConstant: WebViewControllerHeaderImageHeight)
        NSLayoutConstraint.activate([top, leading, trailing, height])

        leadImageView.image = imageView.image
        leadImageView.layer.contentsRect = imageView.layer.contentsRect
        
        leadImageTransitionView = transitionView
        
        view.layoutIfNeeded()
    }

}

private extension UIViewController {
    
    struct Offsets {
        let top: CGFloat?
        let bottom: CGFloat?
        let leading: CGFloat?
        let trailing: CGFloat?
    }
    
    func addChildViewController(childViewController: UIViewController, offsets: Offsets) {
        addChild(childViewController)
        childViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(childViewController.view)
        
        var constraintsToActivate: [NSLayoutConstraint] = []
        if let top = offsets.top {
            let topConstraint = childViewController.view.topAnchor.constraint(equalTo: view.topAnchor, constant: top)
            constraintsToActivate.append(topConstraint)
        }
        
        if let bottom = offsets.bottom {
            let bottomConstraint = childViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: bottom)
            constraintsToActivate.append(bottomConstraint)
        }
        
        if let leading = offsets.leading {
            let leadingConstraint = childViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: leading)
            constraintsToActivate.append(leadingConstraint)
        }
        
        if let trailing = offsets.trailing {
            let trailingConstraint = childViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: trailing)
            constraintsToActivate.append(trailingConstraint)
        }
        
        NSLayoutConstraint.activate(constraintsToActivate)
        
        childViewController.didMove(toParent: self)
    }
}

