import XCTest
import CoreData
@testable import Wikipedia
@testable import WMF

/// Covers the completion contract of `CacheController.finishDBAdd`.
///
/// `finishDBAdd` used to register `group.notify` inside its request loop, so the
/// group completion could fire before every request had been issued, and never fired
/// at all when the request list was empty or every request was skipped. These tests
/// drive it directly with fakes rather than going near the network.
final class CacheControllerCompletionTests: XCTestCase {

    private var context: NSManagedObjectContext!
    private var fetcher: FakeCacheFetcher!

    override func setUpWithError() throws {
        let directory = URL(fileURLWithPath: WMFRandomTemporaryPath())
        context = try XCTUnwrap(CacheController.createCacheContext(cacheURL: directory))
        fetcher = FakeCacheFetcher(session: Session(configuration: Configuration.current), configuration: Configuration.current)
    }

    override func tearDown() {
        context = nil
        fetcher = nil
        super.tearDown()
    }

    private func makeController(shouldDownloadVariant: Bool = true, throttle: CacheRequestThrottle = CacheRequestThrottle()) -> CacheController {
        let dbWriter = FakeCacheDBWriter(context: context, fetcher: fetcher, shouldDownload: shouldDownloadVariant)
        let fileWriter = CacheFileWriter(fetcher: fetcher)
        return CacheController(dbWriter: dbWriter, fileWriter: fileWriter, throttle: throttle)
    }

    private func requests(_ count: Int) -> [URLRequest] {
        (0..<count).map { URLRequest(url: URL(string: "https://en.wikipedia.org/resource/\($0)")!) }
    }

    /// Runs `finishDBAdd` and returns the single group result it produces.
    /// The group completion has to be queued on the gatekeeper the way `add` does it —
    /// `finishDBAdd` runs gatekeeper-queued completions, not the block it is handed.
    private func runFinishDBAdd(
        controller: CacheController,
        groupKey: String,
        result: CacheDBWritingResultWithURLRequests,
        timeout: TimeInterval = 10
    ) -> CacheController.FinalGroupResult? {
        let expectation = expectation(description: "group completion fires")
        var groupResult: CacheController.FinalGroupResult?
        var callCount = 0

        controller.gatekeeper.queueGroupCompletion(groupKey: groupKey) { result in
            callCount += 1
            groupResult = result
            if callCount == 1 {
                expectation.fulfill()
            }
        }

        controller.finishDBAdd(
            groupKey: groupKey,
            individualCompletion: { _ in },
            groupCompletion: { _ in },
            result: result
        )

        wait(for: [expectation], timeout: timeout)
        return groupResult
    }

    func testGroupCompletionReportsEveryRequestWhenTheyCompleteAtDifferentTimes() throws {
        // The premature-fire bug showed up here: staggered completions let the group
        // reach zero while the loop was still issuing requests, so the result carried
        // only the handful that had finished.
        fetcher.completionDelay = { index in Double(index % 5) * 0.01 }
        let controller = makeController()

        let result = try XCTUnwrap(runFinishDBAdd(controller: controller, groupKey: "staggered", result: .success(requests(20))))

        switch result {
        case .success(let uniqueKeys):
            XCTAssertEqual(Set(uniqueKeys).count, 20, "Every request should be represented in the group result")
        case .failure(let error):
            XCTFail("Expected success, got \(error)")
        }
    }

    func testGroupCompletionFiresForAnEmptyRequestList() throws {
        let controller = makeController()

        let result = try XCTUnwrap(runFinishDBAdd(controller: controller, groupKey: "empty", result: .success([])))

        switch result {
        case .success(let uniqueKeys):
            XCTAssertTrue(uniqueKeys.isEmpty)
        case .failure(let error):
            XCTFail("An empty request list should succeed, got \(error)")
        }
    }

