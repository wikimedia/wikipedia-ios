
import Foundation

public protocol CacheFileWriting {
    
    func download(cacheItem: PersistentCacheItem)
    func delete(cacheItem: PersistentCacheItem)
}

