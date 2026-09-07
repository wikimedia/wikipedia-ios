import XCTest
import WMF
@testable import Wikipedia

class WMFDatabaseHousekeeperTests: XCTestCase {

    var dataStore: MWKDataStore!

    override func setUp(completion: @escaping (Error?) -> Void) {
        MWKDataStore.createTemporaryDataStore { dataStore in
            self.dataStore = dataStore
            completion(nil)
        }
    }

    override func tearDown() {
        UserDefaults.standard.wmf_lastDatabaseHousekeepingDate = nil
    }

    // MARK: - Throttle

    func testHousekeepingRunsWhenItNeverRan() {
        UserDefaults.standard.wmf_lastDatabaseHousekeepingDate = nil
        XCTAssertTrue(UserDefaults.standard.wmf_shouldPerformDatabaseHousekeeping)
    }

    func testHousekeepingDoesNotRunAgainImmediately() {
        UserDefaults.standard.wmf_lastDatabaseHousekeepingDate = Date()
        XCTAssertFalse(UserDefaults.standard.wmf_shouldPerformDatabaseHousekeeping)
    }

    func testHousekeepingRunsAgainAfterTheInterval() {
        UserDefaults.standard.wmf_lastDatabaseHousekeepingDate = Date(timeIntervalSinceNow: -WMFDatabaseHousekeepingInterval - 1)
        XCTAssertTrue(UserDefaults.standard.wmf_shouldPerformDatabaseHousekeeping)
    }

    // MARK: - Excluded article keys

    /// A pass deletes a preview article that has no user state and no reference.
    func testUnreferencedArticleIsDeleted() throws {
        let moc = dataStore.viewContext
        let article = try XCTUnwrap(dataStore.fetchOrCreateArticle(with: URL(string: "https://en.wikipedia.org/wiki/Stale")!))
        let key = try XCTUnwrap(article.key)
        try moc.save()

        let deletedURLs = try WMFDatabaseHousekeeper().performHousekeeping(on: moc, excludedArticleKeys: [], cleanupLevel: .low)

        XCTAssertEqual(deletedURLs.count, 1)
        XCTAssertNil(dataStore.fetchArticle(withKey: key))
    }

    /// A pass keeps an article that the caller gives in the excluded keys.
    func testExcludedArticleIsNotDeleted() throws {
        let moc = dataStore.viewContext
        let article = try XCTUnwrap(dataStore.fetchOrCreateArticle(with: URL(string: "https://en.wikipedia.org/wiki/InUse")!))
        let key = try XCTUnwrap(article.key)
        try moc.save()

        let deletedURLs = try WMFDatabaseHousekeeper().performHousekeeping(on: moc, excludedArticleKeys: [key], cleanupLevel: .low)

        XCTAssertTrue(deletedURLs.isEmpty)
        XCTAssertNotNil(dataStore.fetchArticle(withKey: key))
    }

    /// The preserved keys hold an article that is realized in the view context.
    func testArticleKeysToPreserveIncludesRealizedArticles() throws {
        let article = try XCTUnwrap(dataStore.fetchOrCreateArticle(with: URL(string: "https://en.wikipedia.org/wiki/Realized")!))
        let key = try XCTUnwrap(article.key)
        try dataStore.viewContext.save()

        let keys = WMFDatabaseHousekeeper().articleKeysToPreserve(in: dataStore, navigationStateController: NavigationStateController(dataStore: dataStore))

        XCTAssertTrue(keys.contains(key))
    }
    
    func testDaysBefore() {        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm ZZZ"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        
        let localFormatter = DateFormatter()
        localFormatter.dateFormat = "yyyy/MM/dd HH:mm"
        localFormatter.timeZone = TimeZone.current

        guard let d1 = localFormatter.date(from: "2017/03/01 00:00") as NSDate? else {
            XCTFail("Failure parsing date")
            return
        }
        
        guard let d1_30 = d1.wmf_midnightUTCDateFromLocalDate(byAddingDays:-30) else {
            XCTFail("Failure parsing date")
            return
        }
        XCTAssertEqual("2017/01/30 00:00 +0000", formatter.string(from: d1_30))
    
        guard let d1_1 = d1.wmf_midnightUTCDateFromLocalDate(byAddingDays:-1) else {
            XCTFail("Failure parsing date")
            return
        }
        XCTAssertEqual("2017/02/28 00:00 +0000", formatter.string(from: d1_1))
        
        guard let d1_plus1 = d1.wmf_midnightUTCDateFromLocalDate(byAddingDays:1) else {
            XCTFail("Failure parsing date")
            return
        }
        XCTAssertEqual("2017/03/02 00:00 +0000", formatter.string(from: d1_plus1))
    }
}
