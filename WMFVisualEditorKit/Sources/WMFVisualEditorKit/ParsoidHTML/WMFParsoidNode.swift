import Foundation

/// A single attribute of a Parsoid HTML element. Order is preserved because
/// byte-faithful re-serialization of untouched content depends on it.
public struct WMFParsoidAttribute: Sendable, Hashable {
    public let name: String
    public let value: String

    public init(name: String, value: String) {
        self.name = name
        self.value = value
    }
}

/// A node in the document tree parsed from Parsoid HTML.
///
/// The tree preserves everything, including markup the editor does not
/// understand (`data-mw`, `data-parsoid`, RDFa `typeof`, unknown elements),
/// and every node parsed from source carries its exact source ranges so that
/// untouched content re-serializes byte-for-byte from the original document.
public struct WMFParsoidNode: Sendable, Equatable {

    public indirect enum Content: Sendable, Equatable {
        case element(name: String, attributes: [WMFParsoidAttribute], children: [WMFParsoidNode])
        case text(String)
        case comment(String)
    }

    public let content: Content
    /// This node's span in the source (character offsets), including its tags.
    /// nil for nodes synthesized by edits rather than parsed from source.
    public let sourceRange: Range<Int>?
    /// For elements: the span between the end of the open tag and the start of
    /// the close tag. nil for void/self-closing elements and synthesized nodes.
    public let sourceContentRange: Range<Int>?

    public init(content: Content, sourceRange: Range<Int>? = nil, sourceContentRange: Range<Int>? = nil) {
        self.content = content
        self.sourceRange = sourceRange
        self.sourceContentRange = sourceContentRange
    }

    // MARK: - Construction conveniences (used heavily in tests)

    public static func element(name: String, attributes: [WMFParsoidAttribute], children: [WMFParsoidNode]) -> WMFParsoidNode {
        WMFParsoidNode(content: .element(name: name, attributes: attributes, children: children))
    }

    public static func text(_ text: String) -> WMFParsoidNode {
        WMFParsoidNode(content: .text(text))
    }

    public static func comment(_ comment: String) -> WMFParsoidNode {
        WMFParsoidNode(content: .comment(comment))
    }

    // MARK: - Convenience accessors

    public var elementName: String? {
        if case .element(let name, _, _) = content {
            return name
        }
        return nil
    }

    public var children: [WMFParsoidNode] {
        if case .element(_, _, let children) = content {
            return children
        }
        return []
    }

    public var attributes: [WMFParsoidAttribute] {
        if case .element(_, let attributes, _) = content {
            return attributes
        }
        return []
    }

    public func attributeValue(_ attributeName: String) -> String? {
        attributes.first { $0.name == attributeName }?.value
    }

    /// Depth-first search for the first element with the given name.
    public func firstElement(named searchedName: String) -> WMFParsoidNode? {
        if case .element(let name, _, let children) = content {
            if name == searchedName {
                return self
            }
            for child in children {
                if let found = child.firstElement(named: searchedName) {
                    return found
                }
            }
        }
        return nil
    }

    /// Concatenated text content of the subtree.
    public var textContent: String {
        switch content {
        case .text(let text):
            return text
        case .comment:
            return ""
        case .element(_, _, let children):
            return children.map { $0.textContent }.joined()
        }
    }

    /// Text content suitable for display: skips `style` and `script` subtrees,
    /// whose raw text (CSS from TemplateStyles, notably) is not article content.
    public var displayTextContent: String {
        switch content {
        case .text(let text):
            return text
        case .comment:
            return ""
        case .element(let name, _, let children):
            if name == "style" || name == "script" {
                return ""
            }
            return children.map { $0.displayTextContent }.joined()
        }
    }
}
