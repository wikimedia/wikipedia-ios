
import Foundation

public protocol CacheDBWriting: class {
    
    func toggleCache(url: URL)
    func clearURLCache() //maybe settings hook? clear only url cache.
    func clearCoreDataCache()
    //todo: Settings hook, logout don't sync hook, etc.
    //clear out from core data, leave URL cache as-is.
    
    //default implementations
    func isCached(url: URL) -> Bool
    func save(moc: NSManagedObjectContext)
}

public extension CacheDBWriting {
    
    func isCached(url: URL) -> Bool {
        
        guard let groupKey = url.wmf_databaseKey,
        let context = CacheController.backgroundCacheContext else {
            return false
        }
        
        return context.performWaitAndReturn {
            CacheDBWriterHelper.cacheGroup(with: groupKey, in: context) != nil
        } ?? false
    }
    
    func save(moc: NSManagedObjectContext) {
        guard moc.hasChanges else {
            return
        }
        do {
            try moc.save()
        } catch let error {
            assertionFailure("Error saving cache moc: \(error)")
        }
    }
}
