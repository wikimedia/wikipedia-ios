
import Foundation

final class CacheDBWriterHelper {
    static func fetchOrCreateCacheGroup(with groupKey: String, in moc: NSManagedObjectContext) -> PersistentCacheGroup? {
        return cacheGroup(with: groupKey, in: moc) ?? createCacheGroup(with: groupKey, in: moc)
    }

    static func fetchOrCreateCacheItem(with url: URL, itemKey: String, variant: String?, in moc: NSManagedObjectContext) -> PersistentCacheItem? {
        return cacheItem(with: itemKey, variant: variant, in: moc) ?? createCacheItem(with: url, itemKey: itemKey, variant: variant, in: moc)
    }

    static func cacheGroup(with key: String, in moc: NSManagedObjectContext) -> PersistentCacheGroup? {

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
    
    static func cacheItem(with itemKey: String, variant: String?, in moc: NSManagedObjectContext) -> PersistentCacheItem? {
        
        let predicate: NSPredicate
        if let variant = variant {
            predicate = NSPredicate(format: "key == %@ && variant == %@", itemKey, variant)
        } else {
            predicate = NSPredicate(format: "key == %@", itemKey)
        }
        
        let fetchRequest: NSFetchRequest<PersistentCacheItem> = PersistentCacheItem.fetchRequest()
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

    static func createCacheItem(with url: URL, itemKey: String, variant: String?, in moc: NSManagedObjectContext) -> PersistentCacheItem? {
        guard let entity = NSEntityDescription.entity(forEntityName: "PersistentCacheItem", in: moc) else {
            return nil
        }
        let item = PersistentCacheItem(entity: entity, insertInto: moc)
        item.key = itemKey
        item.variant = variant
        item.url = url
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
    
    static func allDownloadedVariantItems(itemKey: CacheController.ItemKey, in moc: NSManagedObjectContext) -> [PersistentCacheItem] {

        let fetchRequest: NSFetchRequest<PersistentCacheItem> = PersistentCacheItem.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "key == %@ && isDownloaded == YES", itemKey)
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
