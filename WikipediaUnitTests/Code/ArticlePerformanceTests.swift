import XCTest
@testable import Wikipedia

class MeasurableArticleViewController: ArticleViewController {
    
    var initialLoadCompletion: (() -> Void)?
    
    override func handlePCSDidFinishFinalSetup() {
        super.handlePCSDidFinishFinalSetup()
        initialLoadCompletion?()
    }
}

class ArticlePerformanceTests: XCTestCase {
    
    private var url: URL!
    
    override func setUp() {
        super.setUp()
        let configuration = Configuration.current
        guard let url = configuration.articleURLForHost("en.wikipedia.org", appending: ["Dog"]).url else {
            XCTFail("Unable to determine articleURL")
            return
        }
        self.url = url
    }
    
    func loadArticle(articleViewController: MeasurableArticleViewController, initialLoadCompletion: @escaping () -> Void) {
       
        articleViewController.initialLoadCompletion = initialLoadCompletion
        UIApplication.shared.keyWindow?.rootViewController = articleViewController
        let _ = articleViewController.view
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            
            guard let measurableArticleVC = MeasurableArticleViewController(articleURL: url, dataStore: MWKDataStore.temporary(), theme: .light) else {
                XCTFail("Unable to instantiate MeasurableArticleViewController")
                return
            }
            
            let setupExpectation = expectation(description: "Waiting for article initial setup call")
            
            loadArticle(articleViewController: measurableArticleVC) {
                setupExpectation.fulfill()
                UIApplication.shared.keyWindow?.rootViewController = nil
                WKWebView.clear()
                URLCache.shared.removeAllCachedResponses()
            }
        
            wait(for: [setupExpectation], timeout: 5)
        }
    }

}

fileprivate extension WKWebView {
    static func clear() {
        let websiteDataTypes = NSSet(array: [WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache])
        let date = Date(timeIntervalSince1970: 0)
        WKWebsiteDataStore.default().removeData(ofTypes: websiteDataTypes as! Set<String>, modifiedSince: date, completionHandler:{ })
    }
}
