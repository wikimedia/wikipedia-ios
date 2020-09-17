//
// Integration tests for Find & Replace functionality in the section editor
//
// More things we could test:
// - Start with cursor near last match of section. Tap replace. Confirm total decrements and next index loops back around to 1. Confirm next highlighted match is the first match in the article
// - Add additional assertion that a highlighted match is the correct CSS class
// - Replace each match individually. Confirm replace buttons become disabled.
// - Replace with a word that contains the original match plus more (i.e. "test" with "testing"). Confirm total does not increment, index increments, and replacedText is set as expected
// - Find a word with different casings. Confirm total is the same for both
// - Replace a word with the same word but different casing. Confirm total does not increment, index increments, and replacedText is set as expected.
// - Test replace all. Confirm alert displays and index / total is reset to 0 / 0

import XCTest
@testable import Wikipedia

private struct Location {
    let line: Int
    let ch: Int
}

class SectionEditorFindAndReplaceTests: XCTestCase {
    let timeout: TimeInterval = 10
    
    private var sectionEditorViewController: SectionEditorViewController!
    private var focusedSectionEditorExpectation: XCTestExpectation!
    private var mockMessagingController: MockSectionEditorWebViewMessagingController!
    private var currentSearchLocation: Location?
    private var nextSearchLocation: Location?
    private var replacedText: String?
    
    private var findAndReplaceView: FindAndReplaceKeyboardBar! {
        return sectionEditorViewController.findAndReplaceViewForTesting
    }
    
    private let findText = "test"
    private let replaceText = "happy"
    private let messageHandlerKeyReplace = "messageHandlerKeyReplace"
    private let messageHandlerKeyCurrentSearchLocation = "messageHandlerKeyCurrentSearchLocation"
    private let messageHandlerKeyNextSearchLocation = "messageHandlerKeyNextSearchLocation"
    private let cursorLineKey = "line"
    private let cursorCharacterKey = "ch"

    override func setUp() {
        super.setUp()
        LSNocilla.sharedInstance().start()
        setupNetworkStubs()
        loadSectionEditor()
    }

    override func tearDown() {
        super.tearDown()
        LSNocilla.sharedInstance().stop()
    }

    private func setupNetworkStubs() {
        
        guard let siteUrl = NSURL.wmf_URL(withDefaultSiteAndlanguage: "en"),
            let url = NSURL.wmf_desktopAPIURL(for: siteUrl),
            let regex = try? NSRegularExpression(pattern: "\(url.absoluteString).*", options: []),
            let json = wmf_bundle().wmf_data(fromContentsOfFile: "BarackEarlyLife", ofType: "json")
        else {
            return
        }
        
        stubRequest("POST", url.absoluteString as NSString)
        
        let _ = stubRequest("GET", regex)
            .andReturn(200)?
            .withHeaders(["Content-Type": "application/json"])?
            .withBody(json as NSData)
    }
    
    private func loadSectionEditor() {
        
        guard let siteUrl = NSURL.wmf_URL(withDefaultSiteAndlanguage: "en") else {
            return
        }
        
        let articleURL = siteUrl.appendingPathComponent("/wiki/Barack_Obama")
        
        mockMessagingController = MockSectionEditorWebViewMessagingController()
        sectionEditorViewController = SectionEditorViewController(articleURL: articleURL, sectionID: 1, messagingController: mockMessagingController, dataStore: MWKDataStore.temporary())
        
        focusedSectionEditorExpectation = expectation(description: "Waiting for sectionEditorDidFinishLoadingWikitext callback")

        sectionEditorViewController.delegate = self
        
        UIApplication.shared.keyWindow?.rootViewController = sectionEditorViewController
        let _ = sectionEditorViewController.view
        
        wait(for: [focusedSectionEditorExpectation], timeout: timeout)
    }
    
    func testFindResultsUpdateToMatchLabel() {
        
        sectionEditorViewController.openFindAndReplaceForTesting()
        
        let findExpectation = expectation(description: "Waiting for find results callback")
        
        findAndReplaceView.setFindTextForTesting(findText)
        mockMessagingController.receivedMessageBlock = { message in
            if message.name == SectionEditorWebViewMessagingController.Message.Name.codeMirrorSearchMessage {
                findExpectation.fulfill()
            }
        }
        
         wait(for: [findExpectation], timeout: timeout)
        
        let matchPlacement = findAndReplaceView.matchPlacementForTesting
        XCTAssertEqual(matchPlacement.index, 1, "Unexpected match placement index")
        XCTAssertEqual(matchPlacement.total, 7, "Unexpected match placement total")
    }
    
