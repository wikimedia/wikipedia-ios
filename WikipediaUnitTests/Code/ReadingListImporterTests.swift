import XCTest
@testable import Wikipedia
@testable import WMF

final class ReadingListImporterTests: XCTestCase {

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

    private func article(title: String, languageCode: String = "en") throws -> WMFArticle {
        try XCTUnwrap(dataStore.fetchOrCreateArticle(with: URL(string: "https://\(languageCode).wikipedia.org/wiki/\(title)")!))
    }

    @MainActor
    func testImportedArticlesAreSortedByTitle() throws {
        let articles = try [
            article(title: "Gato", languageCode: "pt"),
            article(title: "Dog"),
            article(title: "Brasil", languageCode: "pt"),
            article(title: "Cat")
        ]

        let sortedArticles = ReadingListImporter.sortedByTitle(articles)

        XCTAssertEqual(sortedArticles.map { $0.url?.wmf_title }, ["Brasil", "Cat", "Dog", "Gato"])
    }
}
