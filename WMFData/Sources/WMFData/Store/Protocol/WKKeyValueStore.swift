import Foundation

public protocol WKKeyValueStore {
    func load<T: Codable>(key: String...) throws -> T?
    func save<T: Codable>(key: String..., value: T) throws
}
