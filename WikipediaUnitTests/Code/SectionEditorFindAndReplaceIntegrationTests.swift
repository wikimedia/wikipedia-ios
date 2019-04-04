//
//  SectionEditorFindAndReplaceIntegrationTests.swift
//  WikipediaUnitTests
//
//  Created by Toni Sevener on 4/2/19.
//  Copyright © 2019 Wikimedia Foundation. All rights reserved.
//

import XCTest
@testable import Wikipedia

private struct Location {
    let line: Int
    let ch: Int
}

class SectionEditorFindAndReplaceIntegrationTests: XCTestCase {
    
    private var sectionEditorViewController: SectionEditorViewController!
    private var focusedSectionEditorExpectation: XCTestExpectation!
    private var findAndReplaceView: FindAndReplaceKeyboardBar!
    private var mockMessagingController: MockSectionEditorWebViewMessagingController!
    private var currentSearchLocation: Location?
    private var nextSearchLocation: Location?
    private var replacedText: String?

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        super.setUp()
        LSNocilla.sharedInstance().start()
        setupNetworkStubs()
        loadSectionEditor()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
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
        
        stubRequest("GET", regex)
            .andReturn(200)?
            .withHeaders(["Content-Type": "application/json"])?
            .withBody(json as NSData)
    }
    
    private func loadSectionEditor() {
        
        guard let siteUrl = NSURL.wmf_URL(withDefaultSiteAndlanguage: "en") else {
            return
        }
        
        sectionEditorViewController = SectionEditorViewController()
        
        focusedSectionEditorExpectation = expectation(description: "waiting for section editor didFocusWebViewCompletion callback")
        
        let article = MWKArticle(url: siteUrl.appendingPathComponent("/wiki/Barack_Obama"), dataStore: MWKDataStore.temporary())
        let section = MWKSection(article: article, dict: ["id" : 1])
        sectionEditorViewController.section = section
        findAndReplaceView = FindAndReplaceKeyboardBar.wmf_viewFromClassNib()
        sectionEditorViewController.findAndReplaceView = findAndReplaceView
        mockMessagingController = MockSectionEditorWebViewMessagingController()
        sectionEditorViewController.messagingController = mockMessagingController
        sectionEditorViewController.delegate = self
        
        UIApplication.shared.keyWindow?.rootViewController = sectionEditorViewController
        let _ = sectionEditorViewController.view
        
        wait(for: [focusedSectionEditorExpectation], timeout: 5)
        
        
    }
    
    func testFindResultsUpdateToCurrentMatchLabel() {
        
        sectionEditorViewController.openFindAndReplaceForTesting()
        
        let findExpectation = expectation(description: "waiting for find results to come back")
        
        findAndReplaceView.setFindTextForTesting("test")
        mockMessagingController.receivedMessageBlock = { message in
            if message.name == SectionEditorWebViewMessagingController.Message.Name.codeMirrorSearchMessage {
                findExpectation.fulfill()
            }
            
        }
        
         wait(for: [findExpectation], timeout: 5)
        
        if let currentMatchText = findAndReplaceView.currentMatchLabelTextForTesting() {
            XCTAssertEqual(currentMatchText, "1 / 7")
        } else {
            XCTFail("Current match label should be set by now")
        }
    }
    
    func testNoFindResultsUpdateToCurrentMatchLabel() {
        
        sectionEditorViewController.openFindAndReplaceForTesting()
        
        let findExpectation = expectation(description: "waiting for find results to come back")
        
        findAndReplaceView.setFindTextForTesting("gibberish")
        mockMessagingController.receivedMessageBlock = { message in
            if message.name == SectionEditorWebViewMessagingController.Message.Name.codeMirrorSearchMessage {
                findExpectation.fulfill()
            }
            
        }
        
        wait(for: [findExpectation], timeout: 5)
        
        if let currentMatchText = findAndReplaceView.currentMatchLabelTextForTesting() {
            XCTAssertEqual(currentMatchText, "0 / 0")
        } else {
            XCTFail("Current match label should be set by now")
        }
    }
    
    func testFindResultsStartingFromLaterDisplaysCorrectMatchIndex() {
        
        let webView = sectionEditorViewController.webViewForTesting()
        
        let cursorExpectation = expectation(description: "set cursor expectation")
        
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
        
        wait(for: [cursorExpectation], timeout: 5)
        
        //kickoff find
        sectionEditorViewController.openFindAndReplaceForTesting()
        
        let findExpectation = expectation(description: "waiting for find results to come back")
        
        findAndReplaceView.setFindTextForTesting("test")
        mockMessagingController.receivedMessageBlock = { message in
            if message.name == SectionEditorWebViewMessagingController.Message.Name.codeMirrorSearchMessage {
                findExpectation.fulfill()
            }
        }
        
        wait(for: [findExpectation], timeout: 5)
        
        if let currentMatchText = findAndReplaceView.currentMatchLabelTextForTesting() {
            XCTAssertEqual(currentMatchText, "2 / 7")
        } else {
            XCTFail("Current match label should be set by now")
        }
    }
    
    func testFindNextIncrementsMatchLabel() {
        
        //kickoff find
        sectionEditorViewController.openFindAndReplaceForTesting()
        
        let findExpectation = expectation(description: "waiting for find results to come back")
        
        findAndReplaceView.setFindTextForTesting("test")
        mockMessagingController.receivedMessageBlock = { message in
            if message.name == SectionEditorWebViewMessagingController.Message.Name.codeMirrorSearchMessage {
                findExpectation.fulfill()
            }
        }
        
        wait(for: [findExpectation], timeout: 5)
        
        //confirm label is set to first match
        if let currentMatchText = findAndReplaceView.currentMatchLabelTextForTesting() {
            XCTAssertEqual(currentMatchText, "1 / 7")
        } else {
            XCTFail("Current match label should be set by now")
        }
        
        //tap next
        let nextExpectation = expectation(description: "waiting for tapped next message to come back")
        
        findAndReplaceView.tapNextForTesting()
        mockMessagingController.receivedMessageBlock = { message in
            if message.name == SectionEditorWebViewMessagingController.Message.Name.codeMirrorSearchMessage {
                nextExpectation.fulfill()
            }
        }
        
        wait(for: [nextExpectation], timeout: 5)
        
        //confirm current match label increments
        if let currentMatchText = findAndReplaceView.currentMatchLabelTextForTesting() {
            XCTAssertEqual(currentMatchText, "2 / 7")
        } else {
            XCTFail("Current match label should be set by now")
        }
    }
    
    func testFindNextIncreasesSearchStateCursor() {
        
        //kickoff find
        sectionEditorViewController.openFindAndReplaceForTesting()
        
        let findExpectation = expectation(description: "waiting for find results to come back")
        
        findAndReplaceView.setFindTextForTesting("test")
        mockMessagingController.receivedMessageBlock = { message in
            if message.name == SectionEditorWebViewMessagingController.Message.Name.codeMirrorSearchMessage {
                findExpectation.fulfill()
            }
        }
        
        wait(for: [findExpectation], timeout: 5)
        
        let webView = sectionEditorViewController.webViewForTesting()
        let userContentController = webView.configuration.userContentController
        
        //get current search cursor before tapping next
        let currentSearchStateExpectation = expectation(description: "get current search state")
        
        userContentController.add(self, name: "currentSearchLocation")
        
        webView.evaluateJavaScript("""
                var line = editor.state.search.posTo.line
                var ch = editor.state.search.posTo.ch
                window.webkit.messageHandlers.currentSearchLocation.postMessage({'line': line, 'ch': ch})
            """) { (result, error) in
                
                currentSearchStateExpectation.fulfill()
                
                guard let error = error else {
                    return
                }
                XCTFail("Javascript failure")
                print(error)
        }
        
        wait(for: [currentSearchStateExpectation], timeout: 5)
        
        //tap next
        let nextExpectation = expectation(description: "waiting for tapped next message to come back")
        
        findAndReplaceView.tapNextForTesting()
        mockMessagingController.receivedMessageBlock = { message in
            if message.name == SectionEditorWebViewMessagingController.Message.Name.codeMirrorSearchMessage {
                nextExpectation.fulfill()
            }
        }
        
        wait(for: [nextExpectation], timeout: 5)
        
        //get next search cursor
        let nextSearchStateExpectation = expectation(description: "get next search state")
        
        userContentController.add(self, name: "nextSearchLocation")
        
        webView.evaluateJavaScript("""
                var line = editor.state.search.posFrom.line
                var ch = editor.state.search.posFrom.ch
                window.webkit.messageHandlers.nextSearchLocation.postMessage({'line': line, 'ch': ch})
            """) { (result, error) in
                
                nextSearchStateExpectation.fulfill()
                
                guard let error = error else {
                    return
                }
                XCTFail("Javascript failure")
                print(error)
        }
        
        wait(for: [nextSearchStateExpectation], timeout: 5)
        
        //confirm the search cursor is on a later match by checking line
        guard let currentSearchLocation = currentSearchLocation,
            let nextSearchLocation = nextSearchLocation else {
                XCTFail("These should be populated by now via userContentController_ userContentController:, didReceive message:)")
                return
        }
        
        XCTAssertGreaterThan(nextSearchLocation.line, currentSearchLocation.line)
    }
    
    func testReplacingFirstInstanceChangesText() {
        sectionEditorViewController.openFindAndReplaceForTesting()
        
        let findExpectation = expectation(description: "waiting for find results to come back")
        
        findAndReplaceView.setFindTextForTesting("test")
        mockMessagingController.receivedMessageBlock = { message in
            if message.name == SectionEditorWebViewMessagingController.Message.Name.codeMirrorSearchMessage {
                findExpectation.fulfill()
            }
        }
        
        wait(for: [findExpectation], timeout: 5)
        
        let webView = sectionEditorViewController.webViewForTesting()
        let userContentController = webView.configuration.userContentController
        
        //get current search cursor before tapping next
        let currentSearchStateExpectation = expectation(description: "get current search state")
        
        userContentController.add(self, name: "currentSearchLocation")
        
        webView.evaluateJavaScript("""
                var line = editor.state.search.posFrom.line
                var ch = editor.state.search.posFrom.ch
                window.webkit.messageHandlers.currentSearchLocation.postMessage({'line': line, 'ch': ch})
            """) { (result, error) in
                
                currentSearchStateExpectation.fulfill()
                
                guard let error = error else {
                    return
                }
                XCTFail("Javascript failure")
                print(error)
        }
        
        wait(for: [currentSearchStateExpectation], timeout: 5)
        
        //add replace text
        let replaceText = "happy world land"
        findAndReplaceView.setReplaceTextForTesting(replaceText)
        
        //tap replace
        let replaceExpectation = expectation(description: "waiting for replace message to come back")
        
        findAndReplaceView.tapReplaceForTesting()
        mockMessagingController.receivedMessageBlock = { message in
            if message.name == SectionEditorWebViewMessagingController.Message.Name.codeMirrorSearchMessage {
                replaceExpectation.fulfill()
            }
        }
        
        wait(for: [replaceExpectation], timeout: 5)
        
        //calculate new replace range
        guard let currentSearchLocation = currentSearchLocation else {
            XCTFail("currentSearchLocation should be set by now")
            return
        }
        
        let newLocationFrom = Location(line: currentSearchLocation.line, ch: currentSearchLocation.ch)
        let newLocationTo = Location(line: currentSearchLocation.line, ch: currentSearchLocation.ch + replaceText.count)
        
        //pull replaced text using new range, confirm it's what we expect
        let replacedTextExpectation = expectation(description: "get replaced text")
        
        userContentController.add(self, name: "replacedText")
        
        webView.evaluateJavaScript("""
            var replaceText = editor.getRange({line: \(newLocationFrom.line), ch: \(newLocationFrom.ch)}, {line: \(newLocationTo.line), ch: \(newLocationTo.ch)})
                window.webkit.messageHandlers.replacedText.postMessage(replaceText)
            """) { (result, error) in
                
                replacedTextExpectation.fulfill()
                
                guard let error = error else {
                    return
                }
                XCTFail("Javascript failure")
                print(error)
        }
        
        wait(for: [replacedTextExpectation], timeout: 5)
        
        XCTAssertEqual(self.replacedText, replaceText)
        
        //confirm index has incremented and total decremented
        if let currentMatchText = findAndReplaceView.currentMatchLabelTextForTesting() {
            XCTAssertEqual(currentMatchText, "2 / 6")
        } else {
            XCTFail("Current match label should be set by now")
        }
    }
}

