
import XCTest
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
            let result: SignificantEvents = try jsonDecodeData(data: data)
            completionHandler(result as? T, nil, nil)
        } catch (let error) {
            XCTFail("Significant Events json failed to decode \(error)")
        }
    
        return nil
    }
}

class SignificantEventsFetcherTests: XCTestCase {
    
    fileprivate var firstPageSession: MockSession!
    fileprivate var subsequentPageSession: MockSession!
    fileprivate var maxCacheSession: MockSession!
    fileprivate var beginningSession: MockSession!
    fileprivate var templateSession: MockSession!
    
    override func setUpWithError() throws {
        
        if let firstPageData = wmf_bundle().wmf_data(fromContentsOfFile: "SignificantEvents-FirstPage", ofType: "json"),
           let subsequentPageData = wmf_bundle().wmf_data(fromContentsOfFile: "SignificantEvents-SubsequentPage", ofType: "json"),
           let maxCacheData = wmf_bundle().wmf_data(fromContentsOfFile: "SignificantEvents-MaxCache", ofType: "json"),
           let beginningData = wmf_bundle().wmf_data(fromContentsOfFile: "SignificantEvents-Beginning", ofType: "json"),
           let templateData = wmf_bundle().wmf_data(fromContentsOfFile: "SignificantEvents-Templates", ofType: "json") {
            firstPageSession = MockSession(configuration: Configuration.current, data: firstPageData)
            subsequentPageSession = MockSession(configuration: Configuration.current, data: subsequentPageData)
            maxCacheSession = MockSession(configuration: Configuration.current, data: maxCacheData)
            beginningSession = MockSession(configuration: Configuration.current, data: beginningData)
            templateSession = MockSession(configuration: Configuration.current, data: templateData)
        } else {
            XCTFail("Failure setting up MockSession for SignificantEvents")
        }
    }

    func testFetchFirstPageProducesSignificantEvents() throws {
        let fetcher = SignificantEventsFetcher(session: firstPageSession, configuration: Configuration.current)
        
        let fetchExpectation = expectation(description: "Waiting for fetch callback")
        
        let siteURL = URL(string: "https://en.wikipedia.org")!
        
        let title = "United_States"
        
        fetcher.fetchSignificantEvents(title: title, siteURL: siteURL) { (result) in
            
            switch result {
            case .success(let significantEvents):
                XCTAssertEqual(significantEvents.nextRvStartId, 973922738)
                XCTAssertEqual(significantEvents.sha, "5ecb5d13f31361ffd24427a143ec9d32cc83edb0fd99b3af85c98b6b3462a088")
                XCTAssertEqual(significantEvents.typedTimeline.count, 9)
                XCTAssertNotNil(significantEvents.summary)
                
                let summary = significantEvents.summary
                
                XCTAssertEqual(summary.earliestTimestampString, "2020-08-20T02:51:13Z")
                XCTAssertEqual(summary.numChanges, 20)
                XCTAssertEqual(summary.numUsers, 15)
                
                let firstItem = significantEvents.typedTimeline[0]

                switch firstItem {
                case .smallChange(let item):
                    XCTAssertEqual(item.count, 3)
                    XCTAssertEqual(item.outputType, .smallChange)
                default:
                    XCTFail("Unexpected timeline type for firstItem.")
                }
                
                let secondItem = significantEvents.typedTimeline[1]

                switch secondItem {
                case .largeChange(let item):
                    XCTAssertEqual(item.outputType, .largeChange)
                    XCTAssertEqual(item.revId, 975240668)
                    XCTAssertEqual(item.timestampString, "2020-08-27T15:11:26Z")
                    XCTAssertEqual(item.user, "Mason.Jones")
                    XCTAssertEqual(item.userId, 246091)
                    XCTAssertEqual(item.userGroups.count, 4)
                    XCTAssertEqual(item.userEditCount, 2675)
                    XCTAssertEqual(item.typedSignificantChanges.count, 2)
                    
                    let firstChange = item.typedSignificantChanges[0]
                    
                    switch firstChange {
                    case .addedText(let addedTextItem):
                        XCTAssertEqual(addedTextItem.outputType, .addedText)
                        XCTAssertEqual(addedTextItem.sections.count, 1)
                        XCTAssertNotNil(addedTextItem.snippet)
                        XCTAssertEqual(addedTextItem.snippetType, .addedAndDeletedInLine)
                        XCTAssertEqual(addedTextItem.characterCount, 133)
                    default:
                        XCTFail("Unexpected significant change type for firstItem.")
                    }
                    
                    let secondChange = item.typedSignificantChanges[1]
                    
                    switch secondChange {
                    case .deletedText(let deletedTextItem):
                        XCTAssertEqual(deletedTextItem.outputType, .deletedText)
                        XCTAssertEqual(deletedTextItem.sections.count, 1)
                        XCTAssertEqual(deletedTextItem.characterCount, 53)
                    default:
                        XCTFail("Unexpected significant change type for secondItem.")
                    }
                default:
                    XCTFail("Unexpected timeline type for secondItem.")
                }
            case .failure:
                XCTFail("Expected Success")
            }
            
            fetchExpectation.fulfill()
        }
        
        wait(for: [fetchExpectation], timeout: 10)
    }
    
