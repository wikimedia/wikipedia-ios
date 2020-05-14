
import XCTest
@testable import Wikipedia
@testable import WMF

fileprivate class MockSession: Session {
    
    private let data: Data
    
    required init(configuration: Configuration, data: Data) {
        self.data = data
        super.init(configuration: configuration)
    }
    
    required init(configuration: Configuration) {
        fatalError("init(configuration:) has not been implemented")
    }
    
    override public func jsonDecodableTask<T: Decodable>(with url: URL?, method: Session.Request.Method = .get, bodyParameters: Any? = nil, bodyEncoding: Session.Request.Encoding = .json, headers: [String: String] = [:], cachePolicy: URLRequest.CachePolicy? = nil, priority: Float = URLSessionTask.defaultPriority, completionHandler: @escaping (_ result: T?, _ response: URLResponse?,  _ error: Error?) -> Swift.Void) -> URLSessionDataTask? {
        
        do {
            let result: NetworkBase = try jsonDecodeData(data: data)
            completionHandler(result as? T, nil, nil)
        } catch (let error) {
            XCTFail("Talk Page json failed to decode \(error)")
        }
    
        return nil
    }
}

class TalkPageFetcherTests: XCTestCase {
    
    fileprivate var mockSession: MockSession!
    
    override func setUp() {
        super.setUp()
        
        if let data = wmf_bundle().wmf_data(fromContentsOfFile: TalkPageTestHelpers.TalkPageJSONType.original.fileName, ofType: "json") {
            mockSession = MockSession(configuration: Configuration.current, data: data)
        } else {
            XCTFail("Failure setting up MockTalkPageFetcher")
        }
    }
    
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
                XCTAssertEqual(talkPage.url.absoluteString, "https://en.wikipedia.org/api/rest_v1/page/talk/User_talk%3AUsername")
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
                XCTAssertEqual(talkPage.url.absoluteString, "https://en.wikipedia.org/api/rest_v1/page/talk/User_talk%3AUsername")
                XCTAssertEqual(talkPage.revisionId, 5)
            case .failure:
                XCTFail("Expected Success")
            }
        }
        wait(for: [fetchExpectation], timeout: 5)
    }
}


