
import Foundation

enum SaveResult {
    case success
    case failure(Error)
}

enum CacheDBWritingResultWithURLRequests {
    case success([URLRequest])
    case failure(Error)
}

enum CacheDBWritingResultWithItemAndVariantKeys {
    case success([CacheController.ItemKeyAndVariant])
    case failure(Error)
}

enum CacheDBWritingResult {
    case success
    case failure(Error)
}

enum CacheDBWritingMarkDownloadedError: Error {
    case cannotFindCacheGroup
    case cannotFindCacheItem
    case missingExpectedItemsOutOfRequestHeader
    case missingMOC
}

enum CacheDBWritingRemoveError: Error {
    case cannotFindCacheGroup
    case cannotFindCacheItem
    case missingMOC
}

protocol CacheDBWriting: CacheTaskTracking {
    
    typealias CacheDBWritingCompletionWithURLRequests = (CacheDBWritingResultWithURLRequests) -> Void
    typealias CacheDBWritingCompletionWithItemAndVariantKeys = (CacheDBWritingResultWithItemAndVariantKeys) -> Void
    
    func add(url: URL, groupKey: CacheController.GroupKey, completion: @escaping CacheDBWritingCompletionWithURLRequests)
    func add(urls: [URL], groupKey: CacheController.GroupKey, completion: @escaping CacheDBWritingCompletionWithURLRequests)
    func shouldDownloadVariant(itemKey: CacheController.ItemKey, variant: String?) -> Bool

    //default implementations
    func remove(itemAndVariantKey: CacheController.ItemKeyAndVariant, completion: @escaping (CacheDBWritingResult) -> Void)
    func remove(groupKey: String, completion: @escaping (CacheDBWritingResult) -> Void)
    func fetchKeysToRemove(for groupKey: CacheController.GroupKey, completion: @escaping CacheDBWritingCompletionWithItemAndVariantKeys)
    func markDownloaded(urlRequest: URLRequest, completion: @escaping (CacheDBWritingResult) -> Void)
}

extension CacheDBWriting {
    
    func markDownloaded(urlRequest: URLRequest, completion: @escaping (CacheDBWritingResult) -> Void) {
        
        guard let context = CacheController.backgroundCacheContext else {
            completion(.failure(CacheDBWritingMarkDownloadedError.missingMOC))
            return
        }
        
        guard let itemKey = urlRequest.allHTTPHeaderFields?[Session.Header.persistentCacheItemKey] else {
                completion(.failure(CacheDBWritingMarkDownloadedError.missingExpectedItemsOutOfRequestHeader))
                return
        }
        
        let variant = urlRequest.allHTTPHeaderFields?[Session.Header.persistentCacheItemVariant]
    
        context.perform {
            guard let cacheItem = CacheDBWriterHelper.cacheItem(with: itemKey, variant: variant, in: context) else {
                completion(.failure(CacheDBWritingMarkDownloadedError.cannotFindCacheItem))
                return
            }
            cacheItem.isDownloaded = true
            CacheDBWriterHelper.save(moc: context) { (result) in
                switch result {
                case .success:
                    completion(.success)
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    func fetchKeysToRemove(for groupKey: CacheController.GroupKey, completion: @escaping CacheDBWritingCompletionWithItemAndVariantKeys) {
        
        guard let context = CacheController.backgroundCacheContext else {
            completion(.failure(CacheDBWritingMarkDownloadedError.missingMOC))
            return
        }
        
        context.perform {
            guard let group = CacheDBWriterHelper.cacheGroup(with: groupKey, in: context) else {
                completion(.failure(CacheDBWritingMarkDownloadedError.cannotFindCacheGroup))
                return
            }
            guard let cacheItems = group.cacheItems as? Set<CacheItem> else {
                completion(.failure(CacheDBWritingMarkDownloadedError.cannotFindCacheItem))
                return
            }
            
            let cacheItemsToRemove = cacheItems.filter({ (cacheItem) -> Bool in
                return cacheItem.cacheGroups?.count == 1
            })

            completion(.success(cacheItemsToRemove.compactMap { CacheController.ItemKeyAndVariant(itemKey: $0.key, variant: $0.variant) }))
        }
    }
    
    func remove(itemAndVariantKey: CacheController.ItemKeyAndVariant, completion: @escaping (CacheDBWritingResult) -> Void) {

        guard let context = CacheController.backgroundCacheContext else {
            completion(.failure(CacheDBWritingRemoveError.missingMOC))
            return
        }
        
        context.perform {
            guard let cacheItem = CacheDBWriterHelper.cacheItem(with: itemAndVariantKey.itemKey, variant: itemAndVariantKey.variant, in: context) else {
                completion(.failure(CacheDBWritingRemoveError.cannotFindCacheItem))
                return
            }
            
            context.delete(cacheItem)
            
            CacheDBWriterHelper.save(moc: context) { (result) in
                switch result {
                case .success:
                    completion(.success)
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    func remove(groupKey: CacheController.GroupKey, completion: @escaping (CacheDBWritingResult) -> Void) {

        guard let context = CacheController.backgroundCacheContext else {
            completion(.failure(CacheDBWritingRemoveError.missingMOC))
            return
        }
        
        context.perform {
            guard let cacheGroup = CacheDBWriterHelper.cacheGroup(with: groupKey, in: context) else {
                completion(.failure(CacheDBWritingRemoveError.cannotFindCacheItem))
                return
            }
            
            context.delete(cacheGroup)
            
            CacheDBWriterHelper.save(moc: context) { (result) in
                switch result {
                case .success:
                    completion(.success)
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    func fetchAndPrintEachItem() {
        
        guard let context = CacheController.backgroundCacheContext else {
            return
        }
        
        context.perform {
            let fetchRequest = NSFetchRequest<CacheItem>(entityName: "CacheItem")
            do {
                let fetchedResults = try context.fetch(fetchRequest)
                if fetchedResults.count == 0 {
                     DDLogDebug("🌹noItems")
                } else {
                    for item in fetchedResults {
                        DDLogDebug("🌹itemKey: \(item.value(forKey: "key")!), variant:  \(item.value(forKey: "variant") ?? "nil"), itemURL: \(item.value(forKey: "url") ?? "nil")")
                    }
                }
            } catch let error as NSError {
                // something went wrong, print the error.
                print(error.description)
            }
        }
    }
    
    func fetchAndPrintEachGroup() {
        
        guard let context = CacheController.backgroundCacheContext else {
            return
        }
        
        context.perform {
            let fetchRequest = NSFetchRequest<CacheGroup>(entityName: "CacheGroup")
            do {
                let fetchedResults = try context.fetch(fetchRequest)
                if fetchedResults.count == 0 {
                     DDLogDebug("🌹noGroups")
                } else {
                    for item in fetchedResults {
                        DDLogDebug("🌹groupKey: \(item.value(forKey: "key")!)")
                    }
                }
            } catch let error as NSError {
                // something went wrong, print the error.
                DDLogDebug(error.description)
            }
        }
    }
}
