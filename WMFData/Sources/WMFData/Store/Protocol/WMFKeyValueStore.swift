import Foundation

public protocol WMFKeyValueStore: Sendable {
    func load<T: Codable>(key: String...) throws -> T?
    func save<T: Codable>(key: String..., value: T) throws
    func remove(key: String...) throws
}
