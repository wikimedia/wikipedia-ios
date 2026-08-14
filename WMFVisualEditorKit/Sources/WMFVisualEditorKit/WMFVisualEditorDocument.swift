import Foundation

/// A parsed Parsoid document plus its linear editing model — the entry point of
/// the native visual editor engine.
public struct WMFVisualEditorDocument: Sendable {
    /// The complete, fidelity-preserving document tree (from `<body>`).
    public let bodyNode: WMFParsoidNode
    /// The linear editing model built from the tree.
    public let linearModel: [WMFVisualEditorLinearItem]
    public let statistics: WMFVisualEditorDocumentStatistics
    /// The exact source this document was parsed from. Node source ranges are
    /// character offsets into this string; the serializer re-emits untouched
    /// content from it byte-for-byte.
    public let sourceHTML: String
    /// Linear indices of open items whose subtrees have been edited. Everything
    /// outside these subtrees serializes from `sourceHTML` unchanged.
    public let dirtyBlockIndices: Set<Int>

    /// Parses a full Parsoid HTML document (as returned by
    /// `/api/rest_v1/page/html/{title}`) and builds its linear model.
    public static func parse(parsoidHTML: String) throws -> WMFVisualEditorDocument {
        let parser = WMFParsoidHTMLParser()
        let bodyNode = try parser.parseBody(parsoidHTML)
        let output = WMFVisualEditorLinearModelBuilder().buildLinearModel(bodyNode: bodyNode)
        return WMFVisualEditorDocument(
            bodyNode: bodyNode,
            linearModel: output.items,
            statistics: output.statistics,
            sourceHTML: parsoidHTML,
            dirtyBlockIndices: []
        )
    }
}
