import XCTest
import CoreData
@testable import Wikipedia
@testable import WMF

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

    // note, the group completion must be queued on the gatekeeper the way add does it - finishDBAdd runs those, not the block it is handed
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

        // give a duplicate a chance to land before asserting - without this the "fires
        // exactly once" tests cannot fail on a double fire, which is the point of them
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertEqual(callCount, 1, "The group completion must fire exactly once")

        return groupResult
    }

    func testGroupCompletionReportsEveryRequestWhenTheyCompleteAtDifferentTimes() throws {
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

// note, concrete members are declared here so the `where Self: Fetcher` defaults, which reach for a permanent cache that doesn't exist in tests, are bypassed
private final class FakeCacheFetcher: Fetcher, CacheFetching {

    var completionDelay: (Int) -> TimeInterval = { _ in 0 }
    var shouldFail = false

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
            // note, the slot is released inside completion's chain, so this must decrement
            // first or the next request starts before the count drops
            guard !shouldFail,
                  let url = urlRequest.url,
                  let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: nil) else {
                self?.requestFinished()
                completion(.failure(CacheFetchingError.missingURLResponse))
                return
            }
            self?.requestFinished()
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


final class CacheRequestThrottleTests: XCTestCase {

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
        XCTAssertEqual(throttle.inFlightCount(for: "group"), 1, "The second piece of work should be waiting, not running")

        release?()
        wait(for: [secondStarted], timeout: 10)
    }
}
