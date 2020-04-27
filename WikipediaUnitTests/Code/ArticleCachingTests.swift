@testable import Wikipedia
@testable import WMF
import XCTest

private class BasicCachingWebViewController: UIViewController, WKNavigationDelegate {
    static let webProcessPool = WKProcessPool()
    
    let schemeHandler = SchemeHandler.shared
    let articleURL = URL(string: "app://en.wikipedia.org/api/rest_v1/basic")!
    let session = Session.shared
    let configuration = Configuration.current
    var didReceiveDataCallback: ((WKURLSchemeTask, Data) -> Void)?
    
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
        return fetcher.urlRequest(from: articleURL, headers: acceptUTF8HTML)
    }
    
    private func setupWebView() {
        schemeHandler.didReceiveDataCallback = self.didReceiveDataCallback
        webView.navigationDelegate = self
        view.wmf_addSubviewWithConstraintsToEdges(webView)
    }
}

class ArticleCachingTests: XCTestCase {

    override func setUp() {
        super.setUp()
        
        LSNocilla.sharedInstance().start()
        setupNetworkStubs()
        setupTemporaryCacheController()
    }

    override func tearDown() {
        super.tearDown()
        LSNocilla.sharedInstance().stop()
    }
    
    private func setupTemporaryCacheController() {
        let tempPath = WMFRandomTemporaryPath()!
        let randomURL = NSURL.fileURL(withPath: tempPath)
        let temporaryCacheURL = randomURL.appendingPathComponent("Permanent Cache", isDirectory: true)

        CacheController.temporaryCacheURL = temporaryCacheURL
    }

    private func setupNetworkStubs() {
        
        guard let imageData = wmf_bundle().wmf_data(fromContentsOfFile:"960px-Flag_of_the_United_States.svg", ofType:"png"),
            let basicHTMLData = wmf_bundle().wmf_data(fromContentsOfFile:"basic", ofType:"html") else {
            assertionFailure("Error setting up fixtures.")
            return
        }
        
        let _ = stubRequest("GET", "https://upload.wikimedia.org/wikipedia/en/thumb/a/a4/Flag_of_the_United_States.svg/960px-Flag_of_the_United_States.svg.png" as NSString)
        .andReturnRawResponse(imageData)
        
        let _ = stubRequest("GET", "https://en.wikipedia.org/api/rest_v1/basic" as NSString)
        .andReturn(200)?
        .withBody(basicHTMLData as NSData)
        
    }
    
    func testBasicArticleLoad() {
        let basicVC = BasicCachingWebViewController()
        
        let htmlExpectation = expectation(description: "Waiting for html content to return")
        let imageExpectation = expectation(description: "Waiting for image load to return")
        
        basicVC.didReceiveDataCallback = { urlSchemeTask, data in
            
            guard let urlString = urlSchemeTask.request.url?.absoluteString else {
                XCTFail("Unable to determine urlString from scheme task")
                return
            }
            
            switch urlString {
            case "app://en.wikipedia.org/api/rest_v1/basic":
                
                htmlExpectation.fulfill()
                
                let htmlString = String(decoding: data, as: UTF8.self)
                let trimmedHTML = String(htmlString.filter { !"\n\t\r".contains($0) })
                XCTAssertEqual(trimmedHTML, "<!DOCTYPE html><html><head></head><body><p>Testing</p><img src=\"//upload.wikimedia.org/wikipedia/en/thumb/a/a4/Flag_of_the_United_States.svg/960px-Flag_of_the_United_States.svg.png\"></body></html>", "Unexpected basic HTML content")
                
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
    }
    
    func testBasicNetworkFailureWithCachedArticle() {
        
        //START
        //Write necessary objects and files to caching system
        guard let moc = CacheController.backgroundCacheContext else {
            XCTFail("Unable to pull backgroundCacheContext")
            return
        }
        
        //save objects database
        guard let cacheGroup = CacheDBWriterHelper.cacheGroup(with: "https://en.wikipedia.org/api/rest_v1/basic", in: moc),
        let htmlCacheItem = CacheDBWriterHelper.cacheItem(with: "https://en.wikipedia.org/api/rest_v1/basic", variant: nil, in: moc),
         let imageCacheItem = CacheDBWriterHelper.cacheItem(with: "https://upload.wikimedia.org/wikipedia/en/thumb/a/a4/Flag_of_the_United_States.svg/960px-Flag_of_the_United_States.svg.png", variant: "960", in: moc) else {
            XCTFail("Unable to create Cache DB objects")
            return
        }
        
        cacheGroup.addToCacheItems(htmlCacheItem)
        cacheGroup.addToCacheItems(imageCacheItem)
        
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
        guard let htmlURL = URL(string: "https://en.wikipedia.org/api/rest_v1/basic"),
            let uniqueHTMLFileName = fileNameGenerator.uniqueFileNameForURL(htmlURL, type: .article),
            let uniqueHTMLHeaderFileName = fileNameGenerator.uniqueHeaderFileNameForURL(htmlURL, type: .article) else {
                XCTFail("Failure determining html file name")
                return
        }
        
        guard let imageURL = URL(string: "https://upload.wikimedia.org/wikipedia/en/thumb/a/a4/Flag_of_the_United_States.svg/960px-Flag_of_the_United_States.svg.png"),
            let uniqueImageFileName = fileNameGenerator.uniqueFileNameForURL(imageURL, type: .image),
        let uniqueImageHeaderFileName = fileNameGenerator.uniqueHeaderFileNameForURL(imageURL, type: .image) else {
                XCTFail("Failure determining image file name")
                return
        }
        
        guard let htmlData = wmf_bundle().wmf_data(fromContentsOfFile:"basic", ofType:"html"),
            let imageData = wmf_bundle().wmf_data(fromContentsOfFile:"960px-Flag_of_the_United_States.svg", ofType:"png") else {
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
        
        //END
        //Write necessary objects and files to caching system
    }
}
