
import WebKit
import XCTest

class WMFArticleSectionLoadingJSPerformanceTests: XCTestCase, WKScriptMessageHandler {
    
    lazy var session: SessionSingleton = SessionSingleton.init(dataStore: MWKDataStore.temporary())
    lazy var dataStore = session.dataStore!
    lazy var obamaURL: URL = NSURL.wmf_URL(withDomain: "wikipedia.org", language: "en", title: "Barack Obama", fragment: nil)!
    lazy var obamaArticle = article(withMobileViewJSONFixture: "Obama", with: obamaURL, dataStore: dataStore)

    var firstSectionAppearedMessageReceivedExpectation: XCTestExpectation?
    var startTimeMessageReceivedExpectation: XCTestExpectation?

    lazy var webVCConfiguredToEmitFirstSectionAppearanceTimingEvents: WebViewController = {
        // WebViewController configured to emit two events when an article is loaded:
        //    - 'startTime'
        //    - 'testFirstSectionAppearance'
        let vc = WebViewController.wmf_initialViewControllerFromClassStoryboard()!
    
        // Configure the WKUserContentController used by the web view controller - easy way to attach testing JS while
        // keeping all existing JS in place.
        vc.wkUserContentControllerTestingConfigurationBlock = { userContentController in
            // Add self as 'testFirstSectionAppearance' script message handler.
            // The 'userContentController:didReceiveMessage:' delegate method will receive these messages.
            userContentController.add(self, name: self.testFirstSectionAppearanceMessageHandlerString)
            
            // This message will be sent as soon as the web view inflates the DOM of the index.html (before our
            // sections are injected).
            let startTimeJS = "window.webkit.messageHandlers.\(self.testFirstSectionAppearanceMessageHandlerString).postMessage('\(self.testFirstSectionAppearanceStartTimeMessageString)')"
            userContentController.addUserScript(
                WKUserScript.init(source: startTimeJS, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
            )
            
            // This message will fire when the element with the 'soughtID' appears.
            // Idea from: https://davidwalsh.name/detect-node-insertion
            let soughtID = "section_heading_and_content_block_0"
            let animationName = "soughtNodeInsertionAnimation"
            let sectionAppearanceJS = """
            const style = document.createElement('style')
            style.type = 'text/css'
            style.innerHTML = `
                @keyframes \(animationName) {
                    from { opacity: .99; }
                    to { opacity: 1; }
                }
                #\(soughtID) {
                    animation-duration: 0.001s;
                    animation-name: \(animationName);
                }
            `
            document.querySelector('head').appendChild(style)
            document.addEventListener('animationstart', (event) => {
                if (event.animationName === '\(animationName)') {
                    if(event.target.id === '\(soughtID)'){
                        window.webkit.messageHandlers.\(self.testFirstSectionAppearanceMessageHandlerString).postMessage('\(self.testFirstSectionAppearedMessageString)')
                    }
                }
            }, false)
            """
            userContentController.addUserScript(
                WKUserScript.init(source: sectionAppearanceJS, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
            )
        }

        UIApplication.shared.keyWindow?.rootViewController = vc

        return vc
    }()

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // Load the article once before kicking off the 'measureMetrics' tests. Ensures any caching has been warmed.
        loadObamaArticleWithFirstSectionJSPerformanceExpectations()
        wait(for:[startTimeMessageReceivedExpectation!, firstSectionAppearedMessageReceivedExpectation!], timeout: 100, enforceOrder: true)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    let testFirstSectionAppearanceMessageHandlerString = "testFirstSectionAppearance"
    let testFirstSectionAppearanceStartTimeMessageString = "startTime"
    let testFirstSectionAppearedMessageString = "firstSectionAppeared"
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        // print("\n \n \n message body : \(message.body) \n \n \n ")
        guard
            let messageString = message.body as? String
        else {
            assertionFailure("Unhandled message type")
            return
        }
        
        switch message.name {
        case testFirstSectionAppearanceMessageHandlerString:
            switch messageString {
            case testFirstSectionAppearanceStartTimeMessageString:
                startTimeMessageReceivedExpectation?.fulfill()
            case testFirstSectionAppearedMessageString:
                firstSectionAppearedMessageReceivedExpectation?.fulfill()
            default:
                return
            }
        default:
            return
        }
    }

    func loadObamaArticleWithFirstSectionJSPerformanceExpectations() {
        startTimeMessageReceivedExpectation = expectation(description: "waiting for start time message")
        firstSectionAppearedMessageReceivedExpectation = expectation(description: "waiting for first section appeared message")
        webVCConfiguredToEmitFirstSectionAppearanceTimingEvents.setArticle(obamaArticle, articleURL: obamaArticle.url)
    }

    func measureFirstSectionAppearancePerformance() {
        loadObamaArticleWithFirstSectionJSPerformanceExpectations()
        wait(for: [startTimeMessageReceivedExpectation!], timeout: 100)
        startMeasuring()
        wait(for: [firstSectionAppearedMessageReceivedExpectation!], timeout: 100)
        stopMeasuring()
        // Needed because 'measureMetrics' fires its block off ten times and the other expectations aren't scoped to its block because they are fulfilled in a delegate callback.
        wait(for:[startTimeMessageReceivedExpectation!, firstSectionAppearedMessageReceivedExpectation!], timeout: 100, enforceOrder: true)
    }
    
    // Tests the performance of the javascript which fetches, transforms and appends article sections via headless JS DocumentFragments.
    func testFirstSectionAppearancePerformance() {
        measureMetrics(XCTestCase.defaultPerformanceMetrics, automaticallyStartMeasuring: false, for: {
            measureFirstSectionAppearancePerformance()
        })
    }

    func testFirstSectionAppearancePerformanceWithDarkTheme() {
        webVCConfiguredToEmitFirstSectionAppearanceTimingEvents.apply(Theme.dark)
        measureMetrics(XCTestCase.defaultPerformanceMetrics, automaticallyStartMeasuring: false, for: {
            measureFirstSectionAppearancePerformance()
        })
    }
    func testFirstSectionAppearancePerformanceWithSepiaTheme() {
        webVCConfiguredToEmitFirstSectionAppearanceTimingEvents.apply(Theme.sepia)
        measureMetrics(XCTestCase.defaultPerformanceMetrics, automaticallyStartMeasuring: false, for: {
            measureFirstSectionAppearancePerformance()
        })
    }
}

