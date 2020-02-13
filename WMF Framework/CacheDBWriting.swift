
import Foundation

enum SaveResult {
    case success
    case failure(Error)
}

enum CacheDBWritingResultWithItemKeys {
    case success([CacheController.ItemKey])
    case failure(Error)
}

enum CacheDBWritingResult {
    case success
    case failure(Error)
}

enum CacheDBWritingMarkDownloadedError: Error {
    case invalidContext
    case cannotFindCacheGroup
    case cannotFindCacheItem
}

enum CacheDBWritingRemoveError: Error {
    case cannotFindCacheGroup
    case cannotFindCacheItem
}

protocol CacheDBWriting: CacheTaskTracking {
    
    typealias CacheDBWritingCompletion = (CacheDBWritingResultWithItemKeys) -> Void
    
    func add(url: URL, groupKey: CacheController.GroupKey, completion: @escaping CacheDBWritingCompletion)
    func add(url: URL, groupKey: CacheController.GroupKey, itemKey: CacheController.ItemKey, completion: @escaping CacheDBWritingCompletion)

    //default implementations
    func remove(itemKey: String, completion: @escaping (CacheDBWritingResult) -> Void)
    func remove(groupKey: String, completion: @escaping (CacheDBWritingResult) -> Void)
    func fetchItemKeysToRemove(for groupKey: CacheController.GroupKey, completion: @escaping (CacheDBWritingResultWithItemKeys) -> Void)
    func markDownloaded(itemKey: CacheController.ItemKey, etag: String?, completion: @escaping (CacheDBWritingResult) -> Void)
}

extension CacheDBWriting {
    
    func markDownloaded(itemKey: CacheController.ItemKey, etag: String?, completion: @escaping (CacheDBWritingResult) -> Void) {
        
        guard let context = CacheController.backgroundCacheContext else {
            completion(.failure(CacheDBWritingMarkDownloadedError.invalidContext))
            return
        }
    
        context.perform {
            guard let cacheItem = CacheDBWriterHelper.cacheItem(with: itemKey, in: context) else {
                completion(.failure(CacheDBWritingMarkDownloadedError.cannotFindCacheItem))
                return
            }
            cacheItem.isDownloaded = true
            cacheItem.etag = etag
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
    
    func fetchItemKeysToRemove(for groupKey: CacheController.GroupKey, completion: @escaping (CacheDBWritingResultWithItemKeys) -> Void) {
        guard let context = CacheController.backgroundCacheContext else {
            completion(.failure(CacheDBWritingMarkDownloadedError.invalidContext))
            return
        }
        context.perform {
            guard let group = CacheDBWriterHelper.cacheGroup(with: groupKey, in: context) else {
                completion(.failure(CacheDBWritingMarkDownloadedError.cannotFindCacheGroup))
                return
            }
            guard let cacheItems = group.cacheItems as? Set<PersistentCacheItem> else {
                completion(.failure(CacheDBWritingMarkDownloadedError.cannotFindCacheItem))
                return
            }
            
            let cacheItemsToRemove = cacheItems.filter({ (cacheItem) -> Bool in
                return cacheItem.cacheGroups?.count == 1
            })

            completion(.success(cacheItemsToRemove.compactMap { $0.key }))
        }
    }
    
    func remove(itemKey: CacheController.ItemKey, completion: @escaping (CacheDBWritingResult) -> Void) {

        guard let context = CacheController.backgroundCacheContext else {
            completion(.failure(CacheDBWritingMarkDownloadedError.invalidContext))
            return
        }
        
        context.perform {
            guard let cacheItem = CacheDBWriterHelper.cacheItem(with: itemKey, in: context) else {
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
            completion(.failure(CacheDBWritingMarkDownloadedError.invalidContext))
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
            let fetchRequest = NSFetchRequest<PersistentCacheItem>(entityName: "PersistentCacheItem")
            do {
                let fetchedResults = try context.fetch(fetchRequest)
                if fetchedResults.count == 0 {
                     print("🌹noItems")
                } else {
                    for item in fetchedResults {
                        print("🌹itemKey: \(item.value(forKey: "key")!)")
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
            let fetchRequest = NSFetchRequest<PersistentCacheGroup>(entityName: "PersistentCacheGroup")
            do {
                let fetchedResults = try context.fetch(fetchRequest)
                if fetchedResults.count == 0 {
                     print("🌹noGroups")
                } else {
                    for item in fetchedResults {
                        print("🌹groupKey: \(item.value(forKey: "key")!)")
                    }
                }
            } catch let error as NSError {
                // something went wrong, print the error.
                print(error.description)
            }
        }
    }
}