    func testNoFindResultsUpdateToMatchLabel() {
        
        sectionEditorViewController.openFindAndReplaceForTesting()
        
        let findExpectation = expectation(description: "Waiting for find results callback")
        
        findAndReplaceView.setFindTextForTesting("gibberish")
        mockMessagingController.receivedMessageBlock = { message in
            if message.name == SectionEditorWebViewMessagingController.Message.Name.codeMirrorSearchMessage {
                findExpectation.fulfill()
            }
            
        }
        
        wait(for: [findExpectation], timeout: timeout)
        
        let matchPlacement = findAndReplaceView.matchPlacementForTesting
        XCTAssertEqual(matchPlacement.index,0, "Unexpected match placement index")
        XCTAssertEqual(matchPlacement.total, 0, "Unexpected match placement total")
    }
    
    func testFindResultsStartingFromMidArticleUpdateToMatchLabel() {
        
        let webView = sectionEditorViewController.webViewForTesting
        
        let cursorExpectation = expectation(description: "Waiting for set cursor callback")
        
        //set cursor to line 8. first match is on line 7 so index should start at 2
        webView.evaluateJavaScript("""
                editor.setCursor({line: 8, ch: 1})
            """) { (result, error) in
                
                cursorExpectation.fulfill()
                
                guard let error = error else {
                    return
                }
                XCTFail("Javascript failure")
                print(error)
        }
        
        wait(for: [cursorExpectation], timeout: timeout)
        
        //kickoff find
        sectionEditorViewController.openFindAndReplaceForTesting()
        
        let findExpectation = expectation(description: "waiting for find results callback")
        
        findAndReplaceView.setFindTextForTesting(findText)
        mockMessagingController.receivedMessageBlock = { message in
            if message.name == SectionEditorWebViewMessagingController.Message.Name.codeMirrorSearchMessage {
                findExpectation.fulfill()
            }
        }
        
        wait(for: [findExpectation], timeout: timeout)
        
        //confirm match index later in the article (i.e. not 1)
        let matchPlacement = findAndReplaceView.matchPlacementForTesting
        XCTAssertEqual(matchPlacement.index, 2, "Unexpected match placement index")
        XCTAssertEqual(matchPlacement.total, 7, "Unexpected match placement total")
    }
    
    func testFindNextIncrementsMatchLabel() {
        
        //kickoff find
        sectionEditorViewController.openFindAndReplaceForTesting()
        
        let findExpectation = expectation(description: "Waiting for find results callback")
        
        findAndReplaceView.setFindTextForTesting(findText)
        mockMessagingController.receivedMessageBlock = { message in
            if message.name == SectionEditorWebViewMessagingController.Message.Name.codeMirrorSearchMessage {
                findExpectation.fulfill()
            }
        }
        
        wait(for: [findExpectation], timeout: timeout)
        
        //confirm match placement is set to first match
        var matchPlacement = findAndReplaceView.matchPlacementForTesting
        XCTAssertEqual(matchPlacement.index, 1, "Unexpected match placement index")
        XCTAssertEqual(matchPlacement.total, 7, "Unexpected match placement total")
        
        //tap next
        let nextExpectation = expectation(description: "Waiting for tapped next message callback")
        
        findAndReplaceView.tapNextForTesting()
        mockMessagingController.receivedMessageBlock = { message in
            if message.name == SectionEditorWebViewMessagingController.Message.Name.codeMirrorSearchMessage {
                nextExpectation.fulfill()
            }
        }
        
        wait(for: [nextExpectation], timeout: timeout)
        
        //confirm match placement increments
        matchPlacement = findAndReplaceView.matchPlacementForTesting
        XCTAssertEqual(matchPlacement.index, 2, "Unexpected match placement index")
        XCTAssertEqual(matchPlacement.total, 7, "Unexpected match placement total")
    }
    
