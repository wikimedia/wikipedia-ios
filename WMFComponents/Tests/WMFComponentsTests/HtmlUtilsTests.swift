import XCTest
@testable import WMFComponents

final class HtmlUtilsTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testStringFromHtml() {
        let text = "Testing here with <b>tags</b> &amp; &quot;multiple&quot; entities."
        let expectedText = "Testing here with tags & \"multiple\" entities."
        let result = try? HtmlUtils.stringFromHTML(text)
        XCTAssertNotNil(result, "Unexpected result when attempting to strip html and entities.")
        XCTAssertEqual(result, expectedText, "Unexpected result when attempting to strip html and entities.")
    }

}
