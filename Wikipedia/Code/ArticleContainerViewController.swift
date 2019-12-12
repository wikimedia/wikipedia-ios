
import UIKit

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
    private var webViewController: ArticleWebViewController?
    private let toolbarViewController = ArticleToolbarViewController()
    private let schemeHandler: SchemeHandler
    
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
    
    init?(info: InitInfo, schemeHandler: SchemeHandler = SchemeHandler.shared) {
        
        switch info {
        case .url(let url):
            guard let articleTitle = url.wmf_title,
                let language = url.wmf_language else {
                    return nil
            }
            
            self.articleTitle = articleTitle
            self.language = language
        case .langAndTitle(let language, let title):
            self.articleTitle = title
            self.language = language
        }
        
        self.schemeHandler = schemeHandler
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
        
        setupWebViewController()
        setupToolbarViewController()
        
        if let webViewController = webViewController {
            webViewController.view.bottomAnchor.constraint(equalTo: toolbarViewController.view.topAnchor).isActive = true
        }
    }
    
    func setupWebViewController() {
        
        if let url = mobileHTMLUrl(schemeHandler: schemeHandler, articleTitle: articleTitle) {
            
            state = .loading
            let webViewController = ArticleWebViewController(url: url, schemeHandler: schemeHandler, delegate: self)
            self.webViewController = webViewController
            addChildViewController(childViewController: webViewController, offsets: Offsets(top: nil, bottom: nil, leading: 0, trailing: 0))
        } else {
            //tonitodo: error view
        }
    }
    
    func mobileHTMLUrl(schemeHandler: SchemeHandler, articleTitle: String) -> URL? {
        
        //tonitodo: move into configuration
        guard let encodedTitle = articleTitle.addingPercentEncoding(withAllowedCharacters: CharacterSet.pathComponentAllowed) else {
            return nil
        }
        
        let basePath = "\(schemeHandler.scheme)://apps.wmflabs.org/\(language).wikipedia.org/v1/page/mobile-html/"
        return URL(string: basePath + encodedTitle)
    }
    
    func setupToolbarViewController() {
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
