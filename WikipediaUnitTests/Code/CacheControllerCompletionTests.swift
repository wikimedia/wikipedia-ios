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

    private func makeController(shouldDownloadVariant: Bool = true) -> CacheController {
        let dbWriter = FakeCacheDBWriter(context: context, fetcher: fetcher, shouldDownload: shouldDownloadVariant)
        let fileWriter = CacheFileWriter(fetcher: fetcher)
        return CacheController(dbWriter: dbWriter, fileWriter: fileWriter)
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

    private let queue = DispatchQueue(label: "FakeCacheFetcher", attributes: .concurrent)

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
        queue.asyncAfter(deadline: .now() + delay) {
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
