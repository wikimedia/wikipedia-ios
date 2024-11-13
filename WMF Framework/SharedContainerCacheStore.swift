import Foundation
import WMFData

public enum SharedContainerCacheStoreError: Error {
    case unexpectedKeyCount
}

public final class SharedContainerCacheStore: WMFKeyValueStore {
    public init() {
        
    }
    
    public func load<T>(key: String...) throws -> T? where T : Decodable, T : Encodable {
        
        guard (1...2).contains(key.count) else {
            throw SharedContainerCacheStoreError.unexpectedKeyCount
        }
        
        let fileName = key.count == 1 ? key[0] : key[1]
        let subdirectoryPathComponent = key.count == 2 ? key[0] : nil
        
        let sharedContainerCache = SharedContainerCache(fileName: fileName, subdirectoryPathComponent: subdirectoryPathComponent)
        let cache: T? = sharedContainerCache.loadCache()
        return cache
    }
    
    public func save<T>(key: String..., value: T) throws where T : Decodable, T : Encodable {
        
        guard (1...2).contains(key.count) else {
            throw SharedContainerCacheStoreError.unexpectedKeyCount
        }
        
        let fileName = key.count == 1 ? key[0] : key[1]
        let subdirectoryPathComponent = key.count == 2 ? key[0] : nil
        
        let sharedContainerCache = SharedContainerCache(fileName: fileName, subdirectoryPathComponent: subdirectoryPathComponent)
        sharedContainerCache.saveCache(value)
    }

    public func remove(key: String...) throws {
          guard (1...2).contains(key.count) else {
              throw SharedContainerCacheStoreError.unexpectedKeyCount
          }
        
          let fileName = key.count == 1 ? key[0] : key[1]
          let subdirectoryPathComponent = key.count == 2 ? key[0] : nil
        
        let sharedContainerCache = SharedContainerCache(fileName: fileName, subdirectoryPathComponent: subdirectoryPathComponent)
        try? sharedContainerCache.removeCache()
      }
}
