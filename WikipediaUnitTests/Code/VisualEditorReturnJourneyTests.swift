import XCTest
@testable import Wikipedia

final class VisualEditorReturnJourneyTests: XCTestCase {

    private func returnJourney(for urlString: String) throws -> VisualEditorReturnJourney? {
        let url = try XCTUnwrap(URL(string: urlString))
        return VisualEditorReturnJourney(url: url)
    }

    func testPublishedEditWithRevision() throws {
        let journey = try XCTUnwrap(returnJourney(for: "https://en.wikipedia.org/wiki/Cat?saved=true&revision=12345"))
        XCTAssertTrue(journey.saved)
        XCTAssertEqual(journey.revisionID, 12345)
        XCTAssertEqual(journey.articleURL.absoluteString, "https://en.wikipedia.org/wiki/Cat")
    }

    func testPublishedEditWithoutRevision() throws {
        let journey = try XCTUnwrap(returnJourney(for: "https://en.wikipedia.org/wiki/Cat?saved=true"))
        XCTAssertTrue(journey.saved)
        XCTAssertNil(journey.revisionID)
        XCTAssertEqual(journey.articleURL.absoluteString, "https://en.wikipedia.org/wiki/Cat")
    }

    func testAbandonedEdit() throws {
        let journey = try XCTUnwrap(returnJourney(for: "https://en.wikipedia.org/wiki/Cat?saved=false"))
        XCTAssertFalse(journey.saved)
        XCTAssertNil(journey.revisionID)
    }

    func testAbandonedEditIgnoresRevision() throws {
        let journey = try XCTUnwrap(returnJourney(for: "https://en.wikipedia.org/wiki/Cat?saved=false&revision=12345"))
        XCTAssertFalse(journey.saved)
        XCTAssertNil(journey.revisionID)
    }

    func testRevisionWithoutSavedIsTreatedAsPublished() throws {
        let journey = try XCTUnwrap(returnJourney(for: "https://en.wikipedia.org/wiki/Cat?revision=12345"))
        XCTAssertTrue(journey.saved)
        XCTAssertEqual(journey.revisionID, 12345)
    }

    func testMalformedRevisionFallsBackToNil() throws {
        let journey = try XCTUnwrap(returnJourney(for: "https://en.wikipedia.org/wiki/Cat?saved=true&revision=abc"))
        XCTAssertTrue(journey.saved)
        XCTAssertNil(journey.revisionID)
    }

    func testMalformedSavedWithoutRevisionIsNotAReturnJourney() throws {
        XCTAssertNil(try returnJourney(for: "https://en.wikipedia.org/wiki/Cat?saved=maybe"))
    }

    func testURLWithoutQueryIsNotAReturnJourney() throws {
        XCTAssertNil(try returnJourney(for: "https://en.wikipedia.org/wiki/Cat"))
    }

    func testUnrelatedQueryIsNotAReturnJourney() throws {
        XCTAssertNil(try returnJourney(for: "https://en.wikipedia.org/wiki/Cat?campaign=test"))
    }

    func testMidEditReturnThroughNativeAppBanner() throws {
        let journey = try XCTUnwrap(returnJourney(for: "https://en.wikipedia.org/wiki/Cat?useformat=mobile&veaction=edit&returntoapp=1&section=2"))
        XCTAssertFalse(journey.saved)
        XCTAssertNil(journey.revisionID)
        XCTAssertEqual(journey.articleURL.absoluteString, "https://en.wikipedia.org/wiki/Cat")
    }

    func testPublishedEditKeepingEditingQueryItems() throws {
        let journey = try XCTUnwrap(returnJourney(for: "https://en.wikipedia.org/wiki/Cat?veaction=edit&returntoapp=1&saved=true&revision=12345"))
        XCTAssertTrue(journey.saved)
        XCTAssertEqual(journey.revisionID, 12345)
        XCTAssertEqual(journey.articleURL.absoluteString, "https://en.wikipedia.org/wiki/Cat")
    }

    func testPreservesOtherQueryItems() throws {
        let journey = try XCTUnwrap(returnJourney(for: "https://en.wikipedia.org/wiki/Cat?saved=true&revision=12345&campaign=test"))
        XCTAssertEqual(journey.articleURL.absoluteString, "https://en.wikipedia.org/wiki/Cat?campaign=test")
    }

    func testPreservesPercentEncodedTitle() throws {
        let journey = try XCTUnwrap(returnJourney(for: "https://pt.wikipedia.org/wiki/S%C3%A3o_Paulo?saved=true&revision=9"))
        XCTAssertTrue(journey.saved)
        XCTAssertEqual(journey.revisionID, 9)
        XCTAssertEqual(journey.articleURL.absoluteString, "https://pt.wikipedia.org/wiki/S%C3%A3o_Paulo")
    }
}
