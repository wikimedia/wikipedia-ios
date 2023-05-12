import XCTest
@testable import Wikipedia
@testable import WMF

fileprivate class MockTalkPageFetcher: OldTalkPageFetcher {
    
    static var name = "Username1"
    static var domain = "en.wikipedia.org"
    var fetchCalled = false
    private let data: Data
    
    required init(session: Session, configuration: Configuration, data: Data) {
        self.data = data
        super.init(session: session, configuration: configuration)
    }
    
    required init(session: Session, configuration: Configuration) {
        fatalError("init(session:configuration:) has not been implemented")
    }
    
    override func fetchTalkPage(urlTitle: String, displayTitle: String, siteURL: URL, revisionID: Int?, completion: @escaping (Result<NetworkTalkPage, Error>) -> Void) {
        
        fetchCalled = true
        
        if let networkTalkPage = TalkPageTestHelpers.networkTalkPage(for: "https://\(MockTalkPageFetcher.domain)/api/rest_v1/page/talk/\(urlTitle)", data: data, revisionId: MockArticleRevisionFetcher.revisionId) {
            completion(.success(networkTalkPage))
        } else {
            XCTFail("Expected network talk page from helper")
        }
        
    }
}

fileprivate class MockArticleRevisionFetcher: WMFArticleRevisionFetcher {
    
    static var revisionId: Int = 894272715
    
    var resultsDictionary: [AnyHashable : Any] {
        return ["batchcomplete": 1,
                "query" : ["pages": [
                    ["ns": 0,
                     "pageid": 2360669,
                     "revisions": [
                        ["minor": 1,
                         "parentid": 894272641,
                         "revid": MockArticleRevisionFetcher.revisionId,
                         "size": 61252]
                        ],
                     "title": "Benty Grange helmet"
                    ] as [String : Any]
                    ]
            ]
        ]
    }
    
    override func fetchLatestRevisions(forArticleURL articleURL: URL!, resultLimit numberOfResults: UInt, startingWithRevision startRevisionId: NSNumber, endingWithRevision endRevisionId: NSNumber, failure: WMFErrorHandler!, success: WMFSuccessIdHandler!) -> URLSessionTask? {
        do {
            let revisionQueryResults = try WMFLegacySerializer.models(of: WMFRevisionQueryResults.self, fromArrayForKeyPath: "query.pages", inJSONDictionary: resultsDictionary, languageVariantCode: articleURL.wmf_languageVariantCode)
            success(revisionQueryResults)
            return nil
        } catch {
            XCTFail("Failure to create WMFRevisionQueryResults")
        }
        
        return nil
    }
}

class TalkPageControllerTests: XCTestCase {

    var tempDataStore: MWKDataStore!
    var talkPageController: OldTalkPageController!
    fileprivate var talkPageFetcher: MockTalkPageFetcher!
    fileprivate var articleRevisionFetcher: MockArticleRevisionFetcher!

    override func setUp() {
        super.setUp()
        tempDataStore = MWKDataStore.temporary()
        
        if let data = wmf_bundle().wmf_data(fromContentsOfFile: TalkPageTestHelpers.TalkPageJSONType.original.fileName, ofType: "json") {
            talkPageFetcher = MockTalkPageFetcher(session: tempDataStore.session, configuration: tempDataStore.configuration, data: data)
        } else {
            XCTFail("Failure setting up MockTalkPageFetcher")
        }
        
        articleRevisionFetcher = MockArticleRevisionFetcher()
        talkPageController = OldTalkPageController(fetcher: talkPageFetcher, articleRevisionFetcher: articleRevisionFetcher, moc: tempDataStore.viewContext, title: "User talk:Username1", siteURL: URL(string: "https://en.wikipedia.org")!, type: .user)
        MockArticleRevisionFetcher.revisionId = 894272715
        
    }

    override func tearDown() {
        tempDataStore.removeFolderAtBasePath()
        
        let fetchRequest: NSFetchRequest<TalkPage> = TalkPage.fetchRequest()
        
        guard let firstResults = try? tempDataStore.viewContext.fetch(fetchRequest) else {
            XCTFail("Unable to fetch results from fetch request")
            return
        }
        
        for talkPage in firstResults {
            tempDataStore.viewContext.delete(talkPage)
        }
        
        do {
            try tempDataStore.save()
        } catch {
            XCTFail("Failure saving temporary data store")
        }
        
        
        tempDataStore = nil
        super.tearDown()
    }
    
