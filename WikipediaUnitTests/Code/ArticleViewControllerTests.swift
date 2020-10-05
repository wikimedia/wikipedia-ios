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
    
    override func setUp() {
       super.setUp()
       
       LSNocilla.sharedInstance().start()
       ArticleTestHelpers.stubCompleteMobileHTMLResponse(inBundle: wmf_bundle())
    }

    override func tearDown() {
       super.tearDown()
       LSNocilla.sharedInstance().stop()
    }

    func testArticleVCAccessesSchemeHandler() throws {
        
        //test that articleVC converts articleURL to proper scheme and sets up SchemeHandler to ensure it is accessed during a load
        let dataStore = MWKDataStore.temporary()
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
            UIApplication.shared.keyWindow?.rootViewController = nil
            dataStore.clearTemporaryCache()
            dataStore.session.teardown()
        }
            
        UIApplication.shared.keyWindow?.rootViewController = articleVC
    
        wait(for: [setupExpectation], timeout: timeout)
    }

}
