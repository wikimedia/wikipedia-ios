import XCTest
import CoreData
@testable import WMF

class ReadingListsTests: XCTestCase {
    
    var dataStore: MWKDataStore!
    
    override func setUp(completion: @escaping (Error?) -> Void) {
        MWKDataStore.createTemporaryDataStore(completion: { dataStore in
            self.dataStore = dataStore
            completion(nil)
        })
    }
    
    override func tearDown() {
        super.tearDown()
        dataStore.removeFolderAtBasePath()
    }
    
    func testListsWithTheSameName() {
        let originalName = "pebbles"
        let casedName = "pEbBLes"
        let diacriticName = "pEbBLés"
        do {
            let list = try dataStore.readingListsController.createReadingList(named: originalName, description: "Foo")
            XCTAssert(list.name == originalName)
        } catch let error {
            XCTAssert(false, "Should be able to create \(originalName) reading list: \(error)")
        }
        do {
            _ = try dataStore.readingListsController.createReadingList(named: casedName, description: "Foo")
            XCTAssert(true, "Should be able to create list with same title and different case")
        } catch let error {
            XCTAssert(false, "Should not throw an error: \(error) when creating a list with the same title and different case")
        }
        
        do {
            let list = try dataStore.readingListsController.createReadingList(named: diacriticName, description: "Foo")
            XCTAssert(list.name == diacriticName)
        } catch let error {
            XCTAssert(false, "Should be able to create \(diacriticName) reading list: \(error)")
        }
    }
    
    func testDeletingExistingReadingLists() {
        let readingListNames = ["foo", "bar"]
        var readingLists: [ReadingList] = []

        do {
            readingLists.append(try dataStore.readingListsController.createReadingList(named: readingListNames[0], description: "Foo"))
        } catch let error {
            XCTAssert(false, "Should be able to create \(readingListNames[0]) reading list: \(error)")
        }
        
        do {
            readingLists.append(try dataStore.readingListsController.createReadingList(named: readingListNames[1], description: "Foo"))
        } catch let error {
            XCTAssert(false, "Should be able to create \(readingListNames[1]) reading list: \(error)")
        }
        
        do {
            try dataStore.readingListsController.delete(readingLists: readingLists)
        } catch let error {
            XCTAssert(false, "Should be able to delete \(readingListNames) reading lists: \(error)")
        }
    }
    
    func testDeletingNonexistentReadingLists() {
        let readingListNames = ["foo", "bar"]
        var readingLists: [ReadingList] = []
        
        do {
            readingLists.append(try dataStore.readingListsController.createReadingList(named: readingListNames[0], description: "Foo"))
        } catch let error {
            XCTAssert(false, "Should be able to create \(readingListNames[0]) reading list: \(error)")
        }
        
        do {
            try dataStore.readingListsController.delete(readingLists: readingLists)
        } catch let error {
            XCTAssert(false, "Should attempt to delete \(readingListNames) reading lists: \(error)")
        }
    }
    
    func testCreatingReadingListWithArticles() {
        let readingListName = "foo"
        let articleURLs = [URL(string: "//en.wikipedia.org/wiki/Foo")!, URL(string: "//en.wikipedia.org/wiki/Bar")!]
        let articles = articleURLs.compactMap { (articleURL) -> WMFArticle? in
            return dataStore.fetchOrCreateArticle(with: articleURL)
        }
        
        let articleKeys = articles.compactMap { (article) -> String? in
            return article.key
        }
        
        do {
            let readingList = try dataStore.readingListsController.createReadingList(named: readingListName, description: "Foo", with: articles)
            XCTAssert(readingList.articleKeys.wmf_containsObjectsInAnyOrderAndMatchesCount(articleKeys))

        } catch let error {
            XCTAssert(false, "Should be able to add articles to \(readingListName) reading list: \(error)")
        }
        
    }
    
