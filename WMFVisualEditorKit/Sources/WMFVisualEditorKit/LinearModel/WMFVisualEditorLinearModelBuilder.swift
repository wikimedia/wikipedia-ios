import Foundation

/// Converts a Parsoid document tree into the linear document model.
///
/// This intentionally models only the subset of node types the native editor
/// understands so far — paragraphs, headings, lists, sections — plus bold,
/// italic, and link annotations. Every other element becomes an `alien` node
/// that preserves its complete subtree, and non-content source (inter-block
/// whitespace, comments, styles, metas) becomes invisible `meta` items. Nothing
/// is dropped: the serializer re-emits every preserved node byte-for-byte from
/// the original source.
public struct WMFVisualEditorLinearModelBuilder: Sendable {

    public init() {}

    public struct Output: Sendable {
        public let items: [WMFVisualEditorLinearItem]
        public let statistics: WMFVisualEditorDocumentStatistics
    }

    private static let headingLevels: [String: Int] = [
        "h1": 1, "h2": 2, "h3": 3, "h4": 4, "h5": 5, "h6": 6
    ]

    /// Elements that carry no visible article content; preserved as meta items.
    private static let metaElements: Set<String> = ["style", "script", "link", "meta", "base"]

    /// Elements that only contribute annotations, not structure.
    private static let annotationKindsByElementName: [String: WMFVisualEditorAnnotation.Kind] = [
        "b": .bold, "strong": .bold,
        "i": .italic, "em": .italic,
        "a": .link,
        "sup": .superscripted,
        "sub": .subscripted,
        "s": .strikethrough, "del": .strikethrough, "strike": .strikethrough,
        "u": .underline, "ins": .underline,
        "code": .code, "tt": .code
    ]

    public func buildLinearModel(bodyNode: WMFParsoidNode) -> Output {
        var state = BuilderState()
        for child in bodyNode.children {
            convert(node: child, annotations: [], state: &state)
        }
        return Output(items: state.items, statistics: state.statistics)
    }

    // MARK: - Private

    private struct BuilderState {
        var items: [WMFVisualEditorLinearItem] = []
        var statistics = WMFVisualEditorDocumentStatistics()

        mutating func open(_ type: String, attributes: [String: String] = [:], preservedContent: WMFParsoidNode? = nil) {
            items.append(.open(type: type, attributes: attributes, preservedContent: preservedContent))
            statistics.nodeTypeCounts[type, default: 0] += 1
        }

        mutating func close(_ type: String) {
            items.append(.close(type: type))
        }

        mutating func appendMeta(_ node: WMFParsoidNode) {
            items.append(.open(type: "meta", attributes: [:], preservedContent: node))
            items.append(.close(type: "meta"))
            statistics.nodeTypeCounts["meta", default: 0] += 1
        }

        mutating func appendText(_ text: String, annotations: [WMFVisualEditorAnnotation]) {
            for character in text {
                items.append(.character(character, annotations: annotations))
                statistics.characterCount += 1
                if !annotations.isEmpty {
                    statistics.annotatedCharacterCount += 1
                }
            }
        }
    }

    private func convert(node: WMFParsoidNode, annotations: [WMFVisualEditorAnnotation], state: inout BuilderState) {
        switch node.content {
        case .comment:
            state.appendMeta(node)

        case .text(let text):
            // Whitespace-only text between block elements is serialization
            // formatting, not content — preserved invisibly for round-tripping.
            if text.allSatisfy({ $0.isWhitespace }) {
                if !text.isEmpty {
                    state.appendMeta(node)
                }
                return
            }
            state.appendText(text, annotations: annotations)

        case .element(let name, _, let children):
            if Self.metaElements.contains(name) {
                state.appendMeta(node)
                return
            }

            // Transclusions (templates) are opaque regardless of their element name.
            if let typeOf = node.attributeValue("typeof"), typeOf.contains("mw:Transclusion") {
                state.open("mwTransclusion", attributes: metadataAttributes(of: node), preservedContent: node)
                state.close("mwTransclusion")
                return
            }

            // Images (figure / mw:File spans): opaque like aliens — preserved
            // byte-for-byte — but typed so the surface can render the picture.
            if let imageAttributes = imageAttributes(of: node) {
                state.open("mwImage", attributes: imageAttributes, preservedContent: node)
                state.close("mwImage")
                return
            }

            switch name {
            case "section":
                state.open("section", attributes: metadataAttributes(of: node), preservedContent: node)
                for child in children {
                    convert(node: child, annotations: annotations, state: &state)
                }
                state.close("section")

            // Parsoid wraps content in structural containers — modern output puts
            // every heading inside <div class="mw-heading">, hatnotes and quote
            // boxes in <div>/<blockquote> — so wrappers must be descended through
            // transparently or entire blocks collapse into opaque nodes.
            case "div", "blockquote", "center":
                state.open("container", attributes: metadataAttributes(of: node), preservedContent: node)
                for child in children {
                    convert(node: child, annotations: annotations, state: &state)
                }
                state.close("container")

            case "p":
                state.open("paragraph", preservedContent: node)
                convertInlineChildren(children, annotations: annotations, state: &state)
                state.close("paragraph")

            case "h1", "h2", "h3", "h4", "h5", "h6":
                let level = Self.headingLevels[name] ?? 2
                state.open("heading", attributes: ["level": String(level)], preservedContent: node)
                convertInlineChildren(children, annotations: annotations, state: &state)
                state.close("heading")

            case "ul", "ol":
                state.open("list", attributes: ["style": name == "ol" ? "number" : "bullet"], preservedContent: node)
                for child in children {
                    convert(node: child, annotations: annotations, state: &state)
                }
                state.close("list")

            case "li":
                state.open("listItem", preservedContent: node)
                convertInlineChildren(children, annotations: annotations, state: &state)
                state.close("listItem")

            default:
                state.open("alien", attributes: metadataAttributes(of: node), preservedContent: node)
                state.close("alien")
            }
        }
    }

