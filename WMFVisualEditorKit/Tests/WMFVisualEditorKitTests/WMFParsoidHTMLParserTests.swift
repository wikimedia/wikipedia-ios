import Testing
import Foundation
@testable import WMFVisualEditorKit

struct WMFParsoidHTMLParserTests {

    private let parser = WMFParsoidHTMLParser()

    @Test func parsesElementsTextAndAttributes() throws {
        let html = #"<html><body><p id="mwAQ" data-mw="{&quot;x&quot;:1}">Hello <b>bold</b> world</p></body></html>"#
        let body = try parser.parseBody(html)

        let paragraph = try #require(body.firstElement(named: "p"))
        #expect(paragraph.attributeValue("id") == "mwAQ")
        #expect(paragraph.attributeValue("data-mw") == #"{"x":1}"#)
        #expect(paragraph.textContent == "Hello bold world")
    }

    @Test func preservesAttributeOrder() throws {
        let html = ##"<html><body><span typeof="mw:Entity" about="#mwt1" id="z">x</span></body></html>"##
        let body = try parser.parseBody(html)
        let span = try #require(body.firstElement(named: "span"))
        #expect(span.attributes.map(\.name) == ["typeof", "about", "id"])
    }

    @Test func handlesVoidAndSelfClosingElements() throws {
        let html = "<html><body><p>a<br>b<meta property=\"x\"/><img src=\"y\"></p></body></html>"
        let body = try parser.parseBody(html)
        let paragraph = try #require(body.firstElement(named: "p"))
        #expect(paragraph.children.count == 5)
        #expect(paragraph.textContent == "ab")
    }

    @Test func handlesCommentsAndDoctype() throws {
        let html = "<!DOCTYPE html><html><body><!-- a comment --><p>text</p></body></html>"
        let body = try parser.parseBody(html)
        #expect(body.children.count == 2)
        guard case .comment(let comment) = body.children[0].content else {
            Issue.record("expected comment")
            return
        }
        #expect(comment == " a comment ")
    }

    @Test func handlesRawTextElements() throws {
        let html = "<html><head><style>.a < b { color: red }</style></head><body><p>x</p></body></html>"
        let root = try parser.parseDocument(html)
        let style = try #require(root.firstElement(named: "style"))
        #expect(style.textContent == ".a < b { color: red }")
    }

    @Test func decodesEntities() throws {
        #expect(WMFParsoidHTMLEntities.decode("a &amp; b &lt;c&gt; &quot;d&quot; &#233; &#x1F600;") == "a & b <c> \"d\" é 😀")
        #expect(WMFParsoidHTMLEntities.decode("no entities") == "no entities")
        #expect(WMFParsoidHTMLEntities.decode("dangling & ampersand") == "dangling & ampersand")
        #expect(WMFParsoidHTMLEntities.decode("&unknown;") == "&unknown;")
    }

    @Test func tracksSourceRanges() throws {
        let html = "<html><body><p id=\"x\">ab</p></body></html>"
        let body = try parser.parseBody(html)
        let paragraph = try #require(body.firstElement(named: "p"))

        let sourceCharacters = Array(html)
        let sourceRange = try #require(paragraph.sourceRange)
        #expect(String(sourceCharacters[sourceRange]) == "<p id=\"x\">ab</p>")

        let contentRange = try #require(paragraph.sourceContentRange)
        #expect(String(sourceCharacters[contentRange]) == "ab")
    }

    @Test func throwsOnMismatchedClosingTag() {
        #expect(throws: WMFParsoidHTMLParser.ParserError.self) {
            _ = try parser.parseDocument("<html><body><p>text</div></body></html>")
        }
    }
}
