
import Foundation

final class CacheDBWriterHelper {
    static func fetchOrCreateCacheGroup(with groupKey: String, in moc: NSManagedObjectContext) -> PersistentCacheGroup? {
        return cacheGroup(with: groupKey, in: moc) ?? createCacheGroup(with: groupKey, in: moc)
    }

    static func fetchOrCreateCacheItem(with itemKey: String, in moc: NSManagedObjectContext) -> PersistentCacheItem? {
        return cacheItem(with: itemKey, in: moc) ?? createCacheItem(with: itemKey, in: moc)
    }
    
    static func inMemoryCacheGroup(with key: String, in moc: NSManagedObjectContext) -> PersistentCacheGroup? {
        for object in moc.registeredObjects where !object.isFault {
            let predicate = NSPredicate(format: "key == %@", key)
            guard let result = object as? PersistentCacheGroup, predicate.evaluate(with: result) else {
                continue
            }
            return result
        }
        return nil
    }

    static func cacheGroup(with key: String, in moc: NSManagedObjectContext) -> PersistentCacheGroup? {
        
        if let inMemoryGroup = inMemoryCacheGroup(with: key, in: moc) {
            return inMemoryGroup
        }
        
        let fetchRequest: NSFetchRequest<PersistentCacheGroup> = PersistentCacheGroup.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "key == %@", key)
        fetchRequest.fetchLimit = 1
        do {
            guard let group = try moc.fetch(fetchRequest).first else {
                return nil
            }
            return group
        } catch let error {
            fatalError(error.localizedDescription)
        }
    }
    
    static func createCacheGroup(with groupKey: String, in moc: NSManagedObjectContext) -> PersistentCacheGroup? {
        
        guard let entity = NSEntityDescription.entity(forEntityName: "PersistentCacheGroup", in: moc) else {
            return nil
        }
        let group = PersistentCacheGroup(entity: entity, insertInto: moc)
        group.key = groupKey
        return group
    }
    
    static func allVariantItems(for itemKey: CacheController.ItemKey, in moc: NSManagedObjectContext) -> [PersistentCacheItem] {
        
        guard let item = cacheItem(with: itemKey, in: moc) else {
            return []
        }
        
        guard let variantGroupKey = item.variantGroupKey else {
            return [item]
        }
        
        let fetchRequest: NSFetchRequest<PersistentCacheItem> = PersistentCacheItem.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "variantGroupKey == %@", variantGroupKey)
        do {
            return try moc.fetch(fetchRequest)
        } catch {
            return [item]
        }
    }
    
    static func allDownloadedVariantItems(for itemKey: CacheController.ItemKey, in moc: NSManagedObjectContext) -> [PersistentCacheItem] {
        
        guard let item = cacheItem(with: itemKey, in: moc) else {
            return []
        }
        
        guard let variantGroupKey = item.variantGroupKey else {
            return [item]
        }
        
        let fetchRequest: NSFetchRequest<PersistentCacheItem> = PersistentCacheItem.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "variantGroupKey == %@ && isDownloaded == YES", variantGroupKey)
        do {
            return try moc.fetch(fetchRequest)
        } catch {
            return [item]
        }
    }
    
    static func cacheItem(with itemKey: String, in moc: NSManagedObjectContext) -> PersistentCacheItem? {
        
        let fetchRequest: NSFetchRequest<PersistentCacheItem> = PersistentCacheItem.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "key == %@", itemKey)
        fetchRequest.fetchLimit = 1
        do {
            guard let item = try moc.fetch(fetchRequest).first else {
                return nil
            }
            return item
        } catch let error {
            fatalError(error.localizedDescription)
        }
    }

    static func createCacheItem(with itemKey: String, in moc: NSManagedObjectContext) -> PersistentCacheItem? {
        guard let entity = NSEntityDescription.entity(forEntityName: "PersistentCacheItem", in: moc) else {
            return nil
        }
        let item = PersistentCacheItem(entity: entity, insertInto: moc)
        item.key = itemKey
        item.date = Date()
        return item
    }
    
    static func isCached(url: URL, in moc: NSManagedObjectContext) -> Bool {
        
        guard let groupKey = url.wmf_databaseKey,
        let context = CacheController.backgroundCacheContext else {
            return false
        }
        
        return context.performWaitAndReturn {
            CacheDBWriterHelper.cacheGroup(with: groupKey, in: moc) != nil
        } ?? false
    }
    
    static func save(moc: NSManagedObjectContext, completion: (_ result: SaveResult) -> Void) {
        guard moc.hasChanges else {
            completion(.success)
            return
        }
        do {
            try moc.save()
            completion(.success)
        } catch let error {
            assertionFailure("Error saving cache moc: \(error)")
            completion(.failure(error))
        }
    }
}
