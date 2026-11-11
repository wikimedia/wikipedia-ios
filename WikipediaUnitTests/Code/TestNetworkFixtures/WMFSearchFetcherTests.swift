import Foundation
import Testing
import WMFData
@testable import Wikipedia
@testable import WMF

struct WMFSearchFetcherTests {
    @Test
    func nonEmptyPrefixResponse() async throws {
        let harness = try makeHarness(fixture: "ArticleSearchPrefix")
        defer {
            harness.fetcher.cancelAllFetches()
        }
        let siteURL = try #require(URL(string: "https://en.wikipedia.org"))

        let result = try await harness.fetcher.fetchArticles(forSearchTerm: "Barack", siteURL: siteURL, resultLimit: 15)

        let query = harness.json["query"] as? [String: Any]
        let pages = query?["pages"] as? [[String: Any]]
        #expect(result.results.count == pages?.count)
        #expect(result.results.first?.displayTitle == "Barack Obama")
        #expect(result.results.map { $0.index?.intValue } == [1, 2, 3, 4, 5, 6])
        #expect(result.redirectMappings.first?.redirectFromTitle == "Barack Hussein Obama")
        #expect(result.searchTerm == "Barack")
        #expect(harness.service.capturedParameters?["generator"] as? String == "prefixsearch")
    }

    @Test
    func emptyPrefixResponse() async throws {
        let harness = try makeHarness(fixture: "ArticleSearchEmpty")
        defer {
            harness.fetcher.cancelAllFetches()
        }
        let siteURL = try #require(URL(string: "https://en.wikipedia.org"))

        let result = try await harness.fetcher.fetchArticles(forSearchTerm: "asad", siteURL: siteURL, resultLimit: 15)

        #expect(result.results.isEmpty)
        #expect(harness.service.capturedParameters?["generator"] as? String == "prefixsearch")
    }

    @Test
    func fullTextResponseMergesIntoPreviousResults() async throws {
        let harness = try makeHarness(fixture: "ArticleSearchPrefix")
        defer {
            harness.fetcher.cancelAllFetches()
        }
        let siteURL = try #require(URL(string: "https://en.wikipedia.org"))
        let previous = try await harness.fetcher.fetchArticles(forSearchTerm: "Barack", siteURL: siteURL, resultLimit: 15)
        let previousCount = previous.results.count

        let merged = try await harness.fetcher.fetchArticles(forSearchTerm: "Barack", siteURL: siteURL, resultLimit: 15, fullTextSearch: true, appendToPreviousResults: previous)

        #expect(merged === previous)
        #expect(merged.results.count == previousCount, "Results with a known display title are not added twice")
        #expect(harness.service.capturedParameters?["generator"] as? String == "search")
    }

    // MARK: - The CirrusSearch request id

    @Test
    func prefixResponseKeepsItsSearchID() async throws {
        let harness = try makeHarness(fixture: "ArticleSearchPrefix")
        defer {
            harness.fetcher.cancelAllFetches()
        }
        harness.service.headersQueue = [["X-Search-Id": "292nfmbhub08hd5are0cajr22"]]
        let siteURL = try #require(URL(string: "https://en.wikipedia.org"))

        let result = try await harness.fetcher.fetchArticles(forSearchTerm: "foo", siteURL: siteURL, resultLimit: 15)

        #expect(result.prefixSearchID == "292nfmbhub08hd5are0cajr22", "The header name is not case sensitive")
        #expect(result.fullTextSearchID == nil)
    }

    @Test
    func fullTextResponseKeepsItsOwnSearchID() async throws {
        let harness = try makeHarness(fixture: "ArticleSearchPrefix")
        defer {
            harness.fetcher.cancelAllFetches()
        }
        harness.service.headersQueue = [["x-search-id": "prefix-id"], ["x-search-id": "full-text-id"]]
        let siteURL = try #require(URL(string: "https://en.wikipedia.org"))

        let previous = try await harness.fetcher.fetchArticles(forSearchTerm: "foo", siteURL: siteURL, resultLimit: 15)
        let merged = try await harness.fetcher.fetchArticles(forSearchTerm: "foo", siteURL: siteURL, resultLimit: 15, fullTextSearch: true, appendToPreviousResults: previous)

        #expect(merged.prefixSearchID == "prefix-id")
        #expect(merged.fullTextSearchID == "full-text-id")
    }

