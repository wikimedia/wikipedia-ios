
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
  
    private var webViewController: ArticleWebViewController?
    private let toolbarViewController = ArticleToolbarViewController()
    private let schemeHandler: SchemeHandler
    private let cacheController: CacheController
    private let articleURL: URL
    private let language: String
    
    private var state: ViewState = .loading {
        didSet {
            switch state {
            case .unknown:
                fakeProgressController.stop()
                webViewController?.view.isHidden = true
            case .loading:
                fakeProgressController.start()
                webViewController?.view.isHidden = true
            case .data:
                fakeProgressController.stop()
                webViewController?.view.isHidden = false
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
        super.viewDidLoad()

        setup()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //This would be nice in setup() but since navigationBar isn't added to heirarchy until viewWillAppear we have to hook in here.
        webViewController?.view.topAnchor.constraint(equalTo: navigationBar.bottomAnchor).isActive = true
    }
}

private extension ArticleContainerViewController {
    
    func setup() {
        
        addNotificationHandlers()
        setupWebViewController()
        setupToolbarViewController()
        
        if let webViewController = webViewController {
            webViewController.view.bottomAnchor.constraint(equalTo: toolbarViewController.view.topAnchor).isActive = true
        }
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
    
    func setupWebViewController() {
    
        state = .loading
        guard let mobileHTMLURL = ArticleURLConverter.mobileHTMLURL(desktopURL: articleURL, endpointType: .mobileHTML, scheme: WMFURLSchemeHandlerScheme) else {
            //tonitodo: error state?
            return
        }
        
        let webViewController = ArticleWebViewController(url: mobileHTMLURL, schemeHandler: schemeHandler, delegate: self)
        self.webViewController = webViewController
        addChildViewController(childViewController: webViewController, offsets: Offsets(top: nil, bottom: nil, leading: 0, trailing: 0))
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
    func toggleSave(from viewController: ArticleToolbarViewController) {
        
        guard let groupKey = articleURL.wmf_databaseKey else {
            return
        }
        
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
            case .failure(let error):
                print("☕️failure in groupCompletion of \(groupKey): \(error)")
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
