@testable import Wikipedia
@testable import WMF
import XCTest

private class BasicCachingWebViewController: UIViewController, WKNavigationDelegate {
    static let webProcessPool = WKProcessPool()
    
    let schemeHandler = SchemeHandler.shared
    var articleURL = URL(string: "app://en.wikipedia.org/api/rest_v1/page/mobile-html/United_States")!
    let session = Session.shared
    let configuration = Configuration.current
    var didReceiveDataCallback: ((WKURLSchemeTask, Data) -> Void)?
    var extraHeaders: [String: String] = [:]
    
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

class ArticleCacheReadingTests: XCTestCase {
    
    var imageData: Data?
    var basicHTMLData: Data?
    var basicCSSData: Data?
    var basicCachedHTMLData: Data?
    var basicCachedCSSData: Data?
    var basicCachedZhansHTMLData: Data?
    var basicCachedZhCSSData: Data?
    var imageZh640Data: Data?

    override func setUp() {
        super.setUp()
        
        pullDataFromFixtures()
        setupTemporaryCacheController()
    }
    
    
    override func tearDown() {
        super.tearDown()
        
        URLCache.shared.removeAllCachedResponses()
    }
    
    private func setupTemporaryCacheController() {
        let tempPath = WMFRandomTemporaryPath()!
        let randomURL = NSURL.fileURL(withPath: tempPath)
        let temporaryCacheURL = randomURL.appendingPathComponent("Permanent Cache", isDirectory: true)

        CacheController.temporaryCacheURL = temporaryCacheURL
    }

    private func pullDataFromFixtures() {
        
        guard let imageData = wmf_bundle().wmf_data(fromContentsOfFile:"960px-Flag_of_the_United_States.svg", ofType:"png"),
            let basicHTMLData = wmf_bundle().wmf_data(fromContentsOfFile:"basic", ofType:"html"),
            let basicCssData = wmf_bundle().wmf_data(fromContentsOfFile:"basic", ofType:"css"),
            let basicCachedHTMLData = wmf_bundle().wmf_data(fromContentsOfFile:"basicCached", ofType:"html"),
            let basicCachedCssData = wmf_bundle().wmf_data(fromContentsOfFile:"basicCached", ofType:"css"),
            let basicCachedZhansHTMLData = wmf_bundle().wmf_data(fromContentsOfFile:"basicZhans", ofType:"html"),
            let basicCachedZhCSSData = wmf_bundle().wmf_data(fromContentsOfFile:"basicZh", ofType:"css"),
            let imageZh640Data = wmf_bundle().wmf_data(fromContentsOfFile:"640px-Flag_of_the_United_States_(Pantone).svg", ofType:"png") else {
            assertionFailure("Error setting up fixtures.")
            return
        }
        
        self.basicHTMLData = basicHTMLData
        self.basicCachedHTMLData = basicCachedHTMLData
        self.basicCSSData = basicCssData
        self.basicCachedCSSData = basicCachedCssData
        self.imageData = imageData
        self.basicCachedZhansHTMLData = basicCachedZhansHTMLData
        self.basicCachedZhCSSData = basicCachedZhCSSData
        self.imageZh640Data = imageZh640Data
    }
    
    func stub200Responses() {
        
        guard let htmlData = self.basicHTMLData,
            let imageData = self.imageData,
            let cssData = self.basicCSSData else {
                XCTFail("Failure pulling data from Fixtures")
                return
        }
        
        let _ = stubRequest("GET", "https://upload.wikimedia.org/wikipedia/en/thumb/a/a4/Flag_of_the_United_States.svg/960px-Flag_of_the_United_States.svg.png" as NSString)
        .andReturnRawResponse(imageData)
        
        let _ = stubRequest("GET", "https://en.wikipedia.org/api/rest_v1/page/mobile-html/United_States" as NSString)
        .andReturn(200)?
        .withBody(htmlData as NSData)
        
        let _ = stubRequest("GET", "https://en.wikipedia.org/api/rest_v1/data/css/mobile/site" as NSString)
        .andReturn(200)?
        .withBody(cssData as NSData)
    }
    
