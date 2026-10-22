import XCTest
import CoreData
@testable import Wikipedia
@testable import WMF
import WMFData
import WMFComponents
import WMFNativeLocalizations

/// Characterization tests for the Saved tab rules that survive the SwiftUI rewrite (T441442):
/// the saved-articles fetch, search and sort semantics, alert gates and list-name validation.
final class SavedTabCharacterizationTests: XCTestCase {

    private var dataStore: MWKDataStore!
    private var window: UIWindow!

    override func setUp(completion: @escaping (Error?) -> Void) {
        MWKDataStore.createTemporaryDataStore(completion: { dataStore in
            self.dataStore = dataStore
            completion(nil)
        })
    }

    override func tearDown() {
        window = nil
        dataSources = []
        dataStore.removeFolderAtBasePath()
        super.tearDown()
    }

    // MARK: - All articles fetch

    @MainActor
    func testAllArticlesFetchListsEachArticleOnceWithItsCustomListNames() async throws {
        let article = try saveArticle(titled: "Dog", minutesAgo: 10)
        let zoology = try dataStore.readingListsController.createReadingList(named: "Zoology")
        let animals = try dataStore.readingListsController.createReadingList(named: "animals")
        try dataStore.readingListsController.add(articles: [article], to: zoology)
        try dataStore.readingListsController.add(articles: [article], to: animals)
        try dataStore.viewContext.save()

        let savedArticles = try await makeDataController(sortOrder: .byTitle).fetchSavedArticles()

        XCTAssertEqual(savedArticles.map { $0.title }, ["Dog"])
        XCTAssertEqual(Set(savedArticles[0].readingListNames), ["Zoology", "animals"])
    }

    @MainActor
    func testAllArticlesFetchSortsByRecentlyAdded() async throws {
        try saveArticle(titled: "Dog", minutesAgo: 10)
        try saveArticle(titled: "apple", minutesAgo: 3)
        try saveArticle(titled: "Émile Zola", minutesAgo: 2)
        try saveArticle(titled: "Zebra", minutesAgo: 1)

        let savedArticles = try await makeDataController(sortOrder: .byRecentlyAdded).fetchSavedArticles()

        XCTAssertEqual(savedArticles.map { $0.title }, ["Zebra", "Émile Zola", "apple", "Dog"])
    }

    @MainActor
    func testAllArticlesFetchSortsByLocalizedTitle() async throws {
        try saveArticle(titled: "Dog", minutesAgo: 10)
        try saveArticle(titled: "apple", minutesAgo: 3)
        try saveArticle(titled: "Émile Zola", minutesAgo: 2)
        try saveArticle(titled: "Zebra", minutesAgo: 1)

        let savedArticles = try await makeDataController(sortOrder: .byTitle).fetchSavedArticles()

        XCTAssertEqual(savedArticles.map { $0.title }, ["apple", "Dog", "Émile Zola", "Zebra"])
    }

    /// A page can carry a display title that differs from its canonical title (DISPLAYTITLE).
    /// Article URLs come from the canonical title; the display title is for the row only.
    @MainActor
    func testAllArticlesFetchKeepsTheCanonicalTitleNextToTheDisplayTitle() async throws {
        try saveArticle(titled: "IPhone", displayTitle: "iPhone", minutesAgo: 1)

        let savedArticles = try await makeDataController(sortOrder: .byTitle).fetchSavedArticles()
        let savedArticle = try XCTUnwrap(savedArticles.first)

        XCTAssertEqual(savedArticle.title, "IPhone")
        XCTAssertEqual(savedArticle.displayTitle, "iPhone")

        let articleURL = try XCTUnwrap(savedArticle.project.siteURL?.wmf_URL(withTitle: savedArticle.title))
        XCTAssertNotNil(dataStore.fetchArticle(with: articleURL), "The Saved tab rebuilds the article URL from the title to share and open the article.")
    }