    @Test
    func responseWithoutTheHeaderHasNoSearchID() async throws {
        let harness = try makeHarness(fixture: "ArticleSearchPrefix")
        defer {
            harness.fetcher.cancelAllFetches()
        }
        let siteURL = try #require(URL(string: "https://en.wikipedia.org"))

        let result = try await harness.fetcher.fetchArticles(forSearchTerm: "foo", siteURL: siteURL, resultLimit: 15)

        #expect(result.prefixSearchID == nil)
    }

    @Test
    func prefixRequestDoesNotAskForASuggestion() async throws {
        let harness = try makeHarness(fixture: "ArticleSearchPrefix")
        defer {
            harness.fetcher.cancelAllFetches()
        }
        let siteURL = try #require(URL(string: "https://en.wikipedia.org"))

        _ = try await harness.fetcher.fetchArticles(forSearchTerm: "foo", siteURL: siteURL, resultLimit: 15)

        let parameters = try #require(harness.service.capturedParameters)
        #expect(parameters["generator"] as? String == "prefixsearch")
        #expect(parameters["list"] == nil)
        #expect(parameters.keys.allSatisfy { !$0.hasPrefix("sr") })
    }

    // MARK: - A response that has no query

    @Test
    func prefixResponseWithoutQueryKeepsTheSearchTerm() async throws {
        let harness = try makeHarness(data: try JSONSerialization.data(withJSONObject: ["batchcomplete": true]))
        defer {
            harness.fetcher.cancelAllFetches()
        }
        let siteURL = try #require(URL(string: "https://en.wikipedia.org"))

        let result = try await harness.fetcher.fetchArticles(forSearchTerm: "foo", siteURL: siteURL, resultLimit: 15)

        #expect(result.results.isEmpty)
        #expect(result.searchTerm == "foo")
    }

    @Test
    func fullTextResultsMergeIntoAPrefixResponseWithoutQuery() async throws {
        let fixture = try fixtureData(named: "ArticleSearchPrefix")
        let harness = try makeHarness(dataQueue: [try JSONSerialization.data(withJSONObject: ["batchcomplete": true]), fixture])
        defer {
            harness.fetcher.cancelAllFetches()
        }
        let siteURL = try #require(URL(string: "https://en.wikipedia.org"))

        let prefixResults = try await harness.fetcher.fetchArticles(forSearchTerm: "foo", siteURL: siteURL, resultLimit: 15)
        let result = try await harness.fetcher.fetchArticles(forSearchTerm: "foo", siteURL: siteURL, resultLimit: 15, fullTextSearch: true, appendToPreviousResults: prefixResults)

        let json = try #require(try JSONSerialization.jsonObject(with: fixture) as? [String: Any])
        let pages = (json["query"] as? [String: Any])?["pages"] as? [[String: Any]]
        #expect(result.results.count == pages?.count)
        #expect(result.searchTerm == "foo")
    }

    // MARK: - Harness

    private struct Harness {
        let fetcher: WMFSearchFetcher
        let service: FixtureService
        let json: [String: Any]
    }

    private func makeHarness(fixture: String) throws -> Harness {
        let data = try fixtureData(named: fixture)
        let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        return makeHarness(data: data, json: json)
    }

    private func makeHarness(data: Data, json: [String: Any] = [:]) -> Harness {
        let service = FixtureService(data: data)
        let fetcher = WMFSearchFetcher(dataController: WMFArticleSearchDataController(basicService: service))
        return Harness(fetcher: fetcher, service: service, json: json)
    }

