
import Foundation

protocol CacheFileWritingDelegate: class {
    func fileWriterDidDownload(cacheItem: PersistentCacheItem)
    func fileWriterDidDelete(cacheItem: PersistentCacheItem)
    func fileWriterDidFailToDelete(cacheItem: PersistentCacheItem, error: Error)
}

protocol CacheFileWriting {
    
    var delegate: CacheFileWritingDelegate? { get }
    func download(cacheItem: PersistentCacheItem)
    func delete(cacheItem: PersistentCacheItem)
}

