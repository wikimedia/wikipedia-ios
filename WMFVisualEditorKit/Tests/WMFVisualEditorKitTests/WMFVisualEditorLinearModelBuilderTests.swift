import Testing
import Foundation
@testable import WMFVisualEditorKit

struct WMFVisualEditorLinearModelBuilderTests {

    private func makeDocument(_ bodyContent: String) throws -> WMFVisualEditorDocument {
        try WMFVisualEditorDocument.parse(parsoidHTML: "<html><body>\(bodyContent)</body></html>")
    }

    @Test func buildsParagraphWithAnnotations() throws {
        let document = try makeDocument(#"<p>a <b>b</b> <i>c</i> <a rel="mw:WikiLink" href="./Queijo">d</a></p>"#)

        let items = document.linearModel
        guard case .open(let firstType, _, let preservedContent) = try #require(items.first) else {
            Issue.record("expected open item")
            return
        }
        #expect(firstType == "paragraph")
        #expect(preservedContent?.elementName == "p")
        #expect(items.last == .close(type: "paragraph"))

        let annotatedCharacters = items.compactMap { item -> [WMFVisualEditorAnnotation]? in
            if case .character(_, let annotations) = item, !annotations.isEmpty {
                return annotations
            }
            return nil
        }
        #expect(annotatedCharacters.count == 3)
        #expect(annotatedCharacters[0].map(\.kind) == [.bold])
        #expect(annotatedCharacters[0].first?.elementName == "b")
        #expect(annotatedCharacters[1].map(\.kind) == [.italic])
        #expect(annotatedCharacters[2].map(\.kind) == [.link])
        #expect(annotatedCharacters[2].first?.target == "./Queijo")
        // Full source attributes are preserved for serialization of edited blocks.
        #expect(annotatedCharacters[2].first?.attributes.map(\.name) == ["rel", "href"])
    }

    @Test func buildsHeadingsAndLists() throws {
        let document = try makeDocument("<h2>Title</h2><ul><li>one</li><li>two</li></ul>")

        #expect(document.statistics.nodeTypeCounts["heading"] == 1)
        #expect(document.statistics.nodeTypeCounts["list"] == 1)
        #expect(document.statistics.nodeTypeCounts["listItem"] == 2)

        guard case .open(let type, let attributes, _) = document.linearModel.first else {
            Issue.record("expected open item")
            return
        }
        #expect(type == "heading")
        #expect(attributes["level"] == "2")
    }

    @Test func transclusionsBecomeOpaquePreservedNodes() throws {
        let document = try makeDocument(##"<p>x</p><div typeof="mw:Transclusion" data-mw="{}" about="#mwt1"><p>rendered</p></div>"##)

        #expect(document.statistics.nodeTypeCounts["mwTransclusion"] == 1)

        let transclusion = document.linearModel.first { item in
            if case .open(let type, _, _) = item, type == "mwTransclusion" {
                return true
            }
            return false
        }
        guard case .open(_, let attributes, let preservedContent) = try #require(transclusion) else {
            Issue.record("expected open item")
            return
        }
        #expect(attributes["about"] == "#mwt1")
        // The full original subtree must be preserved for future round-tripping.
        #expect(preservedContent?.textContent == "rendered")
        #expect(preservedContent?.attributeValue("data-mw") == "{}")
    }

    @Test func unknownElementsBecomeAliens() throws {
        let document = try makeDocument("<table><tbody><tr><td>cell</td></tr></tbody></table>")
        #expect(document.statistics.nodeTypeCounts["alien"] == 1)
    }

    @Test func figuresBecomeTypedImageNodes() throws {
        let document = try makeDocument(##"<figure typeof="mw:File/Thumb" about="#mwt9"><a href="./File:X.jpg"><img src="//upload.wikimedia.org/x/220px-X.jpg" width="220" height="147"></a><figcaption>A <b>cheese</b> platter</figcaption></figure>"##)

        #expect(document.statistics.nodeTypeCounts["mwImage"] == 1)

        let imageItem = document.linearModel.first { item in
            if case .open(let type, _, _) = item, type == "mwImage" {
                return true
            }
            return false
        }
        guard case .open(_, let attributes, let preservedContent) = try #require(imageItem) else {
            Issue.record("expected open item")
            return
        }
        #expect(attributes["src"] == "//upload.wikimedia.org/x/220px-X.jpg")
        #expect(attributes["width"] == "220")
        #expect(attributes["height"] == "147")
        #expect(attributes["caption"] == "A cheese platter")
        // The full original subtree must survive for byte-identical serialization.
        #expect(preservedContent?.attributeValue("about") == "#mwt9")
    }

    @Test func inlineFileSpansBecomeImageNodes() throws {
        let document = try makeDocument(##"<p>text <span typeof="mw:File"><a href="./File:Icon.svg"><img src="//upload.wikimedia.org/icon.svg" width="20" height="20"></a></span> more</p>"##)
        #expect(document.statistics.nodeTypeCounts["mwImage"] == 1)
    }

    @Test func descendsThroughWrapperContainers() throws {
        // Modern Parsoid wraps headings in <div class="mw-heading">; content must
        // not collapse into opaque nodes because of structural wrappers.
        let document = try makeDocument(#"<div class="mw-heading mw-heading2"><h2>Title</h2></div><div><p>text</p></div><blockquote><p>quote</p></blockquote>"#)

        #expect(document.statistics.nodeTypeCounts["heading"] == 1)
        #expect(document.statistics.nodeTypeCounts["paragraph"] == 2)
        #expect(document.statistics.nodeTypeCounts["alien", default: 0] == 0)
    }

    @Test func buildsSecondaryStyleAnnotations() throws {
        let document = try makeDocument("<p><sup>1</sup><sub>2</sub><s>3</s><u>4</u><code>5</code></p>")

        let kinds = document.linearModel.compactMap { item -> WMFVisualEditorAnnotation.Kind? in
            if case .character(_, let annotations) = item {
                return annotations.first?.kind
            }
            return nil
        }
        #expect(kinds == [.superscripted, .subscripted, .strikethrough, .underline, .code])
    }

    @Test func referenceSupStaysOpaque() throws {
        // Citation markers are <sup typeof="mw:Extension/ref"> — extension
        // output, not superscripted text. They must never become editable
        // annotations.
        let document = try makeDocument(##"<p>fact<sup typeof="mw:Extension/ref" about="#cite1" id="cite_ref-1"><a href="./X#cite_note-1">[1]</a></sup></p>"##)

        #expect(document.statistics.nodeTypeCounts["alien"] == 1)
        #expect(document.statistics.annotatedCharacterCount == 0)
    }

    @Test func wrapperDivWithTransclusionTypeStaysOpaque() throws {
        let document = try makeDocument(##"<div typeof="mw:Transclusion" data-mw="{}" about="#mwt2"><p>rendered</p></div>"##)
        #expect(document.statistics.nodeTypeCounts["mwTransclusion"] == 1)
        #expect(document.statistics.nodeTypeCounts["paragraph", default: 0] == 0)
    }

    @Test func linearModelIsBalanced() throws {
        let document = try makeDocument("<section><h2>t</h2><p>a<b>b</b></p><ul><li>x</li></ul></section>")

        var depth = 0
        for item in document.linearModel {
            switch item {
            case .open:
                depth += 1
            case .close:
                depth -= 1
            case .character:
                break
            }
            #expect(depth >= 0)
        }
        #expect(depth == 0)
    }
}
