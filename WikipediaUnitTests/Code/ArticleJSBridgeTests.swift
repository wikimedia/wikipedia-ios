
import XCTest
@testable import Wikipedia
@testable import WMF

class BasicMessagingWebViewController: UIViewController {
    var articleURL = URL(string: "https://en.wikipedia.org/api/rest_v1/page/mobile-html/United_States")!
    let session: Session
    let configuration: Configuration
    
    let theme = Theme.light
    let margins = PageContentService.Setup.Parameters.Margins(top: "8px", right: "8px", bottom: "8px", left: "8px")
    let areTablesInitiallyExpanded = false
    let userGroups: [String] = []
    let extraHeaders: [String: String] = [:]
    let bodyActionKey = "action"
    let bodyDataKey = "data"
    let leadImageHeight = 200
    let textSizeAdjustment = 100
    
    init() {
        self.session = ArticleTestHelpers.dataStore.session
        self.configuration = ArticleTestHelpers.dataStore.configuration
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    internal lazy var fetcher: ArticleFetcher = ArticleFetcher(session: session, configuration: configuration)
    
    lazy var webViewConfiguration: WKWebViewConfiguration = {
        let configuration = WKWebViewConfiguration()
        return configuration
    }()
    
    lazy var webView: WKWebView = {
        return WMFWebView(frame: view.bounds, configuration: webViewConfiguration)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupWebView()
        
        if let request = getRequest() {
            webView.load(request)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let contentController = webView.configuration.userContentController
        contentController.add(self, name: "pcs")
        contentController.removeAllUserScripts()
        
        do {
            let parameters = PageContentService.Setup.Parameters(theme: theme.webName.lowercased(), dimImages: theme.imageOpacity < 1, margins: margins, leadImageHeight: "\(leadImageHeight)px", areTablesInitiallyExpanded: areTablesInitiallyExpanded, textSizeAdjustmentPercentage: "\(textSizeAdjustment)%", userGroups: userGroups)
            let pcsSetup = try PageContentService.SetupScript(parameters)
            contentController.addUserScript(pcsSetup)
        } catch {
            
        }
        
        let propertiesScript = PageContentService.PropertiesScript()
        contentController.addUserScript(propertiesScript)
        let utilitiesScript = PageContentService.UtilitiesScript()
        contentController.addUserScript(utilitiesScript)
        let styleScript = PageContentService.StyleScript()
        contentController.addUserScript(styleScript)
    }
    
    private func getRequest() -> URLRequest? {
        let acceptUTF8HTML = ["Accept": "text/html; charset=utf-8"]
        return fetcher.urlRequest(from: articleURL, language:articleURL.wmf_language, headers: extraHeaders)
    }
    
    private func setupWebView() {
        view.wmf_addSubviewWithConstraintsToEdges(webView)
    }
}

extension BasicMessagingWebViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any] else {
            return
        }
        guard let actionString = body[bodyActionKey] as? String else {
            return
        }
        let data = body[bodyDataKey] as? [String: Any]
        print(actionString)
        print(data)
    }
}

class ArticleJSBridgeTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        
        let basicVC = BasicMessagingWebViewController()
        
        let htmlExpectation = expectation(description: "Waiting for html content to return")
        
        UIApplication.shared.keyWindow?.rootViewController = basicVC
        
        wait(for: [htmlExpectation], timeout: 10)
    }

}
