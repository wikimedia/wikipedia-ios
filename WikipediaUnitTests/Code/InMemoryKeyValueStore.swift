import Foundation
import os
import WMFData

/// A key-value store that lives only for one test. The lock makes it safe to use from any actor.
final class InMemoryKeyValueStore: WMFKeyValueStore {

    private let values = OSAllocatedUnfairLock<[String: Data]>(initialState: [:])

    func load<T: Codable>(key: String...) throws -> T? {
        guard let data = values.withLock({ $0[key.joined(separator: "/")] }) else { return nil }
        return try JSONDecoder().decode(T.self, from: data)
    }

    func save<T: Codable>(key: String..., value: T) throws {
        let data = try JSONEncoder().encode(value)
        values.withLock { $0[key.joined(separator: "/")] = data }
    }

    func remove(key: String...) throws {
        values.withLock { _ = $0.removeValue(forKey: key.joined(separator: "/")) }
    }

    func keys(inDirectory directory: String) throws -> [String] {
        values.withLock { $0.keys }.filter { $0.hasPrefix(directory + "/") }.map { String($0.dropFirst(directory.count + 1)) }
    }
}
