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

    // MARK: - Production-shaped rate limits

    func testRateLimitWrappedInFileWriterErrorDoesNotFlagArticle() throws {
        let article = try makeSavedArticle()

        let error = CacheControllerError.atLeastOneItemFailedInFileWriter(RequestError.rateLimited(retryAfter: nil))
        fetcher.handleFailure(with: article, error: error)

        XCTAssertEqual(article.error, .none, "A 429 arriving through the file writer is still a global condition")
        XCTAssertEqual(article.downloadAttemptCount, 0)
        XCTAssertNil(article.downloadRetryDate)
    }

    func testBareRateLimitDoesNotFlagArticle() throws {
        let article = try makeSavedArticle()

        fetcher.handleFailure(with: article, error: RequestError.rateLimited(retryAfter: 30))

        XCTAssertEqual(article.error, .none)
        XCTAssertEqual(article.downloadAttemptCount, 0)
        XCTAssertNil(article.downloadRetryDate)
    }

    func testRateLimitWrappedInSyncErrorDoesNotFlagArticle() throws {
        let article = try makeSavedArticle()

        let error = CacheControllerError.atLeastOneItemFailedInSync(RequestError.rateLimited(retryAfter: 30))
        fetcher.handleFailure(with: article, error: error)

        XCTAssertEqual(article.error, .none)
        XCTAssertEqual(article.downloadAttemptCount, 0)
        XCTAssertNil(article.downloadRetryDate)
    }

    func testRateLimitFromMediaListDoesNotFlagArticle() throws {
        let article = try makeSavedArticle()

        let error = ArticleCacheDBWriterError.failureFetchingMediaList(RequestError.rateLimited(retryAfter: nil))
        fetcher.handleFailure(with: article, error: error)

        XCTAssertEqual(article.error, .none, "A 429 from the media-list fetch is still a global condition")
        XCTAssertEqual(article.downloadAttemptCount, 0)
        XCTAssertNil(article.downloadRetryDate)
    }

    func testRateLimitFromOfflineResourceListDoesNotFlagArticle() throws {
        let article = try makeSavedArticle()

        let error = ArticleCacheDBWriterError.failureFetchingOfflineResourceList(RequestError.rateLimited(retryAfter: nil))
        fetcher.handleFailure(with: article, error: error)

        XCTAssertEqual(article.error, .none)
        XCTAssertEqual(article.downloadAttemptCount, 0)
        XCTAssertNil(article.downloadRetryDate)
    }

    func testWrappedServerErrorStillFlagsArticleAndSchedulesRetry() throws {
        let article = try makeSavedArticle()

        let error = CacheControllerError.atLeastOneItemFailedInFileWriter(RequestError.http(503))
        fetcher.handleFailure(with: article, error: error)

        XCTAssertEqual(article.error, .apiFailed, "A non-429 HTTP failure is still this article's problem")
        XCTAssertEqual(article.downloadAttemptCount, 1)
        XCTAssertNotNil(article.downloadRetryDate)
    }

    // MARK: - Cooldown resolution

    func testCooldownFallsBackToDefaultWithoutRetryAfter() {
        let cooldown = SavedArticlesFetcher.rateLimitCooldown(retryAfter: nil, jitter: 1)
        XCTAssertEqual(cooldown, SavedArticlesFetcher.defaultRateLimitCooldown)
    }

    func testCooldownHonoursRetryAfter() {
        let cooldown = SavedArticlesFetcher.rateLimitCooldown(retryAfter: 120, jitter: 1)
        XCTAssertEqual(cooldown, 120)
    }

    func testCooldownClampsExcessiveRetryAfter() {
        let cooldown = SavedArticlesFetcher.rateLimitCooldown(retryAfter: 86400, jitter: 1)
        XCTAssertEqual(cooldown, SavedArticlesFetcher.maximumRateLimitCooldown, "A very long Retry-After should not park downloads for hours")
    }

    func testCooldownIgnoresNonPositiveRetryAfter() {
        let cooldown = SavedArticlesFetcher.rateLimitCooldown(retryAfter: 0, jitter: 1)
        XCTAssertEqual(cooldown, SavedArticlesFetcher.defaultRateLimitCooldown)
    }

    func testCooldownAppliesJitter() {
        let cooldown = SavedArticlesFetcher.rateLimitCooldown(retryAfter: 100, jitter: 1.5)
        XCTAssertEqual(cooldown, 150)
    }
}

final class RequestErrorRateLimitTests: XCTestCase {

    private func response(headerFields: [String: String]?) throws -> HTTPURLResponse {
        try XCTUnwrap(HTTPURLResponse(
            url: URL(string: "https://en.wikipedia.org/w/api.php")!,
            statusCode: 429,
            httpVersion: "HTTP/1.1",
            headerFields: headerFields
        ))
    }

    func testFromCodeProducesRateLimitedFor429() throws {
        let error = RequestError.from(code: 429, response: try response(headerFields: ["Retry-After": "45"]))
        XCTAssertEqual(error.httpStatusCode, 429)
        XCTAssertEqual(error.retryAfterInterval, 45)
    }

    func testFromCodeProducesHTTPForOtherCodes() {
        let error = RequestError.from(code: 503)
        XCTAssertEqual(error.httpStatusCode, 503)
        XCTAssertNil(error.retryAfterInterval)
    }

    func testBareHTTP429StillReportsRateLimitedStatusCode() {
        XCTAssertEqual(RequestError.http(429).httpStatusCode, RequestError.rateLimitedStatusCode)
    }

    func testRetryAfterDeltaSeconds() throws {
        XCTAssertEqual(try response(headerFields: ["Retry-After": "90"]).retryAfterInterval, 90)
    }

    func testRetryAfterIsCaseInsensitive() throws {
        // HTTP/2 lowercases header names.
        XCTAssertEqual(try response(headerFields: ["retry-after": "90"]).retryAfterInterval, 90)
    }

    func testRetryAfterHTTPDate() throws {
        let target = Date(timeIntervalSinceNow: 120)
        let value = DateFormatter.wmf_httpDateFormatter.string(from: target)
        let interval = try XCTUnwrap(response(headerFields: ["Retry-After": value]).retryAfterInterval)
        XCTAssertEqual(interval, 120, accuracy: 2)
    }

    func testRetryAfterPastHTTPDateIsZero() throws {
        let value = DateFormatter.wmf_httpDateFormatter.string(from: Date(timeIntervalSinceNow: -120))
        XCTAssertEqual(try response(headerFields: ["Retry-After": value]).retryAfterInterval, 0)
    }

    func testRetryAfterAbsent() throws {
        XCTAssertNil(try response(headerFields: [:]).retryAfterInterval)
    }

    func testRetryAfterUnparseable() throws {
        XCTAssertNil(try response(headerFields: ["Retry-After": "soon"]).retryAfterInterval)
    }
}
