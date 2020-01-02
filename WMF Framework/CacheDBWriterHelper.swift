
import Foundation

final class CacheDBWriterHelper {
    static func fetchOrCreateCacheGroup(with groupKey: String, in moc: NSManagedObjectContext) -> PersistentCacheGroup? {
        return cacheGroup(with: groupKey, in: moc) ?? createCacheGroup(with: groupKey, in: moc)
    }

    static func fetchOrCreateCacheItem(with itemKey: String, in moc: NSManagedObjectContext) -> PersistentCacheItem? {
        return cacheItem(with: itemKey, in: moc) ?? createCacheItem(with: itemKey, in: moc)
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
}
