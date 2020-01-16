
import UIKit

class ArticleWebViewController: UIViewController {
    
    private let url: URL
    
    private let webView: WKWebView
    
    private weak var delegate: ArticleWebMessageHandling?
    private let messagingController: ArticleWebMessagingController
    
    init(url: URL, schemeHandler: SchemeHandler, delegate: ArticleWebMessageHandling?) {
        self.url = url
    
        let configuration = WKWebViewConfiguration()
        configuration.setURLSchemeHandler(schemeHandler, forURLScheme: schemeHandler.scheme)
        let webView = WKWebView(frame: .zero, configuration: configuration)
        self.webView = webView
        
        self.messagingController = ArticleWebMessagingController(webView: webView, delegate: delegate)
        self.delegate = delegate
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
        loadRequest()
    }
}

private extension ArticleWebViewController {
    
    func setup() {
        
        messagingController.setup()
        view.wmf_addSubviewWithConstraintsToEdges(webView)
        
        webView.backgroundColor = .blue
    }
    
    func loadRequest() {
        let request = URLRequest(url: url)
        webView.load(request)
    }
}