    func stub304Responses() {
        
        let _ = stubRequest("GET", "https://upload.wikimedia.org/wikipedia/en/thumb/a/a4/Flag_of_the_United_States.svg/960px-Flag_of_the_United_States.svg.png" as NSString)
        .andReturn(304)
        
        let _ = stubRequest("GET", "https://en.wikipedia.org/api/rest_v1/page/mobile-html/United_States" as NSString)
        .andReturn(304)
        
        let _ = stubRequest("GET", "https://en.wikipedia.org/api/rest_v1/data/css/mobile/site" as NSString)
        .andReturn(304)
    }
    
    func stub500Responses() {
        
        let _ = stubRequest("GET", "https://upload.wikimedia.org/wikipedia/en/thumb/a/a4/Flag_of_the_United_States.svg/960px-Flag_of_the_United_States.svg.png" as NSString)
        .andReturn(500)
        
        let _ = stubRequest("GET", "https://en.wikipedia.org/api/rest_v1/page/mobile-html/United_States" as NSString)
        .andReturn(500)
        
        let _ = stubRequest("GET", "https://en.wikipedia.org/api/rest_v1/data/css/mobile/site" as NSString)
        .andReturn(500)
    }
    
    func stub500ZhResponses() {
        
        let _ = stubRequest("GET", "https://upload.wikimedia.org/wikipedia/commons/thumb/e/e2/Flag_of_the_United_States_%28Pantone%29.svg/960px-Flag_of_the_United_States_%28Pantone%29.svg.png" as NSString)
        .andReturn(500)
        
        let _ = stubRequest("GET", "https://zh.wikipedia.org/api/rest_v1/page/mobile-html/%E7%BE%8E%E5%9B%BD" as NSString)
        .andReturn(500)
        
        let _ = stubRequest("GET", "https://zh.wikipedia.org/api/rest_v1/data/css/mobile/site" as NSString)
        .andReturn(500)
    }
    
    func testBasicArticleLoad() {
        
        LSNocilla.sharedInstance().start()
        stub200Responses()
        
        let basicVC = BasicCachingWebViewController()
        
        let htmlExpectation = expectation(description: "Waiting for html content to return")
        let imageExpectation = expectation(description: "Waiting for image load to return")
        let cssExpectation = expectation(description: "Waiting for css load to return")
        
        basicVC.didReceiveDataCallback = { urlSchemeTask, data in
            
            guard let urlString = urlSchemeTask.request.url?.absoluteString else {
                XCTFail("Unable to determine urlString from scheme task")
                return
            }
            
            switch urlString {
            case "app://en.wikipedia.org/api/rest_v1/page/mobile-html/United_States":
                
                htmlExpectation.fulfill()
                
                let htmlString = String(decoding: data, as: UTF8.self)
                let trimmedHTML = String(htmlString.filter { !"\n\t\r".contains($0) })
                XCTAssertEqual(trimmedHTML, "<!DOCTYPE html><html><head><link rel=\"stylesheet\" href=\"//en.wikipedia.org/api/rest_v1/data/css/mobile/site\"></head><body><p>Testing</p><img src=\"//upload.wikimedia.org/wikipedia/en/thumb/a/a4/Flag_of_the_United_States.svg/960px-Flag_of_the_United_States.svg.png\"></body></html>")
                
            case "app://en.wikipedia.org/api/rest_v1/data/css/mobile/site":
                
                cssExpectation.fulfill()
                
                let cssString = String(decoding: data, as: UTF8.self)
                let trimmedCSS = String(cssString.filter { !"\n\t\r".contains($0) })
                XCTAssertEqual(trimmedCSS, "body {background-color: green;}", "Unexpected basic HTML content")
            case "app://upload.wikimedia.org/wikipedia/en/thumb/a/a4/Flag_of_the_United_States.svg/960px-Flag_of_the_United_States.svg.png":
                imageExpectation.fulfill()
            default:
                XCTFail("Unexpected scheme task callback")
            }
        }
        
        UIApplication.shared.keyWindow?.rootViewController = basicVC
        let _ = basicVC.view
        
        wait(for: [htmlExpectation], timeout: 10)
        wait(for: [imageExpectation], timeout: 10)
        wait(for: [cssExpectation], timeout: 10)
        
        LSNocilla.sharedInstance().stop()
    }
    
