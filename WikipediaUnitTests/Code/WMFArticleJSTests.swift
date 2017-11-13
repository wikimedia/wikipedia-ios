
import WebKit
import XCTest

class WMFArticleJSTests: XCTestCase, WKScriptMessageHandler {
    
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

    let jsTestingMessageHandlerString = "jsTesting"
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
        
        switch message.name {
        case jsTestingMessageHandlerString:
            switch messageString {
            case startTimeMessageString:
                startTimeMessageReceivedExpectation?.fulfill()
            case firstSectionAppearedMessageString:
                firstSectionAppearedMessageReceivedExpectation?.fulfill()
            default:
                return
            }
        default:
            return
        }
    }
    
    func testFirstSectionAppearanceDelay() {

        measureMetrics(XCTestCase.defaultPerformanceMetrics, automaticallyStartMeasuring: false, for: {
            
            // Needed because 'measureMetrics' fires this block off ten times and the other expectations aren't scoped
            // to this block because they are fulfilled in a delegate callback.
            let safeToContinueExpectation = expectation(description: "waiting for previous measurement to finish")
            
            startTimeMessageReceivedExpectation = expectation(description: "waiting for start time message")
            firstSectionAppearedMessageReceivedExpectation = expectation(description: "waiting for first section appeared message")

            // Configure the WKUserContentController used by the web view controller - easy way to attach testing JS while
            // keeping all existing JS in place.
            webVC?.wkUserContentControllerTestingConfigurationBlock = { userContentController in
                // Add self as 'jsTesting' script message handler.
                userContentController.add(self, name: self.jsTestingMessageHandlerString)
                
                // This message will be sent as soon as the web view inflates the DOM of the index.html (before our
                // sections are injected).
                let startTimeJS = "window.webkit.messageHandlers.\(self.jsTestingMessageHandlerString).postMessage('\(self.startTimeMessageString)')"
                userContentController.addUserScript(
                    WKUserScript.init(source: startTimeJS, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
                )
                
                // This message will be sent as soon as the first section appears in the DOM (within ~10ms). This is
                // reasonable because our sections have all of their JS transformations applied before their respective
                // document fragments are attached to the DOM. The difference between start time and this time will tell
                // about how long it takes for the first section to be created, transformed and appear.
                let tenMillisecondPollingJS = """
                const checkFirstSectionPresence = () => {
                   if(document.querySelector('#section_heading_and_content_block_0')){
                       window.webkit.messageHandlers.\(self.jsTestingMessageHandlerString).postMessage('\(self.firstSectionAppearedMessageString)')
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
            
            wait(for: [startTimeMessageReceivedExpectation!], timeout: 100)
            startMeasuring()
            wait(for: [firstSectionAppearedMessageReceivedExpectation!], timeout: 100)
            stopMeasuring()
            
            // Sanity check only to ensure expections are fulfilled in expected order.
            wait(for:[startTimeMessageReceivedExpectation!, firstSectionAppearedMessageReceivedExpectation!], timeout: 100, enforceOrder: true)
            
            safeToContinueExpectation.fulfill()
            
            wait(for: [safeToContinueExpectation], timeout: 100)
            
            // Reset everything for next measurement run.
            UIApplication.shared.keyWindow?.rootViewController = nil
            firstSectionAppearedMessageReceivedExpectation = nil
            startTimeMessageReceivedExpectation = nil
        })
    }
}

