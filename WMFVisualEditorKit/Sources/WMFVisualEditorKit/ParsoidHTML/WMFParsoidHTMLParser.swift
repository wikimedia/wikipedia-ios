import Foundation

/// Parses Parsoid-serialized HTML into a `WMFParsoidNode` tree.
///
/// This is deliberately not a general-purpose HTML5 parser: Parsoid output is
/// machine-serialized from a DOM — every non-void element is explicitly closed,
/// attributes are quoted, and no tag-soup recovery is required. That regularity is
/// what makes a small exact parser viable. Anything that violates these
/// expectations throws, which for our purposes is the correct behavior: silently
/// "recovering" malformed markup would corrupt content on round-trip.
///
/// Every parsed node carries its exact character range in the source, which is
/// what allows the serializer to emit untouched content byte-for-byte.
public struct WMFParsoidHTMLParser: Sendable {

    public enum ParserError: Error, Equatable {
        case unexpectedEndOfInput
        case malformedTag(position: Int)
        case mismatchedClosingTag(expected: String, found: String, position: Int)
        case missingBody
    }

    private static let voidElements: Set<String> = [
        "area", "base", "br", "col", "embed", "hr", "img", "input",
        "link", "meta", "param", "source", "track", "wbr"
    ]

    private static let rawTextElements: Set<String> = ["script", "style"]

    public init() {}

    /// Parses a full Parsoid document and returns the root (`html`) node.
    public func parseDocument(_ html: String) throws -> WMFParsoidNode {
        var scanner = Scanner(input: html)
        var rootChildren: [WMFParsoidNode] = []
        var stack: [(name: String, attributes: [WMFParsoidAttribute], children: [WMFParsoidNode], openRange: Range<Int>)] = []

        func append(_ node: WMFParsoidNode) {
            if stack.isEmpty {
                rootChildren.append(node)
            } else {
                stack[stack.count - 1].children.append(node)
            }
        }

        while let token = try scanner.nextToken() {
            switch token {
            case .text(let text, let range):
                append(WMFParsoidNode(content: .text(text), sourceRange: range))
            case .comment(let comment, let range):
                append(WMFParsoidNode(content: .comment(comment), sourceRange: range))
            case .doctype:
                break
            case .openTag(let name, let attributes, let selfClosing, let range):
                if selfClosing || Self.voidElements.contains(name) {
                    append(WMFParsoidNode(content: .element(name: name, attributes: attributes, children: []), sourceRange: range))
                } else if Self.rawTextElements.contains(name) {
                    let rawText = try scanner.consumeRawText(until: name)
                    let children: [WMFParsoidNode] = rawText.text.isEmpty ? [] : [
                        WMFParsoidNode(content: .text(rawText.text), sourceRange: rawText.contentRange)
                    ]
                    append(WMFParsoidNode(
                        content: .element(name: name, attributes: attributes, children: children),
                        sourceRange: range.lowerBound..<rawText.endPosition,
                        sourceContentRange: rawText.contentRange))
                } else {
                    stack.append((name, attributes, [], range))
                }
            case .closeTag(let name, let range):
                guard let top = stack.popLast() else {
                    throw ParserError.mismatchedClosingTag(expected: "(none)", found: name, position: scanner.position)
                }
                guard top.name == name else {
                    throw ParserError.mismatchedClosingTag(expected: top.name, found: name, position: scanner.position)
                }
                append(WMFParsoidNode(
                    content: .element(name: top.name, attributes: top.attributes, children: top.children),
                    sourceRange: top.openRange.lowerBound..<range.upperBound,
                    sourceContentRange: top.openRange.upperBound..<range.lowerBound))
            }
        }

        guard stack.isEmpty else {
            throw ParserError.unexpectedEndOfInput
        }

        if rootChildren.count == 1, let only = rootChildren.first, only.elementName != nil {
            return only
        }
        return WMFParsoidNode(content: .element(name: "#root", attributes: [], children: rootChildren), sourceRange: 0..<scanner.position)
    }

    /// Parses a full document and returns its `body` element.
    public func parseBody(_ html: String) throws -> WMFParsoidNode {
        let root = try parseDocument(html)
        guard let body = root.firstElement(named: "body") else {
            throw ParserError.missingBody
        }
        return body
    }

