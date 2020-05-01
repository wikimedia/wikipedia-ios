import XCTest
@testable import Wikipedia

class MeasurableArticleViewController: ArticleViewController {
    
    var initialLoadCompletion: (() -> Void)?
    
    override func handlePCSDidFinishFinalSetup() {
        super.handlePCSDidFinishFinalSetup()
        initialLoadCompletion?()
    }
}

class MeasurableArticlePeekPreviewViewController: ArticlePeekPreviewViewController {
    var displayCompletion: (() -> Void)?
    
    override func updatePreferredContentSize(for contentWidth: CGFloat) {
        super.updatePreferredContentSize(for: contentWidth)
        displayCompletion?()
    }
}

class ArticlePerformanceTests: XCTestCase {
    
    private var articleURL: URL! = URL(string: "https://en.wikipedia.org/wiki/Dog")
    private var appSchemeArticleURL: URL! = URL(string: "app://en.wikipedia.org/wiki/Dog")
    
    override func setUp() {
        super.setUp()
        
        LSNocilla.sharedInstance().start()
        ArticleTestHelpers.stubCompleteMobileHTMLResponse(inBundle: wmf_bundle())
    }

    override func tearDown() {
        super.tearDown()
        LSNocilla.sharedInstance().stop()
    }

    //represents the speed at which article content is seen on screen
    func testArticleSetupTime() {

        self.measure {
            
            let dataStore = MWKDataStore.temporary()
            guard let measurableArticleVC = MeasurableArticleViewController(articleURL: articleURL, dataStore: dataStore, theme: .light) else {
                XCTFail("Unable to instantiate MeasurableArticleViewController")
                return
            }
            
            let setupExpectation = expectation(description: "Waiting for article initial setup call")
            
            measurableArticleVC.initialLoadCompletion = {
                setupExpectation.fulfill()
                UIApplication.shared.keyWindow?.rootViewController = nil
                dataStore.clearTemporaryCache()
            }
            
            UIApplication.shared.keyWindow?.rootViewController = measurableArticleVC
            let _ = measurableArticleVC.view
        
            wait(for: [setupExpectation], timeout: 3)
        }
    }
    
    //represents the speed at which the context menu configuration is generated from a 3D touch on an article link
    func testContextMenuConfigTime() {
        
        let dataStore = MWKDataStore.temporary()
        self.measure {
            
            guard let articleVC = ArticleViewController(articleURL: articleURL, dataStore: dataStore, theme: .light) else {
                XCTFail("Unable to instantiate MeasurableArticleViewController")
                return
            }
            
            let contextExpectation = expectation(description: "Waiting for context menu configuration call")
            
            if #available(iOS 13.0, *) {
                articleVC.contextMenuConfigurationForLinkURL(appSchemeArticleURL) { (completionType, menuConfig) in
                    if completionType == .bail {
                       XCTFail("Menu config should not bail.")
                    }
                    
                    if completionType == .timeout {
                        XCTFail("Menu config should not time out.")
                    }
                    
                    contextExpectation.fulfill()
                    dataStore.clearTemporaryCache()
                }
            } else {
                contextExpectation.fulfill()
            }
        
            wait(for: [contextExpectation], timeout: 3)
        }
    }
    
    func testArticlePeekPreviewControllerDisplayTime() {
        
        let dataStore = MWKDataStore.temporary()
        
        self.measure {
        
            let peekVC = MeasurableArticlePeekPreviewViewController(articleURL: articleURL, dataStore: dataStore, theme: .standard)
            
            let displayExpectation = expectation(description: "Waiting for MeasurableArticlePeekPreviewViewController displayCompletion call")
            
            peekVC.displayCompletion = {
                displayExpectation.fulfill()
                UIApplication.shared.keyWindow?.rootViewController = nil
                dataStore.clearTemporaryCache()
            }
            
            UIApplication.shared.keyWindow?.rootViewController = peekVC
            let _ = peekVC.view
            
            wait(for: [displayExpectation], timeout: 3)
        }
    }
}
