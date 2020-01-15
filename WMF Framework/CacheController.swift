
import Foundation

enum CacheControllerError: Error {
    case atLeastOneItemFailedInFileWriter
    case failureToGenerateItemResult
}

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
    
    public typealias ItemKey = String
    public typealias GroupKey = String
    public typealias ItemCompletionBlock = (FinalItemResult) -> Void
    public typealias GroupCompletionBlock = (FinalGroupResult) -> Void

    public enum FinalItemResult {
        case success(itemKey: ItemKey)
        case failure(error: Error)
    }
    
    public enum FinalGroupResult {
        case success(itemKeys: [ItemKey])
        case failure(error: Error) //, itemKeys: [ItemKey]?
    }
    
    let provider: CacheProviding
    let dbWriter: CacheDBWriting
    let fileWriter: CacheFileWriting
    private let gatekeeper = CacheGatekeeper()
    
    init(fetcher: Fetcher, dbWriter: CacheDBWriting, fileWriter: CacheFileWriting, provider: CacheProviding) {
        self.provider = provider
        self.dbWriter = dbWriter
        self.fileWriter = fileWriter
    }
    
    func clearURLCache() { }//maybe settings hook? clear only url cache.
    func clearCoreDataCache() {}
    //todo: Settings hook, logout don't sync hook, etc.
    //clear out from core data, leave URL cache as-is.

    public func add(url: URL, groupKey: GroupKey, itemKey: ItemKey? = nil, bypassGroupDeduping: Bool = false, itemCompletion: @escaping ItemCompletionBlock, groupCompletion: @escaping GroupCompletionBlock) {
        
        if !bypassGroupDeduping {
            if gatekeeper.numberOfQueuedGroupCompletions(for: groupKey) > 0 {
                gatekeeper.queueGroupCompletion(groupKey: groupKey, groupCompletion: groupCompletion)
                return
            }
        }
        
        gatekeeper.queueGroupCompletion(groupKey: groupKey, groupCompletion: groupCompletion)
        
        if let itemKey = itemKey {
            dbWriter.add(url: url, groupKey: groupKey, itemKey: itemKey) { [weak self] (result) in
                self?.finishDBAdd(groupKey: groupKey, itemCompletion: itemCompletion, groupCompletion: groupCompletion, result: result)
            }
        } else {
            dbWriter.add(url: url, groupKey: groupKey) { [weak self] (result) in
                self?.finishDBAdd(groupKey: groupKey, itemCompletion: itemCompletion, groupCompletion: groupCompletion, result: result)
            }
        }
    }
    
    public func cancelTasks(groupKey: String) {
        dbWriter.cancelTasks(for: groupKey)
        fileWriter.cancelTasks(for: groupKey)
    }
    
    public func recentCachedURLResponse(for url: URL) -> CachedURLResponse? {
        return provider.recentCachedURLResponse(for: url)
    }

    public func persistedCachedURLResponse(for url: URL) -> CachedURLResponse? {
        return provider.persistedCachedURLResponse(for: url)
    }
    
    private func finishDBAdd(groupKey: GroupKey, itemCompletion: @escaping ItemCompletionBlock, groupCompletion: @escaping GroupCompletionBlock, result: CacheDBWritingResult) {
        switch result {
            case .success(let itemKeys):
                
                var successfulItemKeys: [CacheController.ItemKey] = []
                var failedItemKeys: [CacheController.ItemKey] = []
                
                let group = DispatchGroup()
                for itemKey in itemKeys {
                    
                    group.enter()
                    
                    if gatekeeper.numberOfQueuedItemCompletions(for: itemKey) > 0 {
                        defer {
                            group.leave()
                        }
                        gatekeeper.queueItemCompletion(itemKey: itemKey, itemCompletion: itemCompletion)
                        continue
                    }
                    
                    gatekeeper.queueItemCompletion(itemKey: itemKey, itemCompletion: itemCompletion)
                    
                    fileWriter.add(groupKey: groupKey, itemKey: itemKey) { [weak self] (result) in
                        
                        guard let self = self else {
                            return
                        }
                        
                        switch result {
                        case .success:
                            
                            self.dbWriter.markDownloaded(itemKey: itemKey) { (result) in
                                
                                defer {
                                    group.leave()
                                }
                                
                                var itemResult: FinalItemResult
                                switch result {
                                case .success:
                                    successfulItemKeys.append(itemKey)
                                    itemResult = FinalItemResult.success(itemKey: itemKey)
                                    
                                case .failure(let error):
                                    failedItemKeys.append(itemKey)
                                    itemResult = FinalItemResult.failure(error: error)
                                }
                                
                                self.gatekeeper.runAndRemoveItemCompletions(itemKey: itemKey, itemResult: itemResult)
                            }
                            
                        case .failure(let error):
                            
                            defer {
                                group.leave()
                            }
                            
                            failedItemKeys.append(itemKey)
                            let itemResult = FinalItemResult.failure(error: error)
                            self.gatekeeper.runAndRemoveItemCompletions(itemKey: itemKey, itemResult: itemResult)
                        }
                    }
                    
                    group.notify(queue: DispatchQueue.global(qos: .userInitiated)) {
                        
                        let groupResult = failedItemKeys.count > 0 ? FinalGroupResult.failure(error: CacheControllerError.atLeastOneItemFailedInFileWriter) : FinalGroupResult.success(itemKeys: successfulItemKeys)
                        
                        self.gatekeeper.runAndRemoveGroupCompletions(groupKey: groupKey, groupResult: groupResult)
                    }
                }
            
            case .failure(let error):
                let groupResult = FinalGroupResult.failure(error: error)
                gatekeeper.runAndRemoveGroupCompletions(groupKey: groupKey, groupResult: groupResult)
        }
    }
}
//
//    public func remove(groupKey: String, itemKey: String, completion: CompletionQueueBlock? = nil) {
//
//        if let completion = completion {
//             gatekeeper.externalQueue(groupKey: groupKey, completionBlockToQueue: completion)
//        }
//
//        gatekeeper.removeQueuedCompletionItems(with: groupKey)
//
//        cancelTasks(groupKey: groupKey)
//
//        let itemKeysToRemove = dbWriter.itemKeysToRemove(for: groupKey)
//
//        for itemKey in itemKeysToRemove {
//            fileWriter.remove(groupKey: groupKey, itemKey: itemKey)
//        }
//
//        dbWriter.remove(groupKey: groupKey)
//    }
//
//    public func cancelTasks(groupKey: String) {
//        dbWriter.cancelTasks(for: groupKey)
//        fileWriter.cancelTasks(for: groupKey)
//    }
//
//    public func isCached(url: URL) -> Bool {
//        dbWriter.isCached(url: url)
//    }
//
//
//    private func finishAndRunQueue(groupKey: String, itemKey: String, result: CacheResult) {
//
//        handleFinalResult(groupKey: groupKey, itemKey: itemKey, result: result)
//
//        gatekeeper.runAndCleanOutQueuedCompletionItems(result: result, itemKey: itemKey)
//    }
//
//    private func handleFinalResult(groupKey: String, itemKey: String, result: CacheResult) {
//        switch (result.status, result.type) {
//        case (.succeed, .add):
//            handleAddSuccess(groupKey: groupKey, itemKey: itemKey)
//        case (.fail, .add):
//            //tonitodo: notify user that file add failed
//            break
//        case (.fail, .remove):
//            //tonitodo: notify user that file remove failed
//            break
//        case (.succeed, .remove):
//            handleRemoveSuccess(groupKey: groupKey, itemKey: itemKey)
//        }
//    }
//
//    private func handleRemoveSuccess(groupKey: String, itemKey: String) {
//
//        //called when individual items are removed, which we don't really need to handle at this point
//    }
//
//    private func handleRemoveSuccess(groupKey: String) {
//        notifyAllRemoved(groupKey: groupKey)
//    }
//
//    private func handleAddSuccess(groupKey: String, itemKey: String) {
//
//        dbWriter.markDownloaded(itemKey: itemKey)
//
//        if dbWriter.allDownloaded(groupKey: groupKey) {
//
//            notifyAllDownloaded(groupKey: groupKey, itemKey: itemKey)
//        }
//    }
//
//    func notifyAllDownloaded(groupKey: String, itemKey: String) {
//        gatekeeper.externalRunAndCleanOutQueuedCompletionBlock(groupKey: groupKey, cacheResult: CacheResult(status: .succeed, type: .add))
//    }
//
//    func notifyAllRemoved(groupKey: String) {
//        gatekeeper.externalRunAndCleanOutQueuedCompletionBlock(groupKey: groupKey, cacheResult: CacheResult(status: .succeed, type: .remove))
//    }
//}
//
//extension CacheController: CacheDBWritingDelegate {
//
//    func shouldQueue(groupKey: String, itemKey: String) -> Bool {
//
//        return gatekeeper.shouldQueue(groupKey: groupKey, itemKey: itemKey)
//    }
//
//    func queue(groupKey: String, itemKey: String) {
//        return gatekeeper.internalQueue(groupKey: groupKey, itemKey: itemKey) { [weak self] (result) in
//
//            guard let self = self else {
//                return
//            }
//
//            self.handleFinalResult(groupKey: groupKey, itemKey: itemKey, result: result)
//        }
//    }
//
//    func dbWriterDidAdd(groupKey: String, itemKey: String) {
//        fileWriter.add(groupKey: groupKey, itemKey: itemKey)
//    }
//
//    func dbWriterDidRemove(groupKey: String, itemKey: String) {
//        finishAndRunQueue(groupKey: groupKey, itemKey: itemKey, result: CacheResult(status: .succeed, type: .remove))
//    }
//
//    func dbWriterDidFailAdd(groupKey: String, itemKey: String) {
//        finishAndRunQueue(groupKey: groupKey, itemKey: itemKey, result: CacheResult(status: .fail, type: .add))
//    }
//
//    func dbWriterDidFailRemove(groupKey: String, itemKey: String) {
//        finishAndRunQueue(groupKey: groupKey, itemKey: itemKey, result: CacheResult(status: .fail, type: .remove))
//    }
//
//    func dbWriterDidRemove(groupKey: String) {
//        handleRemoveSuccess(groupKey: groupKey)
//    }
//
//    func dbWriterDidFailRemove(groupKey: String) {
//        //tonitodo: how do we resolve, have one last group hanging around in DB
//    }
//
//    func dbWriterDidOutrightFailAdd(groupKey: String) {
//
//        let key = groupKey
//        remove(groupKey: key, itemKey: key, completion: nil)
//    }
//}
//
//extension CacheController: CacheFileWritingDelegate {
//    func fileWriterDidAdd(groupKey: String, itemKey: String) {
//
//        finishAndRunQueue(groupKey: groupKey, itemKey: itemKey, result: CacheResult(status: .succeed, type: .add))
//    }
//
//    func fileWriterDidRemove(groupKey: String, itemKey: String) {
//        dbWriter.remove(groupKey: groupKey, itemKey: itemKey)
//    }
//
//    func fileWriterDidFailAdd(groupKey: String, itemKey: String) {
//        finishAndRunQueue(groupKey: groupKey, itemKey: itemKey, result: CacheResult(status: .fail, type: .add))
//    }
//
//    func fileWriterDidFailRemove(groupKey: String, itemKey: String) {
//        finishAndRunQueue(groupKey: groupKey, itemKey: itemKey, result: CacheResult(status: .fail, type: .remove))
//    }
//}
