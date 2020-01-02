
import Foundation

public final class CacheController {
    
    static let cacheURL: URL = {
        return FileManager.default.wmf_containerURL().appendingPathComponent("PersistentCache", isDirectory: true)
    }()
    
    public static let sharedArticleCache: CacheController? = {
        
        let fetcher = ArticleFetcher()
        
        guard let cacheBackgroundContext = CacheController.backgroundCacheContext,
        let fileWriter = ArticleCacheFileWriter(articleFetcher: fetcher, cacheBackgroundContext: cacheBackgroundContext) else {
            return nil
        }
        
        let provider = ArticleCacheProvider()
        
        let dbWriter = ArticleCacheDBWriter(articleFetcher: fetcher, cacheBackgroundContext: cacheBackgroundContext)
        
        let cacheController = CacheController(fetcher: fetcher, dbWriter: dbWriter, fileWriter: fileWriter, provider: provider)
        
        dbWriter.delegate = cacheController
        fileWriter.delegate = cacheController
        
        return cacheController
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
    
    private let provider: CacheProviding
    private let dbWriter: CacheDBWriting
    private let fileWriter: CacheFileWriting
    
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

public extension CacheController {
    func cacheMobileHtmlUrlFromMigration(articleURL: URL) {
        guard let articleDBWriter = dbWriter as? ArticleCacheDBWriter else {
            return
        }
        
        articleDBWriter.cacheMobileHtmlUrlFromMigration(articleURL: articleURL)
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
    
    func fileWriterDidMigrate(cacheItem: PersistentCacheItem) {
        dbWriter.migratedCacheItemFile(cacheItem: cacheItem)
    }
    
    func fileWriterDidFailToDelete(cacheItem: PersistentCacheItem, error: Error) {
        dbWriter.failureToDeleteCacheItemFile(cacheItem: cacheItem, error: error)
    }
    
    
}
