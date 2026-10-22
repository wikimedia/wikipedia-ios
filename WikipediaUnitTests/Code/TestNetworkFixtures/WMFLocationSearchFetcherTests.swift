import CoreLocation
import Foundation
import Testing
@testable import Wikipedia
@testable import WMF

struct WMFLocationSearchFetcherTests {
    private let taipei = CLLocation(latitude: 25.034, longitude: 121.565)

    @Test
    func nearbyAndRegionSearchesRequestVariantTitles() async throws {
        let nearby = try makeHarness(fixture: "VariantTitlesSearch")
        let region = try makeHarness(fixture: "VariantTitlesSearch")
        defer {
            nearby.fetcher.cancelAllFetches()
            region.fetcher.cancelAllFetches()
        }
        let siteURL = try #require(URL(string: "https://zh.wikipedia.org"))

        _ = try await fetchNearby(nearby.fetcher, siteURL: siteURL)
        _ = try await withCheckedThrowingContinuation { continuation in
            region.fetcher.fetchArticles(withSiteURL: siteURL, in: CLCircularRegion(center: taipei.coordinate, radius: 20000, identifier: ""), matchingSearchTerm: nil, sortStyle: .links, resultLimit: 24, completion: { continuation.resume(returning: $0) }, failure: { continuation.resume(throwing: $0) })
        }

        #expect(nearby.httpClient.capturedRequests.containsVariantTitlesRequest(generator: "geosearch"))
        #expect(region.httpClient.capturedRequests.containsVariantTitlesRequest(generator: "search"))
    }

    @Test
    func showsTheTitleInTheLanguageVariant() async throws {
        let harness = try makeHarness(fixture: "VariantTitlesSearch")
        defer {
            harness.fetcher.cancelAllFetches()
        }
        var siteURL = try #require(URL(string: "https://zh.wikipedia.org"))
        siteURL.wmf_languageVariantCode = "zh-Hant-TW"

        let result = try #require(try await fetchNearby(harness.fetcher, siteURL: siteURL).results.first)

        #expect(result.title == "台北车站")
        #expect(result.displayTitle == "臺北車站")
    }

    @Test(arguments: ["en", "de"])
    func keepsTitlesForLanguagesWithoutVariants(languageCode: String) async throws {
        let harness = try makeHarness(fixture: "DisplayTitleSearch")
        defer {
            harness.fetcher.cancelAllFetches()
        }

        let results = try await fetchNearby(harness.fetcher, siteURL: try #require(URL(string: "https://\(languageCode).wikipedia.org"))).results
            .sorted { ($0.index?.intValue ?? 0) < ($1.index?.intValue ?? 0) }

        #expect(results.map(\.title) == ["IPhone", "Homo sapiens", "Berlin"])
        #expect(results.map(\.displayTitle) == ["iPhone", "Homo sapiens", "Berlin"])
    }

    /// Places saves recent searches, including their search result, in WMFKeyValue, which decodes them with SecureUnarchiveFromDataTransformer
    @Test
    func recentPlaceSearchWithAVariantResultDecodes() async throws {
        let harness = try makeHarness(fixture: "VariantTitlesSearch")
        defer {
            harness.fetcher.cancelAllFetches()
        }
        var siteURL = try #require(URL(string: "https://zh.wikipedia.org"))
        siteURL.wmf_languageVariantCode = "zh-Hant-TW"
        let result = try #require(try await fetchNearby(harness.fetcher, siteURL: siteURL).results.first)
        let placeSearch = PlaceSearch(filter: .top, type: .location, origin: .user, sortStyle: .links, string: nil, region: nil, localizedDescription: result.displayTitle, searchResult: result, siteURL: siteURL)

        let data = try NSKeyedArchiver.archivedData(withRootObject: placeSearch.dictionaryValue as NSDictionary, requiringSecureCoding: true)
        let decoded = try #require(PlaceSearch(object: SecureUnarchiveFromDataTransformer().transformedValue(data) as? NSCoding))

        #expect(decoded.searchResult?.title == "台北车站")
        #expect(decoded.searchResult?.displayTitle == "臺北車站")
    }

    private func fetchNearby(_ fetcher: WMFLocationSearchFetcher, siteURL: URL) async throws -> WMFLocationSearchResults {
        try await withCheckedThrowingContinuation { continuation in
            fetcher.fetchArticles(withSiteURL: siteURL, location: taipei, resultLimit: 24, completion: { continuation.resume(returning: $0) }, failure: { continuation.resume(throwing: $0) })
        }
    }

    private func makeHarness(fixture: String) throws -> (fetcher: WMFLocationSearchFetcher, httpClient: SearchHTTPClient) {
        let httpClient = SearchHTTPClient()
        httpClient.responseData = try #require(Bundle(for: SearchHTTPClient.self).wmf_data(fromContentsOfFile: fixture, ofType: "json"))
        let session = Session(configuration: .current, httpClientProvider: SearchHTTPClientProvider(httpClient: httpClient))
        return (WMFLocationSearchFetcher(session: session, configuration: .current), httpClient)
    }
}
