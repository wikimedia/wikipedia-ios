
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
    
    private let toolbarViewController = ArticleToolbarViewController()
    private let schemeHandler: SchemeHandler
    private let cacheController: CacheController
    private let articleURL: URL
    private let language: String
    
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
    
    @objc convenience init?(articleURL: URL, cacheControllerWrapper: CacheControllerWrapper) {
        
        guard let cacheController = cacheControllerWrapper.cacheController else {
            return nil
        }
        
        self.init(articleURL: articleURL, cacheController: cacheController)
    }
    
    init?(articleURL: URL, schemeHandler: SchemeHandler = SchemeHandler.shared, cacheController: CacheController) {
        
        guard let language = articleURL.wmf_language else {
            return nil
        }
        
        self.articleURL = articleURL
        self.language = language
        self.schemeHandler = schemeHandler
        self.schemeHandler.articleCacheController = cacheController
        self.cacheController = cacheController
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        setup()
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
}

private extension ArticleContainerViewController {
    
    func setup() {
        addNotificationHandlers()
        setupWebView()
        setupToolbarViewController()
        load()
    }
    
    func addNotificationHandlers() {
        //NotificationCenter.default.addObserver(self, selector: #selector(didReceiveChangeNotification(_:)), name: ArticleCacheController.didChangeNotification, object: nil)
    }
    
    @objc func didReceiveChangeNotification(_ notification: Notification) {
        
//        guard let userInfo = notification.userInfo,
//            let dbKey = userInfo[ArticleCacheController.didChangeNotificationUserInfoDBKey] as? String,
//            let isDownloaded = userInfo[ArticleCacheController.didChangeNotificationUserInfoIsDownloadedKey] as? Bool,
//            dbKey == articleURL.wmf_databaseKey else {
//            return
//        }
//
//        DispatchQueue.main.async {
//            self.toolbarViewController.setSavedState(isSaved: isDownloaded)
//        }
    }
    func setupWebView() {
        view.wmf_addSubviewWithConstraintsToEdges(webView)
        scrollView = webView.scrollView // so that content insets are inherited
        let margins = PageContentService.Parameters.Margins(
            top: "16px",
            right: "16px",
            bottom: "16px",
            left: "16px"
        )
        let parameters  = PageContentService.Parameters(theme: theme.name, leadImageHeight: "210px", margins: margins)
        messagingController.setup(webView: webView, with: parameters)
    }
    
    func load() {
        state = .loading
        guard let mobileHTMLURL = ArticleURLConverter.mobileHTMLURL(desktopURL: articleURL, endpointType: .mobileHTML, scheme: WMFURLSchemeHandlerScheme) else {
            WMFAlertManager.sharedInstance.showErrorAlert(RequestError.invalidParameters as NSError, sticky: true, dismissPreviousAlerts: true)
            return
        }
        let request = URLRequest(url: mobileHTMLURL)
        webView.load(request)
    }
    
    func setupToolbarViewController() {
        toolbarViewController.delegate = self
        
        //if cacheController.isCached(url: articleURL) {
            toolbarViewController.setSavedState(isSaved: false)
        //}
        
        addChildViewController(childViewController: toolbarViewController, offsets: Offsets(top: nil, bottom: 0, leading: 0, trailing: 0))
    }
}

extension ArticleContainerViewController: ArticleWebMessageHandling {
    func didTapLink(messagingController: ArticleWebMessagingController, title: String) {

        guard let host = articleURL.host,
            let newArticleURL = ArticleURLConverter.desktopURL(host: host, title: title),
            let newArticleVC = ArticleContainerViewController(articleURL: newArticleURL, schemeHandler: schemeHandler, cacheController: cacheController) else {
            assertionFailure("Failure initializing new Article VC")
            //tonitodo: error state
            return
        }
        
        navigationController?.pushViewController(newArticleVC, animated: true)
    }
    
    func didSetup(messagingController: ArticleWebMessagingController) {
        state = .data
    }
}

extension ArticleContainerViewController: ArticleToolbarHandling {
    
    func toggleSave(from viewController: ArticleToolbarViewController, shouldSave: Bool) {
        
        guard let groupKey = articleURL.wmf_databaseKey else {
            return
        }
        
        if shouldSave {
            cacheController.add(url: articleURL, groupKey: groupKey, itemCompletion: { (itemResult) in
                switch itemResult {
                case .success(let itemKey):
                    print("☕️successfully added \(itemKey)")
                case .failure(let error):
                    print("☕️failure in itemCompletion of \(groupKey): \(error)")
                }
            }) { (groupResult) in
                switch groupResult {
                case .success(let itemKeys):
                    print("☕️group completion: \(groupKey), itemKeyCount: \(itemKeys.count)")
                    DispatchQueue.main.async {
                        self.toolbarViewController.setSavedState(isSaved: true)
                    }
                case .failure(let error):
                    print("☕️failure in groupCompletion of \(groupKey): \(error)")
                }
            }
        } else {
            cacheController.remove(groupKey: groupKey, itemCompletion: { (itemResult) in
                switch itemResult {
                case .success(let itemKey):
                    print("🎢successfully removed \(itemKey)")
                case .failure(let error):
                    print("🎢failure in itemCompletion of \(groupKey): \(error)")
                }
            }) { (groupResult) in
                switch groupResult {
                case .success(let itemKeys):
                    print("🎢group completion: \(groupKey), itemKeyCount: \(itemKeys.count)")
                    DispatchQueue.main.async {
                        self.toolbarViewController.setSavedState(isSaved: false)
                    }
                case .failure(let error):
                    print("🎢failure in groupCompletion of \(groupKey): \(error)")
                }
            }
        }
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
