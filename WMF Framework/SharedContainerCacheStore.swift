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
        
        let sharedContainerCache = SharedContainerCache<T>(fileName: fileName, subdirectoryPathComponent: subdirectoryPathComponent)
        let cache = sharedContainerCache.loadCache()
        return cache
    }
    
    public func save<T>(key: String..., value: T) throws where T : Decodable, T : Encodable {
        
        guard (1...2).contains(key.count) else {
            throw SharedContainerCacheStoreError.unexpectedKeyCount
        }
        
        let fileName = key.count == 1 ? key[0] : key[1]
        let subdirectoryPathComponent = key.count == 2 ? key[0] : nil
        
        let sharedContainerCache = SharedContainerCache<T>(fileName: fileName, subdirectoryPathComponent: subdirectoryPathComponent)
        sharedContainerCache.saveCache(value)
    }

    public func remove(key: String...) throws {
          guard (1...2).contains(key.count) else {
              throw SharedContainerCacheStoreError.unexpectedKeyCount
          }

          let fileName = key.count == 1 ? key[0] : key[1]
          let subdirectoryPathComponent = key.count == 2 ? key[0] : nil

        let sharedContainerCacheRemover = SharedContainerCacheRemover(fileName: fileName, subdirectoryPathComponent: subdirectoryPathComponent)
          sharedContainerCacheRemover.removeCache()
      }
}

/// helper class to circunvent the need to pass a generic value T to SharedContainerCache<T> when deleting a subdirectory
fileprivate final class SharedContainerCacheRemover {

    fileprivate let fileName: String
    fileprivate let subdirectoryPathComponent: String?

    fileprivate init(fileName: String, subdirectoryPathComponent: String? = nil) {
        self.fileName = fileName
        self.subdirectoryPathComponent = subdirectoryPathComponent
    }

    fileprivate static var cacheDirectoryContainerURL: URL {
        FileManager.default.wmf_containerURL()
    }

    fileprivate var cacheDataFileURL: URL {
        let baseURL = subdirectoryURL() ?? Self.cacheDirectoryContainerURL
        return baseURL.appendingPathComponent(fileName).appendingPathExtension("json")
    }

    fileprivate func subdirectoryURL() -> URL? {
        guard let subdirectoryPathComponent = subdirectoryPathComponent else {
            return nil
        }
        return Self.cacheDirectoryContainerURL.appendingPathComponent(subdirectoryPathComponent, isDirectory: true)
    }

    fileprivate func removeCache() {
        try? FileManager.default.removeItem(at: cacheDataFileURL)
    }
}