    /// Answers each request with the next value. The last value answers any further request.
    private func makeHarness(dataQueue: [Data]) throws -> Harness {
        let service = FixtureService(data: try #require(dataQueue.first))
        service.dataQueue = dataQueue
        let fetcher = WMFSearchFetcher(dataController: WMFArticleSearchDataController(basicService: service))
        return Harness(fetcher: fetcher, service: service, json: [:])
    }

    private func fixtureData(named name: String) throws -> Data {
        try #require(Bundle(for: WMFSearchFetcherTestBundleToken.self).wmf_data(fromContentsOfFile: name, ofType: "json"))
    }
}

private final class WMFSearchFetcherTestBundleToken {}

/// A service that answers every request with one fixture.
private final class FixtureService: WMFService, @unchecked Sendable {
    private let data: Data
    private(set) var capturedParameters: [String: Any]?

    /// The data for each request in order. The last value answers any further request.
    var dataQueue: [Data] = []
    /// The response headers for each request in order. A later request gets none.
    var headersQueue: [[String: String]] = []

    init(data: Data) {
        self.data = data
    }

    private func nextData() -> Data {
        if dataQueue.isEmpty {
            return data
        }
        return dataQueue.count == 1 ? dataQueue[0] : dataQueue.removeFirst()
    }

    private func nextHeaders() -> [String: String] {
        headersQueue.isEmpty ? [:] : headersQueue.removeFirst()
    }

    func perform<R: WMFServiceRequest>(request: R, completion: @escaping (Result<Data, Error>) -> Void) {
        capturedParameters = request.parameters
        completion(.success(nextData()))
    }

    func perform<R: WMFServiceRequest>(request: R, completion: @escaping (Result<[String: Any]?, Error>) -> Void) {
        capturedParameters = request.parameters
        completion(.success(try? JSONSerialization.jsonObject(with: nextData()) as? [String: Any]))
    }

    func performDecodableGET<R: WMFServiceRequest, T: Decodable>(request: R, completion: @escaping (Result<T, Error>) -> Void) {
        capturedParameters = request.parameters
        do {
            completion(.success(try JSONDecoder().decode(T.self, from: nextData())))
        } catch {
            completion(.failure(error))
        }
    }

    /// The search reads the CirrusSearch request id from the response headers.
    func performCancellableDecodableGETWithResponse<R: WMFServiceRequest, T: Decodable & Sendable>(
        request: R,
        completion: @escaping @Sendable (Result<WMFServiceResponse<T>, Error>) -> Void
    ) -> WMFURLSessionDataTask? {
        capturedParameters = request.parameters
        do {
            let value = try JSONDecoder().decode(T.self, from: nextData())
            completion(.success(WMFServiceResponse(value: value, headers: nextHeaders())))
        } catch {
            completion(.failure(error))
        }
        return nil
    }

    func performDecodablePOST<R: WMFServiceRequest, T: Decodable>(request: R, completion: @escaping (Result<T, Error>) -> Void) {
        performDecodableGET(request: request, completion: completion)
    }

    func clearCachedData() {
    }
}

private extension WMFSearchFetcher {
    func fetchArticles(forSearchTerm searchTerm: String, siteURL: URL, resultLimit: UInt) async throws -> WMFSearchResults {
        try await withCheckedThrowingContinuation { continuation in
            fetchArticles(forSearchTerm: searchTerm, siteURL: siteURL, resultLimit: resultLimit, failure: { error in
                continuation.resume(throwing: error)
            }, success: { result in
                continuation.resume(returning: result)
            })
        }
    }

    func fetchArticles(forSearchTerm searchTerm: String, siteURL: URL, resultLimit: UInt, fullTextSearch: Bool, appendToPreviousResults previous: WMFSearchResults?) async throws -> WMFSearchResults {
        try await withCheckedThrowingContinuation { continuation in
            fetchArticles(forSearchTerm: searchTerm, siteURL: siteURL, resultLimit: resultLimit, fullTextSearch: fullTextSearch, appendToPreviousResults: previous, failure: { error in
                continuation.resume(throwing: error)
            }, success: { result in
                continuation.resume(returning: result)
            })
        }
    }
}