    // MARK: - Tokenizer

    private enum Token {
        case text(String, Range<Int>)
        case comment(String, Range<Int>)
        case doctype
        case openTag(name: String, attributes: [WMFParsoidAttribute], selfClosing: Bool, range: Range<Int>)
        case closeTag(name: String, range: Range<Int>)
    }

    private struct Scanner {
        private let characters: [Character]
        private var index = 0

        var position: Int { index }

        init(input: String) {
            self.characters = Array(input)
        }

        private var isAtEnd: Bool { index >= characters.count }

        private func peek(_ offset: Int = 0) -> Character? {
            let peekIndex = index + offset
            return peekIndex < characters.count ? characters[peekIndex] : nil
        }

        private mutating func matches(_ literal: String) -> Bool {
            let literalCharacters = Array(literal)
            guard index + literalCharacters.count <= characters.count else {
                return false
            }
            for (offset, character) in literalCharacters.enumerated() where characters[index + offset] != character {
                return false
            }
            return true
        }

        mutating func nextToken() throws -> Token? {
            guard !isAtEnd else {
                return nil
            }

            if peek() == "<" {
                if matches("<!--") {
                    return try consumeComment()
                }
                if matches("<!") {
                    return try consumeDoctype()
                }
                if peek(1) == "/" {
                    return try consumeCloseTag()
                }
                return try consumeOpenTag()
            }
            return consumeText()
        }

        private mutating func consumeText() -> Token {
            let start = index
            var text = ""
            while !isAtEnd, peek() != "<" {
                text.append(characters[index])
                index += 1
            }
            return .text(WMFParsoidHTMLEntities.decode(text), start..<index)
        }

        private mutating func consumeComment() throws -> Token {
            let start = index
            index += 4 // <!--
            var comment = ""
            while !isAtEnd {
                if matches("-->") {
                    index += 3
                    return .comment(comment, start..<index)
                }
                comment.append(characters[index])
                index += 1
            }
            throw ParserError.unexpectedEndOfInput
        }

        private mutating func consumeDoctype() throws -> Token {
            while !isAtEnd, peek() != ">" {
                index += 1
            }
            guard !isAtEnd else {
                throw ParserError.unexpectedEndOfInput
            }
            index += 1 // >
            return .doctype
        }

        private mutating func consumeCloseTag() throws -> Token {
            let start = index
            index += 2 // </
            var name = ""
            while !isAtEnd, let character = peek(), character != ">" {
                name.append(character)
                index += 1
            }
            guard !isAtEnd else {
                throw ParserError.unexpectedEndOfInput
            }
            index += 1 // >
            return .closeTag(name: name.trimmingCharacters(in: .whitespaces).lowercased(), range: start..<index)
        }

        private mutating func consumeOpenTag() throws -> Token {
            let start = index
            index += 1 // <
            var name = ""
            while !isAtEnd, let character = peek(), !character.isWhitespace, character != ">", character != "/" {
                name.append(character)
                index += 1
            }
            guard !name.isEmpty else {
                throw ParserError.malformedTag(position: start)
            }

            var attributes: [WMFParsoidAttribute] = []
            var selfClosing = false

            while true {
                while !isAtEnd, let character = peek(), character.isWhitespace {
                    index += 1
                }
                guard !isAtEnd else {
                    throw ParserError.unexpectedEndOfInput
                }
                if peek() == ">" {
                    index += 1
                    break
                }
                if peek() == "/" {
                    index += 1
                    if peek() == ">" {
                        index += 1
                        selfClosing = true
                        break
                    }
                    throw ParserError.malformedTag(position: index)
                }
                attributes.append(try consumeAttribute())
            }

            return .openTag(name: name.lowercased(), attributes: attributes, selfClosing: selfClosing, range: start..<index)
        }