    func testFindNextIncreasesSearchStateCursor() {
        
        //kickoff find
        sectionEditorViewController.openFindAndReplaceForTesting()
        
        let findExpectation = expectation(description: "Waiting for find results callback")
        
        findAndReplaceView.setFindTextForTesting(findText)
        mockMessagingController.receivedMessageBlock = { message in
            if message.name == SectionEditorWebViewMessagingController.Message.Name.codeMirrorSearchMessage {
                findExpectation.fulfill()
            }
        }
        
        wait(for: [findExpectation], timeout: timeout)
        
        let webView = sectionEditorViewController.webViewForTesting
        let userContentController = webView.configuration.userContentController
        
        //get current search cursor before tapping next
        let currentSearchLocationExpectation = expectation(description: "Waiting for current search location callback")
        
        userContentController.add(self, name: messageHandlerKeyCurrentSearchLocation)
        
        webView.evaluateJavaScript("""
                var line = editor.state.search.posTo.line
                var ch = editor.state.search.posTo.ch
                window.webkit.messageHandlers.\(messageHandlerKeyCurrentSearchLocation).postMessage({'\(cursorLineKey)': line, '\(cursorCharacterKey)': ch})
                true
            """) { (result, error) in
                
                currentSearchLocationExpectation.fulfill()
                
                guard let error = error else {
                    return
                }
                XCTFail("Javascript failure")
                print(error)
        }
        
        wait(for: [currentSearchLocationExpectation], timeout: timeout)
        
        //tap next
        let nextExpectation = expectation(description: "Waiting for tapped next message callback")
        
        findAndReplaceView.tapNextForTesting()
        mockMessagingController.receivedMessageBlock = { message in
            if message.name == SectionEditorWebViewMessagingController.Message.Name.codeMirrorSearchMessage {
                nextExpectation.fulfill()
            }
        }
        
        wait(for: [nextExpectation], timeout: timeout)
        
        //get next search cursor
        let nextSearchLocationExpectation = expectation(description: "Waiting for next search location callback")
        
        userContentController.add(self, name: messageHandlerKeyNextSearchLocation)
        
        webView.evaluateJavaScript("""
                var line = editor.state.search.posFrom.line
                var ch = editor.state.search.posFrom.ch
                window.webkit.messageHandlers.\(messageHandlerKeyNextSearchLocation).postMessage({'\(cursorLineKey)': line, '\(cursorCharacterKey)': ch})
                true
            """) { (result, error) in
                
                nextSearchLocationExpectation.fulfill()
                
                guard let error = error else {
                    return
                }
                XCTFail("Javascript failure")
                print(error)
        }
        
        wait(for: [nextSearchLocationExpectation], timeout: timeout)
        
        //confirm the search cursor is on a later match by checking line
        guard let currentSearchLocation = currentSearchLocation,
            let nextSearchLocation = nextSearchLocation else {
                XCTFail("Missing current & next search locations")
                return
        }
        
        //note this is specific to search term "test", we know the next match is on a later line.
        XCTAssertGreaterThan(nextSearchLocation.line, currentSearchLocation.line, "Expected find next to increase search cursor")
    }
    
