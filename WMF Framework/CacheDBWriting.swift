
import Foundation

enum SaveResult {
    case success
    case failure(Error)
}

protocol CacheDBWritingDelegate: class {
    func shouldQueue(groupKey: String, itemKey: String) -> Bool
    func queue(groupKey: String, itemKey: String)
    func dbWriterDidAdd(groupKey: String, itemKey: String)
    func dbWriterDidRemove(groupKey: String, itemKey: String)
    func dbWriterDidFailAdd(groupKey: String, itemKey: String)
    func dbWriterDidFailRemove(groupKey: String)
}

protocol CacheDBWriting: CacheTaskTracking {
    
    var delegate: CacheDBWritingDelegate? { get }
    
    func add(url: URL, groupKey: String, itemKey: String?)
    func remove(groupKey: String, itemKey: String?)

    func markDownloaded(itemKey: String)
    
    //default implementations
    func isCached(url: URL) -> Bool
}

extension CacheDBWriting {
    
    func isCached(url: URL) -> Bool {
        
        guard let itemKey = url.wmf_databaseKey,
        let context = CacheController.backgroundCacheContext else {
            return false
        }
        
        return context.performWaitAndReturn {
            let cacheItem = CacheDBWriterHelper.cacheItem(with: itemKey, in: context)
            return cacheItem?.isDownloaded
        } ?? false
    }
    
    func allDownloaded(groupKey: String) -> Bool {
        
        guard let context = CacheController.backgroundCacheContext else {
            return false
        }
        
        guard let group = CacheDBWriterHelper.cacheGroup(with: groupKey, in: context) else {
            return false
        }
        guard let cacheItems = group.cacheItems as? Set<PersistentCacheItem> else {
            return false
        }
        
        return context.performWaitAndReturn {
            for item in cacheItems {
                if !item.isDownloaded {
                    return false
                }
            }
            
            return true
        } ?? false
    }
    
    func markDownloaded(itemKey: String) {
        
        guard let context = CacheController.backgroundCacheContext else {
            return
        }
        
        guard let cacheItem = CacheDBWriterHelper.cacheItem(with: itemKey, in: context) else {
            return
        }
        
        context.perform {
            cacheItem.isDownloaded = true
            CacheDBWriterHelper.save(moc: context) { (result) in
                           
            }
        }
    }
}
