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

    //represents the speed at which article content is seen on screen
    func testArticleSetupTime() {
        
        self.measure {
            
            let dataStore = MWKDataStore.temporary()
            guard let measurableArticleVC = MeasurableArticleViewController(articleURL: url, dataStore: dataStore, theme: .light) else {
                XCTFail("Unable to instantiate MeasurableArticleViewController")
                return
            }
            
            let setupExpectation = expectation(description: "Waiting for article initial setup call")
            
            loadArticle(articleViewController: measurableArticleVC) {
                setupExpectation.fulfill()
                UIApplication.shared.keyWindow?.rootViewController = nil
                dataStore.clearTemporaryCache()
            }
        
            wait(for: [setupExpectation], timeout: 10)
        }
    }
    
    //represents the speed at which the article summary will show on screen from a 3D touch
    func testContextMenuConfigTime() {
        
        self.measure {
            
            let dataStore = MWKDataStore.temporary()
            guard let articleVC = ArticleViewController(articleURL: url, dataStore: dataStore, theme: .light) else {
                XCTFail("Unable to instantiate MeasurableArticleViewController")
                return
            }
            
            let contextExpectation = expectation(description: "Waiting for context menu configuration call")
            
            let catURL = URL(string: "app://en.wikipedia.org/wiki/Cat")!
            
            if #available(iOS 13.0, *) {
                articleVC.contextMenuConfigurationForLinkURL(catURL) { (completionType, menuConfig) in
                    if completionType == .bail {
                       print("bailed")
                    }
                    
                    if completionType == .timeout {
                        print("timed out")
                    }
                    
                    contextExpectation.fulfill()
                    dataStore.clearTemporaryCache()
                }
            } else {
                contextExpectation.fulfill()
            }
        
            wait(for: [contextExpectation], timeout: 1)
        }
    }

}
