
import UIKit

private extension CharacterSet {
    static let pathComponentAllowed: CharacterSet = {
        var allowed = CharacterSet.urlPathAllowed
        allowed.remove(charactersIn: "/.")
        return allowed
    }()
}

class ArticleContainerViewController: UIViewController {
  
    private let articleTitle: String
    private let language: String
    private var webViewController: ArticleWebViewController?
    private let toolbarViewController = ArticleToolbarViewController()
    
    init?(articleURL: URL) {
        
        guard let articleTitle = articleURL.wmf_title,
            let language = articleURL.wmf_language else {
                return nil
        }
        
        self.articleTitle = articleTitle
        self.language = language
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
    }
    
    //todo:
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: true)
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
        guard let encodedTitle = articleTitle.addingPercentEncoding(withAllowedCharacters: CharacterSet.pathComponentAllowed) else {
            return
        }
        
        //todo: move into configuration
        let basePath = "https://\(language).wikipedia.org/api/rest_v1/page/mobile-html/"

        if let url = URL(string: basePath + encodedTitle) {
            let webViewController = ArticleWebViewController(url: url)
            self.webViewController = webViewController
            addChildViewController(childViewController: webViewController, offsets: Offsets(top: 0, bottom: nil, leading: 0, trailing: 0))
        } else {
            //todo: error view
        }
    }
    
    func setupToolbarViewController() {
        addChildViewController(childViewController: toolbarViewController, offsets: Offsets(top: nil, bottom: 0, leading: 0, trailing: 0))
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