    func testBasicNetworkNotModifiedWithCachedArticle() {
        
        LSNocilla.sharedInstance().start()
        stub304Responses()
        writeCachedPiecesToCachingSystem()
        
        let basicVC = BasicCachingWebViewController()
        
        let htmlExpectation = expectation(description: "Waiting for html content to return")
        let imageExpectation = expectation(description: "Waiting for image load to return")
        let cssExpectation = expectation(description: "Waiting for css load to return")
        
        basicVC.didReceiveDataCallback = { urlSchemeTask, data in
            
            guard let urlString = urlSchemeTask.request.url?.absoluteString else {
                XCTFail("Unable to determine urlString from scheme task")
                return
            }
            
            switch urlString {
            case "app://en.wikipedia.org/api/rest_v1/page/mobile-html/United_States":
                
                htmlExpectation.fulfill()
                
                let htmlString = String(decoding: data, as: UTF8.self)
                let trimmedHTML = String(htmlString.filter { !"\n\t\r".contains($0) })
                XCTAssertEqual(trimmedHTML, "<!DOCTYPE html><html><head><link rel=\"stylesheet\" href=\"//en.wikipedia.org/api/rest_v1/data/css/mobile/site\"></head><body><p>Testing Cached</p><img src=\"//upload.wikimedia.org/wikipedia/en/thumb/a/a4/Flag_of_the_United_States.svg/960px-Flag_of_the_United_States.svg.png\"></body></html>")
                
            case "app://en.wikipedia.org/api/rest_v1/data/css/mobile/site":
                
                cssExpectation.fulfill()
                
                let cssString = String(decoding: data, as: UTF8.self)
                let trimmedCSS = String(cssString.filter { !"\n\t\r".contains($0) })
                XCTAssertEqual(trimmedCSS, "body {background-color: red;}", "Unexpected basic HTML content")
            case "app://upload.wikimedia.org/wikipedia/en/thumb/a/a4/Flag_of_the_United_States.svg/960px-Flag_of_the_United_States.svg.png":
                imageExpectation.fulfill()
            default:
                XCTFail("Unexpected scheme task callback")
            }
        }
        
        UIApplication.shared.keyWindow?.rootViewController = basicVC
        let _ = basicVC.view
        
        wait(for: [htmlExpectation], timeout: 10)
        wait(for: [imageExpectation], timeout: 10)
        wait(for: [cssExpectation], timeout: 10)
        
        LSNocilla.sharedInstance().stop()
    }
    