    func testReplacingFirstInstanceChangesText() {
        sectionEditorViewController.openFindAndReplaceForTesting()
        
        let findExpectation = expectation(description: "Waiting for find results callback")
        
        findAndReplaceView.setFindTextForTesting(findText)
        mockMessagingController.receivedMessageBlock = { message in
            if message.name == SectionEditorWebViewMessagingController.Message.Name.codeMirrorSearchMessage {
                findExpectation.fulfill()
            }
        }
        
        wait(for: [findExpectation], timeout: timeout)
        
        let webView = sectionEditorViewController.webViewForTesting
        let userContentController = webView.configuration.userContentController
        
        //get current search cursor before tapping next
        let currentSearchLocationExpectation = expectation(description: "Waiting for current search location callback")
        
        userContentController.add(self, name: messageHandlerKeyCurrentSearchLocation)
        
        webView.evaluateJavaScript("""
                var line = editor.state.search.posFrom.line
                var ch = editor.state.search.posFrom.ch
                window.webkit.messageHandlers.\(messageHandlerKeyCurrentSearchLocation).postMessage({'\(cursorLineKey)': line, '\(cursorCharacterKey)': ch})
                true
            """) { (result, error) in
                
                currentSearchLocationExpectation.fulfill()
                
                guard let error = error else {
                    return
                }
                XCTFail("Javascript failure")
                print(error)
        }
        
        wait(for: [currentSearchLocationExpectation], timeout: timeout)
        
        //add replace text
        findAndReplaceView.setReplaceTextForTesting(replaceText)
        
        //tap replace
        let replaceExpectation = expectation(description: "Waiting for replace message callback")
        
        findAndReplaceView.tapReplaceForTesting()
        mockMessagingController.receivedMessageBlock = { message in
            if message.name == SectionEditorWebViewMessagingController.Message.Name.codeMirrorSearchMessage {
                replaceExpectation.fulfill()
            }
        }
        
        wait(for: [replaceExpectation], timeout: timeout)
        
        //calculate new replace range
        guard let currentSearchLocation = currentSearchLocation else {
            XCTFail("Missing currentSearchLocation")
            return
        }
        
        let newLocationFrom = Location(line: currentSearchLocation.line, ch: currentSearchLocation.ch)
        let newLocationTo = Location(line: currentSearchLocation.line, ch: currentSearchLocation.ch + replaceText.count)
        
        //pull replaced text using new range, confirm it's what we expect
        let replacedTextExpectation = expectation(description: "Waiting for get replaced text callback")
        
        userContentController.add(self, name: messageHandlerKeyReplace)
        
        webView.evaluateJavaScript("""
                var replaceText = editor.getRange({line: \(newLocationFrom.line), ch: \(newLocationFrom.ch)}, {line: \(newLocationTo.line), ch: \(newLocationTo.ch)})
                window.webkit.messageHandlers.\(messageHandlerKeyReplace).postMessage(replaceText)
                true
            """) { (result, error) in
                
                replacedTextExpectation.fulfill()
                
                guard let error = error else {
                    return
                }
                XCTFail("Javascript failure")
                print(error)
        }
        
        wait(for: [replacedTextExpectation], timeout: timeout)
        
        XCTAssertEqual(self.replacedText, replaceText, "Expected replaced text from web land to equal replace text from find & replace view")
        
        //confirm total decremented
        let matchPlacement = findAndReplaceView.matchPlacementForTesting
        XCTAssertEqual(matchPlacement.index, 1, "Unexpected match placement index")
        XCTAssertEqual(matchPlacement.total, 6, "Unexpected match placement total")
    }
}

extension SectionEditorFindAndReplaceTests: SectionEditorViewControllerDelegate {
    func sectionEditorDidCancelEditing(_ sectionEditor: SectionEditorViewController) {
        //no-op
    }
    
    func sectionEditorDidFinishEditing(_ sectionEditor: SectionEditorViewController, result: Result<SectionEditorChanges, Error>) {
        //no-op
    }
    
    func sectionEditorDidFinishLoadingWikitext(_ sectionEditor: SectionEditorViewController) {
        focusedSectionEditorExpectation.fulfill()
    }
}

extension SectionEditorFindAndReplaceTests: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
        switch (message.name, message.body) {
        case (messageHandlerKeyReplace, let replaceText as String):
            self.replacedText = replaceText
        case (messageHandlerKeyCurrentSearchLocation, let body as [String: Any]):
            if let line = body[cursorLineKey] as? Int,
            let ch = body[cursorCharacterKey] as? Int {
                currentSearchLocation = Location(line: line, ch: ch)
            } else {
                XCTFail("Unexpected body for messageHandlerKeyCurrentSearchLocation message")
            }
        case (messageHandlerKeyNextSearchLocation, let body as [String: Any]):
            if let line = body[cursorLineKey] as? Int,
                let ch = body[cursorCharacterKey] as? Int {
                nextSearchLocation = Location(line: line, ch: ch)
            } else {
                XCTFail("Unexpected body for messageHandlerKeyCurrentNextLocation message")
            }
        default:
            XCTFail("Unexpected testing message")
        }
    }
}

private class MockSectionEditorWebViewMessagingController: SectionEditorWebViewMessagingController {
    
    var receivedMessageBlock: ((_ message: WKScriptMessage) -> Void)?
    
    override func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        super.userContentController(userContentController, didReceive: message)
        receivedMessageBlock?(message)
    }
}
