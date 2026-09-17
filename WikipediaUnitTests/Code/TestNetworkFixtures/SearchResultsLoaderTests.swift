import Foundation
import Testing
@testable import Wikipedia
@testable import WMF

struct SearchResultsLoaderTests {

    @Test
    func enoughPrefixResultsSkipTheFullTextSearch() async throws {
        let harness = makeHarness()
        defer { harness.fetcher.cancelAllFetches() }
        harness.httpClient.responseData = try fixtureData(named: "BarackSearch")

        let outcome = try await SearchResultsLoader(fetcher: harness.fetcher).fetchResults(for: "foo", siteURL: siteURL)

        #expect(outcome.type == .prefix)
        #expect(outcome.results.results?.count == 24)
        #expect(!harness.httpClient.capturedRequests.containsFullTextSearchRequest)
    }

    @Test
    func fewPrefixResultsTriggerTheFullTextSearch() async throws {
        let harness = makeHarness()
        defer { harness.fetcher.cancelAllFetches() }
        harness.httpClient.responseDataQueue = [try fixtureData(named: "BarackSearch", limitedTo: 5), try fixtureData(named: "BarackSearch")]

        let outcome = try await SearchResultsLoader(fetcher: harness.fetcher).fetchResults(for: "foo", siteURL: siteURL)

        #expect(outcome.type == .full)
        #expect((outcome.results.results?.count ?? 0) > 5)
        #expect(harness.httpClient.capturedRequests.containsFullTextSearchRequest)
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

    private func makeHarness() -> (fetcher: WMFSearchFetcher, httpClient: SearchHTTPClient) {
        let httpClient = SearchHTTPClient()
        let session = Session(configuration: .current, httpClientProvider: SearchHTTPClientProvider(httpClient: httpClient))
        let fetcher = WMFSearchFetcher(session: session, configuration: .current)
        return (fetcher, httpClient)
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
