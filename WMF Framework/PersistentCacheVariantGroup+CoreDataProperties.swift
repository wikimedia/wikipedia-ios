
import Foundation
import CoreData


extension PersistentCacheVariantGroup {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PersistentCacheVariantGroup> {
        return NSFetchRequest<PersistentCacheVariantGroup>(entityName: "PersistentCacheVariantGroup")
    }

    @NSManaged public var key: String?
    @NSManaged public var cacheItems: NSSet?

}

// MARK: Generated accessors for cacheItems
extension PersistentCacheVariantGroup {

    @objc(addCacheItemsObject:)
    @NSManaged public func addToCacheItems(_ value: PersistentCacheItem)

    @objc(removeCacheItemsObject:)
    @NSManaged public func removeFromCacheItems(_ value: PersistentCacheItem)

    @objc(addCacheItems:)
    @NSManaged public func addToCacheItems(_ values: NSSet)

    @objc(removeCacheItems:)
    @NSManaged public func removeFromCacheItems(_ values: NSSet)

}
