
import UIKit

class ArticleWebViewController: UIViewController {
    
    private let url: URL
    private let messageHandlerName = "action"
    private let webView: WKWebView
    
    init(url: URL, schemeHandler: SchemeHandler) {
        self.url = url
    
        let configuration = WKWebViewConfiguration()
        //configuration.setURLSchemeHandler(schemeHandler, forURLScheme: schemeHandler.scheme)
        self.webView = WKWebView(frame: .zero, configuration: configuration)
        
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
        
        let contentController = webView.configuration.userContentController
        contentController.add(self, name: messageHandlerName)
        
        let actionHandler = ActionHandlerScript(theme: .standard, messageHandlerName: messageHandlerName)
        contentController.removeAllUserScripts()
        contentController.addUserScript(actionHandler)
        
        view.wmf_addSubviewWithConstraintsToEdges(webView)
        
        webView.backgroundColor = .blue
    }
    
    func loadRequest() {
        let request = URLRequest(url: url)
        webView.load(request)
    }
}

extension ArticleWebViewController: WKScriptMessageHandler {
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any] else {
            return
        }
        guard let action = body["action"] as? String else {
            return
        }
        let data = body["data"] as? [String: Any]
        print(body)
//        switch action {
//        case "preloaded":
//            //onPreload()
//        case "setup":
//            //onSetup()
//        case "final_setup":
//            //onPostLoad()
//        case "link_clicked":
//            guard let href = data?["href"] as? String else {
//                break
//            }
//            onLinkClicked(href: href)
//        default:
//            break
//        }
    }
    
    
}
