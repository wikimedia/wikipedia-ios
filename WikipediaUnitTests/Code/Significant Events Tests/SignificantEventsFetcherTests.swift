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
    
    override func jsonDecodableTask<T>(with urlRequest: URLRequest, completionHandler: @escaping (T?, URLResponse?, Error?) -> Void) -> URLSessionDataTask? where T : Decodable {
        do {
            let result: SignificantEvents = try jsonDecodeData(data: data)
            completionHandler(result as? T, nil, nil)
        } catch let error {
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
    fileprivate var manyVariationsSession: MockSession!
    
    override func setUpWithError() throws {
        
        if let firstPageData = wmf_bundle().wmf_data(fromContentsOfFile: "SignificantEvents-FirstPage", ofType: "json"),
           let subsequentPageData = wmf_bundle().wmf_data(fromContentsOfFile: "SignificantEvents-SubsequentPage", ofType: "json"),
           let maxCacheData = wmf_bundle().wmf_data(fromContentsOfFile: "SignificantEvents-MaxCache", ofType: "json"),
           let beginningData = wmf_bundle().wmf_data(fromContentsOfFile: "SignificantEvents-Beginning", ofType: "json"),
           let templateData = wmf_bundle().wmf_data(fromContentsOfFile: "SignificantEvents-Templates", ofType: "json"),
           let manyVariationsData = wmf_bundle().wmf_data(fromContentsOfFile: "SignificantEvents-ViewModelVariations", ofType: "json") {
            firstPageSession = MockSession(configuration: Configuration.current, data: firstPageData)
            subsequentPageSession = MockSession(configuration: Configuration.current, data: subsequentPageData)
            maxCacheSession = MockSession(configuration: Configuration.current, data: maxCacheData)
            beginningSession = MockSession(configuration: Configuration.current, data: beginningData)
            templateSession = MockSession(configuration: Configuration.current, data: templateData)
            manyVariationsSession = MockSession(configuration: Configuration.current, data: manyVariationsData)
        } else {
            XCTFail("Failure setting up MockSession for SignificantEvents")
        }
    }
    
    func fetchManyVariationsResult(title: String, siteURL: URL, completion: @escaping (Result<SignificantEvents, Error>) -> Void) {
        let fetcher = SignificantEventsFetcher(session: manyVariationsSession, configuration: Configuration.current)
        fetcher.fetchSignificantEvents(title: title, siteURL: siteURL, completion: completion)
    }

    func testFetchFirstPageProducesSignificantEvents() throws {
        
        let fetchExpectation = expectation(description: "Waiting for fetch callback")
        
        let siteURL = URL(string: "https://en.wikipedia.org")!
        let title = "United_States"

        let fetcher = SignificantEventsFetcher(session: firstPageSession, configuration: Configuration.current)
        fetcher.fetchSignificantEvents(title: title, siteURL: siteURL) { (result) in

            switch result {
            case .success(let significantEvents):
                XCTAssertEqual(significantEvents.nextRvStartId, 973922738)
                XCTAssertEqual(significantEvents.sha, "5ecb5d13f31361ffd24427a143ec9d32cc83edb0fd99b3af85c98b6b3462a088")
                XCTAssertEqual(significantEvents.typedEvents.count, 20)
                XCTAssertNotNil(significantEvents.summary)
                
                let summary = significantEvents.summary
                
                XCTAssertEqual(summary.earliestTimestampString, "2020-08-13T20:44:28Z")
                XCTAssertEqual(summary.numChanges, 80)
                XCTAssertEqual(summary.numUsers, 44)
                
                let smallEvent = significantEvents.typedEvents[0]

                switch smallEvent {
                case .small(let smallChange):
                    XCTAssertEqual(smallChange.revId, 975463557)
                    XCTAssertEqual(smallChange.outputType, .small)
                    XCTAssertEqual(smallChange.timestampString, "2020-08-28T17:22:52Z")
                default:
                    XCTFail("Unexpected type for firstEvent.")
                }
                
                let largeEvent = significantEvents.typedEvents[3]

                switch largeEvent {
                case .large(let largeChange):
                    XCTAssertEqual(largeChange.outputType, .large)
                    XCTAssertEqual(largeChange.revId, 975240668)
                    XCTAssertEqual(largeChange.timestampString, "2020-08-27T15:11:26Z")
                    XCTAssertEqual(largeChange.user, "Mason.Jones")
                    XCTAssertEqual(largeChange.userId, 246091)
                    XCTAssertEqual(largeChange.userGroups?.count, 4)
                    XCTAssertEqual(largeChange.userEditCount, 2733)
                    XCTAssertEqual(largeChange.typedChanges.count, 2)
                    
                    let firstChange = largeChange.typedChanges[0]
                    
                    switch firstChange {
                    case .addedText(let addedText):
                        XCTAssertEqual(addedText.outputType, .addedText)
                        XCTAssertEqual(addedText.sections.count, 1)
                        XCTAssertNotNil(addedText.snippet)
                        XCTAssertEqual(addedText.snippetType, .addedAndDeletedInLine)
                        XCTAssertEqual(addedText.characterCount, 133)
                    default:
                        XCTFail("Unexpected change type for firstChange.")
                    }
                    
                    let secondChange = largeChange.typedChanges[1]
                    
                    switch secondChange {
                    case .deletedText(let deletedText):
                        XCTAssertEqual(deletedText.outputType, .deletedText)
                        XCTAssertEqual(deletedText.sections.count, 1)
                        XCTAssertEqual(deletedText.characterCount, 53)
                    default:
                        XCTFail("Unexpected change type for secondChange.")
                    }
                default:
                    XCTFail("Unexpected event type for secondEvent.")
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
                XCTAssertEqual(significantEvents.typedEvents.count, 21)
                XCTAssertNotNil(significantEvents.summary)
                
                let talkPageEvent = significantEvents.typedEvents[16]

                switch talkPageEvent {
                case .newTalkPageTopic(let newTalkPageTopic):
                    XCTAssertEqual(newTalkPageTopic.outputType, .newTalkPageTopic)
                    XCTAssertEqual(newTalkPageTopic.revId, 973092925)
                    XCTAssertEqual(newTalkPageTopic.timestampString, "2020-08-15T09:23:08Z")
                    XCTAssertNotNil(newTalkPageTopic.snippet)
                    XCTAssertEqual(newTalkPageTopic.user, "Mykhal")
                    XCTAssertEqual(newTalkPageTopic.userId, 88116)
                    XCTAssertEqual(newTalkPageTopic.section, "== Discontinuous region category ==")
                    XCTAssertEqual(newTalkPageTopic.userGroups?.count, 4)
                    XCTAssertEqual(newTalkPageTopic.userEditCount, 3690)
                default:
                    XCTFail("Unexpected event type for talkPageEvent.")
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
                XCTAssertEqual(significantEvents.typedEvents.count, 0)
                XCTAssertNotNil(significantEvents.summary)
                XCTAssertEqual(significantEvents.summary.earliestTimestampString, "2020-06-14T01:07:03Z")
                XCTAssertEqual(significantEvents.summary.numChanges, 282)
                XCTAssertEqual(significantEvents.summary.numUsers, 112)
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
                XCTAssertEqual(significantEvents.typedEvents.count, 13)
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
                XCTAssertEqual(significantEvents.nextRvStartId, 973922738)
                XCTAssertEqual(significantEvents.sha, "5ecb5d13f31361ffd24427a143ec9d32cc83edb0fd99b3af85c98b6b3462a088")
                XCTAssertEqual(significantEvents.typedEvents.count, 1)
                XCTAssertNotNil(significantEvents.summary)
                
                switch significantEvents.typedEvents[0] {
                case .large(let largeChange):
                    XCTAssertEqual(largeChange.revId, 670576931)
                    XCTAssertEqual(largeChange.timestampString, "2015-07-08T21:16:25Z")
                    XCTAssertEqual(largeChange.user, "CoffeeWithMarkets")
                    XCTAssertEqual(largeChange.userId, 17771490)
                    XCTAssertEqual(largeChange.typedChanges.count, 2)
                    
                    let firstChange = largeChange.typedChanges[0]
                    
                    switch firstChange {
                    case .newTemplate(let newTemplate):
                        
                        XCTAssertEqual(newTemplate.sections, ["==Maine Coon=="])
                        XCTAssertEqual(newTemplate.typedTemplates.count, 12)
                        
                        let webTemplate = newTemplate.typedTemplates[1]
                        
                        switch webTemplate {
                        case .websiteCitation(let webTemplate):
                            XCTAssertEqual(webTemplate.title, "No-Vacation Nation Revisited")
                            XCTAssertEqual(webTemplate.urlString, "http://www.cepr.net/documents/publications/no-vacation-update-2013-05.pdf")
                            XCTAssertEqual(webTemplate.publisher, "[[Center for Economic and Policy Research]]")
                            XCTAssertEqual(webTemplate.accessDateString, "September 8, 2013")
                            XCTAssertNil(webTemplate.archiveDateString)
                            XCTAssertNil(webTemplate.archiveDotOrgUrlString)
                        default:
                            XCTFail("Unexpected template type")
                        }
                        
                        let newsTemplate = newTemplate.typedTemplates[6]
                        
                        switch newsTemplate {
                        case .newsCitation(let newsTemplate):
                            XCTAssertEqual(newsTemplate.title, "Mexico crime belies government claims of progress")
                            XCTAssertEqual(newsTemplate.urlString, "https://www.usatoday.com/story/news/world/2014/10/18/mexico-violence-crime/17048757")
                            XCTAssertEqual(newsTemplate.firstName, "David")
                            XCTAssertEqual(newsTemplate.lastName, "Agren")
                            XCTAssertEqual(newsTemplate.accessDateString, "October 19, 2014")
                            XCTAssertEqual(newsTemplate.sourceDateString, "October 19, 2014")
                            XCTAssertEqual(newsTemplate.publication, "Florida Today—USA Today")
                        default:
                            XCTFail("Unexpected template type")
                        }
                        
                        let bookTemplate = newTemplate.typedTemplates[10]
                        
                        switch bookTemplate {
                        case .bookCitation(let bookTemplate):
                            XCTAssertEqual(bookTemplate.title, "A People's History of the United States")
                            XCTAssertEqual(bookTemplate.firstName, "Howard")
                            XCTAssertEqual(bookTemplate.lastName, "Zinn")
                            XCTAssertEqual(bookTemplate.isbn, "978-0-06-083865-2")
                            XCTAssertNil(bookTemplate.locationPublished)
                            XCTAssertNil(bookTemplate.pagesCited)
                            XCTAssertEqual(bookTemplate.publisher, "[[Harper Perennial]] Modern Classics")
                            XCTAssertEqual(bookTemplate.yearPublished, "2005")
                        default:
                            XCTFail("Unexpected template type")
                        }
                        
                        let journalTemplate = newTemplate.typedTemplates[11]
                        
                        switch journalTemplate {
                        case .journalCitation(let journalTemplate):
                            XCTAssertEqual(journalTemplate.journal, "N. Engl. J. Med.")
                            XCTAssertEqual(journalTemplate.title, "First Case of 2019 Novel Coronavirus in the United States")
                            XCTAssertEqual(journalTemplate.pages, "929–936")
                            XCTAssertNil(journalTemplate.lastName)
                            XCTAssertNil(journalTemplate.firstName)
                            XCTAssertEqual(journalTemplate.sourceDateString, "March 2020")
                            XCTAssertEqual(journalTemplate.volumeNumber, "382")
                            XCTAssertNil(journalTemplate.urlString)
                            XCTAssertNil(journalTemplate.database)
                        default:
                            XCTFail("Unexpected template type")
                        }
                        
                    default:
                        XCTFail("Unexpected first significant change type")
                    }
                    
                    let secondChange = largeChange.typedChanges[1]
                    
                    switch secondChange {
                    case .addedText(let addedText):
                        XCTAssertNotNil(addedText.snippet)
                        XCTAssertEqual(addedText.characterCount, 775)
                        XCTAssertEqual(addedText.sections, ["==Maine Coon=="])
                    default:
                        XCTFail("Unexpected second change type")
                    }
                default:
                    XCTFail("Unexpected event type")
                }

            case .failure:
                XCTFail("Expected Success")
            }
            
            fetchExpectation.fulfill()
        }
        
        wait(for: [fetchExpectation], timeout: 10)
    }
}
