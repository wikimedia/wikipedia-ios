import Foundation
import Testing
@testable import Wikipedia
@testable import WMF

struct WMFSearchFetcherTests {
    @Test
    func nonEmptyPrefixResponse() async throws {
        let json = try jsonFixture(named: "BarackSearch")
        let harness = makeHarness()
        defer {
            harness.fetcher.cancelAllFetches()
        }
        harness.httpClient.responseData = try JSONSerialization.data(withJSONObject: json)
        let siteURL = try #require(URL(string: "https://en.wikipedia.org"))

        let result = try await harness.fetcher.fetchArticles(forSearchTerm: "foo", siteURL: siteURL, resultLimit: 15)

        let query = json["query"] as? [String: Any]
        let pages = query?["pages"] as? [String: Any]
        #expect(result.results?.count == pages?.count)
        #expect(harness.httpClient.capturedRequests.containsPrefixSearchRequest)
    }

    @Test
    func emptyPrefixResponse() async throws {
        let json = try jsonFixture(named: "NoSearchResultsWithSuggestion")
        let harness = makeHarness()
        defer {
            harness.fetcher.cancelAllFetches()
        }
        harness.httpClient.responseData = try JSONSerialization.data(withJSONObject: json)
        let siteURL = try #require(URL(string: "https://en.wikipedia.org"))

        let result = try await harness.fetcher.fetchArticles(forSearchTerm: "foo", siteURL: siteURL, resultLimit: 15)

        let query = json["query"] as? [String: Any]
        let searchInfo = query?["searchinfo"] as? [String: Any]
        #expect(result.searchSuggestion == searchInfo?["suggestion"] as? String)
        #expect(result.results?.count == 0)
        #expect(harness.httpClient.capturedRequests.containsPrefixSearchRequest)
    }

    @Test(arguments: [("zh-Hant-TW", "臺北車站"), (nil, "台北车站")] as [(String?, String)])
    func showsTheTitleInTheLanguageVariant(languageVariantCode: String?, displayTitle: String) async throws {
        let harness = makeHarness()
        defer {
            harness.fetcher.cancelAllFetches()
        }
        harness.httpClient.responseData = try JSONSerialization.data(withJSONObject: jsonFixture(named: "VariantTitlesSearch"))
        var siteURL = try #require(URL(string: "https://zh.wikipedia.org"))
        siteURL.wmf_languageVariantCode = languageVariantCode

        let result = try #require(try await harness.fetcher.fetchArticles(forSearchTerm: "foo", siteURL: siteURL, resultLimit: 15).results?.first)

        #expect(harness.httpClient.capturedRequests.containsVariantTitlesRequest(generator: "prefixsearch"))
        #expect(result.title == "台北车站")
        #expect(result.displayTitle == displayTitle)
    }

    @Test(arguments: ["en", "de"])
    func keepsTitlesForLanguagesWithoutVariants(languageCode: String) async throws {
        let harness = makeHarness()
        defer {
            harness.fetcher.cancelAllFetches()
        }
        harness.httpClient.responseData = try JSONSerialization.data(withJSONObject: jsonFixture(named: "DisplayTitleSearch"))
        let siteURL = try #require(URL(string: "https://\(languageCode).wikipedia.org"))

        let results = try #require(try await harness.fetcher.fetchArticles(forSearchTerm: "foo", siteURL: siteURL, resultLimit: 15).results)

        #expect(results.map(\.title) == ["IPhone", "Homo sapiens", "Berlin"])
        #expect(results.map(\.displayTitle) == ["iPhone", "Homo sapiens", "Berlin"])
        #expect(results.map(\.displayTitleHTML) == ["iPhone", "<i>Homo sapiens</i>", "Berlin"])
    }

    private func makeHarness() -> (fetcher: WMFSearchFetcher, httpClient: SearchHTTPClient) {
        let httpClient = SearchHTTPClient()
        let session = Session(configuration: .current, httpClientProvider: SearchHTTPClientProvider(httpClient: httpClient))
        let fetcher = WMFSearchFetcher(session: session, configuration: .current)
        return (fetcher, httpClient)
    }

    private func jsonFixture(named name: String) throws -> [String: Any] {
        let data = try #require(Bundle(for: WMFSearchFetcherTestBundleToken.self).wmf_data(fromContentsOfFile: name, ofType: "json"))
        let jsonObject = try JSONSerialization.jsonObject(with: data)
        return try #require(jsonObject as? [String: Any])
    }
}

private final class WMFSearchFetcherTestBundleToken {}
