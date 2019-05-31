
import XCTest
@testable import Wikipedia
@testable import WMF

fileprivate class MockSession: Session {
    override public func jsonDecodableTask<T: Decodable>(with url: URL?, method: Session.Request.Method = .get, bodyParameters: Any? = nil, bodyEncoding: Session.Request.Encoding = .json, headers: [String: String] = [:], priority: Float = URLSessionTask.defaultPriority, completionHandler: @escaping (_ result: T?, _ response: URLResponse?,  _ error: Error?) -> Swift.Void) {
        do {
            let result: NetworkBase = try jsonDecodeData(data: TalkPageTestHelpers.TalkPageJSONType.original.json)
            completionHandler(result as? T, nil, nil)
        } catch (let error) {
            XCTFail("Talk Page json failed to decode \(error)")
        }
    }
}

class TalkPageFetcherTests: XCTestCase {

    fileprivate let mockSession = MockSession(configuration: Configuration.current)
    
    func testTalkPageFetchReturnsTalkPage() {
        let fetcher = TalkPageFetcher(session: mockSession, configuration: Configuration.current)
        
        let fetchExpectation = expectation(description: "Waiting for fetch callback")
        
        let siteURL = URL(string: "https://en.wikipedia.org")!
        
        let prefixedTitle = TalkPageType.user.titleWithCanonicalNamespacePrefix(title: "Username", siteURL: siteURL)
        guard let title = TalkPageType.user.urlTitle(for: prefixedTitle) else {
            XCTFail("Failure generating title")
            return
        }
        
        fetcher.fetchTalkPage(urlTitle: title, displayTitle: "Username", siteURL: siteURL, revisionID: 5) { (result) in
            
            fetchExpectation.fulfill()

            switch result {
            case .success(let talkPage):
                XCTAssertEqual(talkPage.url.absoluteString, "https://talk-pages.wmflabs.org/en.wikipedia.org/v1/page/talk/User_talk:Username")
                XCTAssertEqual(talkPage.revisionId, 5)
            case .failure:
                XCTFail("Expected Success")
            }
        }
        wait(for: [fetchExpectation], timeout: 5)
    }
    
    func testTalkPageFetchWithPrefixTitleReturnsTalkPage() {
        let fetcher = TalkPageFetcher(session: mockSession, configuration: Configuration.current)
        
        let fetchExpectation = expectation(description: "Waiting for fetch callback")
        
        guard let title = TalkPageType.user.urlTitle(for: "User talk:Username") else {
            XCTFail("Failure generating title")
            return
        }
        
        fetcher.fetchTalkPage(urlTitle: title, displayTitle: "Username", siteURL: URL(string: "https://en.wikipedia.org")!, revisionID: 5) { (result) in
            
            fetchExpectation.fulfill()
            
            switch result {
            case .success(let talkPage):
                XCTAssertEqual(talkPage.url.absoluteString, "https://talk-pages.wmflabs.org/en.wikipedia.org/v1/page/talk/User_talk:Username")
                XCTAssertEqual(talkPage.revisionId, 5)
            case .failure:
                XCTFail("Expected Success")
            }
        }
        wait(for: [fetchExpectation], timeout: 5)
    }
}


