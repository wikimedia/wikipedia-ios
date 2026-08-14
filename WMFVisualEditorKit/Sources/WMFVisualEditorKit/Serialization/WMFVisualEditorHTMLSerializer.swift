import Foundation

/// Serializes an edited document back to Parsoid HTML using **selective
/// serialization**: any node whose subtree was not touched by an edit is
/// emitted byte-for-byte from the original source; only dirty blocks are
/// re-serialized from the linear model. This is the mechanism behind the
/// project's core invariant — a null edit (open, save, no changes) must
/// produce byte-identical HTML, and therefore a clean wikitext diff.
public struct WMFVisualEditorHTMLSerializer: Sendable {

    public init() {}

    /// Serializes the complete document: everything outside the body content
    /// (doctype, head, body tags) comes verbatim from the source, the body
    /// content is serialized selectively.
    public func serializeDocument(_ document: WMFVisualEditorDocument) -> String {
        let source = Array(document.sourceHTML)
        guard !source.isEmpty, let bodyContentRange = document.bodyNode.sourceContentRange else {
            return serializeBodyContent(document)
        }
        let prefix = String(source[0..<bodyContentRange.lowerBound])
        let suffix = String(source[bodyContentRange.upperBound..<source.count])
        return prefix + serializeBodyContent(document) + suffix
    }

    /// Serializes only the body content (the linear model).
    public func serializeBodyContent(_ document: WMFVisualEditorDocument) -> String {
        let source = Array(document.sourceHTML)
        var output = ""
        var index = 0
        while index < document.linearModel.count {
            index = serialize(itemAt: index, document: document, source: source, into: &output)
        }
        return output
    }

    // MARK: - Private

    private func serialize(itemAt index: Int, document: WMFVisualEditorDocument, source: [Character], into output: inout String) -> Int {
        let items = document.linearModel
        switch items[index] {
        case .character:
            return serializeCharacterRun(startingAt: index, items: items, into: &output)

        case .close:
            // Unreachable for balanced models; skip defensively.
            return index + 1

        case .open(let type, let attributes, let preservedContent):
            let closeIndex = matchingCloseIndex(forOpenAt: index, in: items)

            // Clean subtree parsed from source → emit the original bytes.
            let containsDirtyIndex = document.dirtyBlockIndices.contains { $0 >= index && $0 <= closeIndex }
            if !containsDirtyIndex, let sourceRange = preservedContent?.sourceRange {
                output += String(source[sourceRange])
                return closeIndex + 1
            }

            // Dirty (or synthesized) node: canonical open tag, recurse, close tag.
            let tag = tags(type: type, attributes: attributes, preservedContent: preservedContent)
            output += tag.open
            var childIndex = index + 1
            while childIndex < closeIndex {
                childIndex = serialize(itemAt: childIndex, document: document, source: source, into: &output)
            }
            output += tag.close
            return closeIndex + 1
        }
    }

    /// Serializes a run of character items, reconstructing annotation elements
    /// (bold/italic/link) with their preserved names and attributes.
    private func serializeCharacterRun(startingAt startIndex: Int, items: [WMFVisualEditorLinearItem], into output: inout String) -> Int {
        var index = startIndex
        var openAnnotations: [WMFVisualEditorAnnotation] = []

        func closeAnnotations(downTo keepCount: Int) {
            while openAnnotations.count > keepCount {
                let annotation = openAnnotations.removeLast()
                output += "</\(elementName(for: annotation))>"
            }
        }

        func openAnnotation(_ annotation: WMFVisualEditorAnnotation) {
            var tag = "<" + elementName(for: annotation)
            if annotation.attributes.isEmpty, annotation.kind == .link, let target = annotation.target {
                tag += " rel=\"mw:WikiLink\" href=\"\(WMFParsoidHTMLEntities.encodeAttributeValue(target))\""
            } else {
                for attribute in annotation.attributes {
                    tag += " \(attribute.name)=\"\(WMFParsoidHTMLEntities.encodeAttributeValue(attribute.value))\""
                }
            }
            tag += ">"
            output += tag
            openAnnotations.append(annotation)
        }

        while index < items.count, case .character(let character, let annotations) = items[index] {
            // Close annotations no longer active, open newly active ones. The
            // shared prefix stays open — annotations nest in model order.
            var sharedPrefixCount = 0
            while sharedPrefixCount < openAnnotations.count,
                  sharedPrefixCount < annotations.count,
                  openAnnotations[sharedPrefixCount] == annotations[sharedPrefixCount] {
                sharedPrefixCount += 1
            }
            closeAnnotations(downTo: sharedPrefixCount)
            for annotation in annotations[sharedPrefixCount...] {
                openAnnotation(annotation)
            }

            output += WMFParsoidHTMLEntities.encodeText(String(character))
            index += 1
        }
        closeAnnotations(downTo: 0)
        return index
    }

    private func elementName(for annotation: WMFVisualEditorAnnotation) -> String {
        if let elementName = annotation.elementName {
            return elementName
        }
        switch annotation.kind {
        case .bold:
            return "b"
        case .italic:
            return "i"
        case .link:
            return "a"
        case .superscripted:
            return "sup"
        case .subscripted:
            return "sub"
        case .strikethrough:
            return "s"
        case .underline:
            return "u"
        case .code:
            return "code"
        }
    }

    /// Open/close tags for a dirty or synthesized node. Nodes parsed from
    /// source re-emit their original element name and ordered attributes;
    /// synthesized blocks (e.g. paragraphs created by splits) emit bare tags.
    private func tags(type: String, attributes: [String: String], preservedContent: WMFParsoidNode?) -> (open: String, close: String) {
        if let node = preservedContent, case .element(let name, let nodeAttributes, _) = node.content {
            var openTag = "<" + name
            for attribute in nodeAttributes {
                openTag += " \(attribute.name)=\"\(WMFParsoidHTMLEntities.encodeAttributeValue(attribute.value))\""
            }
            openTag += ">"
            return (openTag, "</\(name)>")
        }

        switch type {
        case "paragraph":
            return ("<p>", "</p>")
        case "heading":
            let level = attributes["level"] ?? "2"
            return ("<h\(level)>", "</h\(level)>")
        case "list":
            return attributes["style"] == "number" ? ("<ol>", "</ol>") : ("<ul>", "</ul>")
        case "listItem":
            return ("<li>", "</li>")
        case "section":
            return ("<section>", "</section>")
        default:
            // Synthesized containers/metas have no markup of their own.
            return ("", "")
        }
    }

    private func matchingCloseIndex(forOpenAt openIndex: Int, in items: [WMFVisualEditorLinearItem]) -> Int {
        var depth = 0
        for index in openIndex..<items.count {
            switch items[index] {
            case .open:
                depth += 1
            case .close:
                depth -= 1
                if depth == 0 {
                    return index
                }
            case .character:
                break
            }
        }
        return items.count - 1
    }
}
