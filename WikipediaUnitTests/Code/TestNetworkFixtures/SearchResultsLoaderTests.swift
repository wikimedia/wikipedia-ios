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
        #expect(outcome.prefixResultCount == 24)
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
        #expect(outcome.prefixResultCount == 5)
        #expect(outcome.type(ofRow: 4) == .prefix)
        #expect(outcome.type(ofRow: 5) == .full)
        #expect(harness.service.capturedRequests.containsFullTextSearchRequest)
    }

    @Test
    func noPrefixResultsStillShowTheFullTextResults() async throws {
        let harness = makeHarness()
        defer { harness.fetcher.cancelAllFetches() }
        harness.service.responseDataQueue = [
            try JSONSerialization.data(withJSONObject: ["batchcomplete": true]),
            try fixtureData(named: "ArticleSearchPrefixMany")
        ]

        let outcome = try await SearchResultsLoader(fetcher: harness.fetcher).fetchResults(for: "foo", siteURL: siteURL)

        #expect(outcome.type == .full)
        #expect(outcome.prefixResultCount == 0)
        #expect(outcome.results.results.count > 0)
    }

    @Test
    func fullTextResultsKeepBothSearchIDs() async throws {
        let harness = makeHarness()
        defer { harness.fetcher.cancelAllFetches() }
        harness.service.responseDataQueue = [
            try fixtureData(named: "ArticleSearchPrefixMany", limitedTo: 5),
            try fixtureData(named: "ArticleSearchPrefixMany")
        ]
        harness.service.responseHeadersQueue = [["x-search-id": "prefix-id"], ["x-search-id": "full-text-id"]]

        let outcome = try await SearchResultsLoader(fetcher: harness.fetcher).fetchResults(for: "foo", siteURL: siteURL)

        #expect(outcome.type == .full)
        #expect(outcome.results.prefixSearchID == "prefix-id")
        #expect(outcome.results.fullTextSearchID == "full-text-id")
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

    /// The API reports an error in the body of a 200 response. The loader must fail, not show an empty result.
    @Test
    func prefixAPIErrorBodyIsAPrefixFailure() async throws {
        let harness = makeHarness()
        defer { harness.fetcher.cancelAllFetches() }
        harness.service.responseData = try apiErrorBody()
        let loader = SearchResultsLoader(fetcher: harness.fetcher)

        await #expect(performing: {
            try await loader.fetchResults(for: "foo", siteURL: siteURL)
        }, throws: { error in
            guard case SearchResultsLoader.Failure.fetch(_, let type) = error else { return false }
            return type == .prefix
        })
        #expect(!harness.service.capturedRequests.containsFullTextSearchRequest)
    }

    @Test
    func fullTextAPIErrorBodyWithPrefixResultsKeepsThePrefixResults() async throws {
        let harness = makeHarness()
        defer { harness.fetcher.cancelAllFetches() }
        harness.service.responseDataQueue = [try fixtureData(named: "ArticleSearchPrefixMany", limitedTo: 3), try apiErrorBody()]
        let loader = SearchResultsLoader(fetcher: harness.fetcher)

        let outcome = try await loader.fetchResults(for: "foo", siteURL: siteURL)

        #expect(outcome.type == .prefix)
        #expect(outcome.results.results.count == 3)
        #expect(harness.service.capturedRequests.containsFullTextSearchRequest)
    }

    // MARK: - First section of a result without a lead

    @Test
    func resultsWithoutALeadOfBothListsAreFetchedInOneFollowUp() async throws {
        let harness = makeHarness()
        defer { harness.fetcher.cancelAllFetches() }
        harness.service.responseDataQueue = [
            try fixtureData(named: "ArticleSearchPrefixMany", limitedTo: 5),
            try fixtureData(named: "ArticleSearchPrefixMany")
        ]
        let calls = FollowUpCalls()
        var loader = SearchResultsLoader(fetcher: harness.fetcher)
        loader.firstSectionsProvider = { pageIDs, _ in
            await calls.append(pageIDs)
            return Dictionary(uniqueKeysWithValues: pageIDs.map { ($0, WMFArticleSearchFirstSection(snippetHTML: "Text \($0)")) })
        }

        let outcome = try await loader.fetchRawResults(for: "foo", siteURL: siteURL, resultLimit: 24, fullTextSearchThreshold: SearchResultsLoader.fullTextSearchThreshold, includesExtracts: true)

        let allIDs = (outcome.prefix.results + (outcome.fullText?.results ?? [])).map(\.articleID)
        #expect(Set(allIDs).count < allIDs.count, "The two lists share pages, so the test checks that none is asked for twice")
        let recorded = await calls.all
        #expect(recorded.count == 1, "One request for all the pages")
        #expect(recorded.first?.sorted() == Set(allIDs).sorted())
        #expect(Set(outcome.firstSectionsByPageID.keys) == Set(allIDs))
        let anyID = try #require(allIDs.first)
        #expect(outcome.firstSectionsByPageID[anyID]?.snippetHTML == "Text \(anyID)")
    }

    @Test
    func noFollowUpIsAskedForWhenTheExtractsAreNotRequested() async throws {
        let harness = makeHarness()
        defer { harness.fetcher.cancelAllFetches() }
        harness.service.responseData = try fixtureData(named: "ArticleSearchPrefixMany")
        let calls = FollowUpCalls()
        var loader = SearchResultsLoader(fetcher: harness.fetcher)
        loader.firstSectionsProvider = { pageIDs, _ in
            await calls.append(pageIDs)
            return [:]
        }

        let outcome = try await loader.fetchRawResults(for: "foo", siteURL: siteURL, resultLimit: 24, fullTextSearchThreshold: 12)

        #expect(await calls.all.isEmpty)
        #expect(outcome.firstSectionsByPageID.isEmpty)
    }

    @Test
    func aPageTheFollowUpDoesNotAnswerForIsLeftOut() async throws {
        let harness = makeHarness()
        defer { harness.fetcher.cancelAllFetches() }
        harness.service.responseData = try fixtureData(named: "ArticleSearchPrefixMany")
        var loader = SearchResultsLoader(fetcher: harness.fetcher)
        loader.firstSectionsProvider = { pageIDs, _ in
            let answered = pageIDs.prefix(2)
            return Dictionary(uniqueKeysWithValues: answered.map { ($0, WMFArticleSearchFirstSection(snippetHTML: "Text")) })
        }

        let outcome = try await loader.fetchRawResults(for: "foo", siteURL: siteURL, resultLimit: 24, fullTextSearchThreshold: 12, includesExtracts: true)

        #expect(outcome.firstSectionsByPageID.count == 2)
        #expect(outcome.prefix.results.count == 24)
    }

    @Test
    func aFailedFollowUpIsLeftOutAndTheResultsStay() async throws {
        let harness = makeHarness()
        defer { harness.fetcher.cancelAllFetches() }
        harness.service.responseData = try fixtureData(named: "ArticleSearchPrefixMany")
        var loader = SearchResultsLoader(fetcher: harness.fetcher)
        loader.firstSectionsProvider = { _, _ in throw URLError(.notConnectedToInternet) }

        let outcome = try await loader.fetchRawResults(for: "foo", siteURL: siteURL, resultLimit: 24, fullTextSearchThreshold: 12, includesExtracts: true)

        #expect(outcome.prefix.results.count == 24)
        #expect(outcome.firstSectionsByPageID.isEmpty)
    }

    private func apiErrorBody() throws -> Data {
        try JSONSerialization.data(withJSONObject: [
            "errors": [["code": "cirrussearch-backend-error", "html": "Search is currently too busy.", "module": "query+prefixsearch"]]
        ])
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

private actor FollowUpCalls {
    private var calls: [[Int]] = []

    func append(_ pageIDs: [Int]) {
        calls.append(pageIDs)
    }

    var all: [[Int]] {
        calls
    }
}

/// Holds every request until `cancelAllFetches()` fails it with a cancellation error.
private final class GatedSearchFetcher: WMFSearchFetcher {
    private let lock = NSLock()
    private var pendingFailures: [(Error) -> Void] = []
    private(set) var requestCount = 0
    private(set) var cancelAllFetchesCount = 0

    override func fetchArticles(forSearchTerm searchTerm: String, siteURL: URL, resultLimit: UInt, fullTextSearch: Bool, appendToPreviousResults previousResults: WMFSearchResults?, includesExtracts: Bool = false, failure: @escaping (Error) -> Void, success: @escaping (WMFSearchResults) -> Void) {
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
