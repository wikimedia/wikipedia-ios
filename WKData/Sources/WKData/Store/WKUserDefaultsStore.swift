import Foundation

class WKUserDefaultsStore: WKKeyValueStore {
    func load<T: Codable>(key: String...) throws -> T? {
        let defaultsKey = key.joined(separator: ".")
        return try load(defaultsKey: defaultsKey)
    }
    
    func save<T: Codable>(key: String..., value: T) throws {
        let defaultsKey = key.joined(separator: ".")
        try save(defaultsKey: defaultsKey, value: value)
    }
    
    private func load<T: Codable>(defaultsKey: String) throws -> T? {
        do {
            guard let data = UserDefaults.standard.value(forKey: defaultsKey) as? Data else {
                throw WKUserDefaultsStoreError.unexpectedType
            }
            
            let value = try JSONDecoder().decode(T.self, from: data)
            return value
        } catch let error {
            throw WKUserDefaultsStoreError.failureDecodingJSON(error)
        }
    }
    
    private func save<T: Codable>(defaultsKey: String, value: T) throws {
        do {
            let data = try JSONEncoder().encode(value)
            UserDefaults.standard.set(data, forKey: defaultsKey)
        } catch let error {
            throw WKUserDefaultsStoreError.failureEncodingJSON(error)
        }
    }
}
