import Foundation

public enum CacheControllerError: Error {
    case unableToCreateBackgroundCacheContext
    case atLeastOneItemFailedInFileWriter(Error)
    case failureToGenerateItemResult
    case atLeastOneItemFailedInSync(Error)
}

public class CacheController {
    
    #if TEST
    public static var temporaryCacheURL: URL? = nil
    #endif
    
    static let cacheURL: URL = {
        
        #if TEST
        if let temporaryCacheURL = temporaryCacheURL {
            return temporaryCacheURL
        }
        #endif
        
        var url = FileManager.default.wmf_containerURL().appendingPathComponent("Permanent Cache", isDirectory: true)
        
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        do {
            try url.setResourceValues(values)
        } catch {
            return url
        }
        
        return url
    }()
    
    // todo: Settings hook, logout don't sync hook, etc.
    public static var totalCacheSizeInBytes: Int64 {
        return FileManager.default.sizeOfDirectory(at: cacheURL)
    }
    
    /// Performs any necessary migrations on the CacheController's internal storage
    static func setupCoreDataStack(_ completion: @escaping (NSManagedObjectContext?, CacheControllerError?) -> Void) {
        // Expensive file & db operations happen as a part of this migration, so async it to a non-main queue
        DispatchQueue.global(qos: .default).async {
            // Instantiating the moc will perform the migrations in CacheItemMigrationPolicy
            guard let moc = createCacheContext(cacheURL: cacheURL) else {
                completion(nil, .unableToCreateBackgroundCacheContext)
                return
            }
            // do a moc.perform in case anything else needs to be run before the context is ready
            moc.perform {
                DispatchQueue.main.async {
                    completion(moc, nil)
                }
            }
        }
    }

    static func createCacheContext(cacheURL: URL) -> NSManagedObjectContext? {
        
        // create cacheURL directory
        do {
            try FileManager.default.createDirectory(at: cacheURL, withIntermediateDirectories: true, attributes: nil)
        } catch let error {
            assertionFailure("Error creating permanent cache: \(error)")
            return nil
        }
        
        // create ManagedObjectModel based on Cache.momd
        guard let modelURL = Bundle.wmf.url(forResource: "Cache", withExtension: "momd"),
            let model = NSManagedObjectModel(contentsOf: modelURL) else {
                assertionFailure("Failure to create managed object model")
                return nil
        }

        // create persistent store coordinator / persistent store
        let dbURL = cacheURL.appendingPathComponent("Cache.sqlite", isDirectory: false)
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
    }
    
    public typealias ItemKey = String
    public typealias GroupKey = String
    public typealias UniqueKey = String // combo of item key + variant
    public typealias IndividualCompletionBlock = (FinalIndividualResult) -> Void
    public typealias GroupCompletionBlock = (FinalGroupResult) -> Void
    
    public struct ItemKeyAndVariant: Hashable {
        let itemKey: CacheController.ItemKey
        let variant: String?
        
        init?(itemKey: CacheController.ItemKey?, variant: String?) {
            
            guard let itemKey = itemKey else {
                return nil
            }
            
            self.itemKey = itemKey
            self.variant = variant
        }
    }

    public enum FinalIndividualResult {
        case success(uniqueKey: CacheController.UniqueKey)
        case failure(error: Error)
    }
    
    public enum FinalGroupResult {
        case success(uniqueKeys: [CacheController.UniqueKey])
        case failure(error: Error)
    }
    
    let dbWriter: CacheDBWriting
    let fileWriter: CacheFileWriter
    let gatekeeper = CacheGatekeeper()
    
    init(dbWriter: CacheDBWriting, fileWriter: CacheFileWriter) {
        self.dbWriter = dbWriter
        self.fileWriter = fileWriter
    }

