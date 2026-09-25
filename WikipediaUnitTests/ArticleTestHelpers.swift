@testable import Wikipedia
@testable import WMF
import XCTest
import Foundation

class BasicCachingWebViewController: UIViewController, WKNavigationDelegate {

    let schemeHandler: SchemeHandler
    var articleURL = URL(string: "app://en.wikipedia.org/api/rest_v1/page/mobile-html/United_States")!
    let session: Session
    let configuration: Configuration
    let permanentCache: PermanentCacheController
    var didReceiveDataCallback: ((WKURLSchemeTask, Data) -> Void)?
    var extraHeaders: [String: String] = [:]

    init() {
        self.permanentCache = ArticleTestHelpers.cacheController
        self.session = ArticleTestHelpers.dataStore.session
        self.configuration = ArticleTestHelpers.dataStore.configuration
        self.schemeHandler = SchemeHandler(scheme: "app", session: session)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    internal lazy var fetcher: ArticleFetcher = ArticleFetcher(session: session, configuration: configuration)
    
    lazy var webViewConfiguration: WKWebViewConfiguration = {
        let configuration = WKWebViewConfiguration()
        configuration.setURLSchemeHandler(schemeHandler, forURLScheme: schemeHandler.scheme)
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
    
    private func getRequest() -> URLRequest? {
        let acceptUTF8HTML = ["Accept": "text/html; charset=utf-8"]
        
        for (key, value) in acceptUTF8HTML {
            extraHeaders[key] = value
        }
        return fetcher.urlRequest(from: articleURL, headers: extraHeaders)
    }
    
    private func setupWebView() {
        schemeHandler.didReceiveDataCallback = self.didReceiveDataCallback
        webView.navigationDelegate = self
        view.wmf_addSubviewWithConstraintsToEdges(webView)
    }
}

class ArticleTestHelpers {
    
    struct FixtureData {
        let image: Data
        let html: Data
        let css: Data
        let cachedHTML: Data
        let cachedCSS: Data
        let cachedZhansHTML: Data
        let cachedZhCSS: Data
        let imageZh640: Data
    }
    static var fixtureData: FixtureData?
    
    static var dataStore: MWKDataStore!
    static var cacheController: PermanentCacheController!
    
    static func setupWithNetworkFixtures(completion: @escaping () -> Void) {
        enableNetworkFixtures()
        setup(completion: completion)
    }

    static func tearDownNetworkFixtures() {
        UserDefaults.standard.removeObject(forKey: TestNetworkFixtureInterceptor.profileKey)
        TestNetworkFixtureHTTPClient.resetFixtures()
        tearDown()
    }

    static func tearDown() {
        resetSharedState()
    }

    private static func resetSharedState() {
        fixtureData = nil
        cacheController = nil
        dataStore?.session.teardown()
        dataStore?.removeFolderAtBasePath()
        dataStore = nil
        URLCache.shared.removeAllCachedResponses()
    }

    static func setup(completion: @escaping () -> Void) {
        resetSharedState()
        MWKDataStore.createTemporaryDataStore(completion: { dataStore in
            
            let tempPath = WMFRandomTemporaryPath()!
            let randomURL = NSURL.fileURL(withPath: tempPath)
            let temporaryCacheURL = randomURL.appendingPathComponent("Permanent Cache", isDirectory: true)
            let permCache = PermanentCacheController.testController(with: temporaryCacheURL, dataStore: dataStore)
            
            self.dataStore = dataStore
            self.cacheController = permCache
            completion()
        })
    }

    private static func enableNetworkFixtures() {
        UserDefaults.standard.set(TestHTTPClientProfile.fixtureStrict.rawValue, forKey: TestNetworkFixtureInterceptor.profileKey)
        TestNetworkFixtureHTTPClient.resetFixtures()
    }
}
