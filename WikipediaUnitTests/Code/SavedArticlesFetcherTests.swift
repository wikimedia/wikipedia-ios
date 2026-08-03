import XCTest
@testable import Wikipedia
@testable import WMF

class SavedArticlesFetcherTests: XCTestCase {

    var dataStore: MWKDataStore!
    var fetcher: SavedArticlesFetcher!

    override func setUp(completion: @escaping (Error?) -> Void) {
        MWKDataStore.createTemporaryDataStore(completion: { dataStore in
            self.dataStore = dataStore
            self.fetcher = SavedArticlesFetcher(dataStore: dataStore)
            completion(self.fetcher == nil ? RequestError.unknown : nil)
        })
    }

    override func tearDown() {
        super.tearDown()
        dataStore.removeFolderAtBasePath()
    }

    private func makeSavedArticle() throws -> WMFArticle {
        let article = try XCTUnwrap(dataStore.fetchOrCreateArticle(with: URL(string: "//en.wikipedia.org/wiki/Foo")!))
        article.savedDate = Date()
        try dataStore.viewContext.save()
        return article
    }

    func testSuccessfulDownloadClearsPreviousError() throws {
        let article = try makeSavedArticle()
        article.error = .apiFailed
        article.downloadAttemptCount = 2
        article.downloadRetryDate = Date(timeIntervalSinceNow: 900)
        try dataStore.viewContext.save()

        fetcher.didFetchArticle(with: article.objectID)

        XCTAssertTrue(article.isDownloaded)
        XCTAssertEqual(article.error, .none, "A successful download should clear the error from earlier failed attempts")
        XCTAssertEqual(article.downloadAttemptCount, 0)
        XCTAssertNil(article.downloadRetryDate)
    }

    func testAPIFailureFlagsArticleAndSchedulesRetry() throws {
        let article = try makeSavedArticle()

        fetcher.handleFailure(with: article, error: RequestError.http(500))

        XCTAssertEqual(article.error, .apiFailed)
        XCTAssertEqual(article.downloadAttemptCount, 1)
        XCTAssertNotNil(article.downloadRetryDate)
    }

    func testRateLimitFailureDoesNotFlagArticle() throws {
        let article = try makeSavedArticle()

        fetcher.handleFailure(with: article, error: RequestError.http(429))

        XCTAssertEqual(article.error, .none, "Being rate limited is a global condition and should not brand the article with an error")
        XCTAssertEqual(article.downloadAttemptCount, 0, "Rate limiting should not escalate the article's retry backoff")
        XCTAssertNil(article.downloadRetryDate)
    }
}
