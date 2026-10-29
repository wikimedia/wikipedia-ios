import XCTest
@testable import WMFData
import WMFDataMocks

final class WMFLegacyReadingListsDataControllerTests: XCTestCase {

    private let project = WMFProject.wikipedia(WMFLanguage(languageCode: "en", languageVariantCode: nil))

    private func article(_ title: String, displayTitle: String? = nil, minutesAgo: Int?, lists: [String] = []) -> WMFSavedArticle {
        WMFSavedArticle(id: "\(project.id)|\(title)", title: title, displayTitle: displayTitle, project: project, savedDate: minutesAgo.map { Date(timeIntervalSince1970: 1_000_000 - TimeInterval($0 * 60)) }, readingListNames: lists)
    }

    private func list(_ name: String, minutesAgo: Int?, isDefault: Bool = false, articleIDs: Set<String> = []) -> WMFReadingList {
        WMFReadingList(id: name, name: name, description: nil, isDefault: isDefault, createdDate: minutesAgo.map { Date(timeIntervalSince1970: 1_000_000 - TimeInterval($0 * 60)) }, articleCount: articleIDs.count, articleIDs: articleIDs)
    }

    private func makeController(delegate: MockDelegate) -> WMFLegacyReadingListsDataController {
        WMFLegacyReadingListsDataController(delegate: delegate, userDefaultsStore: WMFMockKeyValueStore())
    }

    // MARK: - Sorting rules

    func testTitleSortIgnoresCaseAndAccents() {
        let articles = [article("Zebra", minutesAgo: 1), article("apple", minutesAgo: 3), article("Émile Zola", minutesAgo: 2), article("Dog", minutesAgo: 10)]
        let sorted = WMFLegacyReadingListsDataController.sorted(articles, by: .byTitle)
        XCTAssertEqual(sorted.map { $0.title }, ["apple", "Dog", "Émile Zola", "Zebra"])
    }

    func testTitleSortAndSearchUseTheDisplayTitle() {
        let phone = article("IPhone", displayTitle: "iPhone", minutesAgo: 1)
        let articles = [article("Zebra", minutesAgo: 2), phone, article("Apple", minutesAgo: 3)]

        let sorted = WMFLegacyReadingListsDataController.sorted(articles, by: .byTitle)
        XCTAssertEqual(sorted.map { $0.displayTitle }, ["Apple", "iPhone", "Zebra"])

        XCTAssertEqual(WMFLegacyReadingListsDataController.filtered(articles, searchText: "iph").map { $0.id }, [phone.id])
        XCTAssertEqual(phone.title, "IPhone", "The canonical title stays as it is; the display title is only for display.")
    }

    func testTitleSortBreaksTiesWithTheNewest() {
        let articles = [article("Dog", minutesAgo: 10), article("Dog", minutesAgo: 1)]
        let sorted = WMFLegacyReadingListsDataController.sorted(articles, by: .byTitle)
        XCTAssertEqual(sorted.map { $0.savedDate }, [articles[1].savedDate, articles[0].savedDate])
    }

    func testRecentlyAddedSortPutsNewestFirstAndUndatedLast() {
        let articles = [article("Dog", minutesAgo: 10), article("Nowhere", minutesAgo: nil), article("Zebra", minutesAgo: 1)]
        let sorted = WMFLegacyReadingListsDataController.sorted(articles, by: .byRecentlyAdded)
        XCTAssertEqual(sorted.map { $0.title }, ["Zebra", "Dog", "Nowhere"])
    }

    func testReadingListsSortKeepsTheDefaultListFirst() {
        let lists = [list("Zoology", minutesAgo: 60), list("Saved", minutesAgo: 1000, isDefault: true), list("animals", minutesAgo: 30), list("Égypte", minutesAgo: 10)]
        XCTAssertEqual(WMFLegacyReadingListsDataController.sorted(lists, by: .byTitle).map { $0.name }, ["Saved", "animals", "Égypte", "Zoology"])
        XCTAssertEqual(WMFLegacyReadingListsDataController.sorted(lists, by: .byRecentlyAdded).map { $0.name }, ["Saved", "Égypte", "animals", "Zoology"])
    }

    // MARK: - Search rules

