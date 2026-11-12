import Foundation
import WMFData

/// A WMFData service that answers each search request with fixture data.
///
/// The search fetcher now gets its data from `WMFArticleSearchDataController`, not from a
/// `Session`. Therefore the search tests inject this service instead of an HTTP client.
final class SearchFixtureService: WMFService, @unchecked Sendable {

    private let lock = NSLock()
    private var queue: [Data] = []
    private var single: Data?
    private var captured: [[String: Any]] = []
    private var headersQueue: [[String: String]] = []

    /// The data for every request. `responseDataQueue` takes priority.
    var responseData: Data? {
        get { lock.withLock { single } }
        set { lock.withLock { single = newValue } }
    }

    /// The data for each request in order. The last value answers any further request.
    var responseDataQueue: [Data] {
        get { lock.withLock { queue } }
        set { lock.withLock { queue = newValue } }
    }

    /// The parameters of each request, in order.
    var capturedRequests: [[String: Any]] {
        lock.withLock { captured }
    }

    /// The response headers for each request in order. A later request gets none.
    var responseHeadersQueue: [[String: String]] {
        get { lock.withLock { headersQueue } }
        set { lock.withLock { headersQueue = newValue } }
    }

    private func nextHeaders() -> [String: String] {
        lock.withLock {
            headersQueue.isEmpty ? [:] : headersQueue.removeFirst()
        }
    }

    private func nextData(for request: any WMFServiceRequest) -> Data? {
        lock.withLock {
            captured.append(request.parameters ?? [:])
            if queue.isEmpty {
                return single
            }
            return queue.count == 1 ? queue[0] : queue.removeFirst()
        }
    }

    // MARK: - WMFService

    func perform<R: WMFServiceRequest>(request: R, completion: @escaping (Result<Data, Error>) -> Void) {
        guard let data = nextData(for: request) else {
            return completion(.failure(SearchFixtureServiceError.noFixture))
        }
        completion(.success(data))
    }

    func perform<R: WMFServiceRequest>(request: R, completion: @escaping (Result<[String: Any]?, Error>) -> Void) {
        guard let data = nextData(for: request) else {
            return completion(.failure(SearchFixtureServiceError.noFixture))
        }
        completion(.success(try? JSONSerialization.jsonObject(with: data) as? [String: Any]))
    }

    func performDecodableGET<R: WMFServiceRequest, T: Decodable>(request: R, completion: @escaping (Result<T, Error>) -> Void) {
        guard let data = nextData(for: request) else {
            return completion(.failure(SearchFixtureServiceError.noFixture))
        }
        do {
            completion(.success(try JSONDecoder().decode(T.self, from: data)))
        } catch {
            completion(.failure(error))
        }
    }

    func performDecodablePOST<R: WMFServiceRequest, T: Decodable>(request: R, completion: @escaping (Result<T, Error>) -> Void) {
        performDecodableGET(request: request, completion: completion)
    }

    /// The search reads the CirrusSearch request id from the response headers. Thus the fixture
    /// service must answer with headers.
    func performCancellableDecodableGETWithResponse<R: WMFServiceRequest, T: Decodable & Sendable>(
        request: R,
        completion: @escaping @Sendable (Result<WMFServiceResponse<T>, Error>) -> Void
    ) -> WMFURLSessionDataTask? {
        guard let data = nextData(for: request) else {
            completion(.failure(SearchFixtureServiceError.noFixture))
            return nil
        }
        do {
            let value = try JSONDecoder().decode(T.self, from: data)
            completion(.success(WMFServiceResponse(value: value, headers: nextHeaders())))
        } catch {
            completion(.failure(error))
        }
        return nil
    }

    func clearCachedData() {
    }
}

enum SearchFixtureServiceError: Error {
    case noFixture
}

extension Array where Element == [String: Any] {
    /// `true` when one request used the full text search generator.
    var containsFullTextSearchRequest: Bool {
        contains { ($0["generator"] as? String) == "search" }
    }

    /// `true` when one request used the title prefix generator.
    var containsPrefixSearchRequest: Bool {
        contains { ($0["generator"] as? String) == "prefixsearch" }
    }
}

extension Dictionary where Key == String, Value == Any {
    /// `true` when the request asks for each page's title in every language variant.
    var requestsVariantTitles: Bool {
        (self["prop"] as? String)?.split(separator: "|").contains("info") == true && self["inprop"] as? String == "varianttitles"
    }
}

private extension NSLock {
    func withLock<T>(_ body: () -> T) -> T {
        lock()
        defer { unlock() }
        return body()
    }
}
