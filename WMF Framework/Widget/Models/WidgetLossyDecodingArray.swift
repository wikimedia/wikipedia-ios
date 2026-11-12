import Foundation

/// Decodes a JSON array element by element, dropping the elements that fail to decode instead of
/// failing the whole array. The feed API omits keys for individual articles now and then (a newly
/// trending page without `view_history`, an article without `extract`), and one bad element must
/// not take every widget down with it.
public struct WidgetLossyDecodingArray<Element: Codable>: Codable {

    // MARK: - Nested Types

    /// Decodes anything, so the unkeyed container can skip past an element that failed to decode.
    private struct AnyDecodableValue: Decodable {
        init(from decoder: Decoder) throws {}
    }

    // MARK: - Properties

    public var elements: [Element]

    /// Runtime-only (excluded from encoding): one description per element that was dropped.
    public var droppedElementErrors: [String] = []

    // MARK: - Public

    public init(elements: [Element]) {
        self.elements = elements
    }

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        var elements: [Element] = []
        var droppedElementErrors: [String] = []

        while !container.isAtEnd {
            let index = container.currentIndex
            do {
                elements.append(try container.decode(Element.self))
            } catch {
                droppedElementErrors.append("[\(index)] \(WidgetDecodingErrorDescription.describe(error))")
                // Consume the element so the container moves on to the next one.
                _ = try? container.decode(AnyDecodableValue.self)
            }
        }

        self.elements = elements
        self.droppedElementErrors = droppedElementErrors
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(elements)
    }

}

/// Short, log-friendly descriptions of `DecodingError`, with the JSON path that failed.
public enum WidgetDecodingErrorDescription {

    public static func describe(_ error: Error) -> String {
        guard let decodingError = error as? DecodingError else {
            return String(describing: error)
        }

        switch decodingError {
        case .keyNotFound(let key, let context):
            return "missing key '\(key.stringValue)' at \(path(context.codingPath))"
        case .typeMismatch(let type, let context):
            return "type mismatch, expected \(type) at \(path(context.codingPath))"
        case .valueNotFound(let type, let context):
            return "null instead of \(type) at \(path(context.codingPath))"
        case .dataCorrupted(let context):
            return "corrupted data at \(path(context.codingPath)): \(context.debugDescription)"
        @unknown default:
            return String(describing: decodingError)
        }
    }

    private static func path(_ codingPath: [CodingKey]) -> String {
        guard !codingPath.isEmpty else {
            return "root"
        }
        return codingPath.map { key in
            if let index = key.intValue {
                return "[\(index)]"
            }
            return key.stringValue
        }.joined(separator: ".")
    }

}
