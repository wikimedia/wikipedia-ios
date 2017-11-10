
import WebKit
import XCTest

class WMFArticleJSTests2: XCTestCase, WKScriptMessageHandler {
    
    var session: SessionSingleton?
    var webVC: WebViewController?
    var obamaURL: URL?
    var obamaArticle: MWKArticle?

    var firstSectionAppearedMessageReceivedExpectation: XCTestExpectation?
    var startTimeMessageReceivedExpectation: XCTestExpectation?

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
        
        startTimeMessageReceivedExpectation = nil
        firstSectionAppearedMessageReceivedExpectation = nil
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    let startTimeMessageString = "startTime"
    let firstSectionAppearedMessageString = "firstSectionAppeared"
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        // print("\n \n \n message body : \(message.body) \n \n \n ")
        guard
            let messageString = message.body as? String
        else {
            assertionFailure("Unhandled message type")
            return
        }
        switch messageString {
        case startTimeMessageString:
            startTimeMessageReceivedExpectation?.fulfill()
        case firstSectionAppearedMessageString:
            firstSectionAppearedMessageReceivedExpectation?.fulfill()
        default:
            return
        }
    }
    
    func testFirstSectionAppearanceDelay() {

        self.measureMetrics(XCTestCase.defaultPerformanceMetrics, automaticallyStartMeasuring: false, for: {
            
            let safeToContinueExpectation = self.expectation(description: "waiting for last measurement to finish")
            
            webVC?.wkUserContentControllerTestingConfigurationBlock = { userContentController in
                userContentController.add(self, name: "jsTesting")
                
                let startTimeJS = "window.webkit.messageHandlers.jsTesting.postMessage('\(self.startTimeMessageString)')"
                userContentController.addUserScript(
                    WKUserScript.init(source: startTimeJS, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
                )
                
                let tenMillisecondPollingJS = """
                const checkFirstSectionPresence = () => {
                   if(document.querySelector('#section_heading_and_content_block_0')){
                       window.webkit.messageHandlers.jsTesting.postMessage('\(self.firstSectionAppearedMessageString)')
                   }else{
                       setTimeout(checkFirstSectionPresence, 10 )
                   }
                }
                checkFirstSectionPresence()
                """
                userContentController.addUserScript(
                    WKUserScript.init(source: tenMillisecondPollingJS, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
                )
            }
            
            UIApplication.shared.keyWindow?.rootViewController = webVC
            
            webVC?.setArticle(obamaArticle, articleURL: obamaURL!)
            
            startTimeMessageReceivedExpectation = expectation(description: "waiting for initial no first section message")
            firstSectionAppearedMessageReceivedExpectation = expectation(description: "waiting for first section to appear")
            
            wait(for: [startTimeMessageReceivedExpectation!], timeout: 100)
            startMeasuring()
            wait(for: [firstSectionAppearedMessageReceivedExpectation!], timeout: 100)
            stopMeasuring()
            
            // sanity check only to ensure expections are fulfilled in expected order.
            wait(for:[startTimeMessageReceivedExpectation!, firstSectionAppearedMessageReceivedExpectation!], timeout: 100, enforceOrder: true)
            
            safeToContinueExpectation.fulfill()
            
            wait(for: [safeToContinueExpectation], timeout: 100)
            
            // reset everything for next measurement run
            UIApplication.shared.keyWindow?.rootViewController = nil
            firstSectionAppearedMessageReceivedExpectation = nil
            startTimeMessageReceivedExpectation = nil
        })
    }
}