    @MainActor
    func testAllArticlesFetchCarriesTheSnippetForTheLongPressPreview() async throws {
        try saveArticle(titled: "Zebra", snippet: "Zebras are African equines with striped coats.", minutesAgo: 1)

        let savedArticles = try await makeDataController(sortOrder: .byTitle).fetchSavedArticles()
        let savedArticle = try XCTUnwrap(savedArticles.first)

        XCTAssertEqual(savedArticle.snippet, "Zebras are African equines with striped coats.")
    }

    @MainActor
    func testAllArticlesAlertFollowsDownloadState() async throws {
        let queued = try saveArticle(titled: "Queued", minutesAgo: 3)
        queued.isDownloaded = false
        let downloaded = try saveArticle(titled: "Downloaded", minutesAgo: 2)
        downloaded.isDownloaded = true
        let failed = try saveArticle(titled: "Failed", minutesAgo: 1)
        failed.isDownloaded = false
        failed.error = .apiFailed
        try dataStore.viewContext.save()

        let savedArticles = try await makeDataController(sortOrder: .byRecentlyAdded).fetchSavedArticles()
        let alertsByTitle = Dictionary(uniqueKeysWithValues: savedArticles.map { ($0.title, $0.alertType) })

        XCTAssertEqual(alertsByTitle["Queued"], .downloading)
        XCTAssertEqual(alertsByTitle["Downloaded"], WMFSavedArticleAlertType.none)
        XCTAssertEqual(alertsByTitle["Failed"], .articleError(ArticleError.apiFailed.localizedDescription))
    }

    @MainActor
    func testAllArticlesAlertReportsSyncLimitsOverDownloadState() async throws {
        let article = try saveArticle(titled: "Dog", minutesAgo: 1)
        article.isDownloaded = true
        let defaultEntry = try XCTUnwrap(entries(for: article).first)
        defaultEntry.errorCode = APIReadingListError.entryLimit.rawValue
        try dataStore.viewContext.save()

        var savedArticles = try await makeDataController(sortOrder: .byTitle).fetchSavedArticles()
        XCTAssertEqual(savedArticles.first?.alertType, .genericNotSynced, "An entry limit on the default list is reported as a generic sync problem.")

        defaultEntry.errorCode = nil
        let defaultList = try XCTUnwrap(dataStore.viewContext.defaultReadingList)
        defaultList.errorCode = APIReadingListError.listLimit.rawValue
        try dataStore.viewContext.save()

        savedArticles = try await makeDataController(sortOrder: .byTitle).fetchSavedArticles()
        let listLimit = dataStore.viewContext.wmf_readingListsConfigMaxListsPerUser
        XCTAssertEqual(savedArticles.first?.alertType, .listLimitExceeded(limit: listLimit))
    }

    // MARK: - Search semantics

    func testReadingListsSearchIgnoresCaseAndDiacritics() throws {
        _ = try dataStore.readingListsController.createReadingList(named: "Zoology")
        _ = try dataStore.readingListsController.createReadingList(named: "Égypte")
        try dataStore.viewContext.save()

        let viewController = ReadingListsViewController(with: dataStore)
        XCTAssertEqual(try readingListNames(matching: "égy", in: viewController), ["Égypte"])
        XCTAssertEqual(try readingListNames(matching: "ZOO", in: viewController), ["Zoology"])
        XCTAssertEqual(try readingListNames(matching: "nothing", in: viewController), [])
    }

    func testReadingListDetailSearchIgnoresCaseAndDiacritics() throws {
        let dog = try saveArticle(titled: "Dog", minutesAgo: 2)
        let zola = try saveArticle(titled: "Émile Zola", minutesAgo: 1)
        let list = try dataStore.readingListsController.createReadingList(named: "Zoology", with: [dog, zola])
        try dataStore.viewContext.save()

        let viewController = ReadingListEntryCollectionViewController(for: list, with: dataStore)
        XCTAssertEqual(try entryTitles(matching: "émile", in: viewController), ["Émile Zola"])
        XCTAssertEqual(try entryTitles(matching: "DOG", in: viewController), ["Dog"])
    }

