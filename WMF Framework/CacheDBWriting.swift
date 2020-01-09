
import Foundation

enum SaveResult {
    case success
    case failure(Error)
}

protocol CacheDBWritingDelegate: class {
    func dbWriterDidSave(groupKey: String, itemKey: String)
    func dbWriterDidDelete(groupKey: String, itemKey: String)
}

protocol CacheDBWriting: class {
    
    var delegate: CacheDBWritingDelegate? { get }
    func toggleCache(url: URL)
    
    func markDeleteFailed(groupKey: String, itemKey: String)
    func markDeleted(groupKey: String, itemKey: String)
    func markDownloaded(groupKey: String, itemKey: String)
    
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
