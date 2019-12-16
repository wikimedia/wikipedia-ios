
import UIKit
import WMF

private extension CharacterSet {
    static let pathComponentAllowed: CharacterSet = {
        var allowed = CharacterSet.urlPathAllowed
        allowed.remove(charactersIn: "/.")
        return allowed
    }()
}

class ArticleContainerViewController: ViewController {
    
    enum ViewState {
        case unknown
        case loading
        case data
    }
    
    enum InitInfo {
        case url(URL)
        case langAndTitle(language: String, title: String)
    }
  
    private let articleTitle: String
    private let language: String
    private let siteURL: URL
    private var webViewController: ArticleWebViewController?
    private let toolbarViewController = ArticleToolbarViewController()
    private let schemeHandler: SchemeHandler
    private let articleCacheDBWriter: ArticleCacheDBWriter
    private let mobileHTMLURL: URL
    
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
    
    init?(info: InitInfo, schemeHandler: SchemeHandler = SchemeHandler.shared, articleCacheDBWriter: ArticleCacheDBWriter? = ArticleCacheDBWriter.shared) {
        
        guard let articleCacheDBWriter = articleCacheDBWriter else {
            return nil
        }
        
        switch info {
        case .url(let url):
            
            guard let articleTitle = url.wmf_title,
                let language = url.wmf_language,
                let siteURL = url.wmf_site else {
                    return nil
            }
            
            self.articleTitle = articleTitle
            self.language = language
            self.siteURL = siteURL
        case .langAndTitle(let language, let title):
            
            guard let siteURL = NSURL.wmf_URL(withDomain: "wikipedia.org", language: language) else {
                return nil
            }
            
            self.articleTitle = title
            self.language = language
            self.siteURL = siteURL
        }
        
        self.schemeHandler = schemeHandler
        self.articleCacheDBWriter = articleCacheDBWriter
        
        guard let mobileHTMLURL = ArticleFetcher.getURL(siteURL: siteURL, articleTitle: articleTitle, endpointType: .mobileHTML, scheme: WMFURLSchemeHandlerScheme) else {
            return nil
        }

        self.mobileHTMLURL = mobileHTMLURL
        
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
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveDidDownloadNotification(_:)), name: ArticleCacheSyncer.didDownloadNotification, object: nil)
    }
    
    @objc func didReceiveDidDownloadNotification(_ notification: Notification) {
        
        guard let dbKey = notification.userInfo?[ArticleCacheSyncer.didDownloadNotificationUserInfoKey] as? String,
            let expectedDatabaseKey = mobileHTMLURL.wmf_databaseKey,
        	dbKey == expectedDatabaseKey else {
            return
        }
        
        DispatchQueue.main.async {
            self.toolbarViewController.setSavedState(isSaved: true)
        }
    }
    
    func setupWebViewController() {
    
        state = .loading
        let webViewController = ArticleWebViewController(url: mobileHTMLURL, schemeHandler: schemeHandler, delegate: self)
        self.webViewController = webViewController
        addChildViewController(childViewController: webViewController, offsets: Offsets(top: nil, bottom: nil, leading: 0, trailing: 0))
    }
    
    func setupToolbarViewController() {
        toolbarViewController.delegate = self
        
        if articleCacheDBWriter.isCached(mobileHTMLURL) {
            toolbarViewController.setSavedState(isSaved: true)
        }
        
        addChildViewController(childViewController: toolbarViewController, offsets: Offsets(top: nil, bottom: 0, leading: 0, trailing: 0))
    }
}

extension ArticleContainerViewController: ArticleWebMessageHandling {
    func didTapLink(messagingController: ArticleWebMessagingController, title: String) {
        
        guard let newArticleVC = ArticleContainerViewController(info: .langAndTitle(language: language, title: title), schemeHandler: schemeHandler) else {
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
        articleCacheDBWriter.toggleCache(for: mobileHTMLURL)
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