    /// Converts children in an inline (content) context: annotation elements
    /// extend the annotation set; nested block elements fall back to the block
    /// conversion; unknown inline elements become inline aliens.
    private func convertInlineChildren(_ children: [WMFParsoidNode], annotations: [WMFVisualEditorAnnotation], state: inout BuilderState) {
        for child in children {
            switch child.content {
            case .comment:
                state.appendMeta(child)

            case .text(let text):
                state.appendText(text, annotations: annotations)

            case .element(let name, _, let grandchildren):
                if Self.metaElements.contains(name) {
                    state.appendMeta(child)
                    continue
                }

                if let typeOf = child.attributeValue("typeof"), typeOf.contains("mw:Transclusion") {
                    state.open("mwTransclusion", attributes: metadataAttributes(of: child), preservedContent: child)
                    state.close("mwTransclusion")
                    continue
                }

                if let imageAttributes = imageAttributes(of: child) {
                    state.open("mwImage", attributes: imageAttributes, preservedContent: child)
                    state.close("mwImage")
                    continue
                }

                // Only annotation elements WITHOUT RDFa typeof are style spans a
                // user may edit through. With typeof they are extension output —
                // `<sup typeof="mw:Extension/ref">` is a citation marker, not
                // superscripted text — and must stay opaque.
                if let kind = Self.annotationKindsByElementName[name], child.attributeValue("typeof") == nil {
                    var extended = annotations
                    let target = kind == .link ? child.attributeValue("href") : nil
                    extended.append(WMFVisualEditorAnnotation(kind: kind, target: target, elementName: name, attributes: child.attributes))
                    convertInlineChildren(grandchildren, annotations: extended, state: &state)
                    continue
                }

                // <span> is pure structure in Parsoid output (language wrappers,
                // ID anchors); descend transparently rather than alienating it.
                // The span wrapper itself is preserved via the enclosing block's
                // dirtiness rules: clean blocks serialize from source.
                if name == "span" {
                    state.open("container", attributes: metadataAttributes(of: child), preservedContent: child)
                    convertInlineChildren(grandchildren, annotations: annotations, state: &state)
                    state.close("container")
                    continue
                }

                state.open("alien", attributes: metadataAttributes(of: child), preservedContent: child)
                state.close("alien")
            }
        }
    }

    /// For image nodes (`<figure>` or anything typed `mw:File…`): the rendering
    /// info the surface needs, or nil when the node is not an image.
    private func imageAttributes(of node: WMFParsoidNode) -> [String: String]? {
        let isImageElement = node.elementName == "figure" || node.elementName == "figure-inline"
        let isFileTyped = node.attributeValue("typeof")?.contains("mw:File") ?? false
        guard isImageElement || isFileTyped else {
            return nil
        }
        guard let imageElement = node.firstElement(named: "img"), let source = imageElement.attributeValue("src") else {
            return nil
        }

        var attributes = metadataAttributes(of: node)
        attributes["src"] = source
        if let width = imageElement.attributeValue("width") {
            attributes["width"] = width
        }
        if let height = imageElement.attributeValue("height") {
            attributes["height"] = height
        }
        if let caption = node.firstElement(named: "figcaption") {
            attributes["caption"] = caption.displayTextContent.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return attributes
    }

    private func metadataAttributes(of node: WMFParsoidNode) -> [String: String] {
        var metadata: [String: String] = [:]
        for interestingAttribute in ["typeof", "about", "id", "data-mw-section-id", "class"] {
            if let value = node.attributeValue(interestingAttribute) {
                metadata[interestingAttribute] = value
            }
        }
        if let elementName = node.elementName {
            metadata["element"] = elementName
        }
        return metadata
    }
}
