
import WebKit
import XCTest

class WMFArticleElementTests : XCTestCase, WKScriptMessageHandler {
    
    lazy var session: SessionSingleton = SessionSingleton.init(dataStore: MWKDataStore.temporary())
    lazy var dataStore = session.dataStore!
    lazy var obamaURL: URL = NSURL.wmf_URL(withDomain: "wikipedia.org", language: "en", title: "Barack Obama", fragment: nil)!
    lazy var obamaArticle = article(withMobileViewJSONFixture: "Obama", with: obamaURL, dataStore: dataStore)

    var lastSectionAppearedMessageReceivedExpectation: XCTestExpectation?
    
    lazy var webVCConfiguredToEmitLastSectionAppearanceEvent: WebViewController = {
        // WebViewController configured to emit an event when an article is loaded:
        //    - 'lastSectionAppeared'
        let vc = WebViewController.wmf_initialViewControllerFromClassStoryboard()!
    
        // Configure the WKUserContentController used by the web view controller - easy way to attach testing JS while
        // keeping all existing JS in place.
        vc.wkUserContentControllerTestingConfigurationBlock = { userContentController in
            // Add self as 'lastSectionAppeared' script message handler.
            // The 'userContentController:didReceiveMessage:' delegate method will receive these messages.
            userContentController.add(self, name: self.lastSectionAppearanceMessageHandlerString)

            userContentController.add(self, name: self.testValueMessageHandlerString)
            
            // This message will fire when the element with the 'soughtID' appears.
            // Idea from: https://davidwalsh.name/detect-node-insertion
            let soughtID = "section_heading_and_content_block_36"
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
                        window.webkit.messageHandlers.\(self.lastSectionAppearanceMessageHandlerString).postMessage('\(self.lastSectionAppearedMessageString)')
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
        loadObamaArticleWithLastSectionJSAppearanceExpectations()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    let lastSectionAppearanceMessageHandlerString = "lastSectionAppearanceHandler"
    let lastSectionAppearedMessageString = "lastSectionAppeared"
    let testValueMessageHandlerString = "testValueReceivedHandler"
    let testValueKeyString = "value"
    var testValueReceivedExpectation: XCTestExpectation?
    var testValue: Any? = nil
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        switch message.body {
        case let messageString as String where messageString == lastSectionAppearedMessageString && message.name == lastSectionAppearanceMessageHandlerString:
            lastSectionAppearedMessageReceivedExpectation?.fulfill()
        case let messageDict as Dictionary<String, Any>:
            testValue = messageDict[testValueKeyString]
            testValueReceivedExpectation?.fulfill()
        default:
            return
        }
    }

    func loadObamaArticleWithLastSectionJSAppearanceExpectations() {
        lastSectionAppearedMessageReceivedExpectation = expectation(description: "waiting for last section appeared message")
        
        webVCConfiguredToEmitLastSectionAppearanceEvent.setArticle(obamaArticle, articleURL: obamaArticle.url)

        wait(for:[lastSectionAppearedMessageReceivedExpectation!], timeout: 100, enforceOrder: true)

        testValueReceivedExpectation = expectation(description: "waiting for test message")
    }
    
    func evaluateJavaScript(js: String, then: (Any?) -> ()) {
        webVCConfiguredToEmitLastSectionAppearanceEvent.webView?.evaluateJavaScript("""
            window.webkit.messageHandlers.\(self.testValueMessageHandlerString).postMessage({"\(testValueKeyString)": (() => {\(js)})()})
        """) { (result, error) in
            guard let error = error else {
                return
            }
            print(error)
        }
        wait(for: [testValueReceivedExpectation!], timeout: 100)
        then(testValue)
    }
    
    func testLazyImageLoadImagePlaceholderUsesImageWideningWidth() {
        // Test for iOS image widening issue which fixed by this line:
        // https://github.com/wikimedia/wikimedia-page-library/pull/111/files#diff-74d0264e88f36c807d54002d3838b2beR95

        // Get placeholderSpanWidth then scroll placeholderSpan into view.
        var placeholderSpanWidth: Any? = nil
        webVCConfiguredToEmitLastSectionAppearanceEvent.webView?.evaluateJavaScript("""
            const getPlaceholderSpanWidth = () => {
                const placeholderSpan = document.querySelector("SPAN[data-src$='640px-Obama_family_portrait_in_the_Green_Room.jpg']")
                if (!placeholderSpan) return 0
                const placeholderSpanWidth = parseInt(window.getComputedStyle(placeholderSpan).width, 10)
                placeholderSpan.scrollIntoView()
                return placeholderSpanWidth
            }
            window.webkit.messageHandlers.\(self.testValueMessageHandlerString).postMessage({"\(testValueKeyString)": getPlaceholderSpanWidth()})
        """) { (result, error) in
            guard let error = error else {
                return
            }
            print(error)
        }
        wait(for: [testValueReceivedExpectation!], timeout: 100)
        placeholderSpanWidth = testValue
        
        // Wait a bit then get imgWidth.
        testValueReceivedExpectation = expectation(description: "waiting for test message")
        var imgWidth: Any? = nil
        webVCConfiguredToEmitLastSectionAppearanceEvent.webView?.evaluateJavaScript("""
            const getImageWidth = () => {
                const img = document.querySelector("IMG[src$='640px-Obama_family_portrait_in_the_Green_Room.jpg']")
                if (!img) return 0
                const imgWidth = parseInt(window.getComputedStyle(img).width, 10)
                return imgWidth
            }
            setTimeout(() => {
                window.webkit.messageHandlers.\(self.testValueMessageHandlerString).postMessage({"\(testValueKeyString)": getImageWidth()})
            }, 3000);
            
        """) { (result, error) in
            guard let error = error else {
                return
            }
            print(error)
        }
        wait(for: [testValueReceivedExpectation!], timeout: 100)
        imgWidth = testValue

        // Compare placeholderSpanWidth and imgWidth.
        guard
            let placeholderSpanWidthString = placeholderSpanWidth as? Int,
            let imgWidthString = imgWidth as? Int,
            placeholderSpanWidthString > 0,
            imgWidthString > 0
        else {
            XCTFail()
            return
        }
        XCTAssertTrue(placeholderSpanWidthString == imgWidthString)
    }
    
    func testExpectedEditPencilCount() {
        evaluateJavaScript(js: """
                return Array.from(document.querySelectorAll("SPAN.pagelib_edit_section_link_container")).filter(container => window.getComputedStyle(container).display !== 'none').length
            """, then: {value in
                if let pencilCount = value as? Int {
                    XCTAssertTrue(pencilCount == 9);
                }else{
                    XCTFail()
                }
        })
    }

    func testExpectedCollapsedTableCount() {
        evaluateJavaScript(js: """
                return document.querySelectorAll("div.pagelib_collapse_table_container").length
            """, then: {value in
                if let collapsedTableCount = value as? Int {
                    XCTAssertTrue(collapsedTableCount == 6);
                }else{
                    XCTFail()
                }
        })
    }

    func testFirstParagraphRelocation() {
        evaluateJavaScript(js: """
                const boldWithinParagraphAfterHatnoteDiv = document.querySelector("div#content_block_0 > div.hatnote ~ p > b")
                return boldWithinParagraphAfterHatnoteDiv ? false : true
            """, then: {value in
                if let paragraphWasMoved = value as? Bool {
                    XCTAssertTrue(paragraphWasMoved);
                }else{
                    XCTFail()
                }
        })
    }
}
