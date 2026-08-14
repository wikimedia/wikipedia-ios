import Testing
import Foundation
@testable import WMFVisualEditorKit

struct WMFVisualEditorEditingTests {

    private func makeDocument(_ bodyContent: String) throws -> WMFVisualEditorDocument {
        try WMFVisualEditorDocument.parse(parsoidHTML: "<html><body>\(bodyContent)</body></html>")
    }

    private func plainText(of document: WMFVisualEditorDocument) -> String {
        var text = ""
        for item in document.linearModel {
            if case .character(let character, _) = item {
                text.append(character)
            }
        }
        return text
    }

    /// Compact structural signature of the linear model, ignoring preserved
    /// content payloads — used to assert structure without comparing trees.
    private func itemSignatures(of document: WMFVisualEditorDocument) -> [String] {
        document.linearModel.map { item in
            switch item {
            case .open(let type, _, _):
                return "open:\(type)"
            case .close(let type):
                return "close:\(type)"
            case .character(let character, let annotations):
                return annotations.isEmpty ? "char:\(character)" : "annotated:\(character)"
            }
        }
    }

    @Test func insertsCharactersInsideParagraph() throws {
        let document = try makeDocument("<p>ab</p>")
        // Linear model: [open paragraph, 'a', 'b', close paragraph]
        let (edited, removedItems) = try document.replacingCharacters(in: 2..<2, with: "XY", annotations: [])

        #expect(removedItems.isEmpty)
        #expect(plainText(of: edited) == "aXYb")
        #expect(edited.statistics.characterCount == 4)
    }

    @Test func deletesCharactersAndReturnsRemovedItemsForUndo() throws {
        let document = try makeDocument("<p>a<b>bc</b>d</p>")
        let (edited, removedItems) = try document.replacingCharacters(in: 2..<4, with: "", annotations: [])

        #expect(plainText(of: edited) == "ad")
        #expect(removedItems.count == 2)
        #expect(removedItems[0] == .character("b", annotations: [WMFVisualEditorAnnotation(kind: .bold, elementName: "b")]))

        // Undo restores the exact items, annotations included.
        let (restored, _) = try edited.replacingItems(in: 2..<2, with: removedItems)
        #expect(plainText(of: restored) == plainText(of: document))
        #expect(restored.linearModel == document.linearModel)
        #expect(restored.statistics == document.statistics)
    }

    @Test func insertsIntoEmptyParagraph() throws {
        let document = try makeDocument("<p></p>")
        let (edited, _) = try document.replacingCharacters(in: 1..<1, with: "x", annotations: [])
        #expect(plainText(of: edited) == "x")
    }

