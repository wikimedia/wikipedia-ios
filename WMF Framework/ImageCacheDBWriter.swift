
import Foundation

final class ImageCacheDBWriter: CacheDBWriting {
    
    weak var delegate: CacheDBWritingDelegate?
    private let cacheBackgroundContext: NSManagedObjectContext
    
    init(cacheBackgroundContext: NSManagedObjectContext, delegate: CacheDBWritingDelegate? = nil) {
        self.cacheBackgroundContext = cacheBackgroundContext
        self.delegate = delegate
    }
    
    func add(url: URL, groupKey: String, itemKey: String?) {
        
        guard let itemKey = itemKey else {
            assertionFailure("Expecting itemKey")
            return
        }
        
        cacheImage(groupKey: groupKey, itemKey: itemKey)
    }
    
    func remove(groupKey: String, itemKey: String?) {
        
        guard let itemKey = itemKey else {
            assertionFailure("Expecting itemKey")
            return
        }
        
        removeCachedImage(groupKey: groupKey, itemKey: itemKey)
    }
    
    func migratedCacheItemFile(cacheItem: PersistentCacheItem) {
        //tonitodo
    }
}

private extension ImageCacheDBWriter {
    
    func cacheImage(groupKey: String, itemKey: String) {
        
        let context = self.cacheBackgroundContext
        context.perform {

            guard let group = CacheDBWriterHelper.fetchOrCreateCacheGroup(with: groupKey, in: context) else {
                return
            }
            
            guard let item = CacheDBWriterHelper.fetchOrCreateCacheItem(with: itemKey, in: context) else {
                return
            }
            
            group.addToCacheItems(item)
            
            CacheDBWriterHelper.save(moc: context) { (result) in
                switch result {
                case .success:
                    self.delegate?.dbWriterDidAdd(groupKey: groupKey, itemKey: itemKey)
                case .failure:
                    self.delegate?.dbWriterDidFailAdd(groupKey: groupKey, itemKey: itemKey)
                }
            }
        }
    }
    
    func removeCachedImage(groupKey: String, itemKey: String) {
        
        let context = cacheBackgroundContext
        context.perform {
            //tonitodo: task tracking in ArticleFetcher
            //self.articleFetcher.cancelAllTasks(forGroupWithKey: key)
            guard let group = CacheDBWriterHelper.cacheGroup(with: groupKey, in: context) else {
                assertionFailure("Cache group for \(groupKey) doesn't exist")
                return
            }
            guard let cacheItems = group.cacheItems as? Set<PersistentCacheItem> else {
                assertionFailure("Cache group for \(groupKey) has no cache items")
                return
            }
            
            let cacheItemsToDelete = cacheItems.filter({ (cacheItem) -> Bool in
                return cacheItem.cacheGroups?.count == 1
            })
            
            for cacheItem in cacheItemsToDelete {
                cacheItem.isPendingDelete = true
            }
            
            CacheDBWriterHelper.save(moc: context) { (result) in
                switch result {
                case .success:
                    
                    for cacheItem in cacheItemsToDelete {
                        
                        guard let itemKey = cacheItem.key else {
                            continue
                        }
                        
                        self.delegate?.dbWriterDidRemove(groupKey: groupKey, itemKey: itemKey)
                    }
                    
                case .failure:
                    self.delegate?.dbWriterDidFailRemove(groupKey: groupKey)
                }
            }
        }
    }
}
