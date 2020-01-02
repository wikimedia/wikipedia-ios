
import Foundation

enum SaveResult {
    case success
    case failure(Error)
}

protocol CacheDBWritingDelegate: class {
    func dbWriterDidSave(cacheItem: PersistentCacheItem)
    func dbWriterDidDelete(cacheItem: PersistentCacheItem)
}

protocol CacheDBWriting: class {
    
    var delegate: CacheDBWritingDelegate? { get }
    func toggleCache(url: URL)
    func clearURLCache() //maybe settings hook? clear only url cache.
    func clearCoreDataCache()
    //todo: Settings hook, logout don't sync hook, etc.
    //clear out from core data, leave URL cache as-is.
    
    func failureToDeleteCacheItemFile(cacheItem: PersistentCacheItem, error: Error)
    func deletedCacheItemFile(cacheItem: PersistentCacheItem)
    func downloadedCacheItemFile(cacheItem: PersistentCacheItem)
    func migratedCacheItemFile(cacheItem: PersistentCacheItem)
    
    //default implementations
    func isCached(url: URL) -> Bool
    func save(moc: NSManagedObjectContext, completion: (_ result: SaveResult) -> Void)
}

extension CacheDBWriting {
    
    func isCached(url: URL) -> Bool {
        
        guard let groupKey = url.wmf_databaseKey,
        let context = CacheController.backgroundCacheContext else {
            return false
        }
        
        return context.performWaitAndReturn {
            CacheDBWriterHelper.cacheGroup(with: groupKey, in: context) != nil
        } ?? false
    }
    
    func save(moc: NSManagedObjectContext, completion: (_ result: SaveResult) -> Void) {
        guard moc.hasChanges else {
            return
        }
        do {
            try moc.save()
            completion(.success)
        } catch let error {
            assertionFailure("Error saving cache moc: \(error)")
            completion(.failure(error))
        }
    }
}
