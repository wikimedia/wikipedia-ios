import Foundation
import Testing
@testable import Wikipedia
@testable import WMF

struct SearchResultsLoaderTests {

    @Test
    func enoughPrefixResultsSkipTheFullTextSearch() async throws {
        let harness = makeHarness()
        defer { harness.fetcher.cancelAllFetches() }
        harness.httpClient.responseData = try searchData(pageCount: 30)

        let outcome = try await SearchResultsLoader(fetcher: harness.fetcher).fetchResults(for: "foo", siteURL: siteURL)

        #expect(outcome.type == .prefix)
        #expect(outcome.results.results?.count == 30)
        #expect(outcome.prefixResultCount == 30)
        #expect(harness.httpClient.capturedRequests.first?.queryParameters["gpslimit"] == "30")
        #expect(!harness.httpClient.capturedRequests.containsFullTextSearchRequest)
    }

    @Test
    func fullTextResultsAppendToAPrefixResponseWithoutQuery() async throws {
        let harness = makeHarness()
        defer { harness.fetcher.cancelAllFetches() }
        harness.httpClient.responseDataQueue = [try searchData(pageCount: 0), try searchData(pageCount: 5, titlePrefix: "Full text", firstPageID: 1000)]

        let outcome = try await SearchResultsLoader(fetcher: harness.fetcher).fetchResults(for: "foo", siteURL: siteURL)

        #expect(outcome.type == .full)
        #expect(outcome.prefixResultCount == 0)
        #expect(outcome.results.results?.count == 5)
    }

    @Test
    func fewerPrefixResultsThanAndroidsFirstPageTriggerTheFullTextSearch() async throws {
        let harness = makeHarness()
        defer { harness.fetcher.cancelAllFetches() }
        harness.httpClient.responseDataQueue = [try fixtureData(named: "BarackSearch"), try searchData(pageCount: 30, titlePrefix: "Full text", firstPageID: 1000)]

        let outcome = try await SearchResultsLoader(fetcher: harness.fetcher).fetchResults(for: "foo", siteURL: siteURL)

        #expect(outcome.type == .full)
        #expect(outcome.prefixResultCount == 24)
        #expect(outcome.results.results?.count == 54)
        let fullTextRequest = try #require(harness.httpClient.capturedRequests.last)
        #expect(fullTextRequest.queryParameters["generator"] == "search")
        #expect(fullTextRequest.queryParameters["gsrlimit"] == "30")
        #expect(fullTextRequest.queryParameters["gsroffset"] == "0")
    }

    @Test
    func fewPrefixResultsTriggerTheFullTextSearch() async throws {
        let harness = makeHarness()
        defer { harness.fetcher.cancelAllFetches() }
        harness.httpClient.responseDataQueue = [try fixtureData(named: "BarackSearch", limitedTo: 5), try fixtureData(named: "BarackSearch")]

        let outcome = try await SearchResultsLoader(fetcher: harness.fetcher).fetchResults(for: "foo", siteURL: siteURL)

        #expect(outcome.type == .full)
        #expect((outcome.results.results?.count ?? 0) > 5)
        #expect(outcome.prefixResultCount == 5)
        #expect(outcome.type(ofRow: 4) == .prefix)
        #expect(outcome.type(ofRow: 5) == .full)
        #expect(harness.httpClient.capturedRequests.containsFullTextSearchRequest)
    }

    @Test
    func fullTextResultsKeepBothSearchIDs() async throws {
        let harness = makeHarness()
        defer { harness.fetcher.cancelAllFetches() }
        harness.httpClient.responseDataQueue = [try fixtureData(named: "BarackSearch", limitedTo: 5), try fixtureData(named: "BarackSearch")]
        harness.httpClient.responseHeadersQueue = [["x-search-id": "prefix-id"], ["x-search-id": "full-text-id"]]

        let outcome = try await SearchResultsLoader(fetcher: harness.fetcher).fetchResults(for: "foo", siteURL: siteURL)

        #expect(outcome.type == .full)
        #expect(outcome.results.prefixSearchID == "prefix-id")
        #expect(outcome.results.fullTextSearchID == "full-text-id")
    }

    @Test
    func fullTextFailureFallsBackToThePrefixResults() async throws {
        let harness = makeHarness()
        defer { harness.fetcher.cancelAllFetches() }
        harness.httpClient.responseDataQueue = [try fixtureData(named: "BarackSearch", limitedTo: 5), Data("not json".utf8)]

        let outcome = try await SearchResultsLoader(fetcher: harness.fetcher).fetchResults(for: "foo", siteURL: siteURL)

        #expect(outcome.type == .prefix)
        #expect(outcome.results.results?.count == 5)
    }