    func testAddingArticlesToExistingReadingList() {
        let readingListName = "foo"
        let articleURLs = [URL(string: "//en.wikipedia.org/wiki/Foo")!, URL(string: "//en.wikipedia.org/wiki/Bar")!]
        let otherArticleURLs = [URL(string: "//en.wikipedia.org/wiki/Foo")!, URL(string: "//en.wikipedia.org/wiki/Bar")!, URL(string: "//en.wikipedia.org/wiki/Baz")!]
        
        let articles = articleURLs.compactMap { (articleURL) -> WMFArticle? in
            return dataStore.fetchOrCreateArticle(with: articleURL)
        }
        
        let otherArticles = otherArticleURLs.compactMap { (articleURL) -> WMFArticle? in
            return dataStore.fetchOrCreateArticle(with: articleURL)
        }
        
        let otherArticleKeys = otherArticles.compactMap { (article) -> String? in
            return article.key
        }
        
        do {
            let readingList = try dataStore.readingListsController.createReadingList(named: readingListName, description: "Foo", with: articles)
            
            do {
                try dataStore.readingListsController.add(articles: otherArticles, to: readingList)
                XCTAssert(readingList.articleKeys.wmf_containsObjectsInAnyOrderAndMatchesCount(otherArticleKeys))
            } catch let error {
                XCTAssert(false, "Should be able to : \(error)")
            }
            
        } catch let error {
            XCTAssert(false, "Should be able to add articles to \(readingListName) reading list: \(error)")
        }
        
    }
    
    func testAddingDuplicateArticlesToExistingReadingList() {
        let readingListName = "foo"
        let articleURLs = [URL(string: "//en.wikipedia.org/wiki/Foo")!, URL(string: "//en.wikipedia.org/wiki/Foo")!]
        
        let articles = articleURLs.compactMap { (articleURL) -> WMFArticle? in
            return dataStore.fetchOrCreateArticle(with: articleURL)
        }
        
        let articleKeys = articles.compactMap { (article) -> String? in
            return article.key
        }
        
        do {
            let readingList = try dataStore.readingListsController.createReadingList(named: readingListName, description: "Foo", with: articles)
            let existingArticleKeys = readingList.articleKeys
            XCTAssert(existingArticleKeys.wmf_containsObjectsInAnyOrder(articleKeys) && existingArticleKeys.count == 1)
        } catch let error {
            XCTAssert(false, "Should be able to add articles to \(readingListName) reading list: \(error)")
        }
    }

    func testClearNeedsRemoteDisableSyncState() {
        let readingListsController = dataStore.readingListsController
        readingListsController.syncState = [.needsRemoteDisable, .needsLocalReset]

        readingListsController.clearNeedsRemoteDisableSyncState()

        XCTAssertFalse(readingListsController.syncState.contains(.needsRemoteDisable), "A pending remote disable should be cleared")
        XCTAssertTrue(readingListsController.syncState.contains(.needsLocalReset), "Other sync state flags should be retained")
    }

    func testClearNeedsRemoteDisableSyncStateIsANoOpWithoutTheFlag() {
        let readingListsController = dataStore.readingListsController
        readingListsController.syncState = [.needsSync, .needsUpdate]

        readingListsController.clearNeedsRemoteDisableSyncState()

        XCTAssertEqual(readingListsController.syncState, [.needsSync, .needsUpdate], "Sync state without a pending remote disable should be unchanged")
    }

    func testDisablingSyncToDeleteRemoteListsDoesNotRequestLocalDataDeletion() {
        let readingListsController = dataStore.readingListsController

        // The disable-sync alert's "Yes" path (T431140)
        readingListsController.setSyncEnabled(false, shouldDeleteLocalLists: false, shouldDeleteRemoteLists: true)

        let state = readingListsController.syncState
        XCTAssertTrue(state.contains(.needsRemoteDisable), "Yes should request the remote teardown")
        XCTAssertTrue(state.contains(.needsLocalReset), "Yes should only reset remote IDs locally")
        XCTAssertFalse(state.contains(.needsLocalArticleClear), "Yes must never delete local saved articles")
        XCTAssertFalse(state.contains(.needsLocalListClear), "Yes must never delete local reading lists")
        XCTAssertFalse(readingListsController.isSyncEnabled)
    }

