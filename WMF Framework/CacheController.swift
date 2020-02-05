
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
            
            if gatekeeper.shouldQueueAddCompletion(groupKey: groupKey) {
                gatekeeper.queueAddCompletion(groupKey: groupKey) {
                    self.add(url: url, groupKey: groupKey, itemKey: itemKey, bypassGroupDeduping: bypassGroupDeduping, itemCompletion: itemCompletion, groupCompletion: groupCompletion)
                    return
                }
            } else {
                gatekeeper.addCurrentlyAddingGroupKey(groupKey)
            }
            
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
    
    public func cachedURLResponse(for request: URLRequest) -> CachedURLResponse? {
        return provider.cachedURLResponse(for: request)
    }
    
    public func newCachePolicyRequest(from originalRequest: NSURLRequest, newURL: URL) -> URLRequest? {
        return provider.newCachePolicyRequest(from: originalRequest, newURL: newURL)
    }
    
    private func finishDBAdd(groupKey: GroupKey, itemCompletion: @escaping ItemCompletionBlock, groupCompletion: @escaping GroupCompletionBlock, result: CacheDBWritingResultWithItemKeys) {
        
        let groupCompleteBlock = { (groupResult: FinalGroupResult) in
            self.gatekeeper.runAndRemoveGroupCompletions(groupKey: groupKey, groupResult: groupResult)
            self.gatekeeper.removeCurrentlyAddingGroupKey(groupKey)
            self.gatekeeper.runAndRemoveQueuedRemoves(groupKey: groupKey)
        }
        
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
                    
                    guard dbWriter.shouldDownloadVariant(itemKey: itemKey) else {
                        continue
                    }
                    
                    fileWriter.add(groupKey: groupKey, itemKey: itemKey) { [weak self] (result) in
                        
                        guard let self = self else {
                            return
                        }
                        
                        switch result {
                        case .success(let etag):
                            
                            self.dbWriter.markDownloaded(itemKey: itemKey, etag: etag) { (result) in
                                
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
                        
                        groupCompleteBlock(groupResult)
                    }
                }
            
            case .failure(let error):
                let groupResult = FinalGroupResult.failure(error: error)
                groupCompleteBlock(groupResult)
        }
    }
    
    public func remove(groupKey: GroupKey, itemCompletion: @escaping ItemCompletionBlock, groupCompletion: @escaping GroupCompletionBlock) {

        if gatekeeper.shouldQueueRemoveCompletion(groupKey: groupKey) {
            gatekeeper.queueRemoveCompletion(groupKey: groupKey) {
                self.remove(groupKey: groupKey, itemCompletion: itemCompletion, groupCompletion: groupCompletion)
                return
            }
        } else {
            gatekeeper.addCurrentlyRemovingGroupKey(groupKey)
        }
        
        if gatekeeper.numberOfQueuedGroupCompletions(for: groupKey) > 0 {
            gatekeeper.queueGroupCompletion(groupKey: groupKey, groupCompletion: groupCompletion)
            return
        }

        gatekeeper.queueGroupCompletion(groupKey: groupKey, groupCompletion: groupCompletion)

        cancelTasks(groupKey: groupKey)
        
        let groupCompleteBlock = { (groupResult: FinalGroupResult) in
            self.gatekeeper.runAndRemoveGroupCompletions(groupKey: groupKey, groupResult: groupResult)
            self.gatekeeper.removeCurrentlyRemovingGroupKey(groupKey)
            self.gatekeeper.runAndRemoveQueuedAdds(groupKey: groupKey)
        }

        dbWriter.fetchItemKeysToRemove(for: groupKey) { [weak self] (result) in
            
            guard let self = self else {
                return
            }
            
            switch result {
            case .success(let itemKeys):
                
                var successfulItemKeys: [CacheController.ItemKey] = []
                var failedItemKeys: [CacheController.ItemKey] = []
                
                let group = DispatchGroup()
                for itemKey in itemKeys {
                    group.enter()
                    
                    if self.gatekeeper.numberOfQueuedItemCompletions(for: itemKey) > 0 {
                        defer {
                            group.leave()
                        }
                        self.gatekeeper.queueItemCompletion(itemKey: itemKey, itemCompletion: itemCompletion)
                        continue
                    }
                    
                    self.gatekeeper.queueItemCompletion(itemKey: itemKey, itemCompletion: itemCompletion)
                    
                    self.fileWriter.remove(itemKey: itemKey) { (result) in
                        
                        switch result {
                        case .success:
                            
                            self.dbWriter.remove(itemKey: itemKey) { (result) in
                                
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
                            failedItemKeys.append(itemKey)
                            let itemResult = FinalItemResult.failure(error: error)
                            self.gatekeeper.runAndRemoveItemCompletions(itemKey: itemKey, itemResult: itemResult)
                            group.leave()
                        }
                    }
                }
                
                group.notify(queue: DispatchQueue.global(qos: .userInitiated)) {
                    
                    if failedItemKeys.count == 0 {
                        
                        self.dbWriter.remove(groupKey: groupKey, completion: { (result) in
                            
                            var groupResult: FinalGroupResult
                            switch result {
                            case .success:
                                groupResult = FinalGroupResult.success(itemKeys: successfulItemKeys)
                                
                            case .failure(let error):
                                groupResult = FinalGroupResult.failure(error: error)
                            }
                            
                           groupCompleteBlock(groupResult)
                        })
                    } else {
                        let groupResult = FinalGroupResult.failure(error: CacheControllerError.atLeastOneItemFailedInFileWriter)
                        groupCompleteBlock(groupResult)
                    }
                }
                
            case .failure(let error):
                let groupResult = FinalGroupResult.failure(error: error)
                groupCompleteBlock(groupResult)
            }
        }
    }
}
