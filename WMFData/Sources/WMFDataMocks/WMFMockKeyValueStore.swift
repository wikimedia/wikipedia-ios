import Foundation
import WMFData

public final class WMFMockKeyValueStore: WMFKeyValueStore, @unchecked Sendable {
    
    public init() {
        self.savedObjects = [:]
    }
    
    private let lock = NSLock()
    private var savedObjects: [String: Codable] = [:]
    
    public func load<T>(key: String...) throws -> T? where T : Decodable, T : Encodable {
        let defaultsKey = key.joined(separator: ".")
        lock.lock()
        defer { lock.unlock() }
        return savedObjects[defaultsKey] as? T
    }
    
    public func save<T>(key: String..., value: T) throws where T : Decodable, T : Encodable {
        let defaultsKey = key.joined(separator: ".")
        lock.lock()
        defer { lock.unlock() }
        savedObjects[defaultsKey] = value
    }

    public func remove(key: String...) throws {
        lock.lock()
        defer { lock.unlock() }
        savedObjects = [:]
    }
}
