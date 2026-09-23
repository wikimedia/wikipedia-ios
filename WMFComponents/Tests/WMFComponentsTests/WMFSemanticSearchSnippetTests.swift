import XCTest
@testable import WMFComponents

final class WMFSemanticSearchSnippetTests: XCTestCase {

    private let text = UIColor.black
    private let highlight = UIColor.yellow
    private let highlightText = UIColor.darkGray
    private let link = UIColor.blue

    private func passage(_ html: String) -> NSAttributedString {
        WMFSemanticSearchSnippet.attributedString(html: html, font: .systemFont(ofSize: 16), textColor: text, highlightColor: highlight, highlightTextColor: highlightText, linkColor: link)
    }

    private func highlightedTexts(in passage: NSAttributedString) -> [String] {
        var texts: [String] = []
        passage.enumerateAttribute(.backgroundColor, in: NSRange(location: 0, length: passage.length)) { value, range, _ in
            if value != nil { texts.append(passage.attributedSubstring(from: range).string) }
        }
        return texts
    }

    func testHighlightIsDrawnBehindTheDecodedText() {
        let passage = passage("La communication est <span class=\"searchmatch\">l&#039;ensemble des interactions</span>. Elle implique.")

        XCTAssertEqual(passage.string, "La communication est l'ensemble des interactions. Elle implique.")
        XCTAssertEqual(highlightedTexts(in: passage), ["l'ensemble des interactions"])
        XCTAssertEqual(passage.attribute(.foregroundColor, at: 21, effectiveRange: nil) as? UIColor, highlightText)
        XCTAssertEqual(passage.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? UIColor, text)
    }

    func testEntitiesAreDecodedOutsideTheHighlight() {
        XCTAssertEqual(passage("support physique de l&#039;information &amp; plus").string, "support physique de l'information & plus")
        XCTAssertEqual(WMFSemanticSearchSnippet.plainText(html: "support physique de l&#039;information &amp; plus"), "support physique de l'information & plus")
    }

    func testSeveralHighlightsKeepTheirOrder() {
        let passage = passage("<span class=\"searchmatch\">Un</span> deux <span class=\"searchmatch\">trois</span>")

        XCTAssertEqual(passage.string, "Un deux trois")
        XCTAssertEqual(highlightedTexts(in: passage), ["Un", "trois"])
    }

    func testHighlightSurvivesNonLatinText() {
        let passage = passage("😀 <span class=\"searchmatch\">情報の伝達</span>")

        XCTAssertEqual(highlightedTexts(in: passage), ["情報の伝達"])
    }

    func testOtherSpansDoNotCloseTheHighlight() {
        let passage = passage("<span class=\"searchmatch\">un <span class=\"nowrap\">deux</span> trois</span> quatre")

        XCTAssertEqual(passage.string, "un deux trois quatre")
        XCTAssertEqual(highlightedTexts(in: passage), ["un deux trois"])
    }

    func testLineBreaksAndSpaceRunsBecomeOneSpace() {
        let html = "John Tennent peut faire référence à :\n - <span class=\"searchmatch\">John Tennent</span> (en) (mort vers 1549), courtisan écossais\n - John Tennent (en)  (1846-1893)"
        let passage = passage(html)

        XCTAssertEqual(passage.string, "John Tennent peut faire référence à : - John Tennent (en) (mort vers 1549), courtisan écossais - John Tennent (en) (1846-1893)")
        XCTAssertEqual(highlightedTexts(in: passage), ["John Tennent"])
        XCTAssertEqual(WMFSemanticSearchSnippet.plainText(html: html), passage.string)
    }

    func testWhitespaceAroundTheHighlightBoundaryIsNotDoubled() {
        let passage = passage("avant \n<span class=\"searchmatch\"> milieu </span>\n après")

        XCTAssertEqual(passage.string, "avant milieu après")
        XCTAssertEqual(highlightedTexts(in: passage), ["milieu"])
    }

    func testLeadingAndTrailingWhitespaceAreRemoved() {
        XCTAssertEqual(passage("\n texte <span class=\"searchmatch\">final</span> \n").string, "texte final")
    }

    func testNonBreakingSpacesAreKept() {
        XCTAssertEqual(passage("référence à\u{00A0}: suite").string, "référence à\u{00A0}: suite")
    }

    func testStandardTagsRenderThroughHtmlUtils() {
        let passage = passage("<b>Bold</b>, <i>italic</i> and H<sub>2</sub>O")

        XCTAssertEqual(passage.string, "Bold, italic and H2O")
        let boldFont = passage.attribute(.font, at: 0, effectiveRange: nil) as? UIFont
        XCTAssertTrue(boldFont?.fontDescriptor.symbolicTraits.contains(.traitBold) ?? false)
        let italicFont = passage.attribute(.font, at: 6, effectiveRange: nil) as? UIFont
        XCTAssertTrue(italicFont?.fontDescriptor.symbolicTraits.contains(.traitItalic) ?? false)
        XCTAssertNotNil(passage.attribute(.baselineOffset, at: 18, effectiveRange: nil), "Subscript keeps its offset.")
    }

    func testLinksAreAnIndicationOnly() {
        let passage = passage("the <span class=\"searchmatch\"><a href=\"/wiki/Transmission\">transmission</a> of information</span>: a <a href=\"/wiki/Message\">message</a>")

        XCTAssertEqual(passage.string, "the transmission of information: a message")
        XCTAssertNil(passage.attribute(.link, at: 4, effectiveRange: nil), "Links are not tappable.")
        XCTAssertNil(passage.attribute(.link, at: 35, effectiveRange: nil))
        XCTAssertEqual(passage.attribute(.foregroundColor, at: 4, effectiveRange: nil) as? UIColor, highlightText, "Inside the highlight the link keeps the highlight text color.")
        XCTAssertEqual(passage.attribute(.underlineStyle, at: 4, effectiveRange: nil) as? Int, NSUnderlineStyle.single.rawValue, "Inside the highlight the link is underlined.")
        XCTAssertEqual(passage.attribute(.foregroundColor, at: 35, effectiveRange: nil) as? UIColor, link, "Outside the highlight the link is in the link color.")
        XCTAssertNil(passage.attribute(.underlineStyle, at: 35, effectiveRange: nil))
    }

    func testReferenceMarkersAreSuperscriptsInTheTextColor() {
        let passage = passage("electricity.<sup id=\"cite_ref-3\"><a href=\"#cite_note-3\">[3]</a></sup> Sender")

        XCTAssertEqual(passage.string, "electricity.[3] Sender")
        XCTAssertLessThan((passage.attribute(.font, at: 12, effectiveRange: nil) as? UIFont)?.pointSize ?? 100, 16)
        XCTAssertNotNil(passage.attribute(.baselineOffset, at: 12, effectiveRange: nil))
        XCTAssertEqual(passage.attribute(.foregroundColor, at: 12, effectiveRange: nil) as? UIColor, text, "The marker is not blue even inside a link.")
        XCTAssertNil(passage.attribute(.link, at: 12, effectiveRange: nil))
    }
}
