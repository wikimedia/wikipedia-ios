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
    
    func testAllWatchlistProjects() async throws {
        let controller = WMFWatchlistDataController()
        let allProjects = await controller.allWatchlistProjects()
        XCTAssertEqual([enProject, esProject, .commons, .wikidata], allProjects)
    }
    
    func testSavingAndLoadingFilterSettings() async throws {
        let controller = WMFWatchlistDataController()
        let filterSettingsToSave = WMFWatchlistFilterSettings(offProjects: [.wikidata, .commons], latestRevisions: .latestRevision, activity: .seenChanges, automatedContributions: .bot, significance: .minorEdits, userRegistration: .registered, offTypes: [.categoryChanges, .loggedActions])
        await controller.saveFilterSettings(filterSettingsToSave)
        let loadedFilterSettings = await controller.loadFilterSettings()
        XCTAssertEqual(filterSettingsToSave, loadedFilterSettings)
    }
    
    func testOnOffWatchlistProjects() async throws {
        let controller = WMFWatchlistDataController()
        let filterSettingsToSave = WMFWatchlistFilterSettings(offProjects: [.wikidata, .commons], latestRevisions: .notTheLatestRevision, activity: .all, automatedContributions: .all, significance: .all, userRegistration: .all, offTypes: [])
        await controller.saveFilterSettings(filterSettingsToSave)
        let onWatchlistProjects = await controller.onWatchlistProjects()
        let offWatchlistProjects = await controller.offWatchlistProjects()
        XCTAssertEqual(onWatchlistProjects, [enProject, esProject])
        XCTAssertEqual(offWatchlistProjects, [.wikidata, .commons])
    }
    
    func testAllOffChangeTypes() async throws {
        let controller = WMFWatchlistDataController()
        let filterSettingsToSave = WMFWatchlistFilterSettings(offProjects: [], latestRevisions: .notTheLatestRevision, activity: .all, automatedContributions: .all, significance: .all, userRegistration: .all, offTypes: [.categoryChanges, .pageCreations])
        await controller.saveFilterSettings(filterSettingsToSave)
        let allChangeTypes = await controller.allChangeTypes()
        let offChangeTypes = await controller.offChangeTypes()
        XCTAssertEqual(allChangeTypes, [.pageEdits, .pageCreations, .categoryChanges, .wikidataEdits, .loggedActions])
        XCTAssertEqual(offChangeTypes, [.categoryChanges, .pageCreations])
    }
    
    func testActiveFilterCount1() async throws {
        let controller = WMFWatchlistDataController()
        let filterSettingsToSave = WMFWatchlistFilterSettings(offProjects: [.commons, .wikidata], latestRevisions: .notTheLatestRevision, activity: .seenChanges, automatedContributions: .bot, significance: .minorEdits, userRegistration: .registered, offTypes: [])
        await controller.saveFilterSettings(filterSettingsToSave)
        let activeFilterCount = await controller.activeFilterCount()
        XCTAssertEqual(activeFilterCount, 6)
    }
    
    func testActiveFilterCount2() async throws {
        let controller = WMFWatchlistDataController()
        let filterSettingsToSave = WMFWatchlistFilterSettings(offProjects: [], latestRevisions: .latestRevision, activity: .all, automatedContributions: .all, significance: .all, userRegistration: .all, offTypes: [.categoryChanges])
        await controller.saveFilterSettings(filterSettingsToSave)
        let activeFilterCount = await controller.activeFilterCount()
        XCTAssertEqual(activeFilterCount, 2)
    }
    
    func testActiveFilterCount3() async throws {
        let controller = WMFWatchlistDataController()
        let filterSettingsToSave = WMFWatchlistFilterSettings(offProjects: [.commons, .wikidata, enProject], latestRevisions: .latestRevision, activity: .unseenChanges, automatedContributions: .human, significance: .nonMinorEdits, userRegistration: .unregistered, offTypes: [.categoryChanges, .loggedActions, .pageCreations, .pageEdits, .wikidataEdits])
        await controller.saveFilterSettings(filterSettingsToSave)
        let activeFilterCount = await controller.activeFilterCount()
        XCTAssertEqual(activeFilterCount, 13)
    }
    
    func testFetchWatchlistWithDefaultFilter() async throws {
        let controller = WMFWatchlistDataController()
        
        let watchlistToTest = try await controller.fetchWatchlist()
        
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
    
    func testFetchWatchlistWithProjectFilter() async throws {
        let controller = WMFWatchlistDataController()
        
        let filterSettingsToSave = WMFWatchlistFilterSettings(offProjects: [enProject, esProject], latestRevisions: .notTheLatestRevision, activity: .all, automatedContributions: .all, significance: .all, userRegistration: .all, offTypes: [])
        await controller.saveFilterSettings(filterSettingsToSave)
        
        let watchlistToTest = try await controller.fetchWatchlist()

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
    
    func testFetchWatchlistWithAllProjectsPlusOneFilter() async throws {
        let controller = WMFWatchlistDataController()
        
        let filterSettingsToSave = WMFWatchlistFilterSettings(offProjects: [enProject, esProject, .wikidata, .commons], latestRevisions: .latestRevision, activity: .all, automatedContributions: .all, significance: .all, userRegistration: .all, offTypes: [])
        await controller.saveFilterSettings(filterSettingsToSave)
        
        let watchlistToTest = try await controller.fetchWatchlist()
        
        XCTAssertEqual(watchlistToTest.activeFilterCount, 5, "Incorrect activeFilterCount")
    }
    
    func testFetchWatchlistWithBotsFilter() async throws {
        let controller = WMFWatchlistDataController()
        
        let filterSettingsToSave = WMFWatchlistFilterSettings(offProjects: [], latestRevisions: .notTheLatestRevision, activity: .all, automatedContributions: .bot, significance: .all, userRegistration: .all, offTypes: [])
        await controller.saveFilterSettings(filterSettingsToSave)
        
        let watchlistToTest = try await controller.fetchWatchlist()
        
        XCTAssertEqual(watchlistToTest.items.count, 2, "Incorrect number of watchlist items returned")
        XCTAssertEqual(watchlistToTest.activeFilterCount, 1, "Incorrect activeFilterCount")
        
        let humanItems = watchlistToTest.items.filter { $0.isBot == false }
        XCTAssertEqual(humanItems.count, 0)
    }
    
    func testFetchWatchlistWithNoCacheAndNoInternetConnection() async throws {
        WMFDataEnvironment.current.mediaWikiService = WMFMockServiceNoInternetConnection()
        let controller = WMFWatchlistDataController()
        
        do {
            _ = try await controller.fetchWatchlist()
            XCTFail("Unexpected success")
        } catch {
            
        }
    }
    
    func testFetchWatchlistWithCacheAndNoInternetConnection() async throws {
        
        // First fetch successfully to populate cache
        let controller = WMFWatchlistDataController()
        let connectedWatchlistReturned = try await controller.fetchWatchlist()
        
        // Drop Internet Connection
        let service = WMFMockServiceNoInternetConnection()
        WMFDataEnvironment.current.mediaWikiService = service
        await controller.setService(service)
        
        // Fetch again, confirm it still succeeds
        let disconnectedAndCachedWatchlistReturned = try await controller.fetchWatchlist()
        
        XCTAssertEqual(connectedWatchlistReturned.items.count, 82, "Incorrect number of watchlist items initially returned")
        XCTAssertEqual(disconnectedAndCachedWatchlistReturned.items.count, 82, "Incorrect number of watchlist items initially returned")
    }
    
    func testPostWatchArticleExpiryNever() async throws {
         let controller = WMFWatchlistDataController()

        try await controller.watch(title: "Cat", project: enProject, expiry: .never)
     }

     func testPostWatchArticleExpiryDate() async throws {
         let controller = WMFWatchlistDataController()

         try await controller.watch(title: "Cat", project: enProject, expiry: .oneMonth)
     }

     func testPostUnwatchArticle() async throws {
         let controller = WMFWatchlistDataController()
         
         try await controller.unwatch(title: "Cat", project: enProject)
     }
    
    func testPostRollbackArticle() async throws {
        let controller = WMFWatchlistDataController()
        
        let result = try await controller.rollback(title: "Cat", project: enProject, username: "Amigao")

        XCTAssertEqual(result.newRevisionID, 573955)
        XCTAssertEqual(result.oldRevisionID, 573953)
    }
    
    func testPostUndoArticle() async throws {
        let controller = WMFWatchlistDataController()
        
        let result = try await controller.undo(title: "Cat", revisionID: 1155871225, summary: "Testing", username: "Amigao", project: enProject)
        
        XCTAssertEqual(result.newRevisionID, 573989)
        XCTAssertEqual(result.oldRevisionID, 573988)
    }
}