    @Test
    func fullTextFailureWithoutPrefixResultsIsAFullTextFailure() async throws {
        let harness = makeHarness()
        defer { harness.fetcher.cancelAllFetches() }
        harness.httpClient.responseDataQueue = [try fixtureData(named: "NoSearchResultsWithSuggestion"), Data("not json".utf8)]
        let loader = SearchResultsLoader(fetcher: harness.fetcher)

        await #expect(performing: {
            try await loader.fetchResults(for: "foo", siteURL: siteURL)
        }, throws: { error in
            guard case SearchResultsLoader.Failure.fetch(_, let type) = error else { return false }
            return type == .full
        })
    }

    @Test
    func prefixFailureIsAPrefixFailure() async throws {
        let harness = makeHarness()
        defer { harness.fetcher.cancelAllFetches() }
        harness.httpClient.responseData = Data("not json".utf8)
        let loader = SearchResultsLoader(fetcher: harness.fetcher)

        await #expect(performing: {
            try await loader.fetchResults(for: "foo", siteURL: siteURL)
        }, throws: { error in
            guard case SearchResultsLoader.Failure.fetch(_, let type) = error else { return false }
            return type == .prefix
        })
        #expect(!harness.httpClient.capturedRequests.containsFullTextSearchRequest)
    }

    private var siteURL: URL {
        URL(string: "https://en.wikipedia.org")!
    }

    @Test
    func cancelledTaskDoesNotStartAnyRequest() async {
        let fetcher = GatedSearchFetcher()
        let loader = SearchResultsLoader(fetcher: fetcher)

        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await loader.fetchResults(for: "foo", siteURL: siteURL)
        }

        await #expect(throws: CancellationError.self) {
            try await task.value
        }
        #expect(fetcher.requestCount == 0)
    }

    @Test
    func cancellationDuringThePrefixSearchCancelsTheFetcher() async {
        let fetcher = GatedSearchFetcher()
        let loader = SearchResultsLoader(fetcher: fetcher)

        let task = Task {
            try await loader.fetchResults(for: "foo", siteURL: siteURL)
        }
        while fetcher.requestCount == 0 {
            await Task.yield()
        }
        task.cancel()

        await #expect(throws: CancellationError.self) {
            try await task.value
        }
        #expect(fetcher.requestCount == 1)
        #expect(fetcher.cancelAllFetchesCount == 1)
    }

    private func makeHarness() -> (fetcher: WMFSearchFetcher, httpClient: SearchHTTPClient) {
        let httpClient = SearchHTTPClient()
        let session = Session(configuration: .current, httpClientProvider: SearchHTTPClientProvider(httpClient: httpClient))
        let fetcher = WMFSearchFetcher(session: session, configuration: .current)
        return (fetcher, httpClient)
    }

    /// A response with `pageCount` pages titled "<titlePrefix> <n>", plus a `continue` when `nextOffset` is set.
    private func searchData(pageCount: Int, titlePrefix: String = "Page", firstPageID: Int = 1, nextOffset: Int? = nil) throws -> Data {
        var json: [String: Any] = ["batchcomplete": ""]
        if pageCount > 0 {
            let pages = (1...pageCount).map { index -> (String, Any) in
                let pageID = firstPageID + index - 1
                return ("\(pageID)", ["pageid": pageID, "ns": 0, "title": "\(titlePrefix) \(index)", "index": index])
            }
            json["query"] = ["pages": Dictionary(uniqueKeysWithValues: pages)]
        }
        if let nextOffset {
            json["continue"] = ["gsroffset": nextOffset, "continue": "gsroffset||"]
        }
        return try JSONSerialization.data(withJSONObject: json)
    }

    private func fixtureData(named name: String, limitedTo pageLimit: Int? = nil) throws -> Data {
        let data = try #require(Bundle(for: SearchResultsLoaderTestBundleToken.self).wmf_data(fromContentsOfFile: name, ofType: "json"))
        guard let pageLimit else { return data }
        var json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        var query = try #require(json["query"] as? [String: Any])
        let pages = try #require(query["pages"] as? [String: Any])
        query["pages"] = Dictionary(uniqueKeysWithValues: pages.sorted { $0.key < $1.key }.prefix(pageLimit).map { ($0.key, $0.value) })
        json["query"] = query
        return try JSONSerialization.data(withJSONObject: json)
    }
}

private final class SearchResultsLoaderTestBundleToken {}

/// Holds every request until `cancelAllFetches()` fails it with a cancellation error.
private final class GatedSearchFetcher: WMFSearchFetcher {
    private let lock = NSLock()
    private var pendingFailures: [(Error) -> Void] = []
    private(set) var requestCount = 0
    private(set) var cancelAllFetchesCount = 0

    override func fetchArticles(forSearchTerm searchTerm: String, siteURL: URL, resultLimit: UInt, fullTextSearch: Bool, offset: UInt, appendToPreviousResults previousResults: WMFSearchResults?, failure: @escaping WMFErrorHandler, success: @escaping WMFSearchResultsHandler) {
        lock.lock()
        requestCount += 1
        pendingFailures.append(failure)
        lock.unlock()
    }

    override func cancelAllFetches() {
        lock.lock()
        cancelAllFetchesCount += 1
        let failures = pendingFailures
        pendingFailures.removeAll()
        lock.unlock()
        for failure in failures {
            failure(NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled))
        }
    }
}