    public func add(url: URL, groupKey: GroupKey, individualCompletion: @escaping IndividualCompletionBlock, groupCompletion: @escaping GroupCompletionBlock) {
        
        if gatekeeper.shouldQueueAddCompletion(groupKey: groupKey) {
            gatekeeper.queueAddCompletion(groupKey: groupKey) {
                self.add(url: url, groupKey: groupKey, individualCompletion: individualCompletion, groupCompletion: groupCompletion)
                return
            }
        } else {
            gatekeeper.addCurrentlyAddingGroupKey(groupKey)
        }
        
        if gatekeeper.numberOfQueuedGroupCompletions(for: groupKey) > 0 {
            gatekeeper.queueGroupCompletion(groupKey: groupKey, groupCompletion: groupCompletion)
            return
        }
        
        gatekeeper.queueGroupCompletion(groupKey: groupKey, groupCompletion: groupCompletion)
        
        dbWriter.add(url: url, groupKey: groupKey) { [weak self] (result) in
            self?.finishDBAdd(groupKey: groupKey, individualCompletion: individualCompletion, groupCompletion: groupCompletion, result: result)
        }
    }
    
    public func cancelTasks(groupKey: String) {
        dbWriter.cancelTasks(for: groupKey)
        fileWriter.cancelTasks(for: groupKey)
    }
    
    public func cancelAllTasks() {
        dbWriter.cancelAllTasks()
        fileWriter.cancelAllTasks()
    }
    
    func shouldDownloadVariantForAllVariantItems(variant: String?, _ allVariantItems: [CacheController.ItemKeyAndVariant]) -> Bool {
        return dbWriter.shouldDownloadVariantForAllVariantItems(variant: variant, allVariantItems)
    }
    
    func finishDBAdd(groupKey: GroupKey, individualCompletion: @escaping IndividualCompletionBlock, groupCompletion: @escaping GroupCompletionBlock, result: CacheDBWritingResultWithURLRequests) {
        
        let groupCompleteBlock = { (groupResult: FinalGroupResult) in
            self.gatekeeper.runAndRemoveGroupCompletions(groupKey: groupKey, groupResult: groupResult)
            self.gatekeeper.removeCurrentlyAddingGroupKey(groupKey)
            self.gatekeeper.runAndRemoveQueuedRemoves(groupKey: groupKey)
        }
        
        switch result {
        case .success(let urlRequests):

            var successfulKeys: [CacheController.UniqueKey] = []
            var failedKeys: [(CacheController.UniqueKey, Error)] = []

            let group = DispatchGroup()
            for urlRequest in urlRequests {

                guard let uniqueKey = fileWriter.uniqueFileNameForURLRequest(urlRequest),
                    let url = urlRequest.url else {
                    continue
                }

                group.enter()

                if gatekeeper.numberOfQueuedIndividualCompletions(for: uniqueKey) > 0 {
                    defer {
                        group.leave()
                    }
                    gatekeeper.queueIndividualCompletion(uniqueKey: uniqueKey, individualCompletion: individualCompletion)
                    continue
                }

                gatekeeper.queueIndividualCompletion(uniqueKey: uniqueKey, individualCompletion: individualCompletion)

                guard dbWriter.shouldDownloadVariant(urlRequest: urlRequest) else {
                    group.leave()
                    continue
                }

                fileWriter.add(groupKey: groupKey, urlRequest: urlRequest) { [weak self] (result) in

                    guard let self = self else {
                        return
                    }

                    switch result {
                    case .success(let response, let data):

                        self.dbWriter.markDownloaded(urlRequest: urlRequest, response: response) { (result) in

                            defer {
                                group.leave()
                            }

                            let individualResult: FinalIndividualResult

                            switch result {
                            case .success:
                                successfulKeys.append(uniqueKey)
                                individualResult = FinalIndividualResult.success(uniqueKey: uniqueKey)

                            case .failure(let error):
                                failedKeys.append((uniqueKey, error))
                                individualResult = FinalIndividualResult.failure(error: error)
                            }

                            self.gatekeeper.runAndRemoveIndividualCompletions(uniqueKey: uniqueKey, individualResult: individualResult)
                        }

                        self.finishFileSave(data: data, mimeType: response.mimeType, uniqueKey: uniqueKey, url: url)

                    case .failure(let error):

                        defer {
                            group.leave()
                        }

                        failedKeys.append((uniqueKey, error))
                        let individualResult = FinalIndividualResult.failure(error: error)
                        self.gatekeeper.runAndRemoveIndividualCompletions(uniqueKey: uniqueKey, individualResult: individualResult)
                    }
                }

                group.notify(queue: DispatchQueue.global(qos: .userInitiated)) {
                    let groupResult: FinalGroupResult
                    if let error = failedKeys.first?.1 {
                        groupResult = FinalGroupResult.failure(error: CacheControllerError.atLeastOneItemFailedInFileWriter(error))
                    } else {
                        groupResult = FinalGroupResult.success(uniqueKeys: successfulKeys)
                    }
                    groupCompleteBlock(groupResult)
                }
            }

        case .failure(let error):
            let groupResult = FinalGroupResult.failure(error: error)
            groupCompleteBlock(groupResult)
        }
    }
    
