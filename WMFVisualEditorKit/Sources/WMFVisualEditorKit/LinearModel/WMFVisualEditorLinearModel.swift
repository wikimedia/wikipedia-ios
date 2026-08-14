import Foundation

/// A text annotation in the linear model (VisualEditor's equivalent of a
/// character style span): bold, italic, or a wiki link.
///
/// The source element's name and full ordered attributes are preserved so the
/// serializer can re-emit annotations in edited blocks without losing markup
/// (`rel="mw:WikiLink"` on links, IDs on bold spans, etc.).
public struct WMFVisualEditorAnnotation: Sendable, Hashable {
    public enum Kind: String, Sendable {
        case bold
        case italic
        case link
        case superscripted
        case subscripted
        case strikethrough
        case underline
        case code
    }

    public let kind: Kind
    /// For links, the target href as present in the Parsoid HTML.
    public let target: String?
    /// The source element name (`b` vs `strong`, …); nil for annotations
    /// created by edits rather than parsed from source.
    public let elementName: String?
    public let attributes: [WMFParsoidAttribute]

    public init(kind: Kind, target: String? = nil, elementName: String? = nil, attributes: [WMFParsoidAttribute] = []) {
        self.kind = kind
        self.target = target
        self.elementName = elementName
        self.attributes = attributes
    }
}

/// One item of the linear document model, mirroring VisualEditor's `ve.dm`
/// linear data: element open/close markers interleaved with annotated characters.
///
/// Node types the editor does not (yet) model natively are preserved as
/// `.open(type: "alien", ...)` items carrying their entire original subtree, so
/// nothing is lost between parse and (future) serialization.
public enum WMFVisualEditorLinearItem: Sendable, Equatable {
    case open(type: String, attributes: [String: String], preservedContent: WMFParsoidNode?)
    case close(type: String)
    case character(Character, annotations: [WMFVisualEditorAnnotation])
}

/// Node type statistics for a converted document — used by tests and by the
/// playground's model inspector.
public struct WMFVisualEditorDocumentStatistics: Sendable, Equatable {
    public internal(set) var nodeTypeCounts: [String: Int] = [:]
    public internal(set) var characterCount: Int = 0
    public internal(set) var annotatedCharacterCount: Int = 0
    public internal(set) var skippedElementCounts: [String: Int] = [:]
}
