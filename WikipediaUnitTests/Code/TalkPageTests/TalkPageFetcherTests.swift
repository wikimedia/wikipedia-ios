import XCTest

@testable import Wikipedia
@testable import WMF


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
    
}