    func testInitialFetchSavesRecordInDB() {
        
        // confirm no talk pages in DB at first
        let fetchRequest: NSFetchRequest<TalkPage> = TalkPage.fetchRequest()
        
        guard let firstResults = try? tempDataStore.viewContext.fetch(fetchRequest) else {
            XCTFail("Failure fetching initial talk pages")
            return
        }
        
        XCTAssertEqual(firstResults.count, 0, "Expected zero existing talk pages at first")
        
        let initialFetchCallback = expectation(description: "Waiting for initial fetch callback")
        talkPageController.fetchTalkPage { (result) in
            initialFetchCallback.fulfill()
            
            switch result {
            case .success(let dbTalkPageID):
                
                // fetch from db again, confirm count is 1 and matches returned talk page
                let fetchRequest: NSFetchRequest<TalkPage> = TalkPage.fetchRequest()
                
                guard let results = try? self.tempDataStore.viewContext.fetch(fetchRequest) else {
                    XCTFail("Failure fetching initial talk pages")
                    return
                }
                let dbTalkPage = try? self.tempDataStore.viewContext.existingObject(with: dbTalkPageID.objectID) as? TalkPage
                XCTAssertEqual(results.count, 1, "Expected one talk page in DB")
                XCTAssertEqual(results.first, dbTalkPage)
                XCTAssertEqual(dbTalkPage?.revisionId?.intValue, MockArticleRevisionFetcher.revisionId)
                
            case .failure:
                XCTFail("TalkPageController fetchTalkPage failure")
            }
        }
        
        wait(for: [initialFetchCallback], timeout: 5)
    }

/* //todo: this fails when run consecutively
    func testFetchSameUserTwiceDoesNotAddMultipleTalkPageRecords() {
        
        //confirm no talk pages in DB at first
        let fetchRequest: NSFetchRequest<TalkPage> = TalkPage.fetchRequest()
        
        guard let firstResults = try? tempDataStore.viewContext.fetch(fetchRequest) else {
            XCTFail("Failure fetching initial talk pages")
            return
        }
        
        XCTAssertEqual(firstResults.count, 0, "Expected zero existing talk pages at first")
        
        let initialFetchCallback = expectation(description: "Waiting for initial fetch callback")
        talkPageController.fetchTalkPage { (result) in
            initialFetchCallback.fulfill()
            
            switch result {
            case .success(let dbTalkPage):
                
                //confirm count is 1 and matches returned talk page
                let fetchRequest: NSFetchRequest<TalkPage> = TalkPage.fetchRequest()
                
                guard let results = try? self.tempDataStore.viewContext.fetch(fetchRequest) else {
                    XCTFail("Failure fetching initial talk pages")
                    return
                }
                
                XCTAssertEqual(results.count, 1, "Expected one talk page in DB")
                XCTAssertEqual(results.first, dbTalkPage)
                
            case .failure:
                XCTFail("TalkPageController fetchTalkPage failure")
            }
        }
        
        wait(for: [initialFetchCallback], timeout: 5)
        
        //same fetch again
        let nextFetchCallback = expectation(description: "Waiting for next fetch callback")
        talkPageController.fetchTalkPage { (result) in
            nextFetchCallback.fulfill()
            
            switch result {
            case .success(let dbTalkPage):
                
                //fetch from db again, confirm count is still 1 and matches returned talk page
                let fetchRequest: NSFetchRequest<TalkPage> = TalkPage.fetchRequest()
                
                guard let results = try? self.tempDataStore.viewContext.fetch(fetchRequest) else {
                    XCTFail("Failure fetching initial talk pages")
                    return
                }
                
                XCTAssertEqual(results.count, 1, "Expected one talk page in DB")
                XCTAssertEqual(results.first, dbTalkPage)
                
            case .failure:
                XCTFail("TalkPageController fetchTalkPage failure")
            }
        }
        
        wait(for: [nextFetchCallback], timeout: 5)
    }
 */
    
