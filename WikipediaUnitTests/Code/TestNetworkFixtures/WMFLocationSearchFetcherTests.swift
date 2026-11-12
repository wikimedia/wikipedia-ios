import CoreLocation
import Foundation
import Testing
import WMFData
@testable import Wikipedia
@testable import WMF

struct WMFLocationSearchFetcherTests {
    private let taipei = CLLocation(latitude: 25.034, longitude: 121.565)

    @Test
    func nearbyAndRegionSearchesRequestVariantTitles() async throws {
        let nearby = try makeHarness(fixture: "VariantTitlesSearch")
        let region = try makeHarness(fixture: "VariantTitlesSearch")
        let siteURL = try #require(URL(string: "https://zh.wikipedia.org"))

        _ = try await fetchNearby(nearby.fetcher, siteURL: siteURL)
        _ = try await withCheckedThrowingContinuation { continuation in
            region.fetcher.fetchArticles(withSiteURL: siteURL, in: CLCircularRegion(center: taipei.coordinate, radius: 20000, identifier: ""), matchingSearchTerm: nil, sortStyle: .links, resultLimit: 24, completion: { continuation.resume(returning: $0) }, failure: { continuation.resume(throwing: $0) })
        }

        #expect(nearby.service.capturedRequests.contains { $0["generator"] as? String == "geosearch" && $0.requestsVariantTitles })
        #expect(region.service.capturedRequests.contains { $0["generator"] as? String == "search" && $0.requestsVariantTitles })
    }

    @Test
    func showsTheTitleInTheLanguageVariant() async throws {
        let harness = try makeHarness(fixture: "VariantTitlesSearch")
        var siteURL = try #require(URL(string: "https://zh.wikipedia.org"))
        siteURL.wmf_languageVariantCode = "zh-Hant-TW"

        let result = try #require(try await fetchNearby(harness.fetcher, siteURL: siteURL).results.first)

        #expect(result.title == "台北车站")
        #expect(result.displayTitle == "臺北車站")
    }

    @Test(arguments: ["en", "de"])
    func keepsTitlesForLanguagesWithoutVariants(languageCode: String) async throws {
        let harness = try makeHarness(fixture: "DisplayTitleSearch")

        let results = try await fetchNearby(harness.fetcher, siteURL: try #require(URL(string: "https://\(languageCode).wikipedia.org"))).results
            .sorted { ($0.index?.intValue ?? 0) < ($1.index?.intValue ?? 0) }

        #expect(results.map(\.title) == ["IPhone", "Homo sapiens", "Berlin"])
        #expect(results.map(\.displayTitle) == ["iPhone", "Homo sapiens", "Berlin"])
    }

    private func fetchNearby(_ fetcher: WMFLocationSearchFetcher, siteURL: URL) async throws -> WMFLocationSearchResults {
        try await withCheckedThrowingContinuation { continuation in
            fetcher.fetchArticles(withSiteURL: siteURL, location: taipei, resultLimit: 24, completion: { continuation.resume(returning: $0) }, failure: { continuation.resume(throwing: $0) })
        }
    }

    private func makeHarness(fixture: String) throws -> (fetcher: WMFLocationSearchFetcher, service: SearchFixtureService) {
        let service = SearchFixtureService()
        service.responseData = try #require(Bundle(for: SearchFixtureService.self).wmf_data(fromContentsOfFile: fixture, ofType: "json"))
        return (WMFLocationSearchFetcher(dataController: WMFArticleSearchDataController(basicService: service)), service)
    }
}
