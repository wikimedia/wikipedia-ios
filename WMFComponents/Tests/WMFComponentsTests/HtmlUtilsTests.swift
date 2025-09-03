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

    func testMalformedListHtml() throws {
        let html = "<div class=\"mw-fr-edit-messages\"><div class=\"cdx-message mw-fr-message-box cdx-message--inline cdx-message--notice\"><span class=\"cdx-message__icon\"></span><div class=\"cdx-message__content\"><p><b>Note:</b> Edits to this page from new or unregistered users are subject to review prior to publication (<a href=\"/wiki/Wikipedia:Pending_changes\" title=\"Wikipedia:Pending changes\">help</a>).\n</p><div id=\"mw-fr-logexcerpt\"><ul class=\'mw-logevent-loglines\'>\n<li data-mw-logid=\"166878532\" data-mw-logaction=\"stable/config\" class=\"mw-logline-stable\"> <a href=\"/w/index.php?title=Special:Log&amp;logid=166878532\" title=\"Special:Log\">21:42, 2 January 2025</a> <a href=\"/wiki/User:Ymblanter\" class=\"mw-userlink\" title=\"User:Ymblanter\"><bdi>Ymblanter</bdi></a> configured pending changes settings for <a href=\"/wiki/Josh_Allen\" title=\"Josh Allen\">Josh Allen</a> [Auto-accept: require &quot;autoconfirmed&quot; permission] (expires 21:42, 2 January 2026 (UTC)) <span class=\"comment\">(Persistent <a href=\"/wiki/Wikipedia:Vandalism\" title=\"Wikipedia:Vandalism\">vandalism</a>; requested at <a href=\"/wiki/Wikipedia:RfPP\" class=\"mw-redirect\" title=\"Wikipedia:RfPP\">WP:RfPP</a> (<a href=\"/wiki/Wikipedia:TW\" class=\"mw-redirect\" title=\"Wikipedia:TW\">TW</a>))</span> <span class=\"mw-logevent-actionlink\">(<a href=\"/w/index.php?title=Josh_Allen&amp;action=history&amp;offset=20250102214253\" title=\"Josh Allen\">hist</a>)</span> </li>\n</ul></ul>\n</div></div></div></div>"

        let attributedString = try HtmlUtils.attributedStringFromHtml(html, styles: .testStyle)
        XCTAssertNotNil(attributedString, "Test extra unordered list did not cause crash")
    }

    func testHtmlLinkWithComplexAttributes() throws {
        let html = "<a typeof=\"mw:ExpandedAttrs\" about=\"#mwt3\" rel=\"mw:WikiLink\" href=\"./Mock:Contribution/Qwe57\" title=\"Mock:Contribution/Qwe57\" data-mw='{\"attribs\":[[[{\"txt\":\"href\"},{\"html\":\"Mock:Contribution/&lt;span about=\"#mwt2\" typeof=\"mw:Transclusion\" data-parsoid=&apos;{\"pi\":[[]],\"dsr\":[216,228,null,null]}&apos; data-mw=&apos;{\"parts\":[{\"template\":{\"target\":{\"wt\":\"PAGENAME\",\"function\":\"pagename\"},\"params\":{},\"i\":0}}]}&apos;>Qwe57&lt;/span>\"}]]}' id=\"mwCg\">Link</a>"

        let attributed = try HtmlUtils.nsAttributedStringFromHtml(html, styles: .testStyle)
        XCTAssertEqual(attributed.string, "Link")

        let linkAttribute = attributed.attribute(.link, at: 0, effectiveRange: nil)
        XCTAssertNotNil(linkAttribute, "The link attribute should be present.")
    }
    
    func testHtmlLinkWithSpecialCharacter() throws {
        let html = "<a rel=\"mw:WikiLink\" href=\"https://en.wikipedia.org/wiki/Stephen_of_La_Ferté\" title=\"Stephen of La Ferté\" id=\"mwFQ\">Patriarch Stephen</a>"
        let attributed = try HtmlUtils.nsAttributedStringFromHtml(html, styles: .testStyle)
        
        // Preferrable that this is a URL type: https://developer.apple.com/documentation/Foundation/NSAttributedString/Key/link
        if let linkAttributeURL = attributed.attribute(.link, at: 0, effectiveRange: nil) as? URL {
            XCTAssertEqual(linkAttributeURL.absoluteString, "https://en.wikipedia.org/wiki/Stephen_of_La_Fert%C3%A9", "Special characters can cause crashes in UITextView - é should be encoded.")
        } else if let linkAttributeString = attributed.attribute(.link, at: 0, effectiveRange: nil) as? String {
            XCTAssertEqual(linkAttributeString, "https://en.wikipedia.org/wiki/Stephen_of_La_Fert%C3%A9", "Special characters can cause crashes in UITextView - é should be encoded.")
        }
        
    }
}

fileprivate extension HtmlUtils.Styles {
    static var testStyle: HtmlUtils.Styles {
        let largeTraitCollection = UITraitCollection(preferredContentSizeCategory: .large)
        return HtmlUtils.Styles(
            font: WMFFont.for(.callout, compatibleWith: largeTraitCollection),
            boldFont: WMFFont.for(.boldCallout, compatibleWith: largeTraitCollection),
            italicsFont: WMFFont.for(.italicCallout, compatibleWith: largeTraitCollection),
            boldItalicsFont: WMFFont.for(.boldItalicCallout, compatibleWith: largeTraitCollection),
            color: WMFTheme.light.text,
            linkColor: WMFTheme.light.link,
            lineSpacing: 0
        )
    }
}
