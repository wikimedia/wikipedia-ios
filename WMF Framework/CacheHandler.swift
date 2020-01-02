
import Foundation

@objc(WMFCacheController)
public final class CacheController: NSObject {
    
    static let cacheURL: URL = {
        return FileManager.default.wmf_containerURL().appendingPathComponent("PersistentCache", isDirectory: true)
    }()
    
    @objc public static let sharedArticleCache: CacheController? = {
        
        let fetcher = ArticleFetcher()
        
        guard let cacheBackgroundContext = CacheController.backgroundCacheContext,
        let fileWriter = ArticleCacheFileWriter(articleFetcher: fetcher, cacheBackgroundContext: cacheBackgroundContext) else {
            return nil
        }
        
        let provider = ArticleCacheProvider()
        
        let dbWriter = ArticleCacheDBWriter(articleFetcher: fetcher, cacheBackgroundContext: cacheBackgroundContext, fileWriter: fileWriter)
        fileWriter.dbWriter = dbWriter
        return CacheController(fetcher: fetcher, dbWriter: dbWriter, fileWriter: fileWriter, provider: provider)
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
    
    public let provider: CacheProviding
    public let dbWriter: CacheDBWriting
    public let fileWriter: CacheFileWriting
    
    init(fetcher: Fetcher, dbWriter: CacheDBWriting, fileWriter: CacheFileWriting, provider: CacheProviding) {
        self.provider = provider
        self.dbWriter = dbWriter
        self.fileWriter = fileWriter
    }
    
    @objc public func setup() {
        
    }
}
