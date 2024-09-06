import Foundation

class WMFUserDefaultsStore: WMFKeyValueStore {

    func load<T: Codable>(key: String...) throws -> T? {
        let defaultsKey = key.joined(separator: ".")
        return try load(defaultsKey: defaultsKey)
    }
    
    func save<T: Codable>(key: String..., value: T) throws {
        let defaultsKey = key.joined(separator: ".")
        try save(defaultsKey: defaultsKey, value: value)
    }

    func remove(key: String...) throws {
           let defaultsKey = key.joined(separator: ".")
           UserDefaults.standard.removeObject(forKey: defaultsKey)
       }

    private func load<T: Codable>(defaultsKey: String) throws -> T? {
        do {
            guard let data = UserDefaults.standard.value(forKey: defaultsKey) as? Data else {
                throw WMFUserDefaultsStoreError.unexpectedType
            }
            
            let value = try JSONDecoder().decode(T.self, from: data)
            return value
        } catch let error {
            throw WMFUserDefaultsStoreError.failureDecodingJSON(error)
        }
    }
    
    private func save<T: Codable>(defaultsKey: String, value: T) throws {
        do {
            let data = try JSONEncoder().encode(value)
            UserDefaults.standard.set(data, forKey: defaultsKey)
        } catch let error {
            throw WMFUserDefaultsStoreError.failureEncodingJSON(error)
        }
    }

}
