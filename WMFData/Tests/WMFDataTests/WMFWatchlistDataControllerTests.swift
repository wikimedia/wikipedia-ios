import XCTest
@testable import WMFData
@testable import WMFDataMocks

final class WMFWatchlistDataControllerTests: XCTestCase {
    
    private let enProject = WMFProject.wikipedia(WMFLanguage(languageCode: "en", languageVariantCode: nil))
    private let esProject = WMFProject.wikipedia(WMFLanguage(languageCode: "es", languageVariantCode: nil))
    
    override func setUp() async throws {
        WMFDataEnvironment.current.appData = WMFAppData(appLanguages:[
            WMFLanguage(languageCode: "en", languageVariantCode: nil),
            WMFLanguage(languageCode: "es", languageVariantCode: nil)
        ])
        WMFDataEnvironment.current.mediaWikiService = WMFMockWatchlistMediaWikiService()
        WMFDataEnvironment.current.userDefaultsStore = WMFMockKeyValueStore()
        WMFDataEnvironment.current.sharedCacheStore = WMFMockKeyValueStore()
    }
    
    func testAllWatchlistProjects() {
        let controller = WMFWatchlistDataController()
        let allProjects = controller.allWatchlistProjects()
        XCTAssertEqual([enProject, esProject, .commons, .wikidata], allProjects)
    }
    
    func testSavingAndLoadingFilterSettings() {
        let controller = WMFWatchlistDataController()
        let filterSettingsToSave = WMFWatchlistFilterSettings(offProjects: [.wikidata, .commons], latestRevisions: .latestRevision, activity: .seenChanges, automatedContributions: .bot, significance: .minorEdits, userRegistration: .registered, offTypes: [.categoryChanges, .loggedActions])
        controller.saveFilterSettings(filterSettingsToSave)
        let loadedFilterSettings = controller.loadFilterSettings()
        XCTAssertEqual(filterSettingsToSave, loadedFilterSettings)
    }
    
    func testOnOffWatchlistProjects() {
        let controller = WMFWatchlistDataController()
        let filterSettingsToSave = WMFWatchlistFilterSettings(offProjects: [.wikidata, .commons], latestRevisions: .notTheLatestRevision, activity: .all, automatedContributions: .all, significance: .all, userRegistration: .all, offTypes: [])
        controller.saveFilterSettings(filterSettingsToSave)
        XCTAssertEqual(controller.onWatchlistProjects(), [enProject, esProject])
        XCTAssertEqual(controller.offWatchlistProjects(), [.wikidata, .commons])
    }
    
    func testAllOffChangeTypes() {
        let controller = WMFWatchlistDataController()
        let filterSettingsToSave = WMFWatchlistFilterSettings(offProjects: [], latestRevisions: .notTheLatestRevision, activity: .all, automatedContributions: .all, significance: .all, userRegistration: .all, offTypes: [.categoryChanges, .pageCreations])
        controller.saveFilterSettings(filterSettingsToSave)
        XCTAssertEqual(controller.allChangeTypes(), [.pageEdits, .pageCreations, .categoryChanges, .wikidataEdits, .loggedActions])
        XCTAssertEqual(controller.offChangeTypes(), [.categoryChanges, .pageCreations])
    }
    
    func testActiveFilterCount1() {
        let controller = WMFWatchlistDataController()
        let filterSettingsToSave = WMFWatchlistFilterSettings(offProjects: [.commons, .wikidata], latestRevisions: .notTheLatestRevision, activity: .seenChanges, automatedContributions: .bot, significance: .minorEdits, userRegistration: .registered, offTypes: [])
        controller.saveFilterSettings(filterSettingsToSave)
        XCTAssertEqual(controller.activeFilterCount(), 6)
    }
    
    func testActiveFilterCount2() {
        let controller = WMFWatchlistDataController()
        let filterSettingsToSave = WMFWatchlistFilterSettings(offProjects: [], latestRevisions: .latestRevision, activity: .all, automatedContributions: .all, significance: .all, userRegistration: .all, offTypes: [.categoryChanges])
        controller.saveFilterSettings(filterSettingsToSave)
        XCTAssertEqual(controller.activeFilterCount(), 2)
    }
    
    func testActiveFilterCount3() {
        let controller = WMFWatchlistDataController()
        let filterSettingsToSave = WMFWatchlistFilterSettings(offProjects: [.commons, .wikidata, enProject], latestRevisions: .latestRevision, activity: .unseenChanges, automatedContributions: .human, significance: .nonMinorEdits, userRegistration: .unregistered, offTypes: [.categoryChanges, .loggedActions, .pageCreations, .pageEdits, .wikidataEdits])
        controller.saveFilterSettings(filterSettingsToSave)
        XCTAssertEqual(controller.activeFilterCount(), 13)
    }
    