    func testSearchIgnoresCaseAccentsAndSurroundingSpaces() {
        XCTAssertTrue(WMFLegacyReadingListsDataController.matches("Émile Zola", searchText: "emile"))
        XCTAssertTrue(WMFLegacyReadingListsDataController.matches("Zoology", searchText: " ZOO "))
        XCTAssertTrue(WMFLegacyReadingListsDataController.matches("Dog", searchText: ""))
        XCTAssertFalse(WMFLegacyReadingListsDataController.matches("Dog", searchText: "cat"))
    }

    // MARK: - Reading list filters

    func testAllFilterHidesTheDefaultListUnlessItIsEnabled() {
        let lists = [list("Saved", minutesAgo: 100, isDefault: true), list("Zoology", minutesAgo: 60)]
        XCTAssertEqual(WMFLegacyReadingListsDataController.filtered(lists, filter: .all, isDefaultListEnabled: false).map { $0.name }, ["Zoology"])
        XCTAssertEqual(WMFLegacyReadingListsDataController.filtered(lists, filter: .all, isDefaultListEnabled: true).map { $0.name }, ["Saved", "Zoology"])
    }

    func testAddToListFilterLeavesOutListsThatAlreadyHoldEveryArticle() {
        let dog = article("Dog", minutesAgo: 1).id
        let zebra = article("Zebra", minutesAgo: 1).id
        let lists = [list("Zoology", minutesAgo: 60, articleIDs: [dog, zebra]), list("animals", minutesAgo: 30, articleIDs: [dog]), list("Égypte", minutesAgo: 10)]

        let forDog = WMFLegacyReadingListsDataController.filtered(lists, filter: .excludingListsContainingAll(articleIDs: [dog]), isDefaultListEnabled: false)
        XCTAssertEqual(forDog.map { $0.name }, ["Égypte"])

        let forBoth = WMFLegacyReadingListsDataController.filtered(lists, filter: .excludingListsContainingAll(articleIDs: [dog, zebra]), isDefaultListEnabled: false)
        XCTAssertEqual(forBoth.map { $0.name }, ["animals", "Égypte"], "animals holds only one of the two, so it stays available")
    }

    func testNamedFilterReturnsOnlyThoseLists() {
        let lists = [list("Zoology", minutesAgo: 60), list("animals", minutesAgo: 30)]
        XCTAssertEqual(WMFLegacyReadingListsDataController.filtered(lists, filter: .named(["animals"]), isDefaultListEnabled: false).map { $0.name }, ["animals"])
    }

    // MARK: - Fetches through the delegate

    func testFetchSavedArticlesUsesTheDefaultListSortOrderAndTheSearchText() async throws {
        let delegate = MockDelegate()
        delegate.savedArticles = [article("Zebra", minutesAgo: 1), article("apple", minutesAgo: 3), article("Dog", minutesAgo: 10)]
        delegate.defaultListID = "default"
        delegate.sortOrders["default"] = .byTitle
        let controller = makeController(delegate: delegate)

        let result1 = try await controller.fetchSavedArticles()

        XCTAssertEqual(result1.map { $0.title }, ["apple", "Dog", "Zebra"])
        let result2 = try await controller.fetchSavedArticles(searchText: "ZEB")
        XCTAssertEqual(result2.map { $0.title }, ["Zebra"])

        try await controller.setSavedArticlesSortOrder(.byRecentlyAdded)
        XCTAssertEqual(delegate.sortOrders["default"], .byRecentlyAdded)
        let result3 = try await controller.fetchSavedArticles()
        XCTAssertEqual(result3.map { $0.title }, ["Zebra", "apple", "Dog"])
    }

    func testFetchSavedArticlesDefaultsToRecentlyAddedWithoutAStoredChoice() async throws {
        let delegate = MockDelegate()
        delegate.savedArticles = [article("apple", minutesAgo: 3), article("Zebra", minutesAgo: 1)]
        let controller = makeController(delegate: delegate)
        let result4 = try await controller.fetchSavedArticles()
        XCTAssertEqual(result4.map { $0.title }, ["Zebra", "apple"])
    }

