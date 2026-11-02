import XCTest
import WMFData
@testable import Wikipedia
@testable import WMF

final class CreateReadingListCoordinatorTests: XCTestCase {

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

    private let english = WMFProject.wikipedia(WMFLanguage(languageCode: "en", languageVariantCode: nil))

    private func discoverPage(title: String) -> WMFDiscoverRecommendedPage {
        WMFDiscoverRecommendedPage(title: title, project: english, description: nil, thumbnailURL: nil, extract: nil, recommendedDate: Date())
    }

    private func article(title: String) throws -> WMFArticle {
        try XCTUnwrap(dataStore.fetchOrCreateArticle(with: URL(string: "https://en.wikipedia.org/wiki/\(title)")!))
    }

    // MARK: - Discover

    @MainActor
    func testSelectedDiscoverArticlesKeepOnlySelectedPagesInListOrder() throws {
        let pages = ["Foo", "Bar", "Baz"].map(discoverPage(title:))

        let articles = CreateReadingListCoordinator.selectedArticles(of: pages, selectedIDs: [pages[2].id, pages[0].id], dataStore: dataStore)

        XCTAssertEqual(articles.map(\.key), [try article(title: "Foo").key, try article(title: "Baz").key])
    }

    @MainActor
    func testSelectedDiscoverArticlesWithoutDataStoreIsEmpty() {
        let pages = [discoverPage(title: "Foo")]

        let articles = CreateReadingListCoordinator.selectedArticles(of: pages, selectedIDs: [pages[0].id], dataStore: nil)

        XCTAssertTrue(articles.isEmpty)
    }

    // MARK: - Import

    @MainActor
    func testSelectedImportedArticlesKeepOnlySelectedKeysInListOrder() throws {
        let articles = try ["Foo", "Bar", "Baz"].map(article(title:))
        let selectedIDs = try [articles[2], articles[0]].map { try XCTUnwrap($0.key) }

        let selectedArticles = CreateReadingListCoordinator.selectedArticles(of: articles, selectedIDs: selectedIDs)

        XCTAssertEqual(selectedArticles, [articles[0], articles[2]])
    }

    @MainActor
    func testSelectableArticleMapsImportedArticle() throws {
        let article = try article(title: "Foo")
        article.displayTitleHTML = "<i>Foo</i>"
        article.wikidataDescription = "example description"
        article.imageURLString = "https://upload.wikimedia.org/wikipedia/commons/thumb/a/a9/Example.jpg/640px-Example.jpg"

        let selectableArticle = try XCTUnwrap(CreateReadingListCoordinator.selectableArticle(for: article))

        XCTAssertEqual(selectableArticle.id, article.key)
        XCTAssertEqual(selectableArticle.displayTitle, "<i>Foo</i>")
        XCTAssertEqual(selectableArticle.project, english)
        XCTAssertEqual(selectableArticle.description, "Example description")
        XCTAssertNotNil(selectableArticle.thumbnailURL)
        XCTAssertEqual(selectableArticle.thumbnailURL, article.imageURL(forWidth: ImageUtils.nearbyThumbnailWidth()))
    }

    // MARK: - Name validation

    @MainActor
    func testNameValidationReturnsErrorOnlyForExistingName() throws {
        _ = try dataStore.readingListsController.createReadingList(named: "Foo", description: nil)
        let validation = CreateReadingListCoordinator.nameValidation(dataStore: dataStore)

        XCTAssertEqual(validation("Foo"), ReadingListError.listExistsWithTheSameName.localizedDescription)
        XCTAssertNil(validation("Bar"))
    }

    @MainActor
    func testNameValidationWithoutDataStoreAcceptsAnyName() {
        let validation = CreateReadingListCoordinator.nameValidation(dataStore: nil)

        XCTAssertNil(validation("Foo"))
    }
}