    func testGroupCompletionFiresWhenNoVariantShouldBeDownloaded() throws {
        // Every iteration hits the shouldDownloadVariant guard, so nothing is issued.
        let controller = makeController(shouldDownloadVariant: false)

        let result = try XCTUnwrap(runFinishDBAdd(controller: controller, groupKey: "skipped", result: .success(requests(5))))

        switch result {
        case .success(let uniqueKeys):
            XCTAssertTrue(uniqueKeys.isEmpty)
        case .failure(let error):
            XCTFail("Skipping every variant should still complete, got \(error)")
        }
    }

    func testGroupCompletionFiresWhenEveryRequestFails() throws {
        fetcher.shouldFail = true
        let controller = makeController()

        let result = try XCTUnwrap(runFinishDBAdd(controller: controller, groupKey: "failing", result: .success(requests(5))))

        switch result {
        case .success:
            XCTFail("Expected a failure when every request fails")
        case .failure(let error):
            guard case CacheControllerError.atLeastOneItemFailedInFileWriter = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testThrottleBoundsConcurrentRequestsForOneGroup() throws {
        // Requests hold their slot for long enough that an unbounded loop would have
        // all 12 in flight at once.
        fetcher.completionDelay = { _ in 0.05 }
        let controller = makeController(throttle: CacheRequestThrottle(maxConcurrentRequestsPerGroup: 3))

        let result = try XCTUnwrap(runFinishDBAdd(controller: controller, groupKey: "bounded", result: .success(requests(12))))

        XCTAssertLessThanOrEqual(fetcher.peakConcurrentRequests, 3, "The throttle should cap in-flight requests per group")
        switch result {
        case .success(let uniqueKeys):
            XCTAssertEqual(Set(uniqueKeys).count, 12, "Queued requests should still all run")
        case .failure(let error):
            XCTFail("Expected success, got \(error)")
        }
    }

    func testGroupCompletionForwardsDBWriterFailure() throws {
        let controller = makeController()

        let result = try XCTUnwrap(runFinishDBAdd(controller: controller, groupKey: "dbfail", result: .failure(CacheFetchingError.missingURLResponse)))

        switch result {
        case .success:
            XCTFail("Expected the db writer failure to be forwarded")
        case .failure:
            break
        }
    }
}

// MARK: - Fakes

/// A `Fetcher` that conforms to `CacheFetching` with its own concrete members, so the
/// `where Self: Fetcher` defaults (which all reach for a permanent cache that does not
/// exist here) are bypassed for everything this path touches.
private final class FakeCacheFetcher: Fetcher, CacheFetching {

    /// Per-request delay before the completion fires, keyed by the index encoded in the URL.
    var completionDelay: (Int) -> TimeInterval = { _ in 0 }
    var shouldFail = false

    /// Highest number of requests this fetcher had in flight at once.
    private(set) var peakConcurrentRequests = 0
    private var inFlight = 0

    private let queue = DispatchQueue(label: "FakeCacheFetcher", attributes: .concurrent)
    private let countingQueue = DispatchQueue(label: "FakeCacheFetcher.counting")

    private func requestStarted() {
        countingQueue.sync {
            inFlight += 1
            peakConcurrentRequests = max(peakConcurrentRequests, inFlight)
        }
    }

    private func requestFinished() {
        countingQueue.sync { inFlight -= 1 }
    }

    private func index(for urlRequest: URLRequest) -> Int {
        Int(urlRequest.url?.lastPathComponent ?? "") ?? 0
    }

    private func key(for urlRequest: URLRequest) -> String? {
        urlRequest.url?.absoluteString.addingPercentEncoding(withAllowedCharacters: .alphanumerics)
    }

    @discardableResult
    func dataForURLRequest(_ urlRequest: URLRequest, completion: @escaping DataCompletion) -> URLSessionTask? {
        let delay = completionDelay(index(for: urlRequest))
        let shouldFail = self.shouldFail
        requestStarted()
        queue.asyncAfter(deadline: .now() + delay) { [weak self] in
            defer {
                self?.requestFinished()
            }
            guard !shouldFail,
                  let url = urlRequest.url,
                  let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: nil) else {
                completion(.failure(CacheFetchingError.missingURLResponse))
                return
            }
            completion(.success(CacheFetchingResult(data: Data("body".utf8), response: response)))
        }
        return nil
    }

    func cacheResponse(httpUrlResponse: HTTPURLResponse, content: CacheResponseContentType, urlRequest: URLRequest, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        success()
    }

    func uniqueFileNameForURLRequest(_ urlRequest: URLRequest) -> String? {
        key(for: urlRequest)
    }

    func uniqueFileNameForItemKey(_ itemKey: CacheController.ItemKey, variant: String?) -> String? {
        itemKey
    }

    func uniqueHeaderFileNameForItemKey(_ itemKey: CacheController.ItemKey, variant: String?) -> String? {
        itemKey + "__header"
    }

    func itemKeyForURLRequest(_ urlRequest: URLRequest) -> String? {
        key(for: urlRequest)
    }

    func variantForURLRequest(_ urlRequest: URLRequest) -> String? {
        nil
    }
}

private final class FakeCacheDBWriter: CacheDBWriting {

