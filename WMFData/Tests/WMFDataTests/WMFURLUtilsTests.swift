import XCTest
@testable import WMFData

final class WMFURLUtilsTests: XCTestCase {

    // MARK: - String.denormalizedPageTitle

    func testDenormalizedPageTitleReplacesSpacesWithUnderscores() {
        XCTAssertEqual("San Francisco".denormalizedPageTitle, "San_Francisco")
        XCTAssertEqual("A B C".denormalizedPageTitle, "A_B_C")
    }

    func testDenormalizedPageTitleLeavesTitleWithoutSpacesUnchanged() {
        XCTAssertEqual("Already_Underscored".denormalizedPageTitle, "Already_Underscored")
        XCTAssertEqual("Cat".denormalizedPageTitle, "Cat")
    }

    func testDenormalizedPageTitleAppliesCanonicalComposition() {
        // Decomposed "e" + combining acute accent should compose to precomposed "é".
        let decomposed = "Beyonce\u{0301}"
        XCTAssertEqual(decomposed.unicodeScalars.count, 8)

        let result = decomposed.denormalizedPageTitle
        XCTAssertEqual(result, "Beyonc\u{00E9}")
        XCTAssertEqual(result.unicodeScalars.count, 7)
    }

    // MARK: - URL.wmfURL(withTitle:languageVariantCode:)

    func testWMFURLBuildsCanonicalWikiPath() throws {
        let base = try XCTUnwrap(URL(string: "https://en.wikipedia.org"))
        let url = base.wmfURL(withTitle: "San Francisco")
        XCTAssertEqual(url?.absoluteString, "https://en.wikipedia.org/wiki/San_Francisco")
    }

    func testWMFURLDiscardsExistingPath() throws {
        let base = try XCTUnwrap(URL(string: "https://en.wikipedia.org/wiki/Existing_Article"))
        let url = base.wmfURL(withTitle: "Cat")
        XCTAssertEqual(url?.absoluteString, "https://en.wikipedia.org/wiki/Cat")
    }

    func testWMFURLReturnsNilWhenSchemeMissing() throws {
        let base = try XCTUnwrap(URL(string: "/wiki/Cat"))
        XCTAssertNil(base.wmfURL(withTitle: "Cat"))
    }

    func testWMFURLReturnsNilWhenHostMissing() throws {
        let base = try XCTUnwrap(URL(string: "mailto:someone@example.com"))
        XCTAssertNil(base.wmfURL(withTitle: "Cat"))
    }
}
