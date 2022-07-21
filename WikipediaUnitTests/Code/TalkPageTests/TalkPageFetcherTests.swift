import XCTest

@testable import Wikipedia
@testable import WMF
import SwiftUI


final class TalkPageFetcherTests: XCTestCase {
    
    func testFetchTalkPage() {
        
        let fetcher = TalkPageFetcher()
        let siteURL = URL(string: "https://en.wikipedia.org")!
        let expectation = expectation(description: "Waiting for completion")
        
        fetcher.fetchTalkPageContent(talkPageTitle: "Talk:Archaeoindris", siteURL: siteURL) { result in
            expectation.fulfill()
            
            switch result {
            case let .success(talk):
                XCTAssertNotNil(talk)
            case .failure:
                XCTFail("Expected Success")
            }
        }
        wait(for: [expectation], timeout: 5)
    }
    
    func testPostReply() {
        
        let fetcher = MockTalkPageFetcher()
        let siteURL = URL(string: "https://en.wikipedia.org")!
        
        fetcher.postReply(talkPageTitle: "User_talk:Username", siteURL: siteURL, commentId: "commentid", comment: "comment") { _ in }
        XCTAssertTrue(fetcher.postReplyWasCalled)
    }
    
    func testPostTopic() {
        let fetcher = MockTalkPageFetcher()
        let siteURL = URL(string: "https://en.wikipedia.org")!
        
        fetcher.postTopic(talkPageTitle: "User_talk:Username", siteURL: siteURL, topicTitle: "Title", topicBody: "body") { _ in }
        XCTAssertTrue(fetcher.postTopicWasCalled)
    }
}

class MockTalkPageFetcher: TalkPageFetcher {
    
    var postReplyWasCalled = false
    var postTopicWasCalled = false
    
    override func postReply(talkPageTitle: String, siteURL: URL, commentId: String, comment: String, completion: @escaping(Result<[AnyHashable: Any], Error>) -> Void) {
        
        postReplyWasCalled = true
    }
    
    override func postTopic(talkPageTitle: String, siteURL: URL, topicTitle: String, topicBody: String, completion: @escaping(Result<[AnyHashable: Any], Error>) -> Void) {
        postTopicWasCalled = true
    }
    
}