    var groupedTasks: [String: [IdentifiedTask]] = [:]

    let context: NSManagedObjectContext
    let fetcher: CacheFetching
    private let shouldDownload: Bool

    init(context: NSManagedObjectContext, fetcher: CacheFetching, shouldDownload: Bool) {
        self.context = context
        self.fetcher = fetcher
        self.shouldDownload = shouldDownload
    }

    func add(url: URL, groupKey: CacheController.GroupKey, completion: @escaping CacheDBWritingCompletionWithURLRequests) {
        completion(.success([URLRequest(url: url)]))
    }

    func add(urls: [URL], groupKey: CacheController.GroupKey, completion: @escaping CacheDBWritingCompletionWithURLRequests) {
        completion(.success(urls.map { URLRequest(url: $0) }))
    }

    func shouldDownloadVariant(itemKey: CacheController.ItemKey, variant: String?) -> Bool {
        shouldDownload
    }

    func shouldDownloadVariant(urlRequest: URLRequest) -> Bool {
        shouldDownload
    }

    func shouldDownloadVariantForAllVariantItems(variant: String?, _ allVariantItems: [CacheController.ItemKeyAndVariant]) -> Bool {
        shouldDownload
    }

    func markDownloaded(urlRequest: URLRequest, response: HTTPURLResponse?, completion: @escaping (CacheDBWritingResult) -> Void) {
        completion(.success)
    }
}


/// Unit tests for the limiter itself, independent of the cache controller.
final class CacheRequestThrottleTests: XCTestCase {

    /// Tracks how many pieces of work are running at once.
    private final class ConcurrencyRecorder {
        private let queue = DispatchQueue(label: "ConcurrencyRecorder")
        private var current = 0
        private(set) var peak = 0

        func started() {
            queue.sync {
                current += 1
                peak = max(peak, current)
            }
        }

        func finished() {
            queue.sync { current -= 1 }
        }

        var peakValue: Int {
            queue.sync { peak }
        }
    }

    func testNeverExceedsTheBoundAndStillRunsEverything() {
        let throttle = CacheRequestThrottle(maxConcurrentRequestsPerGroup: 4)
        let recorder = ConcurrencyRecorder()
        let workQueue = DispatchQueue(label: "work", attributes: .concurrent)
        let allDone = expectation(description: "all work runs")
        allDone.expectedFulfillmentCount = 30

        for _ in 0..<30 {
            throttle.enqueue(groupKey: "group") { done in
                recorder.started()
                workQueue.asyncAfter(deadline: .now() + 0.01) {
                    recorder.finished()
                    allDone.fulfill()
                    done()
                }
            }
        }

        wait(for: [allDone], timeout: 20)
        XCTAssertLessThanOrEqual(recorder.peakValue, 4)
    }