    func testFetchWatchlistWithDefaultFilter() {
        let controller = WMFWatchlistDataController()
        
        let expectation = XCTestExpectation(description: "Fetch Watchlist")
        
        var watchlistToTest: WMFWatchlist?
        controller.fetchWatchlist { result in
            switch result {
            case .success(let watchlist):
                
                watchlistToTest = watchlist
                
            case .failure(let error):
                XCTFail("Failure fetching watchlist: \(error)")
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
        
        guard let watchlistToTest else {
            XCTFail("Missing watchlistToTest")
            return
        }
        
        XCTAssertEqual(watchlistToTest.items.count, 82, "Incorrect number of watchlist items returned")
        XCTAssertEqual(watchlistToTest.activeFilterCount, 0, "Incorrect activeFilterCount")
        
        let enItems = watchlistToTest.items.filter { $0.project == enProject }
        let esItems = watchlistToTest.items.filter { $0.project == esProject }
        let wikidataItems = watchlistToTest.items.filter { $0.project == .wikidata }
        let commonsItems = watchlistToTest.items.filter { $0.project == .commons }
        
        XCTAssertEqual(enItems.count, 38, "Incorrect number of EN watchlist items returned")
        XCTAssertEqual(esItems.count, 13, "Incorrect number of ES watchlist items returned")
        XCTAssertEqual(wikidataItems.count, 28, "Incorrect number of wikidata watchlist items returned")
        XCTAssertEqual(commonsItems.count, 3, "Incorrect number of commons watchlist items returned")
        
        let first = watchlistToTest.items.first!
        XCTAssertEqual(first.title, "Talk:Cat", "Unexpected watchlist item title property")
        XCTAssertEqual(first.username, "CatLover 1137", "Unexpected watchlist item username property")
        XCTAssertEqual(first.revisionID, 1157699533, "Unexpected watchlist item revisionID property")
        XCTAssertEqual(first.oldRevisionID, 1157699360, "Unexpected watchlist item oldRevisionID property")
        XCTAssertEqual(first.isAnon, false, "Unexpected watchlist item isAnon property")
        XCTAssertEqual(first.isBot, false, "Unexpected watchlist item isBot property")
        XCTAssertEqual(first.commentWikitext, "/* I disagree with the above comment */ Reply", "Unexpected watchlist item commentWikitext property")
        XCTAssertEqual(first.commentHtml, "<span dir=\"auto\"><span class=\"autocomment\"><a href=\"/wiki/Talk:Cat#I_disagree_with_the_above_comment\" title=\"Talk:Cat\">→‎I disagree with the above comment</a>: </span> Reply</span>", "Unexpected watchlist item commentHtml property")
        XCTAssertEqual(first.byteLength, 4246, "Unexpected watchlist item byteLength property")
        XCTAssertEqual(first.oldByteLength, 4071, "Unexpected watchlist item oldByteLength property")
        XCTAssertEqual(first.project, WMFProject.wikipedia(WMFLanguage(languageCode: "en", languageVariantCode: nil)))
        
        var dateComponents = DateComponents()
        dateComponents.year = 2023
        dateComponents.month = 5
        dateComponents.day = 30
        dateComponents.timeZone = TimeZone(abbreviation: "UTC")
        dateComponents.hour = 11
        dateComponents.minute = 37
        dateComponents.second = 31
        
        guard let testDate = Calendar.current.date(from: dateComponents) else {
            XCTFail("Failure creating testDate")
            return
        }
        
        XCTAssertEqual(first.timestamp, testDate, "Unexpected watchlist item timestamp property")
    }
    
    func testFetchWatchlistWithProjectFilter() {
        let controller = WMFWatchlistDataController()
        
        let filterSettingsToSave = WMFWatchlistFilterSettings(offProjects: [enProject, esProject], latestRevisions: .notTheLatestRevision, activity: .all, automatedContributions: .all, significance: .all, userRegistration: .all, offTypes: [])
        controller.saveFilterSettings(filterSettingsToSave)
        
        let expectation = XCTestExpectation(description: "Fetch Watchlist")
        
        var watchlistToTest: WMFWatchlist?
        controller.fetchWatchlist { result in
            switch result {
            case .success(let watchlist):
                
                watchlistToTest = watchlist
                
            case .failure(let error):
                XCTFail("Failure fetching watchlist: \(error)")
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
        
        guard let watchlistToTest else {
            XCTFail("Missing watchlistToTest")
            return
        }
        
        XCTAssertEqual(watchlistToTest.items.count, 31, "Incorrect number of watchlist items returned")
        XCTAssertEqual(watchlistToTest.activeFilterCount, 2, "Incorrect activeFilterCount")
        
        let enItems = watchlistToTest.items.filter { $0.project == enProject }
        let esItems = watchlistToTest.items.filter { $0.project == esProject }
        let wikidataItems = watchlistToTest.items.filter { $0.project == .wikidata }
        let commonsItems = watchlistToTest.items.filter { $0.project == .commons }
        
        XCTAssertEqual(enItems.count, 0, "Incorrect number of EN watchlist items returned")
        XCTAssertEqual(esItems.count, 0, "Incorrect number of ES watchlist items returned")
        XCTAssertEqual(wikidataItems.count, 28, "Incorrect number of wikidata watchlist items returned")
        XCTAssertEqual(commonsItems.count, 3, "Incorrect number of commons watchlist items returned")
    }
    
    func testFetchWatchlistWithAllProjectsPlusOneFilter() {
        let controller = WMFWatchlistDataController()
        
        let filterSettingsToSave = WMFWatchlistFilterSettings(offProjects: [enProject, esProject, .wikidata, .commons], latestRevisions: .latestRevision, activity: .all, automatedContributions: .all, significance: .all, userRegistration: .all, offTypes: [])
        controller.saveFilterSettings(filterSettingsToSave)
        
        let expectation = XCTestExpectation(description: "Fetch Watchlist")
        
        var watchlistToTest: WMFWatchlist?
        controller.fetchWatchlist { result in
            switch result {
            case .success(let watchlist):
                
                watchlistToTest = watchlist
                
            case .failure(let error):
                XCTFail("Failure fetching watchlist: \(error)")
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
        
        guard let watchlistToTest else {
            XCTFail("Missing watchlistToTest")
            return
        }
        
        XCTAssertEqual(watchlistToTest.activeFilterCount, 5, "Incorrect activeFilterCount")
    }
    
    func testFetchWatchlistWithBotsFilter() {
        let controller = WMFWatchlistDataController()
        
        let filterSettingsToSave = WMFWatchlistFilterSettings(offProjects: [], latestRevisions: .notTheLatestRevision, activity: .all, automatedContributions: .bot, significance: .all, userRegistration: .all, offTypes: [])
        controller.saveFilterSettings(filterSettingsToSave)
        
        let expectation = XCTestExpectation(description: "Fetch Watchlist")
        
        var watchlistToTest: WMFWatchlist?
        controller.fetchWatchlist { result in
            switch result {
            case .success(let watchlist):
                
                watchlistToTest = watchlist
                
            case .failure(let error):
                XCTFail("Failure fetching watchlist: \(error)")
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
        
        guard let watchlistToTest else {
            XCTFail("Missing watchlistToTest")
            return
        }
        
        XCTAssertEqual(watchlistToTest.items.count, 2, "Incorrect number of watchlist items returned")
        XCTAssertEqual(watchlistToTest.activeFilterCount, 1, "Incorrect activeFilterCount")
        
        let humanItems = watchlistToTest.items.filter { $0.isBot == false }
        XCTAssertEqual(humanItems.count, 0)
    }
    
    func testFetchWatchlistWithNoCacheAndNoInternetConnection() {
        WMFDataEnvironment.current.mediaWikiService = WMFMockServiceNoInternetConnection()
        let controller = WMFWatchlistDataController()
        
        let expectation = XCTestExpectation(description: "Fetch Watchlist")
        
        controller.fetchWatchlist { result in
            switch result {
            case .success:
                
                XCTFail("Unexpected success")
                
            case .failure:
                break
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testFetchWatchlistWithCacheAndNoInternetConnection() {
        
        // First fetch successfully to populate cache
        let controller = WMFWatchlistDataController()
        
        let expectation1 = XCTestExpectation(description: "Fetch Watchlist with Internet Connection")
        let expectation2 = XCTestExpectation(description: "Fetch Watchlist without Internet Connection")
        var connectedWatchlistReturned: WMFWatchlist? = nil
        var disconnectedAndCachedWatchlistReturned: WMFWatchlist? = nil
        
        controller.fetchWatchlist { result in
            switch result {
            case .success(let watchlist1):
                
                connectedWatchlistReturned = watchlist1
                
                // Drop Internet Connection
                WMFDataEnvironment.current.mediaWikiService = WMFMockServiceNoInternetConnection()
                controller.service = WMFDataEnvironment.current.mediaWikiService

                // Fetch again, confirm it still succeeds
                controller.fetchWatchlist { result in
                    switch result {
                    case .success(let watchlist2):
                        disconnectedAndCachedWatchlistReturned = watchlist2
                    case .failure:
                        XCTFail("Unexpected disconnected failure")
                    }
                    
                    expectation2.fulfill()
                }
            case .failure:
                XCTFail("Unexpected connected failure")
            }
            
            expectation1.fulfill()
        }
        
        wait(for: [expectation1], timeout: 10.0)
        wait(for: [expectation2], timeout: 10.0)
        
        XCTAssertEqual(connectedWatchlistReturned?.items.count, 82, "Incorrect number of watchlist items initially returned")
        XCTAssertEqual(disconnectedAndCachedWatchlistReturned?.items.count, 82, "Incorrect number of watchlist items initially returned")
    }
    
    func testPostWatchArticleExpiryNever() {
         let controller = WMFWatchlistDataController()

         let expectation = XCTestExpectation(description: "Post Watch Article Expiry Never")

         var resultToTest: Result<Void, Error>?
        controller.watch(title: "Cat", project: enProject, expiry: .never) { result in
             resultToTest = result
             expectation.fulfill()
         }

         wait(for: [expectation], timeout: 10.0)

         guard case .success = resultToTest else {
             return XCTFail("Unexpected result")
         }
     }

     func testPostWatchArticleExpiryDate() {
         let controller = WMFWatchlistDataController()

         let expectation = XCTestExpectation(description: "Post Watch Article Expiry Date")

         var resultToTest: Result<Void, Error>?
         controller.watch(title: "Cat", project: enProject, expiry: .oneMonth) { result in
             resultToTest = result
             expectation.fulfill()
         }

         wait(for: [expectation], timeout: 10.0)

         guard case .success = resultToTest else {
             return XCTFail("Unexpected result")
         }
     }

     func testPostUnwatchArticle() {
         let controller = WMFWatchlistDataController()

         let expectation = XCTestExpectation(description: "Post Watch Unwatch Article")

         var resultToTest: Result<Void, Error>?
         controller.unwatch(title: "Cat", project: enProject) { result in
             resultToTest = result
             expectation.fulfill()
         }

         wait(for: [expectation], timeout: 10.0)

         guard case .success = resultToTest else {
             return XCTFail("Unexpected result")
         }
     }
    
    func testFetchWatchStatus() {
         let controller = WMFWatchlistDataController()

         let expectation = XCTestExpectation(description: "Fetch Watch Status")
         var statusToTest: WMFPageWatchStatus?
        controller.fetchWatchStatus(title: "Cat", project: enProject) { result in
             switch result {
             case .success(let status):
                 statusToTest = status
             case .failure(let error):
                 XCTFail("Failure fetching watch status: \(error)")
             }
             expectation.fulfill()
         }

         guard let statusToTest else {
             XCTFail("Missing statusToTest")
             return
         }

         XCTAssertTrue(statusToTest.watched)
         XCTAssertNil(statusToTest.userHasRollbackRights)
     }

     func testFetchWatchStatusWithRollbackRights() {
         let controller = WMFWatchlistDataController()

         let expectation = XCTestExpectation(description: "Fetch Watch Status")
         var statusToTest: WMFPageWatchStatus?
         controller.fetchWatchStatus(title: "Cat", project: enProject, needsRollbackRights: true) { result in
             switch result {
             case .success(let status):
                 statusToTest = status
             case .failure(let error):
                 XCTFail("Failure fetching watch status: \(error)")
             }
             expectation.fulfill()
         }

         guard let statusToTest else {
             XCTFail("Missing statusToTest")
             return
         }

         XCTAssertFalse(statusToTest.watched)
         XCTAssertTrue((statusToTest.userHasRollbackRights ?? false))
     }
    
    func testPostRollbackArticle() {
        let controller = WMFWatchlistDataController()

        let expectation = XCTestExpectation(description: "Post Rollback Article")

        var resultToTest: Result<WMFUndoOrRollbackResult, Error>?
        controller.rollback(title: "Cat", project: enProject, username: "Amigao") { result in
            resultToTest = result
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10.0)

        guard let resultToTest else {
            return XCTFail("Unexpected result")
        }
        
        switch resultToTest {
        case .success(let result):
            XCTAssertEqual(result.newRevisionID, 573955)
            XCTAssertEqual(result.oldRevisionID, 573953)
        case .failure:
            return XCTFail("Unexpected result")
        }
    }
    
    func testPostUndoArticle() {
        let controller = WMFWatchlistDataController()
        
        let expectation = XCTestExpectation(description: "Post Undo Article")

        var resultToTest: Result<WMFUndoOrRollbackResult, Error>?
        controller.undo(title: "Cat", revisionID: 1155871225, summary: "Testing", username: "Amigao", project: enProject) { result in
            resultToTest = result
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10.0)
        
        guard let resultToTest else {
            return XCTFail("Unexpected result")
        }
        
        switch resultToTest {
        case .success(let result):
            XCTAssertEqual(result.newRevisionID, 573989)
            XCTAssertEqual(result.oldRevisionID, 573988)
        case .failure:
            return XCTFail("Unexpected result")
        }
    }
}
