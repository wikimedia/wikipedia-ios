import Foundation
import os
import WMFData

/// Keeps the values in memory. The lock makes the store safe to use from any actor, like the real stores.
public final class WMFMockKeyValueStore: WMFKeyValueStore {

    private let savedData = OSAllocatedUnfairLock<[String: Data]>(initialState: [:])

    public init() {}

    public func load<T: Codable>(key: String...) throws -> T? {
        let defaultsKey = key.joined(separator: ".")
        guard let data = savedData.withLock({ $0[defaultsKey] }) else { return nil }
        return try JSONDecoder().decode(T.self, from: data)
    }

    public func save<T: Codable>(key: String..., value: T) throws {
        let defaultsKey = key.joined(separator: ".")
        let data = try JSONEncoder().encode(value)
        savedData.withLock { $0[defaultsKey] = data }
    }

    public func remove(key: String...) throws {
        let defaultsKey = key.joined(separator: ".")
        savedData.withLock { _ = $0.removeValue(forKey: defaultsKey) }
    }

    public func keys(inDirectory directory: String) throws -> [String] {
        let prefix = directory + "."
        return savedData.withLock { $0.keys }
            .filter { $0.hasPrefix(prefix) }
            .map { String($0.dropFirst(prefix.count)) }
            .sorted()
    }
}