    func testFetchSameUserDifferentLanguageAddsMultipleTalkPageRecords() {
        let initialFetchCallback = expectation(description: "Waiting for initial fetch callback")
        talkPageController.fetchTalkPage { (result) in
            initialFetchCallback.fulfill()
            
            switch result {
            case .success(let dbTalkPageID):
                
                // fetch from db again, confirm count is 1 and matches returned talk page
                let fetchRequest: NSFetchRequest<TalkPage> = TalkPage.fetchRequest()
                
                guard let results = try? self.tempDataStore.viewContext.fetch(fetchRequest) else {
                    XCTFail("Failure fetching initial talk pages")
                    return
                }
                
                XCTAssertEqual(results.count, 1, "Expected one talk page in DB")
                XCTAssertEqual(results.first?.objectID, dbTalkPageID.objectID)
                
            case .failure:
                XCTFail("TalkPageController fetchTalkPage failure")
            }
        }
        
        wait(for: [initialFetchCallback], timeout: 5)
        
        // fetch again for ES language
        MockTalkPageFetcher.domain = "es.wikipedia.org"
        talkPageController = OldTalkPageController(fetcher: talkPageFetcher, articleRevisionFetcher: articleRevisionFetcher, moc: tempDataStore.viewContext, title: "User talk:Username1", siteURL: URL(string: "https://es.wikipedia.org")!, type: .user)
        
        let nextFetchCallback = expectation(description: "Waiting for next fetch callback")
        talkPageController.fetchTalkPage { (result) in
            nextFetchCallback.fulfill()
            
            switch result {
            case .success:
                
                let fetchRequest: NSFetchRequest<TalkPage> = TalkPage.fetchRequest()
                
                guard let results = try? self.tempDataStore.viewContext.fetch(fetchRequest) else {
                    XCTFail("Failure fetching initial talk pages")
                    return
                }
                
                XCTAssertEqual(results.count, 2, "Expected two talk pages in DB")
                
            case .failure:
                XCTFail("TalkPageController fetchTalkPage failure")
            }
        }
        
        wait(for: [nextFetchCallback], timeout: 5)
    }
    
    func testFetchDifferentUserSameLanguageAddsMultipleTalkPageRecords() {
        let initialFetchCallback = expectation(description: "Waiting for initial fetch callback")
        talkPageController.fetchTalkPage { (result) in
            initialFetchCallback.fulfill()
            
            switch result {
            case .success:
                
                // fetch from db again, confirm count is 1 and matches returned talk page
                let fetchRequest: NSFetchRequest<TalkPage> = TalkPage.fetchRequest()
                
                guard let results = try? self.tempDataStore.viewContext.fetch(fetchRequest) else {
                    XCTFail("Failure fetching initial talk pages")
                    return
                }
                
                XCTAssertEqual(results.count, 1, "Expected one talk page in DB")
                
            case .failure:
                XCTFail("TalkPageController fetchTalkPage failure")
            }
        }
        
        wait(for: [initialFetchCallback], timeout: 5)
        
        MockTalkPageFetcher.name = "Username2"
        talkPageController = OldTalkPageController(fetcher: talkPageFetcher, articleRevisionFetcher: articleRevisionFetcher, moc: tempDataStore.viewContext, title: "User talk:Username2", siteURL: URL(string: "https://en.wikipedia.org")!, type: .user)
        
        let nextFetchCallback = expectation(description: "Waiting for next fetch callback")
        talkPageController.fetchTalkPage { (result) in
            nextFetchCallback.fulfill()
            
            switch result {
            case .success:
                
                let fetchRequest: NSFetchRequest<TalkPage> = TalkPage.fetchRequest()
                
                guard let results = try? self.tempDataStore.viewContext.fetch(fetchRequest) else {
                    XCTFail("Failure fetching initial talk pages")
                    return
                }
                
                XCTAssertEqual(results.count, 2, "Expected two talk pages in DB")
                
            case .failure:
                XCTFail("TalkPageController fetchTalkPage failure")
            }
        }
        
        wait(for: [nextFetchCallback], timeout: 5)
    }
    