    @Test func rejectsRangeCoveringStructure() throws {
        let document = try makeDocument("<p>a</p><p>b</p>")
        // Range spans the close/open items between the paragraphs.
        #expect(throws: WMFVisualEditorDocument.EditingError.rangeContainsStructure) {
            _ = try document.replacingCharacters(in: 1..<5, with: "x", annotations: [])
        }
    }

    @Test func rejectsInsertionOutsideContent() throws {
        let document = try makeDocument(#"<div typeof="mw:Transclusion" data-mw="{}"><p>t</p></div>"#)
        // Position 1 is between the transclusion open and close items.
        #expect(throws: WMFVisualEditorDocument.EditingError.invalidInsertionPoint) {
            _ = try document.replacingCharacters(in: 1..<1, with: "x", annotations: [])
        }
    }

    @Test func rejectsOutOfBoundsRange() throws {
        let document = try makeDocument("<p>a</p>")
        #expect(throws: WMFVisualEditorDocument.EditingError.rangeOutOfBounds) {
            _ = try document.replacingCharacters(in: 3..<9, with: "x", annotations: [])
        }
    }

    @Test func splitsParagraphInTheMiddle() throws {
        let document = try makeDocument("<p>ab</p>")
        // [open paragraph, 'a', 'b', close paragraph] — split between a and b.
        let (edited, insertedItems) = try document.splittingBlock(at: 2)

        #expect(insertedItems == [.close(type: "paragraph"), .open(type: "paragraph", attributes: [:], preservedContent: nil)])
        #expect(edited.statistics.nodeTypeCounts["paragraph"] == 2)
        #expect(itemSignatures(of: edited) == [
            "open:paragraph", "char:a", "close:paragraph",
            "open:paragraph", "char:b", "close:paragraph"
        ])

        // Undo: remove the inserted pair via the low-level splice.
        let (restored, removed) = try edited.splicingItems(in: 2..<4, with: [])
        #expect(removed == insertedItems)
        #expect(restored.linearModel == document.linearModel)
        #expect(restored.statistics == document.statistics)
    }

    @Test func splitAtEndOfHeadingStartsParagraph() throws {
        let document = try makeDocument("<h2>Title</h2>")
        // Caret at the heading's close item (end of block).
        let (edited, insertedItems) = try document.splittingBlock(at: 6)

        #expect(insertedItems.last == .open(type: "paragraph", attributes: [:], preservedContent: nil))
        #expect(edited.statistics.nodeTypeCounts["paragraph"] == 1)
        #expect(edited.statistics.nodeTypeCounts["heading"] == 1)
    }

    @Test func splitInMiddleOfHeadingKeepsHeadingType() throws {
        let document = try makeDocument("<h2>ab</h2>")
        let (edited, _) = try document.splittingBlock(at: 2)
        #expect(edited.statistics.nodeTypeCounts["heading"] == 2)
    }

    @Test func splitOutsideContentBlockThrows() throws {
        let document = try makeDocument(#"<div typeof="mw:Transclusion" data-mw="{}"><p>t</p></div>"#)
        #expect(throws: WMFVisualEditorDocument.EditingError.invalidInsertionPoint) {
            _ = try document.splittingBlock(at: 1)
        }
    }

    @Test func splicingRejectsUnbalancedResult() throws {
        let document = try makeDocument("<p>a</p>")
        // Removing only the paragraph's close item leaves the model unbalanced.
        #expect(throws: WMFVisualEditorDocument.EditingError.unbalancedResult) {
            _ = try document.splicingItems(in: 2..<3, with: [])
        }
    }

    @Test func deletingAcrossInvisibleStructurePreservesIt() throws {
        // Real articles have invisible spans everywhere: deleting characters on
        // both sides of a span boundary must flow around the structure.
        let document = try makeDocument(#"<p>ab<span id="anchor">cd</span>ef</p>"#)
        // [open p, a, b, open container, c, d, close container, e, f, close p]
        let (edited, removedSlice, newSliceCount) = try document.replacingCharactersPreservingStructure(in: 2..<8, with: "", annotations: [])

        #expect(plainText(of: edited) == "af")
        #expect(newSliceCount == 2)
        #expect(itemSignatures(of: edited) == [
            "open:paragraph", "char:a", "open:container", "close:container", "char:f", "close:paragraph"
        ])

        // Undo restores the original interleaving exactly.
        let (restored, _) = try edited.splicingItems(in: 2..<4, with: removedSlice)
        #expect(restored.linearModel == document.linearModel)
    }

    @Test func typingAcrossStructurePlacesTextBeforePreservedItems() throws {
        let document = try makeDocument(#"<p>ab<span id="anchor">cd</span></p>"#)
        // Replace "bc" (crosses into the span) with "X".
        let (edited, _, _) = try document.replacingCharactersPreservingStructure(in: 2..<5, with: "X", annotations: [])

        #expect(plainText(of: edited) == "aXd")
        #expect(itemSignatures(of: edited) == [
            "open:paragraph", "char:a", "char:X", "open:container", "char:d", "close:container", "close:paragraph"
        ])
    }

    @Test func structurePreservingEditMarksPreservedStructureDirty() throws {
        let document = try makeDocument(#"<p>ab<span id="anchor">cd</span>ef</p>"#)
        let (edited, _, _) = try document.replacingCharactersPreservingStructure(in: 2..<8, with: "", annotations: [])
        // Both the paragraph and the surviving (now dirty) span are marked.
        #expect(edited.dirtyBlockIndices.contains(0))
        #expect(edited.dirtyBlockIndices.contains(2))
    }

    @Test func togglingAnnotationAddsAndRemoves() throws {
        let document = try makeDocument("<p>abc</p>")

        // Add bold to "ab" (linear 1..<3).
        let (bolded, removedItems) = try document.togglingAnnotation(kind: .bold, in: 1..<3)
        guard case .character(_, let annotations) = bolded.linearModel[1] else {
            Issue.record("expected character")
            return
        }
        #expect(annotations.map(\.kind) == [.bold])
        #expect(bolded.statistics.annotatedCharacterCount == 2)

        // Toggling again over the same range removes it.
        let (unbolded, _) = try bolded.togglingAnnotation(kind: .bold, in: 1..<3)
        #expect(unbolded.statistics.annotatedCharacterCount == 0)

        // Undo restores exactly.
        let (restored, _) = try bolded.splicingItems(in: 1..<3, with: removedItems)
        #expect(restored.linearModel == document.linearModel)
    }

    @Test func togglingMixedRangeAnnotatesEverything() throws {
        let document = try makeDocument("<p>a<b>b</b></p>")
        // "ab" where b is already bold: mixed → both end up bold.
        let (edited, _) = try document.togglingAnnotation(kind: .bold, in: 1..<3)
        #expect(edited.statistics.annotatedCharacterCount == 2)
    }

    @Test func togglingLinkCarriesTarget() throws {
        let document = try makeDocument("<p>ab</p>")
        let (edited, _) = try document.togglingAnnotation(kind: .link, target: "./Queijo", in: 1..<3)
        guard case .character(_, let annotations) = edited.linearModel[1] else {
            Issue.record("expected character")
            return
        }
        #expect(annotations.first?.target == "./Queijo")
    }

    @Test func togglingAnnotationOverStructureThrows() throws {
        let document = try makeDocument("<p>a</p><p>b</p>")
        #expect(throws: WMFVisualEditorDocument.EditingError.rangeContainsStructure) {
            _ = try document.togglingAnnotation(kind: .bold, in: 1..<5)
        }
    }

    @Test func statisticsTrackAnnotatedInsertions() throws {
        let document = try makeDocument("<p>a</p>")
        let bold = [WMFVisualEditorAnnotation(kind: .bold)]
        let (edited, _) = try document.replacingCharacters(in: 2..<2, with: "bb", annotations: bold)

        #expect(edited.statistics.characterCount == 3)
        #expect(edited.statistics.annotatedCharacterCount == 2)
    }
}
