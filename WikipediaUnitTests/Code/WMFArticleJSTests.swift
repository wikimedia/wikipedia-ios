
import WebKit
import XCTest

class WMFArticleJSTests2: XCTestCase, WKScriptMessageHandler {
    
    var session: SessionSingleton?
    var webVC: WebViewController?
    var obamaURL: URL?
    var obamaArticle: MWKArticle?

    var receivedInitialNoFirstSectionYetMessage: Bool = false
    
    var firstSectionAppearedMessageReceivedExpectation: XCTestExpectation?
    var initialNoFirstSectionYetMessageReceivedExpectation: XCTestExpectation?

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.

        session = SessionSingleton.init(dataStore: MWKDataStore.temporary())
        webVC = WebViewController.wmf_initialViewControllerFromClassStoryboard()
        
        guard
            let newObamaURL = NSURL.wmf_URL(withDomain: "wikipedia.org", language: "en", title: "Barack Obama", fragment: nil),
            let dataStore = session?.dataStore
        else {
            assertionFailure("Expected Obama article and data store")
            return
        }
        obamaURL = newObamaURL
        obamaArticle = article(withMobileViewJSONFixture: "Obama", with: newObamaURL, dataStore: dataStore)
        obamaArticle?.save()
        
        initialNoFirstSectionYetMessageReceivedExpectation = nil
        firstSectionAppearedMessageReceivedExpectation = nil
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        // print("\n \n \n message body : \(message.body) \n \n \n ")
        
        if
            receivedInitialNoFirstSectionYetMessage == false,
            let messageString = message.body as? String,
            messageString == "noFirstSectionYet"
        {
            receivedInitialNoFirstSectionYetMessage = true
            initialNoFirstSectionYetMessageReceivedExpectation?.fulfill()
        }

        if
            let messageString = message.body as? String,
            messageString == "firstSectionAppeared"
        {
            firstSectionAppearedMessageReceivedExpectation?.fulfill()
        }
    }
    
    func testFirstSectionAppearanceDelay() {

        self.measureMetrics(XCTestCase.defaultPerformanceMetrics, automaticallyStartMeasuring: false, for: {
            
            let safeToContinueExpectation = self.expectation(description: "waiting for last measurement to finish")
            
            webVC?.wkUserContentControllerTestingConfigurationBlock = { userContentController in
                userContentController.add(self, name: "jsTesting")
                
                let js = """
                const checkForFirstSectionIsPresent = () => {
                   if(document.querySelector('#section_heading_and_content_block_0')){
                       window.webkit.messageHandlers.jsTesting.postMessage('firstSectionAppeared')
                   }else{
                       window.webkit.messageHandlers.jsTesting.postMessage('noFirstSectionYet')
                       setTimeout(checkForFirstSectionIsPresent, 10 )
                   }
                }
                checkForFirstSectionIsPresent()
            """
                userContentController.addUserScript(WKUserScript.init(source: js, injectionTime: .atDocumentEnd, forMainFrameOnly: true))
            }
            
            UIApplication.shared.keyWindow?.rootViewController = webVC
            
            webVC?.setArticle(obamaArticle, articleURL: obamaURL!)
            
            initialNoFirstSectionYetMessageReceivedExpectation = expectation(description: "waiting for initial no first section message")
            firstSectionAppearedMessageReceivedExpectation = expectation(description: "waiting for first section to appear")
            
            
            wait(for: [initialNoFirstSectionYetMessageReceivedExpectation!], timeout: 100, enforceOrder: true)
            startMeasuring()
            wait(for: [firstSectionAppearedMessageReceivedExpectation!], timeout: 100, enforceOrder: true)
            stopMeasuring()
            
            
            safeToContinueExpectation.fulfill()
            
            wait(for: [safeToContinueExpectation], timeout: 100, enforceOrder: false)
            
            // reset everything for next measurement run
            UIApplication.shared.keyWindow?.rootViewController = nil
            firstSectionAppearedMessageReceivedExpectation = nil
            initialNoFirstSectionYetMessageReceivedExpectation = nil
            receivedInitialNoFirstSectionYetMessage = false
        })
    }
}