    func testBasicNetworkFailureWithCachedArticle() {
        
        LSNocilla.sharedInstance().start()
        stub500Responses()
        writeCachedPiecesToCachingSystem()
        
        let basicVC = BasicCachingWebViewController()
        
        let htmlExpectation = expectation(description: "Waiting for html content to return")
        let imageExpectation = expectation(description: "Waiting for image load to return")
        let cssExpectation = expectation(description: "Waiting for css load to return")
        
        basicVC.didReceiveDataCallback = { urlSchemeTask, data in
            
            guard let urlString = urlSchemeTask.request.url?.absoluteString else {
                XCTFail("Unable to determine urlString from scheme task")
                return
            }
            
            switch urlString {
            case "app://en.wikipedia.org/api/rest_v1/page/mobile-html/United_States":
                
                htmlExpectation.fulfill()
                
                let htmlString = String(decoding: data, as: UTF8.self)
                let trimmedHTML = String(htmlString.filter { !"\n\t\r".contains($0) })
                XCTAssertEqual(trimmedHTML, "<!DOCTYPE html><html><head><link rel=\"stylesheet\" href=\"//en.wikipedia.org/api/rest_v1/data/css/mobile/site\"></head><body><p>Testing Cached</p><img src=\"//upload.wikimedia.org/wikipedia/en/thumb/a/a4/Flag_of_the_United_States.svg/960px-Flag_of_the_United_States.svg.png\"></body></html>")
                
            case "app://en.wikipedia.org/api/rest_v1/data/css/mobile/site":
                
                cssExpectation.fulfill()
                
                let cssString = String(decoding: data, as: UTF8.self)
                let trimmedCSS = String(cssString.filter { !"\n\t\r".contains($0) })
                XCTAssertEqual(trimmedCSS, "body {background-color: red;}", "Unexpected basic HTML content")
            case "app://upload.wikimedia.org/wikipedia/en/thumb/a/a4/Flag_of_the_United_States.svg/960px-Flag_of_the_United_States.svg.png":
                imageExpectation.fulfill()
            default:
                XCTFail("Unexpected scheme task callback")
            }
        }
        
        UIApplication.shared.keyWindow?.rootViewController = basicVC
        let _ = basicVC.view
        
        wait(for: [htmlExpectation], timeout: 10)
        wait(for: [imageExpectation], timeout: 10)
        wait(for: [cssExpectation], timeout: 10)
        
        LSNocilla.sharedInstance().stop()
    }
    
    func testBasicNetworkNoConnectionWithCachedArticle() {
        
        //FLIP DEVICE TO AIRPLANE MODE BEFORE RUNNING THIS
        
        writeCachedPiecesToCachingSystem()
        
        let basicVC = BasicCachingWebViewController()
        
        let htmlExpectation = expectation(description: "Waiting for html content to return")
        let imageExpectation = expectation(description: "Waiting for image load to return")
        let cssExpectation = expectation(description: "Waiting for css load to return")
        
        basicVC.didReceiveDataCallback = { urlSchemeTask, data in
            
            guard let urlString = urlSchemeTask.request.url?.absoluteString else {
                XCTFail("Unable to determine urlString from scheme task")
                return
            }
            
            switch urlString {
            case "app://en.wikipedia.org/api/rest_v1/page/mobile-html/United_States":
                
                htmlExpectation.fulfill()
                
                let htmlString = String(decoding: data, as: UTF8.self)
                let trimmedHTML = String(htmlString.filter { !"\n\t\r".contains($0) })
                XCTAssertEqual(trimmedHTML, "<!DOCTYPE html><html><head><link rel=\"stylesheet\" href=\"//en.wikipedia.org/api/rest_v1/data/css/mobile/site\"></head><body><p>Testing Cached</p><img src=\"//upload.wikimedia.org/wikipedia/en/thumb/a/a4/Flag_of_the_United_States.svg/960px-Flag_of_the_United_States.svg.png\"></body></html>")
                
            case "app://en.wikipedia.org/api/rest_v1/data/css/mobile/site":
                
                cssExpectation.fulfill()
                
                let cssString = String(decoding: data, as: UTF8.self)
                let trimmedCSS = String(cssString.filter { !"\n\t\r".contains($0) })
                XCTAssertEqual(trimmedCSS, "body {background-color: red;}", "Unexpected basic HTML content")
            case "app://upload.wikimedia.org/wikipedia/en/thumb/a/a4/Flag_of_the_United_States.svg/960px-Flag_of_the_United_States.svg.png":
                imageExpectation.fulfill()
            default:
                XCTFail("Unexpected scheme task callback")
            }
        }
        
        UIApplication.shared.keyWindow?.rootViewController = basicVC
        let _ = basicVC.view
        
        wait(for: [htmlExpectation], timeout: 10)
        wait(for: [imageExpectation], timeout: 10)
        wait(for: [cssExpectation], timeout: 10)
    }
    
