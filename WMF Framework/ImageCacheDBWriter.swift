
import Foundation

final class ImageCacheDBWriter: CacheDBWriting {
    
    weak var delegate: CacheDBWritingDelegate?
    private let cacheBackgroundContext: NSManagedObjectContext
    
    init(cacheBackgroundContext: NSManagedObjectContext, delegate: CacheDBWritingDelegate? = nil) {
        self.cacheBackgroundContext = cacheBackgroundContext
        self.delegate = delegate
    }
    
    func cache(url: URL, groupKey: String) {
        guard let itemKey = url.wmf_databaseKey else {
            return
        }
        
        guard !isCached(url: url) else {
            //tonitodo: error handling
            return
        }
        
        cacheImage(groupKey: groupKey, itemKey: itemKey)
    }
    
    func toggleCache(url: URL) {
        assert(Thread.isMainThread)
        
        guard let key = url.wmf_databaseKey else {
            return
        }
        
        toggleCache(!isCached(url: url), groupKey: key, itemKey: key)
    }
    
    func markDeleteFailed(groupKey: String, itemKey: String) {
        //tonitodo: not sure what to do in this case. maybe at least some logging?
    }
    
    func markDeleted(groupKey: String, itemKey: String) {
        
        guard let cacheItem = CacheDBWriterHelper.cacheItem(with: itemKey, in: cacheBackgroundContext) else {
            return
        }
        
        cacheBackgroundContext.perform {
            self.cacheBackgroundContext.delete(cacheItem)
            
            if let cacheGroups = cacheItem.cacheGroups,
            cacheGroups.count == 1,
                let cacheGroup = cacheGroups.anyObject() as? PersistentCacheGroup {
                self.cacheBackgroundContext.delete(cacheGroup)
            }
            self.save(moc: self.cacheBackgroundContext) { (result) in
                
            }
        }
    }
    
    func markDownloaded(groupKey: String, itemKey: String) {
    
        guard let cacheItem = CacheDBWriterHelper.cacheItem(with: itemKey, in: cacheBackgroundContext) else {
            return
        }
    
        cacheBackgroundContext.perform {
            cacheItem.isDownloaded = true
            self.save(moc: self.cacheBackgroundContext) { (result) in
                           
            }
        }
    }
    
    func migratedCacheItemFile(cacheItem: PersistentCacheItem) {
        //tonitodo
    }
}

private extension ImageCacheDBWriter {
    func toggleCache(_ cache: Bool, groupKey: String, itemKey: String) {
        
        if cache {
            cacheImage(groupKey: groupKey, itemKey: itemKey)
        } else {
            removeCachedImage(groupKey: groupKey, itemKey: itemKey)
        }
    }
    
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
            
            self.save(moc: context) { (result) in
                switch result {
                case .success:
                    self.delegate?.dbWriterDidSave(groupKey: groupKey, itemKey: itemKey)
                case .failure:
                    break
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
            
            self.save(moc: context) { (result) in
                switch result {
                case .success:
                    
                    for cacheItem in cacheItemsToDelete {
                        
                        guard let itemKey = cacheItem.key else {
                            continue
                        }
                        
                        self.delegate?.dbWriterDidDelete(groupKey: groupKey, itemKey: itemKey)
                    }
                    
                case .failure:
                    break
                }
            }
        }
    }
}
