
import Foundation

enum SaveResult {
    case success
    case failure(Error)
}

enum CacheDBWritingResult {
    case success([CacheController.ItemKey])
    case failure(Error)
}

enum CacheDBWritingMarkDownloadedResult {
    case success
    case failure(Error)
}

enum CacheDBWritingMarkDownloadedError: Error {
    case invalidContext
    case cannotFindCacheItem
}

protocol CacheDBWriting: CacheTaskTracking {
    
    typealias CacheDBWritingCompletion = (CacheDBWritingResult) -> Void
    
    func add(url: URL, groupKey: CacheController.GroupKey, completion: @escaping CacheDBWritingCompletion)
    func add(url: URL, groupKey: CacheController.GroupKey, itemKey: CacheController.ItemKey, completion: @escaping CacheDBWritingCompletion)

    //default implementations
    //func remove(groupKey: String, itemKey: String)
    //func itemKeysToRemove(for groupKey: String) -> [String]
    func markDownloaded(itemKey: String, completion: @escaping (CacheDBWritingMarkDownloadedResult) -> Void)
}

extension CacheDBWriting {
    
    func markDownloaded(itemKey: String, completion: @escaping (CacheDBWritingMarkDownloadedResult) -> Void) {
        
        guard let context = CacheController.backgroundCacheContext else {
            completion(.failure(CacheDBWritingMarkDownloadedError.invalidContext))
            return
        }
        
        guard let cacheItem = CacheDBWriterHelper.cacheItem(with: itemKey, in: context) else {
            completion(.failure(CacheDBWritingMarkDownloadedError.cannotFindCacheItem))
            return
        }
        
        context.perform {
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
    
//    func itemKeysToRemove(for groupKey: String) -> [String] {
//        guard let context = CacheController.backgroundCacheContext else {
//            return []
//        }
//
//       return context.performWaitAndReturn {
//
//            guard let group = CacheDBWriterHelper.cacheGroup(with: groupKey, in: context) else {
//                return []
//            }
//            guard let cacheItems = group.cacheItems as? Set<PersistentCacheItem> else {
//                return []
//            }
//
//            let cacheItemsToRemove = cacheItems.filter({ (cacheItem) -> Bool in
//                return cacheItem.cacheGroups?.count == 1
//            })
//
//            return cacheItemsToRemove.compactMap { $0.key }
//        } ?? []
//    }
//
//    func remove(groupKey: String) {
//        guard let context = CacheController.backgroundCacheContext else {
//           return
//       }
//
//       context.perform {
//
//           guard let cacheGroup = CacheDBWriterHelper.cacheGroup(with: groupKey, in: context) else {
//               return
//           }
//
//           context.delete(cacheGroup)
//
//           CacheDBWriterHelper.save(moc: context) { (result) in
//               switch result {
//               case .success:
//                   self.delegate?.dbWriterDidRemove(groupKey: groupKey)
//               case .failure:
//                   self.delegate?.dbWriterDidFailRemove(groupKey: groupKey)
//               }
//           }
//       }
//    }
//
//    func remove(groupKey: String, itemKey: String) {
//
//        guard let context = CacheController.backgroundCacheContext else {
//            return
//        }
//
//        context.perform {
//
//            guard let cacheGroup = CacheDBWriterHelper.cacheGroup(with: groupKey, in: context) else {
//                return
//            }
//
//            guard let cacheItems = cacheGroup.cacheItems as? Set<PersistentCacheItem> else {
//                return
//            }
//
//            for cacheItem in cacheItems where cacheItem.key == itemKey {
//
//                if (cacheItem.cacheGroups?.count == 1) {
//                    context.delete(cacheItem)
//                }
//            }
//
//            CacheDBWriterHelper.save(moc: context) { (result) in
//                switch result {
//                case .success:
//                    self.delegate?.dbWriterDidRemove(groupKey: groupKey, itemKey: itemKey)
//                case .failure:
//                    self.delegate?.dbWriterDidFailRemove(groupKey: groupKey, itemKey: itemKey)
//                }
//            }
//        }
//    }
    
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
