import Testing
import Foundation
@testable import WMFVisualEditorKit

/// The null-edit gate: parsing a document and serializing it back with zero
/// edits MUST produce byte-identical output. This is the invariant that keeps
/// saves from producing dirty diffs, and the hard requirement every engine
/// change has to keep passing.
struct WMFVisualEditorHTMLSerializerTests {

    private let serializer = WMFVisualEditorHTMLSerializer()

    private func loadFixture(_ name: String) throws -> String {
        let url = try #require(Bundle.module.url(forResource: "Fixtures/\(name)", withExtension: "html"))
        return try String(contentsOf: url, encoding: .utf8)
    }

    // MARK: - Null-edit gate

    @Test(arguments: ["pt__lontra", "zh__cheese"])
    func nullEditIsByteIdenticalOnRealArticles(fixtureName: String) throws {
        let html = try loadFixture(fixtureName)
        let document = try WMFVisualEditorDocument.parse(parsoidHTML: html)
        let serialized = serializer.serializeDocument(document)

        #expect(serialized == html)
        if serialized != html {
            let divergence = zip(serialized, html).enumerated().first { $0.element.0 != $0.element.1 }?.offset ?? min(serialized.count, html.count)
            let context = String(Array(html)[max(0, divergence - 80)..<min(html.count, divergence + 80)])
            Issue.record("first divergence at character \(divergence): …\(context)…")
        }
    }

    @Test func nullEditPreservesNonContentSource() throws {
        let html = """
        <!DOCTYPE html><html><head><style>.x { color: red }</style></head><body id="mwAA">
        <section data-mw-section-id="0" id="mwAQ">
        <p id="mwAg">a &amp; b</p>
        <!-- a comment --><meta property="mw:pageNamespace" content="0"/>
        </section>
        </body></html>
        """
        let document = try WMFVisualEditorDocument.parse(parsoidHTML: html)
        #expect(serializer.serializeDocument(document) == html)
    }

    // MARK: - Selective serialization of edits

    @Test func editedBlockReserializesOthersStayByteIdentical() throws {
        let html = #"<html><body><section id="s1"><p id="p1">alpha</p><p id="p2">beta <b>bold</b></p></section></html>"#
        // (Note: no closing </body> above would be malformed; use a proper document.)
        let properHTML = #"<html><body><section id="s1"><p id="p1">alpha</p><p id="p2">beta <b>bold</b></p></section></body></html>"#
        _ = html

        let document = try WMFVisualEditorDocument.parse(parsoidHTML: properHTML)
        // Insert "X" after "alpha"'s first character: linear index of 'a' start:
        // [open section, open p1, a,l,p,h,a → indices 2..6]
        let (edited, _) = try document.replacingCharacters(in: 3..<3, with: "X", annotations: [])
        let serialized = serializer.serializeDocument(edited)

        // The edited paragraph re-serializes with its original attributes and new text.
        #expect(serialized.contains(#"<p id="p1">aXlpha</p>"#))
        // The untouched sibling paragraph is emitted byte-for-byte from source.
        #expect(serialized.contains(#"<p id="p2">beta <b>bold</b></p>"#))

        // The output must reparse to an equivalent model.
        let reparsed = try WMFVisualEditorDocument.parse(parsoidHTML: serialized)
        #expect(reparsed.statistics.characterCount == edited.statistics.characterCount)
    }

    @Test func splitBlockSerializesAsTwoParagraphs() throws {
        let properHTML = #"<html><body><section id="s1"><p id="p1">ab</p></section></body></html>"#
        let document = try WMFVisualEditorDocument.parse(parsoidHTML: properHTML)
        // [open section, open p, 'a', 'b', close p, close section] — split between a and b.
        let (split, _) = try document.splittingBlock(at: 3)
        let serialized = serializer.serializeDocument(split)

        #expect(serialized.contains(#"<p id="p1">a</p><p>b</p>"#))

        let reparsed = try WMFVisualEditorDocument.parse(parsoidHTML: serialized)
        #expect(reparsed.statistics.nodeTypeCounts["paragraph"] == 2)
    }

    @Test func editedLinkKeepsItsSourceAttributes() throws {
        let properHTML = #"<html><body><p id="p1">see <a rel="mw:WikiLink" href="./Cheese" title="Cheese">cheese</a> here</p></body></html>"#
        let document = try WMFVisualEditorDocument.parse(parsoidHTML: properHTML)
        // Type inside the link text: after 'c' of cheese.
        // [open p, s,e,e,' ' → 1..4, annotated c,h,e,e,s,e → 5..10]
        let annotations = try {
            guard case .character(_, let annotations) = document.linearModel[5] else {
                throw WMFVisualEditorDocument.EditingError.rangeOutOfBounds
            }
            return annotations
        }()
        let (edited, _) = try document.replacingCharacters(in: 6..<6, with: "X", annotations: annotations)
        let serialized = serializer.serializeDocument(edited)

        // rel/href/title survive the re-serialization of the dirty block.
        #expect(serialized.contains(#"<a rel="mw:WikiLink" href="./Cheese" title="Cheese">cXheese</a>"#))
    }

    @Test func undoRestoresNullEditFidelityIsNotGuaranteedButOutputReparses() throws {
        // Undo marks blocks conservatively dirty, so the undone document may
        // re-serialize normalized rather than byte-identical — but it must
        // still reparse to the same content.
        let properHTML = #"<html><body><p id="p1">abc</p></body></html>"#
        let document = try WMFVisualEditorDocument.parse(parsoidHTML: properHTML)
        let (edited, removedItems) = try document.replacingCharacters(in: 2..<2, with: "X", annotations: [])
        let (undone, _) = try edited.splicingItems(in: 2..<3, with: removedItems)

        let serialized = serializer.serializeDocument(undone)
        let reparsed = try WMFVisualEditorDocument.parse(parsoidHTML: serialized)
        #expect(reparsed.statistics.characterCount == document.statistics.characterCount)
        #expect(serialized.contains(#"<p id="p1">abc</p>"#))
    }
}