    func testVariantFallbacksUponNetworkFailure() {
        LSNocilla.sharedInstance().start()
        stub500ZhResponses()
        writeVariantPiecesToCachingSystem()
        
        let basicVC = BasicCachingWebViewController()
        basicVC.extraHeaders = ["Accept-Language": "zh-hant"]
        basicVC.articleURL = URL(string: "app://zh.wikipedia.org/api/rest_v1/page/mobile-html/%E7%BE%8E%E5%9B%BD")!
        
        let htmlExpectation = expectation(description: "Waiting for html content to return")
        let imageExpectation = expectation(description: "Waiting for image load to return")
        let cssExpectation = expectation(description: "Waiting for css load to return")
        
        basicVC.didReceiveDataCallback = { urlSchemeTask, data in
            
            guard let urlString = urlSchemeTask.request.url?.absoluteString else {
                XCTFail("Unable to determine urlString from scheme task")
                return
            }
            
            switch urlString {
            case "app://zh.wikipedia.org/api/rest_v1/page/mobile-html/%E7%BE%8E%E5%9B%BD":
                
                htmlExpectation.fulfill()
                
                let htmlString = String(decoding: data, as: UTF8.self)
                let trimmedHTML = String(htmlString.filter { !"\n\t\r".contains($0) })
                XCTAssertEqual(trimmedHTML, "<!DOCTYPE html><html><head><link rel=\"stylesheet\" href=\"//zh.wikipedia.org/api/rest_v1/data/css/mobile/site\"></head><body><p>美国 (美洲北部国家)</p><img src=\"//upload.wikimedia.org/wikipedia/commons/thumb/e/e2/Flag_of_the_United_States_%28Pantone%29.svg/960px-Flag_of_the_United_States_%28Pantone%29.svg.png\"></body></html>")
                
            case "app://zh.wikipedia.org/api/rest_v1/data/css/mobile/site":
                
                cssExpectation.fulfill()
                
                let cssString = String(decoding: data, as: UTF8.self)
                let trimmedCSS = String(cssString.filter { !"\n\t\r".contains($0) })
                XCTAssertEqual(trimmedCSS, "body {background-color: blue;}", "Unexpected basic HTML content")
            case "app://upload.wikimedia.org/wikipedia/commons/thumb/e/e2/Flag_of_the_United_States_%28Pantone%29.svg/960px-Flag_of_the_United_States_%28Pantone%29.svg.png":
                imageExpectation.fulfill()
            default:
                XCTFail("Unexpected scheme task callback")
            }
        }
        
        UIApplication.shared.keyWindow?.rootViewController = basicVC
        let _ = basicVC.view
        
        wait(for: [htmlExpectation], timeout: 10)
        wait(for: [imageExpectation], timeout: 100)
        wait(for: [cssExpectation], timeout: 10)
        
        LSNocilla.sharedInstance().stop()
    }
    
