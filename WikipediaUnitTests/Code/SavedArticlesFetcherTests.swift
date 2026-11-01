import XCTest
import WMFData
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

    func testServerBusyFailureDoesNotFlagArticle() throws {
        let article = try makeSavedArticle()

        fetcher.handleFailure(with: article, error: RequestError.serverBusy(statusCode: 503, retryAfter: 5))

        XCTAssertEqual(article.error, .none)
        XCTAssertEqual(article.downloadAttemptCount, 0)
        XCTAssertNil(article.downloadRetryDate)
    }

    func testServerBusyCooldownUsesRetryAfterAndBacksOff() {
        XCTAssertEqual(SavedArticlesFetcher.serverBusyCooldown(retryAfter: nil, consecutiveFailures: 1), 60)
        XCTAssertEqual(SavedArticlesFetcher.serverBusyCooldown(retryAfter: nil, consecutiveFailures: 3), 240)
        XCTAssertEqual(SavedArticlesFetcher.serverBusyCooldown(retryAfter: 7, consecutiveFailures: 1), 7)
        XCTAssertEqual(SavedArticlesFetcher.serverBusyCooldown(retryAfter: 7, consecutiveFailures: 3), 28)
        XCTAssertEqual(SavedArticlesFetcher.serverBusyCooldown(retryAfter: 1, consecutiveFailures: 1), 5, "A tiny Retry-After still waits the minimum")
        XCTAssertEqual(SavedArticlesFetcher.serverBusyCooldown(retryAfter: nil, consecutiveFailures: 10), 15 * 60, "Backoff is capped")
    }

    func testDownloadSlotDelayRespectsPerMinuteBudget() {
        let now = Date()
        let full = (0..<SavedArticlesFetcher.maximumDownloadsPerMinute).map { now.addingTimeInterval(-Double($0 + 1)) }
        let delay = SavedArticlesFetcher.delayUntilNextDownloadSlot(startDates: full, now: now)
        XCTAssertEqual(try XCTUnwrap(delay), 60 - Double(SavedArticlesFetcher.maximumDownloadsPerMinute), accuracy: 0.001, "Waits until the oldest download leaves the one-minute window")

        let stale = full.map { $0.addingTimeInterval(-61) }
        XCTAssertNil(SavedArticlesFetcher.delayUntilNextDownloadSlot(startDates: stale, now: now), "Downloads older than a minute do not count")

        let partial = Array(full.prefix(SavedArticlesFetcher.maximumDownloadsPerMinute - 1))
        XCTAssertNil(SavedArticlesFetcher.delayUntilNextDownloadSlot(startDates: partial, now: now))
    }
}
