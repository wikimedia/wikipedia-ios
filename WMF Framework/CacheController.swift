
import Foundation

public class CacheController {
    
    static let cacheURL: URL = {
        var url = FileManager.default.wmf_containerURL().appendingPathComponent("PersistentCache", isDirectory: true)
        
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        do {
            try url.setResourceValues(values)
        } catch {
            return url
        }
        
        return url
    }()
    
    static let backgroundCacheContext: NSManagedObjectContext? = {
        
        //create ManagedObjectModel based on Cache.momd
        guard let modelURL = Bundle.wmf.url(forResource: "PersistentCache", withExtension: "momd"),
            let model = NSManagedObjectModel(contentsOf: modelURL) else {
                assertionFailure("Failure to create managed object model")
                return nil
        }
                
        //create persistent store coordinator / persistent store
        let dbURL = cacheURL.deletingLastPathComponent().appendingPathComponent("PersistentCache.sqlite", isDirectory: false)
        let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        
        let options = [
            NSMigratePersistentStoresAutomaticallyOption: NSNumber(booleanLiteral: true),
            NSInferMappingModelAutomaticallyOption: NSNumber(booleanLiteral: true)
        ]
        
        do {
            try persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: dbURL, options: options)
        } catch {
            do {
                try FileManager.default.removeItem(at: dbURL)
            } catch {
                assertionFailure("Failure to remove old db file")
                return nil
            }

            do {
                try persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: dbURL, options: options)
            } catch {
                assertionFailure("Failure to add persistent store to coordinator")
                return nil
            }
        }

        let cacheBackgroundContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        cacheBackgroundContext.persistentStoreCoordinator = persistentStoreCoordinator
                
        return cacheBackgroundContext
    }()
    
    let provider: CacheProviding
    let dbWriter: CacheDBWriting
    let fileWriter: CacheFileWriting
    
    init(fetcher: Fetcher, dbWriter: CacheDBWriting, fileWriter: CacheFileWriting, provider: CacheProviding) {
        self.provider = provider
        self.dbWriter = dbWriter
        self.fileWriter = fileWriter
    }
    
    
    func clearURLCache() { }//maybe settings hook? clear only url cache.
    func clearCoreDataCache() {}
    //todo: Settings hook, logout don't sync hook, etc.
    //clear out from core data, leave URL cache as-is.
    
    @objc public func setup() {
        
    }
    
    public func toggleCache(url: URL) {
        dbWriter.toggleCache(url: url)
    }
    
    public func isCached(url: URL) -> Bool {
        dbWriter.isCached(url: url)
    }
    
    public func recentCachedURLResponse(for url: URL) -> CachedURLResponse? {
        return provider.recentCachedURLResponse(for: url)
    }
    
    public func persistedCachedURLResponse(for url: URL) -> CachedURLResponse? {
        return provider.persistedCachedURLResponse(for: url)
    }
}

extension CacheController: CacheDBWritingDelegate {
    func dbWriterDidSave(groupKey: String, itemKey: String) {
        fileWriter.download(groupKey: groupKey, itemKey: itemKey)
    }
    
    func dbWriterDidDelete(groupKey: String, itemKey: String) {
        fileWriter.delete(groupKey: groupKey, itemKey: itemKey)
    }
}

extension CacheController: CacheFileWritingDelegate {
    func fileWriterDidDownload(groupKey: String, itemKey: String) {
        dbWriter.markDownloaded(groupKey: groupKey, itemKey: itemKey)
    }
    
    func fileWriterDidDelete(groupKey: String, itemKey: String) {
        dbWriter.markDeleted(groupKey: groupKey, itemKey: itemKey)
    }
    
    func fileWriterDidFailToDelete(groupKey: String, itemKey: String) {
        dbWriter.markDeleteFailed(groupKey: groupKey, itemKey: itemKey)
    }
    
    
}
