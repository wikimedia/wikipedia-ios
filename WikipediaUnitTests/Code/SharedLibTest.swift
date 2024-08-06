import XCTest

final class SharedLibTest: XCTestCase {

    var alt: AltText?

    override func setUpWithError() throws {
        alt = try AltText()
    }

    override func tearDownWithError() throws {
    }

    func testCaptionNoAlt() throws {
        let text = "[[File:Test no alt.jpg|caption here]]"
        let wikitext = "text text " + text + " text text"
        let result = try alt?.missingAltTextLinks(text: wikitext, language: "en")
        XCTAssertEqual(result?.count, 1)
        let link = result?[0]
        XCTAssertEqual(link?.text, text)
        XCTAssertEqual(link?.file, "File:Test no alt.jpg")
        XCTAssertEqual(link?.offset, "text text ".count)
        XCTAssertEqual(link?.length, text.count)
    }

    func testCaptionWithAlt() throws {
        let text = "[[File:Test with alt.jpg|caption here|alt=Cool picture]]"
        let wikitext = "text text " + text + " text text"
        let result = try alt?.missingAltTextLinks(text: wikitext, language: "en")
        XCTAssertEqual(result?.count, 0)
    }

}
