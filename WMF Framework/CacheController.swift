
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
    
    typealias CacheControllerCompletion = (_ isAdd: Bool, _ isSuccess: Bool) -> Void
    typealias ItemKey = String
    
    private var queuedCompletions: [ItemKey: [CacheControllerCompletion]] = [:]
    
    init(fetcher: Fetcher, dbWriter: CacheDBWriting, fileWriter: CacheFileWriting, provider: CacheProviding) {
        self.provider = provider
        self.dbWriter = dbWriter
        self.fileWriter = fileWriter
    }
    
    func clearURLCache() { }//maybe settings hook? clear only url cache.
    func clearCoreDataCache() {}
    //todo: Settings hook, logout don't sync hook, etc.
    //clear out from core data, leave URL cache as-is.
    
    public func toggleCache(url: URL) {
        assertionFailure("Must subclass")
    }

    func add(url: URL, groupKey: String, itemKey: String) {
        
        dbWriter.add(url: url, groupKey: groupKey, itemKey: itemKey)
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
    
    private func finishAndRunQueue(groupKey: String, itemKey: String, isAdd: Bool, isSuccess: Bool) {
        
        handleFinalResult(groupKey: groupKey, itemKey: itemKey, isAdd: isAdd, isSuccess: isSuccess)
        
        if let queuedCompletions = queuedCompletions[itemKey] {
            for queuedCompletion in queuedCompletions {
                queuedCompletion(isAdd, isSuccess)
            }
        }
        
    }
    
    private func handleFinalResult(groupKey: String, itemKey: String, isAdd: Bool, isSuccess: Bool) {
        switch (isAdd, isSuccess) {
        case (true, true):
            
            handleAddSuccess(groupKey: groupKey, itemKey: itemKey)
        default:
            break
            //tonitodo: error handling
        }
    }
    
    private func handleAddSuccess(groupKey: String, itemKey: String) {
        
        dbWriter.markDownloaded(itemKey: itemKey)
        
        if dbWriter.allDownloaded(groupKey: groupKey) {
            
            //fire notification here for WMFArticle.isDownloaded = yes?
        }
    }
}

extension CacheController: CacheDBWritingDelegate {
    
    func shouldQueue(groupKey: String, itemKey: String) -> Bool {
        
        let isEmpty = queuedCompletions[itemKey]?.isEmpty ?? true
        return !isEmpty
    }
    
    func queue(groupKey: String, itemKey: String) {
        let queuedCompletionBlock = { (isAdd: Bool, isSuccess: Bool) in
            self.handleFinalResult(groupKey: groupKey, itemKey: itemKey, isAdd: isAdd, isSuccess: isSuccess)
        }
        
        queuedCompletions[itemKey]?.append(queuedCompletionBlock)
    }
    
    func dbWriterDidAdd(groupKey: String, itemKey: String) {
        fileWriter.add(groupKey: groupKey, itemKey: itemKey)
    }
    
    func dbWriterDidRemove(groupKey: String, itemKey: String) {
        fileWriter.remove(groupKey: groupKey, itemKey: itemKey)
    }
    
    func dbWriterDidFailAdd(groupKey: String, itemKey: String) {
        finishAndRunQueue(groupKey: groupKey, itemKey: itemKey, isAdd: true, isSuccess: false)
    }
    
    func dbWriterDidFailRemove(groupKey: String) {
        //tonitodo: anything worth doing here / queuing since we don't have an itemKey to pull queued completions with?
    }
}

extension CacheController: CacheFileWritingDelegate {
    func fileWriterDidAdd(groupKey: String, itemKey: String) {
         
        finishAndRunQueue(groupKey: groupKey, itemKey: itemKey, isAdd: true, isSuccess: true)
    }
    
    func fileWriterDidRemove(groupKey: String, itemKey: String) {
        finishAndRunQueue(groupKey: groupKey, itemKey: itemKey, isAdd: false, isSuccess: true)
    }
    
    func fileWriterDidFailAdd(groupKey: String, itemKey: String) {
        finishAndRunQueue(groupKey: groupKey, itemKey: itemKey, isAdd: true, isSuccess: false)
    }
    
    func fileWriterDidFailRemove(groupKey: String, itemKey: String) {
        finishAndRunQueue(groupKey: groupKey, itemKey: itemKey, isAdd: false, isSuccess: false)
    }
}