        private mutating func consumeAttribute() throws -> WMFParsoidAttribute {
            var name = ""
            while !isAtEnd, let character = peek(), !character.isWhitespace, character != "=", character != ">", character != "/" {
                name.append(character)
                index += 1
            }
            while !isAtEnd, let character = peek(), character.isWhitespace {
                index += 1
            }
            guard peek() == "=" else {
                return WMFParsoidAttribute(name: name, value: "")
            }
            index += 1 // =
            while !isAtEnd, let character = peek(), character.isWhitespace {
                index += 1
            }
            guard let quote = peek(), quote == "\"" || quote == "'" else {
                // Parsoid always quotes attribute values; accept unquoted as a value
                // terminated by whitespace or '>' for robustness.
                var value = ""
                while !isAtEnd, let character = peek(), !character.isWhitespace, character != ">" {
                    value.append(character)
                    index += 1
                }
                return WMFParsoidAttribute(name: name, value: WMFParsoidHTMLEntities.decode(value))
            }
            index += 1 // opening quote
            var value = ""
            while !isAtEnd, let character = peek(), character != quote {
                value.append(character)
                index += 1
            }
            guard !isAtEnd else {
                throw ParserError.unexpectedEndOfInput
            }
            index += 1 // closing quote
            return WMFParsoidAttribute(name: name, value: WMFParsoidHTMLEntities.decode(value))
        }

        mutating func consumeRawText(until elementName: String) throws -> (text: String, contentRange: Range<Int>, endPosition: Int) {
            let closing = "</\(elementName)"
            let contentStart = index
            var rawText = ""
            while !isAtEnd {
                if peek() == "<", matches(closing) {
                    let contentEnd = index
                    index += closing.count
                    while !isAtEnd, peek() != ">" {
                        index += 1
                    }
                    guard !isAtEnd else {
                        throw ParserError.unexpectedEndOfInput
                    }
                    index += 1 // >
                    return (rawText, contentStart..<contentEnd, index)
                }
                rawText.append(characters[index])
                index += 1
            }
            throw ParserError.unexpectedEndOfInput
        }
    }
}

/// Decodes the HTML character references Parsoid emits. Parsoid entity-encodes
/// only what HTML requires (ampersands, angle brackets, quotes in attributes)
/// plus numeric references; unknown named references are left untouched rather
/// than guessed at.
enum WMFParsoidHTMLEntities {
    private static let named: [String: String] = [
        "amp": "&", "lt": "<", "gt": ">", "quot": "\"", "apos": "'", "nbsp": "\u{00A0}"
    ]

    static func decode(_ input: String) -> String {
        guard input.contains("&") else {
            return input
        }

        var output = ""
        output.reserveCapacity(input.count)
        var remainder = Substring(input)

        while let ampersandIndex = remainder.firstIndex(of: "&") {
            output += remainder[..<ampersandIndex]
            remainder = remainder[ampersandIndex...]

            guard let semicolonIndex = remainder.firstIndex(of: ";"),
                  remainder.distance(from: remainder.startIndex, to: semicolonIndex) <= 10 else {
                output.append(remainder.removeFirst())
                continue
            }

            let entity = remainder[remainder.index(after: remainder.startIndex)..<semicolonIndex]
            if entity.hasPrefix("#") {
                let numeric = entity.dropFirst()
                let scalarValue: UInt32?
                if numeric.hasPrefix("x") || numeric.hasPrefix("X") {
                    scalarValue = UInt32(numeric.dropFirst(), radix: 16)
                } else {
                    scalarValue = UInt32(numeric)
                }
                if let scalarValue, let scalar = Unicode.Scalar(scalarValue) {
                    output.append(Character(scalar))
                    remainder = remainder[remainder.index(after: semicolonIndex)...]
                    continue
                }
            } else if let replacement = named[String(entity)] {
                output += replacement
                remainder = remainder[remainder.index(after: semicolonIndex)...]
                continue
            }

            output.append(remainder.removeFirst())
        }

        output += remainder
        return output
    }

    /// Minimal encoding for serialized text content: only what HTML requires.
    static func encodeText(_ input: String) -> String {
        var output = ""
        output.reserveCapacity(input.count)
        for character in input {
            switch character {
            case "&":
                output += "&amp;"
            case "<":
                output += "&lt;"
            case ">":
                output += "&gt;"
            default:
                output.append(character)
            }
        }
        return output
    }

    /// Minimal encoding for double-quoted attribute values.
    static func encodeAttributeValue(_ input: String) -> String {
        var output = ""
        output.reserveCapacity(input.count)
        for character in input {
            switch character {
            case "&":
                output += "&amp;"
            case "\"":
                output += "&quot;"
            default:
                output.append(character)
            }
        }
        return output
    }
}
