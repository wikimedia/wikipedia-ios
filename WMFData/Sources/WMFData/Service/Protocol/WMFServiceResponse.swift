import Foundation

/// A decoded response with the HTTP headers that came with it.
public struct WMFServiceResponse<Value: Sendable>: Sendable {
    public let value: Value
    private let headers: [String: String]

    public init(value: Value, headers: [String: String] = [:]) {
        self.value = value
        self.headers = Dictionary(headers.map { ($0.key.lowercased(), $0.value) }, uniquingKeysWith: { first, _ in first })
    }

    /// The header value. The name is not case sensitive, as in HTTP.
    public func header(_ name: String) -> String? {
        headers[name.lowercased()]
    }
}