    func testFetchSameRevisionIdDoesNotCallFetcher() {
        // confirm no talk pages in DB at first
        let fetchRequest: NSFetchRequest<TalkPage> = TalkPage.fetchRequest()
        
        guard let firstResults = try? tempDataStore.viewContext.fetch(fetchRequest) else {
            XCTFail("Failure fetching initial talk pages")
            return
        }
        
        XCTAssertEqual(firstResults.count, 0, "Expected zero existing talk pages at first")
        
        // initial fetch to populate DB
        let initialFetchCallback = expectation(description: "Waiting for initial fetch callback")
        
        var firstDBTalkPage: TalkPage?
        talkPageController.fetchTalkPage { (result) in
            initialFetchCallback.fulfill()
            
            switch result {
            case .success(let dbTalkPageID):
                let dbTalkPage = try? self.tempDataStore.viewContext.existingObject(with: dbTalkPageID.objectID) as? TalkPage
                firstDBTalkPage = dbTalkPage
                XCTAssertEqual(dbTalkPage?.revisionId?.intValue, MockArticleRevisionFetcher.revisionId)
                XCTAssertTrue(self.talkPageFetcher.fetchCalled, "Expected fetcher to be called for initial fetch")
                
            case .failure:
                XCTFail("TalkPageController fetchTalkPage failure")
            }
        }
         wait(for: [initialFetchCallback], timeout: 5)
        
        // reset fetchCalled
        talkPageFetcher.fetchCalled = false
        
        // make same fetch again, same revision ID. Confirm fetcher was never called and same talk page is returned
        let secondFetchCallback = expectation(description: "Waiting for initial fetch callback")
        
        talkPageController.fetchTalkPage { (result) in
            
            switch result {
            case .success(let dbTalkPageID):
                guard !dbTalkPageID.isInitialLocalResult else {
                    return
                }
                let dbTalkPage = try? self.tempDataStore.viewContext.existingObject(with: dbTalkPageID.objectID) as? TalkPage
                XCTAssertEqual(firstDBTalkPage, dbTalkPage)
                XCTAssertEqual(dbTalkPage?.revisionId?.intValue, MockArticleRevisionFetcher.revisionId)
                XCTAssertFalse(self.talkPageFetcher.fetchCalled, "Expected fetcher to not be called for second fetch")
                
            case .failure:
                XCTFail("TalkPageController fetchTalkPage failure")
            }
            
            secondFetchCallback.fulfill()
        }
        wait(for: [secondFetchCallback], timeout: 5)
    }
    
/* //todo: this fails when run consecutively
    func testIncrementedRevisionDoesCallFetcher() {
        
        //confirm no talk pages in DB at first
        let fetchRequest: NSFetchRequest<TalkPage> = TalkPage.fetchRequest()
        
        guard let firstResults = try? tempDataStore.viewContext.fetch(fetchRequest) else {
            XCTFail("Failure fetching initial talk pages")
            return
        }
        
        XCTAssertEqual(firstResults.count, 0, "Expected zero existing talk pages at first")
        
        //initial fetch to populate DB
        let initialFetchCallback = expectation(description: "Waiting for initial fetch callback")
        
        var firstDBTalkPage: TalkPage?
        talkPageController.fetchTalkPage { (result) in
            initialFetchCallback.fulfill()
            
            switch result {
            case .success(let dbTalkPage):
                firstDBTalkPage = dbTalkPage
                XCTAssertEqual(dbTalkPage.revisionId, MockArticleRevisionFetcher.revisionId)
                XCTAssertTrue(self.talkPageFetcher.fetchCalled, "Expected fetcher to be called for initial fetch")
                
            case .failure:
                XCTFail("TalkPageController fetchTalkPage failure")
            }
        }
        wait(for: [initialFetchCallback], timeout: 5)
        
        //reset fetchCalled
        talkPageFetcher.fetchCalled = false
        
        MockArticleRevisionFetcher.revisionId += 1
        
        //make same fetch again, same revision ID. Confirm fetcher was never called and same talk page is returned
        let secondFetchCallback = expectation(description: "Waiting for initial fetch callback")
        
        talkPageController.fetchTalkPage { (result) in
            secondFetchCallback.fulfill()
            
            switch result {
            case .success(let dbTalkPage):
                
                XCTAssertEqual(firstDBTalkPage, dbTalkPage)
                XCTAssertEqual(dbTalkPage.revisionId, MockArticleRevisionFetcher.revisionId)
                XCTAssertTrue(self.talkPageFetcher.fetchCalled, "Expected fetcher to be called for second fetch")
                
            case .failure:
                XCTFail("TalkPageController fetchTalkPage failure")
            }
        }
        wait(for: [secondFetchCallback], timeout: 5)
    }
 */
}
