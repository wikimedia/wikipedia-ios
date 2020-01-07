
import Foundation

public class CacheController {
    
    static let cacheURL: URL = {
        return FileManager.default.wmf_containerURL().appendingPathComponent("PersistentCache", isDirectory: true)
    }()
    
    static let backgroundCacheContext: NSManagedObjectContext? = {
        
        //tonitodo: taken from ImageController. Do we only want this set for images?
//        var values = URLResourceValues()
//        values.isExcludedFromBackup = true
//        do {
//            try cacheURL.setResourceValues(values)
//        } catch {
//            return nil
//        }
        
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
    func dbWriterDidSave(cacheItem: PersistentCacheItem) {
        fileWriter.download(cacheItem: cacheItem)
    }
    
    func dbWriterDidDelete(cacheItem: PersistentCacheItem) {
        fileWriter.delete(cacheItem: cacheItem)
    }
}

extension CacheController: CacheFileWritingDelegate {
    func fileWriterDidDownload(cacheItem: PersistentCacheItem) {
        dbWriter.downloadedCacheItemFile(cacheItem: cacheItem)
    }
    
    func fileWriterDidDelete(cacheItem: PersistentCacheItem) {
        dbWriter.deletedCacheItemFile(cacheItem: cacheItem)
    }
    
    func fileWriterDidFailToDelete(cacheItem: PersistentCacheItem, error: Error) {
        dbWriter.failureToDeleteCacheItemFile(cacheItem: cacheItem, error: error)
    }
    
    
}
