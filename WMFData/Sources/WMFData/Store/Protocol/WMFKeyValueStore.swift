import Foundation

public protocol WMFKeyValueStore {
    func load<T: Codable>(key: String...) throws -> T?
    func save<T: Codable>(key: String..., value: T) throws
    func remove(key: String...) throws
    /// The keys of every value stored under `directory`, the first component of a two-part key.
    func keys(inDirectory directory: String) throws -> [String]
}