    func finishFileSave(data: Data, mimeType: String?, uniqueKey: CacheController.UniqueKey, url: URL) {
        // hook to allow subclasses to do any additional work with data
    }
    
    public func remove(groupKey: GroupKey, individualCompletion: @escaping IndividualCompletionBlock, groupCompletion: @escaping GroupCompletionBlock) {

        if gatekeeper.shouldQueueRemoveCompletion(groupKey: groupKey) {
            gatekeeper.queueRemoveCompletion(groupKey: groupKey) {
                self.remove(groupKey: groupKey, individualCompletion: individualCompletion, groupCompletion: groupCompletion)
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

        dbWriter.fetchKeysToRemove(for: groupKey) { [weak self] (result) in
            
            guard let self = self else {
                return
            }
            
            switch result {
            case .success(let keys):
                
                var successfulKeys: [CacheController.UniqueKey] = []
                var failedKeys: [(CacheController.UniqueKey, Error)] = []
                
                let group = DispatchGroup()
                for key in keys {
                    
                    guard let uniqueKey = self.fileWriter.uniqueFileNameForItemKey(key.itemKey, variant: key.variant) else {
                        continue
                    }
                    
                    group.enter()
                    
                    if self.gatekeeper.numberOfQueuedIndividualCompletions(for: uniqueKey) > 0 {
                        defer {
                            group.leave()
                        }
                        self.gatekeeper.queueIndividualCompletion(uniqueKey: uniqueKey, individualCompletion: individualCompletion)
                        continue
                    }
                    
                    self.gatekeeper.queueIndividualCompletion(uniqueKey: uniqueKey, individualCompletion: individualCompletion)
                    
                    self.fileWriter.remove(itemKey: key.itemKey, variant: key.variant) { (result) in
                        
                        switch result {
                        case .success:
                            
                            self.dbWriter.remove(itemAndVariantKey: key) { (result) in
                                defer {
                                    group.leave()
                                }
                                
                                var individualResult: FinalIndividualResult
                                switch result {
                                case .success:
                                    successfulKeys.append(uniqueKey)
                                    individualResult = FinalIndividualResult.success(uniqueKey: uniqueKey)
                                case .failure(let error):
                                    failedKeys.append((uniqueKey, error))
                                    individualResult = FinalIndividualResult.failure(error: error)
                                }
                                
                                self.gatekeeper.runAndRemoveIndividualCompletions(uniqueKey: uniqueKey, individualResult: individualResult)
                            }
                            
                        case .failure(let error):
                            failedKeys.append((uniqueKey, error))
                            let individualResult = FinalIndividualResult.failure(error: error)
                            self.gatekeeper.runAndRemoveIndividualCompletions(uniqueKey: uniqueKey, individualResult: individualResult)
                            group.leave()
                        }
                    }
                }
                
                group.notify(queue: DispatchQueue.global(qos: .userInitiated)) {
                    if let error = failedKeys.first?.1 {
                        let groupResult = FinalGroupResult.failure(error: CacheControllerError.atLeastOneItemFailedInFileWriter(error))
                        groupCompleteBlock(groupResult)
                        return
                    }
                    self.dbWriter.remove(groupKey: groupKey, completion: { (result) in
                        var groupResult: FinalGroupResult
                        switch result {
                        case .success:
                            groupResult = FinalGroupResult.success(uniqueKeys: successfulKeys)
                            
                        case .failure(let error):
                            groupResult = FinalGroupResult.failure(error: error)
                        }
                        
                        groupCompleteBlock(groupResult)
                    })
                }
                
            case .failure(let error):
                let groupResult = FinalGroupResult.failure(error: error)
                groupCompleteBlock(groupResult)
            }
        }
    }
}
