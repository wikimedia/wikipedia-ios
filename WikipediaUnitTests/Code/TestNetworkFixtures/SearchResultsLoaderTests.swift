import Foundation
import Testing
import WMFData
@testable import Wikipedia
@testable import WMF

struct SearchResultsLoaderTests {

    @Test
    func enoughPrefixResultsSkipTheFullTextSearch() async throws {
        let harness = makeHarness()
        defer { harness.fetcher.cancelAllFetches() }
        harness.service.responseData = try fixtureData(named: "ArticleSearchPrefixMany")

        let outcome = try await SearchResultsLoader(fetcher: harness.fetcher).fetchResults(for: "foo", siteURL: siteURL)

        #expect(outcome.type == .prefix)
        #expect(outcome.results.results.count == 24)
        #expect(!harness.service.capturedRequests.containsFullTextSearchRequest)
    }

    @Test
    func fewPrefixResultsTriggerTheFullTextSearch() async throws {
        let harness = makeHarness()
        defer { harness.fetcher.cancelAllFetches() }
        harness.service.responseDataQueue = [
            try fixtureData(named: "ArticleSearchPrefixMany", limitedTo: 5),
            try fixtureData(named: "ArticleSearchPrefixMany")
        ]

        let outcome = try await SearchResultsLoader(fetcher: harness.fetcher).fetchResults(for: "foo", siteURL: siteURL)

        #expect(outcome.type == .full)
        #expect(outcome.results.results.count > 5)
        #expect(harness.service.capturedRequests.containsFullTextSearchRequest)
    }

    @Test
    func fullTextFailureFallsBackToThePrefixResults() async throws {
        let harness = makeHarness()
        defer { harness.fetcher.cancelAllFetches() }
        harness.service.responseDataQueue = [
            try fixtureData(named: "ArticleSearchPrefixMany", limitedTo: 5),
            Data("not json".utf8)
        ]

        let outcome = try await SearchResultsLoader(fetcher: harness.fetcher).fetchResults(for: "foo", siteURL: siteURL)

        #expect(outcome.type == .prefix)
        #expect(outcome.results.results.count == 5)
    }

    @Test
    func fullTextFailureWithoutPrefixResultsIsAFullTextFailure() async throws {
        let harness = makeHarness()
        defer { harness.fetcher.cancelAllFetches() }
        harness.service.responseDataQueue = [try fixtureData(named: "ArticleSearchEmpty"), Data("not json".utf8)]
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
        harness.service.responseData = Data("not json".utf8)
        let loader = SearchResultsLoader(fetcher: harness.fetcher)

        await #expect(performing: {
            try await loader.fetchResults(for: "foo", siteURL: siteURL)
        }, throws: { error in
            guard case SearchResultsLoader.Failure.fetch(_, let type) = error else { return false }
            return type == .prefix
        })
        #expect(!harness.service.capturedRequests.containsFullTextSearchRequest)
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

    /// The fetcher now reads from a WMFData data controller, so the test injects a service
    /// instead of an HTTP client.
    private func makeHarness() -> (fetcher: WMFSearchFetcher, service: SearchFixtureService) {
        let service = SearchFixtureService()
        let fetcher = WMFSearchFetcher(dataController: WMFArticleSearchDataController(basicService: service))
        return (fetcher, service)
    }

    private func fixtureData(named name: String, limitedTo pageLimit: Int? = nil) throws -> Data {
        let data = try #require(Bundle(for: SearchResultsLoaderTestBundleToken.self).wmf_data(fromContentsOfFile: name, ofType: "json"))
        guard let pageLimit else { return data }
        var json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        var query = try #require(json["query"] as? [String: Any])
        let pages = try #require(query["pages"] as? [[String: Any]])
        query["pages"] = Array(pages.prefix(pageLimit))
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

    override func fetchArticles(forSearchTerm searchTerm: String, siteURL: URL, resultLimit: UInt, fullTextSearch: Bool, appendToPreviousResults previousResults: WMFSearchResults?, failure: @escaping (Error) -> Void, success: @escaping (WMFSearchResults) -> Void) {
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