    // MARK: - Sort persistence

    func testReadingListDetailSortIsReadFromTheListAndDefaultsToRecentlyAdded() throws {
        let list = try dataStore.readingListsController.createReadingList(named: "Zoology")
        try dataStore.viewContext.save()
        let viewController = ReadingListEntryCollectionViewController(for: list, with: dataStore)

        XCTAssertEqual(viewController.baseSortDescriptors.map { $0.key }, ["createdDate"])
        XCTAssertEqual(viewController.baseSortDescriptors.first?.ascending, false)

        list.sortOrder = NSNumber(value: SortActionType.byTitle.rawValue)
        XCTAssertEqual(viewController.sort.descriptors.map { $0.key }, ["displayTitle"])
        XCTAssertEqual(viewController.sort.descriptors.first?.ascending, true)

        list.sortOrder = NSNumber(value: SortActionType.byRecentlyAdded.rawValue)
        XCTAssertEqual(viewController.sort.descriptors.map { $0.key }, ["createdDate"])
    }

    // MARK: - Alert gates

    func testUnsaveAlertIsSkippedWhenArticlesAreOnlyInTheDefaultList() throws {
        let article = try saveArticle(titled: "Dog", minutesAgo: 1)
        let presenter = makePresenter()

        let completion = expectation(description: "completion")
        ReadingListsAlertController().showAlertIfNeeded(presenter: presenter, for: [article], with: []) { presented in
            XCTAssertFalse(presented)
            completion.fulfill()
        }
        wait(for: [completion], timeout: 2)
        XCTAssertNil(presenter.presentedViewController)
    }

    func testUnsaveAlertIsShownWhenAnArticleIsInACustomList() throws {
        let article = try saveArticle(titled: "Dog", minutesAgo: 1)
        let list = try dataStore.readingListsController.createReadingList(named: "Zoology")
        try dataStore.readingListsController.add(articles: [article], to: list)
        try dataStore.viewContext.save()
        let presenter = makePresenter()

        let completion = expectation(description: "completion")
        ReadingListsAlertController().showAlertIfNeeded(presenter: presenter, for: [article], with: [ReadingListsAlertActionType.cancel.action()]) { presented in
            XCTAssertTrue(presented)
            completion.fulfill()
        }
        wait(for: [completion], timeout: 5)
        let alert = try XCTUnwrap(presenter.presentedViewController as? UIAlertController)
        XCTAssertEqual(alert.view.accessibilityIdentifier, AccessibilityIdentifiers.Saved.unsaveArticlesAlert)
    }

    func testDeleteListsAlertIsSkippedForEmptyListsAndShownForListsWithArticles() throws {
        let emptyList = try dataStore.readingListsController.createReadingList(named: "Égypte")
        let article = try saveArticle(titled: "Dog", minutesAgo: 1)
        let fullList = try dataStore.readingListsController.createReadingList(named: "Zoology", with: [article])
        try dataStore.viewContext.save()
        let presenter = makePresenter()

        let skipped = expectation(description: "skipped")
        ReadingListsAlertController().showAlertIfNeeded(presenter: presenter, for: [emptyList], with: []) { presented in
            XCTAssertFalse(presented)
            skipped.fulfill()
        }
        wait(for: [skipped], timeout: 2)
        XCTAssertNil(presenter.presentedViewController)

        let shown = expectation(description: "shown")
        ReadingListsAlertController().showAlertIfNeeded(presenter: presenter, for: [fullList], with: [ReadingListsAlertActionType.cancel.action()]) { presented in
            XCTAssertTrue(presented)
            shown.fulfill()
        }
        wait(for: [shown], timeout: 5)
        let alert = try XCTUnwrap(presenter.presentedViewController as? UIAlertController)
        XCTAssertEqual(alert.view.accessibilityIdentifier, AccessibilityIdentifiers.Saved.deleteReadingListsAlert)
    }

