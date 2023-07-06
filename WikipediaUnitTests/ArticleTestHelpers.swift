@testable import Wikipedia
@testable import WMF
import XCTest
import Foundation

class BasicCachingWebViewController: UIViewController, WKNavigationDelegate {
    static let webProcessPool = WKProcessPool()
    
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
        configuration.processPool = BasicCachingWebViewController.webProcessPool
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
    
    static func setup(completion: @escaping () -> Void) {
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
    
    static func stubCompleteMobileHTMLResponse(inBundle bundle: Bundle) {
        guard let dogSummaryJSONData = bundle.wmf_data(fromContentsOfFile: "DogArticleSummary", ofType: "json"),
            let dogCollageImageData = bundle.wmf_data(fromContentsOfFile:"CollageOfNineDogs", ofType:"jpg"),
            let userGroupsData = bundle.wmf_data(fromContentsOfFile:"UserInfoGroups", ofType:"json"),
            let mobileHTMLData = bundle.wmf_data(fromContentsOfFile:"DogMobileHTML", ofType:"html"),
            let mobileBaseCSSData = bundle.wmf_data(fromContentsOfFile:"MobileBase", ofType:"css"),
            let mobileSiteCSSData = bundle.wmf_data(fromContentsOfFile:"MobileSite", ofType:"css"),
            let mobilePCSCSSData = bundle.wmf_data(fromContentsOfFile:"MobilePCS", ofType:"css"),
            let mobilePCSJSData = bundle.wmf_data(fromContentsOfFile:"MobilePCS", ofType:"js"),
            let i18PCSData = bundle.wmf_data(fromContentsOfFile:"PCSI18N", ofType: "json"),
            let redPencilImageData = bundle.wmf_data(fromContentsOfFile:"RedPencilIcon", ofType:"png"),
            let commonsLogoImageData = bundle.wmf_data(fromContentsOfFile:"59pxCommonsLogo.svg", ofType:"webp"),
            let footerDog1ImageData = bundle.wmf_data(fromContentsOfFile:"64pxAussieBlacktri", ofType:"jpg"),
            let footerDog2ImageData = bundle.wmf_data(fromContentsOfFile:"64pxOkapi2", ofType:"jpg"),
            let wiktionaryLogoImageData = bundle.wmf_data(fromContentsOfFile:"54pxWiktionaryLogoV2.svg", ofType:"webp"),
            let smallCommonsLogoImageData = bundle.wmf_data(fromContentsOfFile:"40pxCommonsLogo.svg", ofType:"webp"),
            let wikiQuoteLogoImageData = bundle.wmf_data(fromContentsOfFile:"46pxWikiquoteLogo.svg", ofType:"webp"),
            let wikiSpeciesLogoImageData = bundle.wmf_data(fromContentsOfFile:"46pxWikispeciesLogo.svg", ofType:"webp"),
            let wikiSourceLogoImageData = bundle.wmf_data(fromContentsOfFile:"51pxWikisourceLogo.svg", ofType:"webp"),
            let wikiBooksLogoImageData = bundle.wmf_data(fromContentsOfFile:"54pxWikibooksLogo.svg", ofType:"webp"),
            let wikiNewsLogoImageData = bundle.wmf_data(fromContentsOfFile:"54pxWikinewsLogo.svg", ofType:"webp"),
            let genericDogImageData = bundle.wmf_data(fromContentsOfFile:"640pxDogMorphologicalVariation", ofType:"png"),
            let significantEventsData = bundle.wmf_data(fromContentsOfFile:"SignificantEventsDog", ofType: "json"),
            let dailyMetricsData = bundle.wmf_data(fromContentsOfFile:"DogDailyMetrics", ofType: "json"),
            let dailyMetricsRegex = try? NSRegularExpression(pattern: "https://wikimedia.org/api/rest_v1/metrics/edits/per-page/en.wikipedia.org/Dog/all-editor-types/daily/(.*?)/(.*?)", options: []),
            let imageRegex = try? NSRegularExpression(pattern: "https://upload.wikimedia.org/wikipedia/commons/thumb.*", options: []) else {
            assertionFailure("Error setting up fixtures.")
            return
        }

        _ = stubRequest("GET", "https://en.wikipedia.org/api/rest_v1/page/summary/Dog" as NSString)
            .andReturn(200)?
            .withHeaders(["Content-Type": "application/json"])?
            .withBody(dogSummaryJSONData as NSData)
        
        _ = stubRequest("GET", "https://en.wikipedia.org/api/rest_v1/page/summary/Cat" as NSString)
            .andReturn(200)?
            .withHeaders(["Content-Type": "application/json"])?
            .withBody(dogSummaryJSONData as NSData)
        
        _ = stubRequest("GET", "https://upload.wikimedia.org/wikipedia/commons/thumb/d/d9/Collage_of_Nine_Dogs.jpg/1280px-Collage_of_Nine_Dogs.jpg" as NSString)
            .andReturnRawResponse(dogCollageImageData)
        
        _ = stubRequest("GET", "https://upload.wikimedia.org/wikipedia/commons/thumb/6/69/Dog_morphological_variation.png/640px-Dog_morphological_variation.png" as NSString)
            .andReturnRawResponse(genericDogImageData)
        
        _ = stubRequest("GET", "https://upload.wikimedia.org/wikipedia/commons/thumb/a/a0/Llop.jpg/320px-Llop.jpg" as NSString)
            .andReturnRawResponse(genericDogImageData)
        
        _ = stubRequest("POST", "https://en.wikipedia.org/w/api.php" as NSString)
            .withBody("action=query&format=json&meta=userinfo&uiprop=groups" as NSString)?
            .andReturn(200)?
            .withBody(userGroupsData as NSData)
        
        _ = stubRequest("GET", "https://en.wikipedia.org/api/rest_v1/page/mobile-html/Dog" as NSString)
            .andReturn(200)?
            .withBody(mobileHTMLData as NSData)
        
        _ = stubRequest("GET", "https://en.wikipedia.org/api/rest_v1/page/mobile-html/Cat" as NSString)
            .andReturn(200)?
            .withBody(mobileHTMLData as NSData)
        
        _ = stubRequest("GET", "https://mobileapps-ios-experiments.wmflabs.org/en.wikipedia.org/v1/page/significant-events/Dog" as NSString)
            .andReturn(200)?
            .withBody(significantEventsData as NSData)
        
        _ = stubRequest("GET", dailyMetricsRegex)
            .andReturn(200)?
            .withBody(dailyMetricsData as NSData)
        
        _ = stubRequest("GET", "https://meta.wikimedia.org/api/rest_v1/data/css/mobile/base" as NSString)
            .andReturn(200)?
            .withBody(mobileBaseCSSData as NSData)
        
        _ = stubRequest("GET", "https://en.wikipedia.org/api/rest_v1/data/css/mobile/site" as NSString)
        .andReturn(200)?
        .withBody(mobileSiteCSSData as NSData)
        
        _ = stubRequest("GET", "https://meta.wikimedia.org/api/rest_v1/data/css/mobile/pcs" as NSString)
        .andReturn(200)?
        .withBody(mobilePCSCSSData as NSData)
        
        _ = stubRequest("GET", "https://meta.wikimedia.org/api/rest_v1/data/javascript/mobile/pcs" as NSString)
        .andReturn(200)?
        .withBody(mobilePCSJSData as NSData)
        
        _ = stubRequest("GET", "https://upload.wikimedia.org/wikipedia/commons/7/74/Red_Pencil_Icon.png" as NSString)
        .andReturnRawResponse(redPencilImageData)
        
        _ = stubRequest("GET", "https://upload.wikimedia.org/wikipedia/en/thumb/4/4a/Commons-logo.svg/59px-Commons-logo.svg.png" as NSString)
        .andReturnRawResponse(commonsLogoImageData)
        
        _ = stubRequest("GET", "https://upload.wikimedia.org/wikipedia/commons/thumb/d/da/Aussie-blacktri.jpg/64px-Aussie-blacktri.jpg" as NSString)
        .andReturnRawResponse(footerDog1ImageData)
        
        _ = stubRequest("GET", "https://upload.wikimedia.org/wikipedia/commons/thumb/1/18/Okapi2.jpg/64px-Okapi2.jpg" as NSString)
        .andReturnRawResponse(footerDog2ImageData)
        
        _ = stubRequest("GET", "https://upload.wikimedia.org/wikipedia/commons/thumb/1/18/Okapi2.jpg/64px-Okapi2.jpg" as NSString)
        .andReturnRawResponse(footerDog2ImageData)
        
        _ = stubRequest("GET", "https://upload.wikimedia.org/wikipedia/en/thumb/0/06/Wiktionary-logo-v2.svg/54px-Wiktionary-logo-v2.svg.png" as NSString)
        .andReturnRawResponse(wiktionaryLogoImageData)
        
        _ = stubRequest("GET", "https://upload.wikimedia.org/wikipedia/en/thumb/4/4a/Commons-logo.svg/40px-Commons-logo.svg.png" as NSString)
        .andReturnRawResponse(smallCommonsLogoImageData)
        
        _ = stubRequest("GET", "https://upload.wikimedia.org/wikipedia/commons/thumb/2/24/Wikinews-logo.svg/54px-Wikinews-logo.svg.png" as NSString)
        .andReturnRawResponse(wikiNewsLogoImageData)
        
        _ = stubRequest("GET", "https://upload.wikimedia.org/wikipedia/commons/thumb/f/fa/Wikiquote-logo.svg/46px-Wikiquote-logo.svg.png" as NSString)
        .andReturnRawResponse(wikiQuoteLogoImageData)
        
        _ = stubRequest("GET", "https://upload.wikimedia.org/wikipedia/commons/thumb/4/4c/Wikisource-logo.svg/51px-Wikisource-logo.svg.png" as NSString)
        .andReturnRawResponse(wikiSourceLogoImageData)
        
        _ = stubRequest("GET", "https://upload.wikimedia.org/wikipedia/commons/thumb/f/fa/Wikibooks-logo.svg/54px-Wikibooks-logo.svg.png" as NSString)
        .andReturnRawResponse(wikiBooksLogoImageData)
        
        _ = stubRequest("GET", "https://upload.wikimedia.org/wikipedia/commons/thumb/d/df/Wikispecies-logo.svg/46px-Wikispecies-logo.svg.png" as NSString)
        .andReturnRawResponse(wikiSpeciesLogoImageData)
        
        _ = stubRequest("GET", "https://en.wikipedia.org/api/rest_v1/data/i18n/pcs" as NSString)
        .andReturn(200)?
        .withBody(i18PCSData as NSData)
        
        _ = stubRequest("GET", imageRegex)
        .andReturnRawResponse(genericDogImageData)
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