    func testReadingListsSortOrderIsStoredOnDeviceAndDefaultsToTitle() async throws {
        let delegate = MockDelegate()
        delegate.readingLists = [list("Zoology", minutesAgo: 60), list("animals", minutesAgo: 30), list("Égypte", minutesAgo: 10)]
        let store = WMFMockKeyValueStore()
        let controller = WMFLegacyReadingListsDataController(delegate: delegate, userDefaultsStore: store)

        XCTAssertEqual(controller.readingListsSortOrder, .byTitle)
        let result5 = try await controller.fetchReadingLists()
        XCTAssertEqual(result5.map { $0.name }, ["animals", "Égypte", "Zoology"])

        controller.setReadingListsSortOrder(.byRecentlyAdded)
        let reloaded = WMFLegacyReadingListsDataController(delegate: delegate, userDefaultsStore: store)
        XCTAssertEqual(reloaded.readingListsSortOrder, .byRecentlyAdded)
        let result6 = try await reloaded.fetchReadingLists(searchText: "a")
        XCTAssertEqual(result6.map { $0.name }, ["animals"])
    }

    func testFetchArticlesInListUsesThatListsSortOrder() async throws {
        let delegate = MockDelegate()
        delegate.articlesByList["zoology"] = [article("Zebra", minutesAgo: 1), article("apple", minutesAgo: 3)]
        delegate.sortOrders["zoology"] = .byTitle
        let controller = makeController(delegate: delegate)

        let result7 = try await controller.fetchArticles(inReadingList: "zoology")

        XCTAssertEqual(result7.map { $0.title }, ["apple", "Zebra"])
        try await controller.setSortOrder(.byRecentlyAdded, forReadingList: "zoology")
        let result8 = try await controller.fetchArticles(inReadingList: "zoology")
        XCTAssertEqual(result8.map { $0.title }, ["Zebra", "apple"])
    }

    func testMoveAddsToTheDestinationBeforeRemovingFromTheSource() async throws {
        let delegate = MockDelegate()
        let controller = makeController(delegate: delegate)
        try await controller.moveArticles(ids: ["a"], fromReadingList: "zoology", toReadingList: "animals")
        XCTAssertEqual(delegate.log, ["add a to animals", "remove a from zoology"])
    }

    func testMissingDelegateThrows() async {
        let controller = WMFLegacyReadingListsDataController(delegate: nil, userDefaultsStore: WMFMockKeyValueStore())
        do {
            _ = try await controller.fetchSavedArticles()
            XCTFail("Expected an error")
        } catch {
            XCTAssertTrue(error is WMFLegacyReadingListsDataControllerError)
        }
    }
}

private final class MockDelegate: WMFLegacyReadingListsDataControllerDelegate {
    var savedArticles: [WMFSavedArticle] = []
    var readingLists: [WMFReadingList] = []
    var articlesByList: [String: [WMFSavedArticle]] = [:]
    var sortOrders: [String: WMFReadingListSortOrder] = [:]
    var defaultListID: String?
    var defaultReadingListEnabled = false
    var log: [String] = []

    func fetchSavedArticles() async throws -> [WMFSavedArticle] { savedArticles }
    func fetchReadingLists() async throws -> [WMFReadingList] { readingLists }
    func fetchArticles(inReadingList readingListID: String) async throws -> [WMFSavedArticle] { articlesByList[readingListID] ?? [] }
    func defaultReadingListID() async throws -> String? { defaultListID }
    func isDefaultReadingListEnabled() async -> Bool { defaultReadingListEnabled }
    func sortOrder(forReadingList readingListID: String) async throws -> WMFReadingListSortOrder? { sortOrders[readingListID] }
    func setSortOrder(_ sortOrder: WMFReadingListSortOrder, forReadingList readingListID: String) async throws { sortOrders[readingListID] = sortOrder }
    func createReadingList(name: String, description: String?) async throws -> WMFReadingList {
        WMFReadingList(id: name, name: name, description: description, isDefault: false, createdDate: Date(), articleCount: 0, articleIDs: [])
    }
    func updateReadingList(id readingListID: String, name: String?, description: String?) async throws { log.append("update \(readingListID)") }
    func deleteReadingLists(ids readingListIDs: [String]) async throws { log.append("delete \(readingListIDs.joined(separator: ","))") }
    func addArticles(ids articleIDs: [String], toReadingList readingListID: String) async throws { log.append("add \(articleIDs.joined(separator: ",")) to \(readingListID)") }
    func removeArticles(ids articleIDs: [String], fromReadingList readingListID: String) async throws { log.append("remove \(articleIDs.joined(separator: ",")) from \(readingListID)") }
    func unsaveArticles(ids articleIDs: [String]) async throws { log.append("unsave \(articleIDs.joined(separator: ","))") }
    func deleteSavedArticles(articles: [WMFSavedArticle], fromLongPress: Bool, completion: @escaping (Bool) -> Void) { completion(true) }
}
