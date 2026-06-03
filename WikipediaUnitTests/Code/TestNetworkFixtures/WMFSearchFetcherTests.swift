import Foundation
@testable import Wikipedia
@testable import WMF
import XCTest

final class WMFSearchFetcherTests: XCTestCase {
    private var fetcher: WMFSearchFetcher!
    private var httpClient: SearchHTTPClient!

    override func setUp() {
        super.setUp()

        httpClient = SearchHTTPClient()
        let session = Session(configuration: .current, httpClientProvider: SearchHTTPClientProvider(httpClient: httpClient))
        fetcher = WMFSearchFetcher(session: session, configuration: .current)
    }

    override func tearDown() {
        fetcher.cancelAllFetches()
        fetcher = nil
        httpClient = nil

        super.tearDown()
    }

    func testNonEmptyPrefixResponse() throws {
        let json = try jsonFixture(named: "BarackSearch")
        httpClient.responseData = try JSONSerialization.data(withJSONObject: json)
        let siteURL = try XCTUnwrap(URL(string: "https://en.wikipedia.org"))

        let expectation = expectation(description: "Wait for articles")

        fetcher.fetchArticles(forSearchTerm: "foo", siteURL: siteURL, resultLimit: 15, failure: { error in
            XCTFail("Expected search success, got \(error)")
            expectation.fulfill()
        }, success: { result in
            let query = json["query"] as? [String: Any]
            let pages = query?["pages"] as? [String: Any]
            XCTAssertEqual(result.results?.count, pages?.count)
            expectation.fulfill()
        })

        waitForExpectations(timeout: 10)
        XCTAssertTrue(httpClient.capturedRequests.containsPrefixSearchRequest)
    }

    func testEmptyPrefixResponse() throws {
        let json = try jsonFixture(named: "NoSearchResultsWithSuggestion")
        httpClient.responseData = try JSONSerialization.data(withJSONObject: json)
        let siteURL = try XCTUnwrap(URL(string: "https://en.wikipedia.org"))

        let expectation = expectation(description: "Wait for articles")

        fetcher.fetchArticles(forSearchTerm: "foo", siteURL: siteURL, resultLimit: 15, failure: { error in
            XCTFail("Expected search success, got \(error)")
            expectation.fulfill()
        }, success: { result in
            let query = json["query"] as? [String: Any]
            let searchInfo = query?["searchinfo"] as? [String: Any]
            XCTAssertEqual(result.searchSuggestion, searchInfo?["suggestion"] as? String)
            XCTAssertEqual(result.results?.count, 0)
            expectation.fulfill()
        })

        waitForExpectations(timeout: 10)
        XCTAssertTrue(httpClient.capturedRequests.containsPrefixSearchRequest)
    }

    private func jsonFixture(named name: String) throws -> [String: Any] {
        let data = try XCTUnwrap(wmf_bundle().wmf_data(fromContentsOfFile: name, ofType: "json"))
        return try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }
}