extension SectionEditorFindAndReplaceIntegrationTests: SectionEditorViewControllerDelegate {
    func sectionEditorDidFinishEditing(_ sectionEditor: SectionEditorViewController, withChanges didChange: Bool) {
        //no-op
    }
    
    func sectionEditorDidFinishLoadingWikitext(_ sectionEditor: SectionEditorViewController) {
        focusedSectionEditorExpectation.fulfill()
    }
}

private class MockSectionEditorWebViewMessagingController: SectionEditorWebViewMessagingController {
    
    var receivedMessageBlock: ((_ message: WKScriptMessage) -> Void)?
    
    override func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        super.userContentController(userContentController, didReceive: message)
        receivedMessageBlock?(message)
    }
}

extension SectionEditorFindAndReplaceIntegrationTests: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
        switch (message.name, message.body) {
        case ("replacedText", let replaceText as String):
            self.replacedText = replaceText
        case ("currentSearchLocation", let body as [String: Any]):
            if let line = body["line"] as? Int,
            let ch = body["ch"] as? Int {
                currentSearchLocation = Location(line: line, ch: ch)
            } else {
                XCTFail("Unexpected body for currentSearchLocation message")
            }
        case ("nextSearchLocation", let body as [String: Any]):
            if let line = body["line"] as? Int,
                let ch = body["ch"] as? Int {
                nextSearchLocation = Location(line: line, ch: ch)
            } else {
                XCTFail("Unexpected body for nextSearchLocation message")
            }
        default:
            XCTFail("Unexpected testing message body")
        }
    }
    
    
}