    func testFetchSubsequentPageProducesSignificantEvents() throws {
        
        let fetcher = SignificantEventsFetcher(session: subsequentPageSession, configuration: Configuration.current)
        let fetchExpectation = expectation(description: "Waiting for fetch callback")
        let siteURL = URL(string: "https://en.wikipedia.org")!
        let title = "United_States"
        
        fetcher.fetchSignificantEvents(title: title, siteURL: siteURL) { (result) in
            
            switch result {
            case .success(let significantEvents):
                XCTAssertEqual(significantEvents.nextRvStartId, 972790429)
                XCTAssertNil(significantEvents.sha)
                XCTAssertEqual(significantEvents.typedTimeline.count, 7)
                XCTAssertNotNil(significantEvents.summary)
                
                let talkPageItem = significantEvents.typedTimeline[5]

                switch talkPageItem {
                case .newTalkPageTopic(let item):
                    XCTAssertEqual(item.outputType, .newTalkPageTopic)
                    XCTAssertEqual(item.revId, 973092925)
                    XCTAssertEqual(item.timestampString, "2020-08-15T09:23:08Z")
                    XCTAssertNotNil(item.snippet)
                    XCTAssertEqual(item.user, "Mykhal")
                    XCTAssertEqual(item.userId, 88116)
                    XCTAssertEqual(item.section, "== Discontinuous region category ==")
                    XCTAssertEqual(item.userGroups.count, 4)
                    XCTAssertEqual(item.userEditCount, 3640)
                default:
                    XCTFail("Unexpected timeline type for talkPageItem.")
                }
            case .failure:
                XCTFail("Expected Success")
            }
            
            fetchExpectation.fulfill()
        }
        
        wait(for: [fetchExpectation], timeout: 10)
    }
    
    func testFetchMaxCacheProducesSignificantEvents() throws {
        
        let fetcher = SignificantEventsFetcher(session: maxCacheSession, configuration: Configuration.current)
        let fetchExpectation = expectation(description: "Waiting for fetch callback")
        let siteURL = URL(string: "https://en.wikipedia.org")!
        let title = "United_States"
        
        fetcher.fetchSignificantEvents(title: title, siteURL: siteURL) { (result) in
            
            switch result {
            case .success(let significantEvents):
                XCTAssertNil(significantEvents.nextRvStartId)
                XCTAssertNil(significantEvents.sha)
                XCTAssertEqual(significantEvents.typedTimeline.count, 0)
                XCTAssertNotNil(significantEvents.summary)

            case .failure:
                XCTFail("Expected Success")
            }
            
            fetchExpectation.fulfill()
        }
        
        wait(for: [fetchExpectation], timeout: 10)
    }
    
    func testFetchBeginningProducesSignificantEvents() throws {
        
        let fetcher = SignificantEventsFetcher(session: beginningSession, configuration: Configuration.current)
        let fetchExpectation = expectation(description: "Waiting for fetch callback")
        let siteURL = URL(string: "https://en.wikipedia.org")!
        let title = "United_States"
        
        fetcher.fetchSignificantEvents(title: title, siteURL: siteURL) { (result) in
            
            switch result {
            case .success(let significantEvents):
                XCTAssertEqual(significantEvents.nextRvStartId, 0)
                XCTAssertNil(significantEvents.sha)
                XCTAssertEqual(significantEvents.typedTimeline.count, 11)
                XCTAssertNotNil(significantEvents.summary)

            case .failure:
                XCTFail("Expected Success")
            }
            
            fetchExpectation.fulfill()
        }
        
        wait(for: [fetchExpectation], timeout: 10)
    }
    
    func testFetchTemplatesProducesSignificantEvents() throws {
        
        let fetcher = SignificantEventsFetcher(session: templateSession, configuration: Configuration.current)
        let fetchExpectation = expectation(description: "Waiting for fetch callback")
        let siteURL = URL(string: "https://en.wikipedia.org")!
        let title = "United_States"
        
        fetcher.fetchSignificantEvents(title: title, siteURL: siteURL) { (result) in
            
            switch result {
            case .success(let significantEvents):
                XCTAssertEqual(significantEvents.nextRvStartId, 0)
                XCTAssertNil(significantEvents.sha)
                XCTAssertEqual(significantEvents.typedTimeline.count, 11)
                XCTAssertNotNil(significantEvents.summary)

            case .failure:
                XCTFail("Expected Success")
            }
            
            fetchExpectation.fulfill()
        }
        
        wait(for: [fetchExpectation], timeout: 10)
    }
}
