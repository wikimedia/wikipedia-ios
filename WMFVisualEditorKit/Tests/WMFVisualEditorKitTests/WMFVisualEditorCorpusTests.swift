import Testing
import Foundation
@testable import WMFVisualEditorKit

/// Parses real Parsoid documents (checked-in snapshots from the oracle corpus)
/// end to end: tokenizer → tree → linear model. The full multilingual corpus and
/// the VisualEditor oracle comparison run from Oracle/ (see Oracle/README.md);
/// these fixtures keep a fast real-world regression signal in CI.
struct WMFVisualEditorCorpusTests {

    private func loadFixture(_ name: String) throws -> String {
        let url = try #require(Bundle.module.url(forResource: "Fixtures/\(name)", withExtension: "html"))
        return try String(contentsOf: url, encoding: .utf8)
    }

    // zh__cheese is deliberately template-heavy: 57KB of Parsoid HTML containing a
    // single <p> — nearly all its content lives inside transclusions (opaque nodes).
    @Test(arguments: [
        (fixtureName: "pt__lontra", minimumCharacterCount: 500),
        (fixtureName: "zh__cheese", minimumCharacterCount: 20)
    ])
    func parsesRealParsoidDocument(fixtureName: String, minimumCharacterCount: Int) throws {
        let html = try loadFixture(fixtureName)
        let document = try WMFVisualEditorDocument.parse(parsoidHTML: html)

        #expect(!document.linearModel.isEmpty)
        #expect(document.statistics.characterCount > minimumCharacterCount)
        #expect(document.statistics.nodeTypeCounts["paragraph", default: 0] > 0)
        #expect(document.statistics.nodeTypeCounts["section", default: 0] > 0)
        #expect(document.statistics.nodeTypeCounts["mwTransclusion", default: 0] > 0)

        // Every open must have a matching close and depth must never go negative.
        var depth = 0
        for item in document.linearModel {
            if case .open = item {
                depth += 1
            } else if case .close = item {
                depth -= 1
            }
            #expect(depth >= 0)
        }
        #expect(depth == 0)
    }

    @Test func fidelityTreePreservesParsoidMetadata() throws {
        let html = try loadFixture("pt__lontra")
        let parser = WMFParsoidHTMLParser()
        let body = try parser.parseBody(html)

        // The tree must retain Parsoid/RDFa metadata for future round-tripping.
        var transclusionCount = 0
        func walk(_ node: WMFParsoidNode) {
            if let typeOf = node.attributeValue("typeof"), typeOf.contains("mw:Transclusion") {
                transclusionCount += 1
                #expect(node.attributeValue("data-mw") != nil)
            }
            for child in node.children {
                walk(child)
            }
        }
        walk(body)
        #expect(transclusionCount > 0)
    }
}