    // MARK: - List name validation

    func testCreateReadingListRejectsAnExistingNameAndTheDefaultListName() throws {
        _ = try dataStore.readingListsController.createReadingList(named: "Zoology")

        XCTAssertThrowsError(try dataStore.readingListsController.createReadingList(named: "Zoology")) { error in
            XCTAssertEqual(error as? ReadingListError, .listExistsWithTheSameName)
        }
        XCTAssertThrowsError(try dataStore.readingListsController.createReadingList(named: CommonStrings.readingListsDefaultListTitle)) { error in
            XCTAssertEqual(error as? ReadingListError, .listExistsWithTheSameName)
        }
        XCTAssertNoThrow(try dataStore.readingListsController.createReadingList(named: "zoology"), "A different case is a different list.")
    }

    // MARK: - Helpers

    @discardableResult
    private func saveArticle(titled title: String, displayTitle: String? = nil, snippet: String? = nil, minutesAgo: Int) throws -> WMFArticle {
        let url = try XCTUnwrap(URL(string: "https://en.wikipedia.org/wiki/\(title.replacingOccurrences(of: " ", with: "_"))"))
        let article = try XCTUnwrap(dataStore.fetchOrCreateArticle(with: url))
        article.displayTitleHTML = displayTitle ?? title
        article.snippet = snippet
        dataStore.savedPageList.addSavedPage(with: url)
        let date = Date(timeIntervalSinceNow: -TimeInterval(minutesAgo * 60))
        article.savedDate = date
        for entry in try entries(for: article) {
            entry.createdDate = date as NSDate
        }
        try dataStore.viewContext.save()
        return article
    }

    private func entries(for article: WMFArticle) throws -> [ReadingListEntry] {
        let request: NSFetchRequest<ReadingListEntry> = ReadingListEntry.fetchRequest()
        request.predicate = NSPredicate(format: "articleKey == %@ && isDeletedLocally == NO", try XCTUnwrap(article.key))
        return try dataStore.viewContext.fetch(request)
    }

    /// The All articles sort is stored on the default reading list, which is what the data source reads.
    @MainActor
    private func makeDataController(sortOrder: WMFReadingListSortOrder) async throws -> WMFLegacyReadingListsDataController {
        let dataSource = LegacyReadingListsDataSource(dataStore: dataStore)
        dataSource.unsaveConfirmation = nil
        dataSources.append(dataSource)
        let controller = WMFLegacyReadingListsDataController(delegate: dataSource)
        try await controller.setSavedArticlesSortOrder(sortOrder)
        return controller
    }

    /// The controller holds its delegate weakly; keep the data sources alive for the test.
    private var dataSources: [LegacyReadingListsDataSource] = []

    private func makePresenter() -> UIViewController {
        let presenter = UIViewController()
        window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = presenter
        window.makeKeyAndVisible()
        return presenter
    }

    private func readingListNames(matching searchString: String, in viewController: ReadingListsViewController) throws -> [String] {
        viewController.searchString = searchString
        let request: NSFetchRequest<ReadingList> = ReadingList.fetchRequest()
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [viewController.basePredicate, try XCTUnwrap(viewController.searchPredicate)])
        return try dataStore.viewContext.fetch(request).compactMap { $0.name }
    }

    private func entryTitles(matching searchString: String, in viewController: ReadingListEntryCollectionViewController) throws -> [String] {
        viewController.searchString = searchString
        let request: NSFetchRequest<ReadingListEntry> = ReadingListEntry.fetchRequest()
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [viewController.basePredicate, try XCTUnwrap(viewController.searchPredicate)])
        return try dataStore.viewContext.fetch(request).compactMap { $0.displayTitle }
    }
}