    func testVariantFallbacksUponConnectionFailure() {

        //FLIP DEVICE TO AIRPLANE MODE BEFORE RUNNING THIS
        
        writeVariantPiecesToCachingSystem()
        
        let basicVC = BasicCachingWebViewController()
        basicVC.extraHeaders = ["Accept-Language": "zh-hant"]
        basicVC.articleURL = URL(string: "app://zh.wikipedia.org/api/rest_v1/page/mobile-html/%E7%BE%8E%E5%9B%BD")!
        
        let htmlExpectation = expectation(description: "Waiting for html content to return")
        let imageExpectation = expectation(description: "Waiting for image load to return")
        let cssExpectation = expectation(description: "Waiting for css load to return")
        
        basicVC.didReceiveDataCallback = { urlSchemeTask, data in
            
            guard let urlString = urlSchemeTask.request.url?.absoluteString else {
                XCTFail("Unable to determine urlString from scheme task")
                return
            }
            
            switch urlString {
            case "app://zh.wikipedia.org/api/rest_v1/page/mobile-html/%E7%BE%8E%E5%9B%BD":
                
                htmlExpectation.fulfill()
                
                let htmlString = String(decoding: data, as: UTF8.self)
                let trimmedHTML = String(htmlString.filter { !"\n\t\r".contains($0) })
                XCTAssertEqual(trimmedHTML, "<!DOCTYPE html><html><head><link rel=\"stylesheet\" href=\"//zh.wikipedia.org/api/rest_v1/data/css/mobile/site\"></head><body><p>美国 (美洲北部国家)</p><img src=\"//upload.wikimedia.org/wikipedia/commons/thumb/e/e2/Flag_of_the_United_States_%28Pantone%29.svg/960px-Flag_of_the_United_States_%28Pantone%29.svg.png\"></body></html>")
                
            case "app://zh.wikipedia.org/api/rest_v1/data/css/mobile/site":
                
                cssExpectation.fulfill()
                
                let cssString = String(decoding: data, as: UTF8.self)
                let trimmedCSS = String(cssString.filter { !"\n\t\r".contains($0) })
                XCTAssertEqual(trimmedCSS, "body {background-color: blue;}", "Unexpected basic HTML content")
            case "app://upload.wikimedia.org/wikipedia/commons/thumb/e/e2/Flag_of_the_United_States_%28Pantone%29.svg/960px-Flag_of_the_United_States_%28Pantone%29.svg.png":
                imageExpectation.fulfill()
            default:
                XCTFail("Unexpected scheme task callback")
            }
        }
        
        UIApplication.shared.keyWindow?.rootViewController = basicVC
        let _ = basicVC.view
        
        wait(for: [htmlExpectation], timeout: 10)
        wait(for: [imageExpectation], timeout: 100)
        wait(for: [cssExpectation], timeout: 10)
    }
    
    private func writeVariantPiecesToCachingSystem() {
        guard let moc = CacheController.backgroundCacheContext else {
            XCTFail("Unable to pull backgroundCacheContext")
            return
        }
         
        let mobileHTMLURLString = "https://zh.wikipedia.org/api/rest_v1/page/mobile-html/%E7%BE%8E%E5%9B%BD"
        let cssString = "https://zh.wikipedia.org/api/rest_v1/data/css/mobile/site"
        let imageURLString = "https://upload.wikimedia.org/wikipedia/commons/thumb/e/e2/Flag_of_the_United_States_%28Pantone%29.svg/640px-Flag_of_the_United_States_%28Pantone%29.svg.png"
        
        //save objects database
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
        
        //set up file names and content
        let fileNameGenerator = PermanentlyPersistableURLCache()
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
        
        guard let htmlData = self.basicCachedZhansHTMLData,
            let imageData = self.imageZh640Data,
            let cssData = self.basicCachedZhCSSData else {
                XCTFail("Failure pulling data from Fixtures")
                return
        }
        
        //save content in file system
        CacheFileWriterHelper.saveData(data: htmlData, toNewFileWithKey: uniqueHTMLFileName) { (result) in
            switch result {
            case .success, .exists:
                break
            case .failure:
                XCTFail("Failure saving html data")
            }
        }
        
        CacheFileWriterHelper.saveData(data: imageData, toNewFileWithKey: uniqueImageFileName) { (result) in
            switch result {
            case .success, .exists:
                break
            case .failure:
                XCTFail("Failure saving html data")
            }
        }
        
        CacheFileWriterHelper.saveData(data: cssData, toNewFileWithKey: uniqueCSSFileName) { (result) in
            switch result {
            case .success, .exists:
                break
            case .failure:
                XCTFail("Failure saving html data")
            }
        }
        
        //save headers in file system
        let htmlHeaders: [String: String] = ["Content-Type": "text/html; charset=utf-8;",
                                             "Vary": "Accept-Language, Accept-Encoding"]
        
        CacheFileWriterHelper.saveResponseHeader(headerFields: htmlHeaders, toNewFileName: uniqueHTMLHeaderFileName) { (result) in
            switch result {
            case .success, .exists:
                break
            case .failure:
                break
            }
        }
        
        let imageHeaders: [String: String] = ["Content-Type": "image/jpeg",
                                              "Content-Length": String((imageData as NSData).length)]
        
        CacheFileWriterHelper.saveResponseHeader(headerFields: imageHeaders, toNewFileName: uniqueImageHeaderFileName) { (result) in
            switch result {
            case .success, .exists:
                break
            case .failure:
                break
            }
        }
        
        let cssHeaders: [String: String] = ["Content-Type": "text/css; charset=utf-8;",
                                              "Content-Length": String((cssData as NSData).length)]
        
        CacheFileWriterHelper.saveResponseHeader(headerFields: cssHeaders, toNewFileName: uniqueCSSHeaderFileName) { (result) in
            switch result {
            case .success, .exists:
                break
            case .failure:
                break
            }
        }
    }
    