    func testReleasingASlotTwiceDoesNotWidenTheBound() {
        let throttle = CacheRequestThrottle(maxConcurrentRequestsPerGroup: 2)
        let recorder = ConcurrencyRecorder()
        let workQueue = DispatchQueue(label: "work", attributes: .concurrent)
        let allDone = expectation(description: "all work runs")
        allDone.expectedFulfillmentCount = 12

        for _ in 0..<12 {
            throttle.enqueue(groupKey: "group") { done in
                recorder.started()
                workQueue.asyncAfter(deadline: .now() + 0.01) {
                    recorder.finished()
                    allDone.fulfill()
                    // Success and failure arrive on different queues in the real path,
                    // so a doubled release is plausible and must not free two slots.
                    done()
                    done()
                }
            }
        }

        wait(for: [allDone], timeout: 20)
        XCTAssertLessThanOrEqual(recorder.peakValue, 2)
    }

    func testGroupsHaveIndependentBudgets() {
        let throttle = CacheRequestThrottle(maxConcurrentRequestsPerGroup: 1)
        let firstStarted = expectation(description: "first group starts")
        let secondStarted = expectation(description: "second group starts")

        // Neither call the done block, so each group keeps its only slot occupied.
        throttle.enqueue(groupKey: "a") { _ in firstStarted.fulfill() }
        throttle.enqueue(groupKey: "b") { _ in secondStarted.fulfill() }

        wait(for: [firstStarted, secondStarted], timeout: 10)
        XCTAssertEqual(throttle.inFlightCount(for: "a"), 1)
        XCTAssertEqual(throttle.inFlightCount(for: "b"), 1)
    }

    func testWorkBeyondTheBoundWaitsForASlot() {
        let throttle = CacheRequestThrottle(maxConcurrentRequestsPerGroup: 1)
        let firstStarted = expectation(description: "first starts")
        let secondStarted = expectation(description: "second starts once a slot frees")

        var release: (() -> Void)?
        throttle.enqueue(groupKey: "group") { done in
            release = done
            firstStarted.fulfill()
        }
        wait(for: [firstStarted], timeout: 10)

        throttle.enqueue(groupKey: "group") { _ in secondStarted.fulfill() }
        // inFlightCount hops onto the same serial queue as enqueue, so this observes
        // the state after the enqueue above rather than racing it.
        XCTAssertEqual(throttle.inFlightCount(for: "group"), 1, "The second piece of work should be waiting, not running")

        release?()
        wait(for: [secondStarted], timeout: 10)
    }
}

/// Covers splitting a batched `imageinfo` response into the per-title bodies the
/// offline gallery reads back. A key mismatch here fails silently — captions just
/// stop appearing offline — so the title mapping is tested directly.
final class ImageInfoResponseSplitterTests: XCTestCase {

    private func page(id: String, title: String, description: String) -> [String: Any] {
        [
            "pageid": Int(id) ?? 0,
            "title": title,
            "imageinfo": [[
                "url": "https://upload.wikimedia.org/\(title).jpg",
                "extmetadata": ["ImageDescription": ["value": description]]
            ]]
        ]
    }

    private func response(pages: [String: Any], normalized: [[String: String]]? = nil) -> [String: Any] {
        var query: [String: Any] = ["pages": pages]
        if let normalized = normalized {
            query["normalized"] = normalized
        }
        return ["query": query]
    }

    func testSplitsOneBodyPerRequestedTitle() throws {
        let batch = response(pages: [
            "1": page(id: "1", title: "File:A.jpg", description: "a"),
            "2": page(id: "2", title: "File:B.jpg", description: "b")
        ])

        let result = try ImageInfoResponseSplitter.split(response: batch, requestedTitles: ["File:A.jpg", "File:B.jpg"])

        XCTAssertEqual(Set(result.bodiesByRequestedTitle.keys), ["File:A.jpg", "File:B.jpg"])
        XCTAssertTrue(result.missingTitles.isEmpty)
    }

