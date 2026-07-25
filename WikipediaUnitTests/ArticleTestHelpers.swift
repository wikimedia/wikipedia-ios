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
    
    static func pullDataFromFixtures(inBundle bundle: Bundle) {
        
        guard let image = bundle.wmf_data(fromContentsOfFile:"960px-Flag_of_the_United_States.svg", ofType:"png"),
            let html = bundle.wmf_data(fromContentsOfFile:"basic", ofType:"html"),
            let css = bundle.wmf_data(fromContentsOfFile:"basic", ofType:"css"),
            let cachedHTML = bundle.wmf_data(fromContentsOfFile:"basicCached", ofType:"html"),
            let cachedCSS = bundle.wmf_data(fromContentsOfFile:"basicCached", ofType:"css"),
            let cachedZhansHTML = bundle.wmf_data(fromContentsOfFile:"basicZhans", ofType:"html"),
            let cachedZhCSS = bundle.wmf_data(fromContentsOfFile:"basicZh", ofType:"css"),
            let imageZh640 = bundle.wmf_data(fromContentsOfFile:"640px-Flag_of_the_United_States_(Pantone).svg", ofType:"png") else {
            assertionFailure("Error setting up fixtures.")
            return
        }
        
        self.fixtureData = FixtureData(image: image, html: html, css: css, cachedHTML: cachedHTML, cachedCSS: cachedCSS, cachedZhansHTML: cachedZhansHTML, cachedZhCSS: cachedZhCSS, imageZh640: imageZh640)
    }
    
    static func writeCachedPiecesToCachingSystem() {
        let moc = cacheController.managedObjectContext
         
        let mobileHTMLURLString = "https://en.wikipedia.org/api/rest_v1/page/mobile-html/United_States"
        let cssString = "https://en.wikipedia.org/api/rest_v1/data/css/mobile/site"
        
        // save objects database
        guard let cacheGroup = CacheDBWriterHelper.createCacheGroup(with: mobileHTMLURLString, in: moc),
            let htmlCacheItem = CacheDBWriterHelper.createCacheItem(with: URL(string: mobileHTMLURLString)!, itemKey: mobileHTMLURLString, variant: nil, in: moc),
            let imageCacheItem = CacheDBWriterHelper.createCacheItem(with: URL(string: "https://upload.wikimedia.org/wikipedia/en/thumb/a/a4/Flag_of_the_United_States.svg/960px-Flag_of_the_United_States.svg.png")!, itemKey: "upload.wikimedia.org__Flag_of_the_United_States.svg", variant: "960", in: moc),
            let cssCacheItem = CacheDBWriterHelper.createCacheItem(with: URL(string: cssString)!, itemKey: cssString, variant: nil, in: moc) else {
            XCTFail("Unable to create Cache DB objects")
            return
        }
        
        cacheGroup.addToCacheItems(htmlCacheItem)
        cacheGroup.addToCacheItems(imageCacheItem)
        cacheGroup.addToCacheItems(cssCacheItem)
        
        CacheDBWriterHelper.save(moc: moc) { (result) in
            
            switch result {
            case .success:
                break
            case .failure:
                XCTFail("Failure saving Cache DB objects")
            }
        }
        
        // set up file names and content
        let fileNameGenerator = PermanentlyPersistableURLCache(moc: moc)
        guard let htmlURL = URL(string: "https://en.wikipedia.org/api/rest_v1/page/mobile-html/United_States"),
            let uniqueHTMLFileName = fileNameGenerator.uniqueFileNameForURL(htmlURL, type: .article),
            let uniqueHTMLHeaderFileName = fileNameGenerator.uniqueHeaderFileNameForURL(htmlURL, type: .article) else {
                XCTFail("Failure determining html file name")
                return
        }
        
        guard let cssURL = URL(string: "https://en.wikipedia.org/api/rest_v1/data/css/mobile/site"),
            let uniqueCSSFileName = fileNameGenerator.uniqueFileNameForURL(cssURL, type: .article),
            let uniqueCSSHeaderFileName = fileNameGenerator.uniqueHeaderFileNameForURL(cssURL, type: .article) else {
                XCTFail("Failure determining html file name")
                return
        }
        
        guard let imageURL = URL(string: "https://upload.wikimedia.org/wikipedia/en/thumb/a/a4/Flag_of_the_United_States.svg/960px-Flag_of_the_United_States.svg.png"),
            let uniqueImageFileName = fileNameGenerator.uniqueFileNameForURL(imageURL, type: .image),
        let uniqueImageHeaderFileName = fileNameGenerator.uniqueHeaderFileNameForURL(imageURL, type: .image) else {
                XCTFail("Failure determining image file name")
                return
        }
        
        guard let fixtureData = self.fixtureData else {
                XCTFail("Failure pulling data from Fixtures")
                return
        }
        
        // save content in file system
        CacheFileWriterHelper.saveData(data: fixtureData.cachedHTML, toNewFileWithKey: uniqueHTMLFileName) { (result) in
            switch result {
            case .success, .exists:
                break
            case .failure:
                XCTFail("Failure saving html data")
            }
        }
        
        CacheFileWriterHelper.saveData(data: fixtureData.image, toNewFileWithKey: uniqueImageFileName) { (result) in
            switch result {
            case .success, .exists:
                break
            case .failure:
                XCTFail("Failure saving image data")
            }
        }
        
        CacheFileWriterHelper.saveData(data: fixtureData.cachedCSS, toNewFileWithKey: uniqueCSSFileName) { (result) in
            switch result {
            case .success, .exists:
                break
            case .failure:
                XCTFail("Failure saving css data")
            }
        }
        
        // save headers in file system
        let htmlHeaders: [String: String] = ["Content-Type": "text/html; charset=utf-8;"]
        
        CacheFileWriterHelper.saveResponseHeader(headerFields: htmlHeaders, toNewFileName: uniqueHTMLHeaderFileName) { (result) in
            switch result {
            case .success, .exists:
                break
            case .failure:
                XCTFail("Failure saving html header")
            }
        }
        
        let imageHeaders: [String: String] = ["Content-Type": "image/jpeg",
                                              "Content-Length": String((fixtureData.image as NSData).length)]
        
        CacheFileWriterHelper.saveResponseHeader(headerFields: imageHeaders, toNewFileName: uniqueImageHeaderFileName) { (result) in
            switch result {
            case .success, .exists:
                break
            case .failure:
                XCTFail("Failure saving image header")
            }
        }
        
        let cssHeaders: [String: String] = ["Content-Type": "text/css; charset=utf-8;",
                                            "Content-Length": String((fixtureData.cachedCSS as NSData).length)]
        
        CacheFileWriterHelper.saveResponseHeader(headerFields: cssHeaders, toNewFileName: uniqueCSSHeaderFileName) { (result) in
            switch result {
            case .success, .exists:
                break
            case .failure:
                XCTFail("Failure saving css header")
            }
        }
    }
    
    static func writeVariantPiecesToCachingSystem() {
        let moc = cacheController.managedObjectContext
         
        let mobileHTMLURLString = "https://zh.wikipedia.org/api/rest_v1/page/mobile-html/%E7%BE%8E%E5%9B%BD"
        let cssString = "https://zh.wikipedia.org/api/rest_v1/data/css/mobile/site"
        let imageURLString = "https://upload.wikimedia.org/wikipedia/commons/thumb/e/e2/Flag_of_the_United_States_%28Pantone%29.svg/640px-Flag_of_the_United_States_%28Pantone%29.svg.png"
        
        // save objects database
        guard let cacheGroup = CacheDBWriterHelper.createCacheGroup(with: mobileHTMLURLString, in: moc),
            let htmlCacheItem = CacheDBWriterHelper.createCacheItem(with: URL(string: mobileHTMLURLString)!, itemKey: mobileHTMLURLString, variant: "zh-hans", in: moc),
            let imageCacheItem = CacheDBWriterHelper.createCacheItem(with: URL(string: imageURLString)!, itemKey: "upload.wikimedia.org__Flag_of_the_United_States_%28Pantone%29.svg", variant: "640", in: moc),
            let cssCacheItem = CacheDBWriterHelper.createCacheItem(with: URL(string: cssString)!, itemKey: cssString, variant: nil, in: moc) else {
            XCTFail("Unable to create Cache DB objects")
            return
        }
        imageCacheItem.isDownloaded = true
        cacheGroup.addToCacheItems(htmlCacheItem)
        cacheGroup.addToCacheItems(imageCacheItem)
        cacheGroup.addToCacheItems(cssCacheItem)
        
        CacheDBWriterHelper.save(moc: moc) { (result) in
            
            switch result {
            case .success:
                break
            case .failure:
                XCTFail("Failure saving Cache DB objects")
            }
        }
        
        // set up file names and content
        let fileNameGenerator = PermanentlyPersistableURLCache(moc: moc)
        guard let htmlURL = URL(string: mobileHTMLURLString),
            let uniqueHTMLFileName = fileNameGenerator.uniqueFileNameForURL(htmlURL, type: .article),
            let uniqueHTMLHeaderFileName = fileNameGenerator.uniqueHeaderFileNameForURL(htmlURL, type: .article) else {
                XCTFail("Failure determining html file name")
                return
        }
        
        guard let cssURL = URL(string: cssString),
            let uniqueCSSFileName = fileNameGenerator.uniqueFileNameForURL(cssURL, type: .article),
            let uniqueCSSHeaderFileName = fileNameGenerator.uniqueHeaderFileNameForURL(cssURL, type: .article) else {
                XCTFail("Failure determining html file name")
                return
        }
        
        guard let imageURL = URL(string: imageURLString),
            let uniqueImageFileName = fileNameGenerator.uniqueFileNameForURL(imageURL, type: .image),
        let uniqueImageHeaderFileName = fileNameGenerator.uniqueHeaderFileNameForURL(imageURL, type: .image) else {
                XCTFail("Failure determining image file name")
                return
        }
        
        guard let fixtureData = self.fixtureData else {
                XCTFail("Failure pulling data from Fixtures")
                return
        }
        
        // save content in file system
        CacheFileWriterHelper.saveData(data: fixtureData.cachedZhansHTML, toNewFileWithKey: uniqueHTMLFileName) { (result) in
            switch result {
            case .success, .exists:
                break
            case .failure:
                XCTFail("Failure saving html data")
            }
        }
        
        CacheFileWriterHelper.saveData(data: fixtureData.imageZh640, toNewFileWithKey: uniqueImageFileName) { (result) in
            switch result {
            case .success, .exists:
                break
            case .failure:
                XCTFail("Failure saving image data")
            }
        }
        
        CacheFileWriterHelper.saveData(data: fixtureData.cachedZhCSS, toNewFileWithKey: uniqueCSSFileName) { (result) in
            switch result {
            case .success, .exists:
                break
            case .failure:
                XCTFail("Failure saving css data")
            }
        }
        
        // save headers in file system
        let htmlHeaders: [String: String] = ["Content-Type": "text/html; charset=utf-8;",
                                             "Vary": "Accept-Language, Accept-Encoding"]
        
        CacheFileWriterHelper.saveResponseHeader(headerFields: htmlHeaders, toNewFileName: uniqueHTMLHeaderFileName) { (result) in
            switch result {
            case .success, .exists:
                break
            case .failure:
                XCTFail("Failure saving html header")
            }
        }
        
        let imageHeaders: [String: String] = ["Content-Type": "image/jpeg",
                                              "Content-Length": String((fixtureData.imageZh640 as NSData).length)]
        
        CacheFileWriterHelper.saveResponseHeader(headerFields: imageHeaders, toNewFileName: uniqueImageHeaderFileName) { (result) in
            switch result {
            case .success, .exists:
                break
            case .failure:
                XCTFail("Failure saving image header")
            }
        }
        
        let cssHeaders: [String: String] = ["Content-Type": "text/css; charset=utf-8;",
                                            "Content-Length": String((fixtureData.cachedZhCSS as NSData).length)]
        
        CacheFileWriterHelper.saveResponseHeader(headerFields: cssHeaders, toNewFileName: uniqueCSSHeaderFileName) { (result) in
            switch result {
            case .success, .exists:
                break
            case .failure:
                XCTFail("Failure saving css header")
            }
        }
    }
}
