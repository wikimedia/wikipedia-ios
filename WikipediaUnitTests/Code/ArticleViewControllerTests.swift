@testable import Wikipedia
import XCTest

private class MockSchemeHandler: SchemeHandler {
    
    var accessed = false
    
    required init(scheme: String, session: Session) {
        super.init(scheme: scheme, session: session)
        let didReceiveDataCallback: ((WKURLSchemeTask, Data) -> Void)? = { [weak self] _, _ in
            self?.accessed = true
        }
        self.didReceiveDataCallback = didReceiveDataCallback
    }
}

class ArticleViewControllerTests: XCTestCase {
    let timeout: TimeInterval = 10
    
    override func setUp(completion: @escaping (Error?) -> Void) {
        
        ArticleTestHelpers.setup {
            LSNocilla.sharedInstance().start()
            ArticleTestHelpers.stubCompleteMobileHTMLResponse(inBundle: self.wmf_bundle())
            completion(nil)
        }
        
    }

    override func tearDown() {
       super.tearDown()
       LSNocilla.sharedInstance().stop()
    }

    func testArticleVCAccessesSchemeHandler() throws {
        
        // test that articleVC converts articleURL to proper scheme and sets up SchemeHandler to ensure it is accessed during a load
        
        let tempDatabaseExpectation = expectation(description: "Waiting for temp database setup")
        
        var dataStore: MWKDataStore!
        MWKDataStore.createTemporaryDataStore { result in
            
            dataStore = result
            tempDatabaseExpectation.fulfill()
        }
        
        wait(for: [tempDatabaseExpectation], timeout: timeout)
        
        let theme = Theme.light
        let url = URL(string: "https://en.wikipedia.org/wiki/Dog")!
        let schemeHandler = MockSchemeHandler(scheme: "app", session: dataStore.session)
        guard let articleVC = ArticleViewController(articleURL: url, dataStore: dataStore, theme: theme, schemeHandler: schemeHandler) else {
            XCTFail("Failure initializing Article View Controller")
            return
        }
        
        let setupExpectation = expectation(description: "Waiting for article initial setup call")
        
        articleVC.initialSetupCompletion = {
            setupExpectation.fulfill()
            XCTAssert(schemeHandler.accessed, "SchemeHandler was not accessed during article load.")
            UIApplication.shared.workaroundKeyWindow?.rootViewController = nil
            dataStore.clearTemporaryCache()
            dataStore.session.teardown()
        }
            
        UIApplication.shared.workaroundKeyWindow?.rootViewController = articleVC
    
        wait(for: [setupExpectation], timeout: timeout)
    }

}