    func testPendingRemoteDisableSurvivesSyncWithoutPermanentAuthAndPreservesLocalLists() throws {
        let readingListsController = dataStore.readingListsController
        let article = try XCTUnwrap(dataStore.fetchOrCreateArticle(with: URL(string: "//en.wikipedia.org/wiki/Foo")!))
        _ = try readingListsController.createReadingList(named: "pending-teardown", description: "Foo", with: [article])

        // The disable-sync alert's "Yes" path, but the teardown can't complete
        // (no permanent account here — the same situation as being offline mid-teardown)
        readingListsController.setSyncEnabled(false, shouldDeleteLocalLists: false, shouldDeleteRemoteLists: true)
        readingListsController.isSyncRemotelyEnabled = true

        try runSyncOperation()

        dataStore.viewContext.refreshAllObjects()
        XCTAssertFalse(readingListsController.syncState.contains(.needsLocalReset), "The sync operation should have processed the local reset")
        XCTAssertTrue(readingListsController.syncState.contains(.needsRemoteDisable), "An unfulfilled remote disable is retained by the sync operation — the T431140 stale-flag precondition")
        XCTAssertEqual(try fetchReadingLists(named: "pending-teardown").count, 1, "Local lists must survive the disable-sync Yes path")

        // App launch / logout clears the stale flag so a later sync can't tear down remote lists
        readingListsController.clearNeedsRemoteDisableSyncState()
        XCTAssertFalse(readingListsController.syncState.contains(.needsRemoteDisable))

        // The next sync of the session (relaunch) leaves everything intact
        try runSyncOperation()
        dataStore.viewContext.refreshAllObjects()
        XCTAssertFalse(readingListsController.syncState.contains(.needsRemoteDisable))
        XCTAssertEqual(try fetchReadingLists(named: "pending-teardown").count, 1)
    }

    func testAuthenticationManagerResetClearsPendingRemoteDisable() throws {
        let readingListsController = dataStore.readingListsController
        readingListsController.syncState = [.needsRemoteDisable, .needsSync]

        let delegate = try XCTUnwrap(dataStore as? WMFAuthenticationManagerDelegate, "MWKDataStore should be the authentication manager's delegate")
        delegate.authenticationManagerDidReset()

        XCTAssertFalse(readingListsController.syncState.contains(.needsRemoteDisable), "Logout must clear a pending remote disable")
        XCTAssertFalse(readingListsController.isSyncEnabled)
    }

    private func runSyncOperation(timeout: TimeInterval = 30) throws {
        let operation = ReadingListsSyncOperation(readingListsController: dataStore.readingListsController)
        let operationFinished = expectation(description: "sync operation finished")
        operation.completionBlock = {
            operationFinished.fulfill()
        }
        OperationQueue().addOperation(operation)
        waitForExpectations(timeout: timeout)
        if let error = operation.error {
            throw error
        }
    }

    private func fetchReadingLists(named name: String) throws -> [ReadingList] {
        let request: NSFetchRequest<ReadingList> = ReadingList.fetchRequest()
        request.predicate = NSPredicate(format: "canonicalName == %@", name)
        return try dataStore.viewContext.fetch(request)
    }
}

extension Array where Element: Hashable {
    func wmf_containsObjectsInAnyOrderAndMatchesCount(_ other: [Element]) -> Bool {
        return wmf_containsObjectsInAnyOrder(other) && self.count == other.count
    }
    
    func wmf_containsObjectsInAnyOrder(_ other: [Element]) -> Bool {
        let selfSet = Set(self)
        let otherSet = Set(other)
        return otherSet.isSubset(of: selfSet)
    }
}

