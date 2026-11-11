import XCTest
import WMFData
@testable import Wikipedia
@testable import WMF

class RateLimitSummaryAccumulatorTests: XCTestCase {

    private func pattern(_ string: String) throws -> String {
        RateLimitSummaryAccumulator.endpointPattern(for: try XCTUnwrap(URL(string: string)))
    }

    func testEndpointPatternDropsTitlesRevisionsAndDates() throws {
        XCTAssertEqual(try pattern("https://en.wikipedia.org/api/rest_v1/page/mobile-html/Villa_Savoye"), "page/mobile-html")
        XCTAssertEqual(try pattern("https://en.wikipedia.org/api/rest_v1/page/mobile-html/Villa_Savoye/1364999716"), "page/mobile-html")
        XCTAssertEqual(try pattern("https://en.wikipedia.org/api/rest_v1/page/media-list/New_York_City"), "page/media-list")
        XCTAssertEqual(try pattern("https://meta.wikimedia.org/api/rest_v1/data/javascript/mobile/mathjax/sre/mathmaps/en.json"), "data/javascript")
        XCTAssertEqual(try pattern("https://en.wikipedia.org/api/rest_v1/feed/featured/2026/10/16"), "feed/featured")
        XCTAssertEqual(try pattern("https://en.wikipedia.org/api/rest_v1/data/lists/"), "data/lists")
        XCTAssertEqual(try pattern("https://en.wikipedia.org/w/api.php?action=query&list=search&srsearch=rome"), "api.php?action=query")
        XCTAssertEqual(try pattern("https://en.wikipedia.org/w/rest.php/v1/search/page?q=rome"), "rest.php/v1/search")
        XCTAssertEqual(RateLimitSummaryAccumulator.hostAndEndpoint(from: nil).host, "unknown")
    }

    func testRecordsPerHostAndHandsBackTheSummaryOnce() {
        var accumulator = RateLimitSummaryAccumulator()
        for _ in 0..<40 { accumulator.record(urlString: "https://en.wikipedia.org/api/rest_v1/page/mobile-html/A") }
        for _ in 0..<8 { accumulator.record(urlString: "https://en.wikipedia.org/api/rest_v1/page/media-list/B") }
        accumulator.record(urlString: "https://meta.wikimedia.org/api/rest_v1/data/javascript/mobile/pcs")

        let english = try! XCTUnwrap(accumulator.take(host: "en.wikipedia.org"))
        XCTAssertEqual(english.droppedCount, 48)
        XCTAssertEqual(english.endpointsValue, "page/mobile-html:40,page/media-list:8")
        XCTAssertEqual(ClientErrorFunnel.summaryContext(english)["dropped_429_count"], "48")
        XCTAssertNil(accumulator.take(host: "en.wikipedia.org"), "A summary is handed back once")

        let remaining = accumulator.takeAll()
        XCTAssertEqual(remaining.keys.sorted(), ["meta.wikimedia.org"])
        XCTAssertEqual(remaining["meta.wikimedia.org"]?.endpointsValue, "data/javascript:1")
        XCTAssertTrue(accumulator.takeAll().isEmpty, "takeAll resets the accumulator")
    }
}
