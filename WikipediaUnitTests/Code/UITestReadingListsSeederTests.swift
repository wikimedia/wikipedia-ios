import XCTest
@testable import WMF

/// The seeder must leave the same data on a device that already has saved articles and lists
/// as on a fresh install, because UI tests share one install and seed on every launch.
final class UITestReadingListsSeederTests: XCTestCase {

    private var dataStore: MWKDataStore!
    private var userDefaults: UserDefaults!

    override func setUp(completion: @escaping (Error?) -> Void) {
        userDefaults = UserDefaults(suiteName: "UITestReadingListsSeederTests-\(UUID().uuidString)")
        MWKDataStore.createTemporaryDataStore(completion: { dataStore in
            self.dataStore = dataStore
            completion(nil)
        })
    }

    override func tearDown() {
        dataStore.removeFolderAtBasePath()
        super.tearDown()
    }

    @MainActor
    func testSeedingTwiceLeavesExactlyTheSeededData() throws {
        let seed = UITestReadingListsSeed(
            readingLists: [
                .init(name: "Zoology", description: nil, createdMinutesAgo: 60),
                .init(name: "Égypte", description: "Empty", createdMinutesAgo: 10)
            ],
            articles: [
                .init(title: "Dog", description: "domesticated animal", snippet: "The dog is a domesticated descendant of the wolf.", savedMinutesAgo: 10, readingListNames: ["Zoology"]),
                .init(title: "Zebra", description: nil, snippet: nil, savedMinutesAgo: 1, readingListNames: [])
            ]
        )
        let data = try JSONEncoder().encode(seed)
        userDefaults.set(data.base64EncodedString(), forKey: UITestReadingListsSeeder.launchArgumentKey)

        for _ in 0..<2 {
            UITestReadingListsSeeder(dataStore: dataStore).applyIfNeeded(userDefaults: userDefaults)

            let listsRequest: NSFetchRequest<ReadingList> = ReadingList.fetchRequest()
            listsRequest.predicate = NSPredicate(format: "isDeletedLocally == NO && isDefault == NO")
            let listNames = try dataStore.viewContext.fetch(listsRequest).compactMap { $0.name }
            XCTAssertEqual(Set(listNames), ["Zoology", "Égypte"])

            let articlesRequest: NSFetchRequest<WMFArticle> = WMFArticle.fetchRequest()
            articlesRequest.predicate = NSPredicate(format: "savedDate != NULL")
            let savedArticles = try dataStore.viewContext.fetch(articlesRequest)
            XCTAssertEqual(Set(savedArticles.compactMap { $0.displayTitle }), ["Dog", "Zebra"])
            XCTAssertTrue(savedArticles.allSatisfy { $0.isDownloaded })

            let dog = try XCTUnwrap(savedArticles.first { $0.displayTitle == "Dog" })
            XCTAssertEqual(dog.sortedNonDefaultReadingLists.compactMap { $0.name }, ["Zoology"])
            XCTAssertEqual(dog.snippet, "The dog is a domesticated descendant of the wolf.")
        }
    }
}