    func testEachBodyKeepsTheShapeTheReadPathParses() throws {
        let batch = response(pages: [
            "1": page(id: "1", title: "File:A.jpg", description: "a"),
            "2": page(id: "2", title: "File:B.jpg", description: "b")
        ])

        let result = try ImageInfoResponseSplitter.split(response: batch, requestedTitles: ["File:A.jpg"])
        let body = try XCTUnwrap(result.bodiesByRequestedTitle["File:A.jpg"])
        let parsed = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])

        // MWKImageInfoFetcher.responseObjectForJSON: reads exactly query.pages.
        let pages = try XCTUnwrap((parsed["query"] as? [String: Any])?["pages"] as? [String: Any])
        XCTAssertEqual(pages.count, 1, "A split body should carry only its own page")
        let onlyPage = try XCTUnwrap(pages["1"] as? [String: Any])
        XCTAssertEqual(onlyPage["title"] as? String, "File:A.jpg")
    }

    func testMapsTitlesTheAPINormalised() throws {
        // The API rewrites underscores to spaces and reports it in query.normalized.
        let batch = response(
            pages: ["7": page(id: "7", title: "File:Some Image.jpg", description: "x")],
            normalized: [["from": "File:Some_Image.jpg", "to": "File:Some Image.jpg"]]
        )

        let result = try ImageInfoResponseSplitter.split(response: batch, requestedTitles: ["File:Some_Image.jpg"])

        XCTAssertNotNil(result.bodiesByRequestedTitle["File:Some_Image.jpg"], "The body should be keyed by the title we asked for, not the normalised one")
        XCTAssertTrue(result.missingTitles.isEmpty)
    }

    func testUnderscoreAndSpaceFormsMatchWithoutANormalisedSection() throws {
        let batch = response(pages: ["7": page(id: "7", title: "File:Some Image.jpg", description: "x")])

        let result = try ImageInfoResponseSplitter.split(response: batch, requestedTitles: ["File:Some_Image.jpg"])

        XCTAssertNotNil(result.bodiesByRequestedTitle["File:Some_Image.jpg"])
    }

    func testReportsTitlesWithNoPage() throws {
        let batch = response(pages: ["1": page(id: "1", title: "File:A.jpg", description: "a")])

        let result = try ImageInfoResponseSplitter.split(response: batch, requestedTitles: ["File:A.jpg", "File:Gone.jpg"])

        XCTAssertEqual(result.missingTitles, ["File:Gone.jpg"])
        XCTAssertNil(result.bodiesByRequestedTitle["File:Gone.jpg"])
    }

    func testThrowsOnAResponseWithNoPages() {
        XCTAssertThrowsError(try ImageInfoResponseSplitter.split(response: ["query": [:]], requestedTitles: ["File:A.jpg"]))
    }

    func testDropsHeadersThatDescribeTheBatch() throws {
        let url = try XCTUnwrap(URL(string: "https://en.wikipedia.org/w/api.php"))
        let response = try XCTUnwrap(HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: [
                "Etag": "\"batch-etag\"",
                "Content-Length": "4096",
                "Content-Type": "application/json"
            ]
        ))

        let fields = ImageInfoResponseSplitter.perTitleHeaderFields(from: response)

        // Etag belongs to the batch URL and is read back into If-None-Match;
        // Content-Length describes the batch body.
        XCTAssertNil(fields.first { $0.key.lowercased() == "etag" })
        XCTAssertNil(fields.first { $0.key.lowercased() == "content-length" })
        XCTAssertEqual(fields["Content-Type"], "application/json")
    }

    func testBatchSizeIsWithinTheAPILimit() {
        XCTAssertLessThanOrEqual(ArticleCacheDBWriter.imageInfoBatchSize, 50, "MWKImageInfoFetcher asserts at most 50 titles per request")
        XCTAssertGreaterThan(ArticleCacheDBWriter.imageInfoBatchSize, 1, "A batch of one would be no better than the per-image requests this replaces")
    }
}
