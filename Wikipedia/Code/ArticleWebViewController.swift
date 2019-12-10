
import UIKit

class ArticleWebViewController: UIViewController {
    
    private let url: URL
    private lazy var webView: WKWebView = {
        let webView = WKWebView()
        webView.backgroundColor = .blue
        return webView
    }()
    
    init(url: URL) {
        self.url = url
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
        view.wmf_addSubviewWithConstraintsToEdges(webView)
    }
    
    func loadRequest() {
        let request = URLRequest(url: url)
        webView.load(request)
    }
}
