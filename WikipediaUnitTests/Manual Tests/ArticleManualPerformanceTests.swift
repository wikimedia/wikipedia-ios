import XCTest
@testable import Wikipedia

class MeasurableArticlePeekPreviewViewController: ArticlePeekPreviewViewController {
    var displayCompletion: (() -> Void)?
    
    override func updatePreferredContentSize(for contentWidth: CGFloat) {
        super.updatePreferredContentSize(for: contentWidth)
        displayCompletion?()
    }
}

class ArticleManualPerformanceTests: XCTestCase {
    let timeout: TimeInterval = 10
    
    private var articleURL: URL! = URL(string: "https://en.wikipedia.org/wiki/Dog")
    private var appSchemeArticleURL: URL! = URL(string: "app://en.wikipedia.org/wiki/Dog")
    private var contextMenuConfigAppSchemeArticleURL: URL! = URL(string: "app://en.wikipedia.org/wiki/Cat")
    
    override func setUp(completion: @escaping (Error?) -> Void) {
        LSNocilla.sharedInstance().start()
        ArticleTestHelpers.setup {
            ArticleTestHelpers.stubCompleteMobileHTMLResponse(inBundle: self.wmf_bundle())
            completion(nil)
        }
    }

    override func tearDown() {
        super.tearDown()
        LSNocilla.sharedInstance().stop()
    }

    // represents the speed at which article content is seen on screen
    func testArticleSetupTime() {
        
        let tempDatabaseExpectation = expectation(description: "Waiting for temp database setup")
        
        var dataStore: MWKDataStore!
        MWKDataStore.createTemporaryDataStore { result in
            
            dataStore = result
            tempDatabaseExpectation.fulfill()
        }
        
        wait(for: [tempDatabaseExpectation], timeout: timeout)

        self.measure {

            guard let articleVC = ArticleViewController(articleURL: articleURL, dataStore: dataStore, theme: .light) else {
                XCTFail("Unable to instantiate ArticleViewController")
                return
            }
            
            let articleSetupExpectation = expectation(description: "Waiting for article initial setup call")
            
            articleVC.initialSetupCompletion = {
                articleSetupExpectation.fulfill()
                UIApplication.shared.workaroundKeyWindow?.rootViewController = nil
                dataStore.clearTemporaryCache()
            }
            
            UIApplication.shared.workaroundKeyWindow?.rootViewController = articleVC
        
            wait(for: [articleSetupExpectation], timeout: timeout)
        }
    }
    
    // represents the speed at which the context menu configuration is generated from a 3D touch on an article link
    func testContextMenuConfigTime() {
        
        let tempDatabaseExpectation = expectation(description: "Waiting for temp database setup")
        
        var dataStore: MWKDataStore!
        MWKDataStore.createTemporaryDataStore { result in
            dataStore = result
            tempDatabaseExpectation.fulfill()
        }
        
        wait(for: [tempDatabaseExpectation], timeout: timeout)
        
        self.measure {
            
            guard let articleVC = ArticleViewController(articleURL: articleURL, dataStore: dataStore, theme: .light) else {
                XCTFail("Unable to instantiate ArticleViewController")
                return
            }
            
            let contextExpectation = expectation(description: "Waiting for context menu configuration call")
            
            articleVC.contextMenuConfigurationForLinkURL(contextMenuConfigAppSchemeArticleURL, ignoreTimeout: true) { (completionType, menuConfig) in
                if completionType == .bail {
                   XCTFail("Menu config should not bail.")
                }
                
                if completionType == .timeout {
                    XCTFail("Menu config should not time out.")
                }
                
                contextExpectation.fulfill()
                dataStore.clearTemporaryCache()
            }
        
            wait(for: [contextExpectation], timeout: timeout)
        }
    }
    
    func testArticlePeekPreviewControllerDisplayTime() {
        
        let tempDatabaseExpectation = expectation(description: "Waiting for temp database setup")
        
        var dataStore: MWKDataStore!
        MWKDataStore.createTemporaryDataStore { result in
            dataStore = result
            tempDatabaseExpectation.fulfill()
        }
        
        wait(for: [tempDatabaseExpectation], timeout: timeout)
        
        self.measure {
        
            let peekVC = MeasurableArticlePeekPreviewViewController(articleURL: articleURL, dataStore: dataStore, theme: .standard)
            
            let displayExpectation = expectation(description: "Waiting for MeasurableArticlePeekPreviewViewController displayCompletion call")
            
            peekVC.displayCompletion = {
                displayExpectation.fulfill()
                UIApplication.shared.workaroundKeyWindow?.rootViewController = nil
                dataStore.clearTemporaryCache()
            }
            
            UIApplication.shared.workaroundKeyWindow?.rootViewController = peekVC
            
            wait(for: [displayExpectation], timeout: timeout)
        }
    }
}
