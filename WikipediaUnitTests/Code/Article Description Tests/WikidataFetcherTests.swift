import XCTest
@testable import Wikipedia
@testable import WMF

class WikidataFetcherTests: XCTestCase {

    func testPublishResultDecodesLastRevisionID() throws {
        let json = """
        {"entity":{"descriptions":{"pt":{"language":"pt","value":"extensão do padrão PAL"}},"id":"Q1657380","type":"item","lastrevid":2094832199},"success":1}
        """
        let result = try JSONDecoder().decode(WikidataFetcher.WikidataAPIPublishResult.self, from: Data(json.utf8))
        XCTAssertTrue(result.succeeded)
        XCTAssertEqual(result.entity?.lastrevid, 2094832199)
    }

    func testPublishResultToleratesMissingEntity() throws {
        let json = """
        {"success":1}
        """
        let result = try JSONDecoder().decode(WikidataFetcher.WikidataAPIPublishResult.self, from: Data(json.utf8))
        XCTAssertTrue(result.succeeded)
        XCTAssertNil(result.entity?.lastrevid)
    }
}