    private func writeCachedPiecesToCachingSystem() {
        guard let moc = CacheController.backgroundCacheContext else {
            XCTFail("Unable to pull backgroundCacheContext")
            return
        }
         
        let mobileHTMLURLString = "https://en.wikipedia.org/api/rest_v1/page/mobile-html/United_States"
        let cssString = "https://en.wikipedia.org/api/rest_v1/data/css/mobile/site"
        
        //save objects database
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
        
        //set up file names and content
        let fileNameGenerator = PermanentlyPersistableURLCache()
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
        
        guard let htmlData = self.basicCachedHTMLData,
            let imageData = self.imageData,
            let cssData = self.basicCachedCSSData else {
                XCTFail("Failure pulling data from Fixtures")
                return
        }
        
        //save content in file system
        CacheFileWriterHelper.saveData(data: htmlData, toNewFileWithKey: uniqueHTMLFileName) { (result) in
            switch result {
            case .success, .exists:
                break
            case .failure:
                XCTFail("Failure saving html data")
            }
        }
        
        CacheFileWriterHelper.saveData(data: imageData, toNewFileWithKey: uniqueImageFileName) { (result) in
            switch result {
            case .success, .exists:
                break
            case .failure:
                XCTFail("Failure saving html data")
            }
        }
        
        CacheFileWriterHelper.saveData(data: cssData, toNewFileWithKey: uniqueCSSFileName) { (result) in
            switch result {
            case .success, .exists:
                break
            case .failure:
                XCTFail("Failure saving html data")
            }
        }
        
        //save headers in file system
        let htmlHeaders: [String: String] = ["Content-Type": "text/html; charset=utf-8;"]
        
        CacheFileWriterHelper.saveResponseHeader(headerFields: htmlHeaders, toNewFileName: uniqueHTMLHeaderFileName) { (result) in
            switch result {
            case .success, .exists:
                break
            case .failure:
                break
            }
        }
        
        let imageHeaders: [String: String] = ["Content-Type": "image/jpeg",
                                              "Content-Length": String((imageData as NSData).length)]
        
        CacheFileWriterHelper.saveResponseHeader(headerFields: imageHeaders, toNewFileName: uniqueImageHeaderFileName) { (result) in
            switch result {
            case .success, .exists:
                break
            case .failure:
                break
            }
        }
        
        let cssHeaders: [String: String] = ["Content-Type": "text/css; charset=utf-8;",
                                              "Content-Length": String((cssData as NSData).length)]
        
        CacheFileWriterHelper.saveResponseHeader(headerFields: cssHeaders, toNewFileName: uniqueCSSHeaderFileName) { (result) in
            switch result {
            case .success, .exists:
                break
            case .failure:
                break
            }
        }
    }
}
