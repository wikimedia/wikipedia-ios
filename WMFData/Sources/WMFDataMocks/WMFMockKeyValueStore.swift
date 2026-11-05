import Foundation
import WMFData

// @unchecked Sendable: the lock guards every read and write of savedObjects.
public final class WMFMockKeyValueStore: WMFKeyValueStore, @unchecked Sendable {
    
    public init() {
        self.savedObjects = [:]
    }
    
    private let lock = NSLock()
    private var savedObjects: [String: Codable] = [:]
    public func load<T>(key: String...) throws -> T? where T : Decodable, T : Encodable {
        let defaultsKey = key.joined(separator: ".")
        return lock.withLock { savedObjects[defaultsKey] as? T }
    }
    
    public func save<T>(key: String..., value: T) throws where T : Decodable, T : Encodable {
        let defaultsKey = key.joined(separator: ".")
        lock.withLock { savedObjects[defaultsKey] = value }
    }

    public func remove(key: String...) throws {
        let defaultsKey = key.joined(separator: ".")
        _ = lock.withLock { savedObjects.removeValue(forKey: defaultsKey) }
    }

    public func keys(inDirectory directory: String) throws -> [String] {
        let prefix = directory + "."
        let keys = lock.withLock { Array(savedObjects.keys) }
        return keys
            .filter { $0.hasPrefix(prefix) }
            .map { String($0.dropFirst(prefix.count)) }
            .sorted()
    }

}
