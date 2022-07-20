import Foundation

final class CacheDBWriterHelper {
    static func fetchOrCreateCacheGroup(with groupKey: String, in moc: NSManagedObjectContext) -> CacheGroup? {
        return cacheGroup(with: groupKey, in: moc) ?? createCacheGroup(with: groupKey, in: moc)
    }

    static func fetchOrCreateCacheItem(with url: URL, itemKey: String, variant: String?, in moc: NSManagedObjectContext) -> CacheItem? {
        return cacheItem(with: itemKey, variant: variant, in: moc) ?? createCacheItem(with: url, itemKey: itemKey, variant: variant, in: moc)
    }

    static func cacheGroup(with key: String, in moc: NSManagedObjectContext) ->
        CacheGroup? {

        let fetchRequest: NSFetchRequest<CacheGroup> = CacheGroup.fetchRequest()
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
    
    static func createCacheGroup(with groupKey: String, in moc: NSManagedObjectContext) -> CacheGroup? {
        
        guard let entity = NSEntityDescription.entity(forEntityName: "CacheGroup", in: moc) else {
            return nil
        }
        let group = CacheGroup(entity: entity, insertInto: moc)
        group.key = groupKey
        return group
    }
    
    static func cacheItem(with itemKey: String, variant: String?, in moc: NSManagedObjectContext) -> CacheItem? {
        
        let predicate: NSPredicate
        if let variant = variant {
            predicate = NSPredicate(format: "key == %@ && variant == %@", itemKey, variant)
        } else {
            predicate = NSPredicate(format: "key == %@", itemKey)
        }
        
        let fetchRequest: NSFetchRequest<CacheItem> = CacheItem.fetchRequest()
        fetchRequest.predicate = predicate
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

    static func createCacheItem(with url: URL, itemKey: String, variant: String?, in moc: NSManagedObjectContext) -> CacheItem? {
        guard let entity = NSEntityDescription.entity(forEntityName: "CacheItem", in: moc) else {
            return nil
        }
        let item = CacheItem(entity: entity, insertInto: moc)
        item.key = itemKey
        item.variant = variant
        item.url = url
        item.date = Date()
        return item
    }
    
    static func isCached(itemKey: CacheController.ItemKey, variant: String?, in moc: NSManagedObjectContext, completion: @escaping (Bool) -> Void) {
        return moc.perform {
            let isCached = CacheDBWriterHelper.cacheItem(with: itemKey, variant: variant, in: moc) != nil
            completion(isCached)
        }
    }
    
    static func allDownloadedVariantItems(itemKey: CacheController.ItemKey, in moc: NSManagedObjectContext) -> [CacheItem] {

        let fetchRequest: NSFetchRequest<CacheItem> = CacheItem.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "key == %@ && isDownloaded == YES", itemKey)
        do {
            return try moc.fetch(fetchRequest)
        } catch {
            return []
        }
    }
    
    static func allVariantItems(itemKey: CacheController.ItemKey, in moc: NSManagedObjectContext) -> [CacheItem] {

        let fetchRequest: NSFetchRequest<CacheItem> = CacheItem.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "key == %@", itemKey)
        do {
            return try moc.fetch(fetchRequest)
        } catch {
            return []
        }
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
