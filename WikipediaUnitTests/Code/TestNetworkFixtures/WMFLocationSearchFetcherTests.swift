import CoreLocation
import Foundation
import Testing
import WMFData
@testable import Wikipedia
@testable import WMF

struct WMFLocationSearchFetcherTests {

    /// The API reports an error in the body of a 200 response. Places shows the error in a toast and
    /// offers the "Did you mean" search only for the "No results found" error.
    @Test
    func apiErrorBodyBecomesTheNoResultsError() async throws {
        let service = SearchFixtureService()
        service.responseData = try JSONSerialization.data(withJSONObject: [
            "errors": [["code": "cirrussearch-regex-too-complex-error", "html": "Regular expression is too complex.", "module": "query+geosearch"]]
        ])
        let fetcher = WMFLocationSearchFetcher(dataController: WMFArticleSearchDataController(basicService: service))
        let region = CLCircularRegion(center: CLLocationCoordinate2D(latitude: 51.5, longitude: -0.12), radius: 1000, identifier: "")

        let error = await failure(of: fetcher, in: region)

        let nserror = try #require(error) as NSError
        #expect(nserror.domain == WMFLocationSearchErrorDomain)
        #expect(nserror.code == Int(WMFLocationSearchErrorCode.noResults.rawValue))
        #expect(!nserror.localizedDescription.contains("WMFDataControllerError"))
    }

    @Test
    func networkErrorReachesTheCallerUnchanged() {
        let networkError = URLError(.notConnectedToInternet)

        let error = WMFLocationSearchFetcher.failureError(for: networkError) as NSError

        #expect(error.domain == NSURLErrorDomain)
        #expect(error.code == URLError.notConnectedToInternet.rawValue)
    }

    @Test
    func otherErrorBecomesTheNoResultsError() {
        let error = WMFLocationSearchFetcher.failureError(for: WMFDataControllerError.unexpectedResponse) as NSError

        #expect(error.domain == WMFLocationSearchErrorDomain)
        #expect(error.code == Int(WMFLocationSearchErrorCode.noResults.rawValue))
    }

    private func failure(of fetcher: WMFLocationSearchFetcher, in region: CLCircularRegion) async -> Error? {
        await withCheckedContinuation { continuation in
            fetcher.fetchArticles(withSiteURL: URL(string: "https://en.wikipedia.org")!, in: region, matchingSearchTerm: "x", sortStyle: .links, resultLimit: 50, completion: { _ in
                continuation.resume(returning: nil)
            }, failure: { error in
                continuation.resume(returning: error)
            })
        }
    }
}
