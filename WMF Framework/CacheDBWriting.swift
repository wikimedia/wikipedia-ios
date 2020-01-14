
import Foundation

enum SaveResult {
    case success
    case failure(Error)
}

protocol CacheDBWritingDelegate: class {
    func shouldQueue(groupKey: String, itemKey: String) -> Bool
    func queue(groupKey: String, itemKey: String)
    func dbWriterDidOutrightFailAdd(groupKey: String)
    func dbWriterDidAdd(groupKey: String, itemKey: String)
    func dbWriterDidRemove(groupKey: String, itemKey: String)
    func dbWriterDidRemove(groupKey: String)
    func dbWriterDidFailAdd(groupKey: String, itemKey: String)
    func dbWriterDidFailRemove(groupKey: String, itemKey: String)
    func dbWriterDidFailRemove(groupKey: String)
}

protocol CacheDBWriting: CacheTaskTracking {
    
    var delegate: CacheDBWritingDelegate? { get }
    
    func add(url: URL, groupKey: String, itemKey: String)

    //default implementations
    func remove(groupKey: String, itemKey: String)
    func isCached(url: URL) -> Bool
    func itemKeysToRemove(for groupKey: String) -> [String]
    func markDownloaded(itemKey: String)
    func allDownloaded(groupKey: String) -> Bool
}

extension CacheDBWriting {
    
    func isCached(url: URL) -> Bool {
        
        guard let itemKey = url.wmf_databaseKey,
        let context = CacheController.backgroundCacheContext else {
            return false
        }
        
        return context.performWaitAndReturn {
            let cacheItem = CacheDBWriterHelper.cacheItem(with: itemKey, in: context)
            return cacheItem?.isDownloaded
        } ?? false
    }
    
    func allDownloaded(groupKey: String) -> Bool {
        
        guard let context = CacheController.backgroundCacheContext else {
            return false
        }
        
        guard let group = CacheDBWriterHelper.cacheGroup(with: groupKey, in: context) else {
            return false
        }
        guard let cacheItems = group.cacheItems as? Set<PersistentCacheItem> else {
            return false
        }
        
        return context.performWaitAndReturn {
            for item in cacheItems {
                if !item.isDownloaded {
                    return false
                }
            }
            
            return true
        } ?? false
    }
    
    func markDownloaded(itemKey: String) {
        
        guard let context = CacheController.backgroundCacheContext else {
            return
        }
        
        guard let cacheItem = CacheDBWriterHelper.cacheItem(with: itemKey, in: context) else {
            return
        }
        
        context.perform {
            cacheItem.isDownloaded = true
            CacheDBWriterHelper.save(moc: context) { (result) in
                           
            }
        }
    }
    
    func itemKeysToRemove(for groupKey: String) -> [String] {
        guard let context = CacheController.backgroundCacheContext else {
            return []
        }
        
       return context.performWaitAndReturn {
            
            guard let group = CacheDBWriterHelper.cacheGroup(with: groupKey, in: context) else {
                return []
            }
            guard let cacheItems = group.cacheItems as? Set<PersistentCacheItem> else {
                return []
            }
            
            let cacheItemsToRemove = cacheItems.filter({ (cacheItem) -> Bool in
                return cacheItem.cacheGroups?.count == 1
            })
            
            return cacheItemsToRemove.compactMap { $0.key }
        } ?? []
    }
    
    func remove(groupKey: String) {
        guard let context = CacheController.backgroundCacheContext else {
           return
       }
       
       context.perform {
           
           guard let cacheGroup = CacheDBWriterHelper.cacheGroup(with: groupKey, in: context) else {
               return
           }
           
           context.delete(cacheGroup)
           
           CacheDBWriterHelper.save(moc: context) { (result) in
               switch result {
               case .success:
                   self.delegate?.dbWriterDidRemove(groupKey: groupKey)
               case .failure:
                   self.delegate?.dbWriterDidFailRemove(groupKey: groupKey)
               }
           }
       }
    }
    
    func remove(groupKey: String, itemKey: String) {
        
        guard let context = CacheController.backgroundCacheContext else {
            return
        }
        
        context.perform {
            
            guard let cacheGroup = CacheDBWriterHelper.cacheGroup(with: groupKey, in: context) else {
                return
            }
            
            guard let cacheItems = cacheGroup.cacheItems as? Set<PersistentCacheItem> else {
                return
            }
            
            for cacheItem in cacheItems where cacheItem.key == itemKey {
                
                if (cacheItem.cacheGroups?.count == 1) {
                    context.delete(cacheItem)
                }
            }
            
            CacheDBWriterHelper.save(moc: context) { (result) in
                switch result {
                case .success:
                    self.delegate?.dbWriterDidRemove(groupKey: groupKey, itemKey: itemKey)
                case .failure:
                    self.delegate?.dbWriterDidFailRemove(groupKey: groupKey, itemKey: itemKey)
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
