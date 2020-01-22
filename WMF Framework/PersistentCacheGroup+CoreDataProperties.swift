
import Foundation
import CoreData


extension PersistentCacheGroup {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PersistentCacheGroup> {
        return NSFetchRequest<PersistentCacheGroup>(entityName: "PersistentCacheGroup")
    }

    @NSManaged public var key: String?
    @NSManaged public var cacheItems: NSSet?
    @NSManaged public var mustHaveCacheItems: NSSet?

}

// MARK: Generated accessors for cacheItems
extension PersistentCacheGroup {

    @objc(addCacheItemsObject:)
    @NSManaged public func addToCacheItems(_ value: PersistentCacheItem)

    @objc(removeCacheItemsObject:)
    @NSManaged public func removeFromCacheItems(_ value: PersistentCacheItem)

    @objc(addCacheItems:)
    @NSManaged public func addToCacheItems(_ values: NSSet)

    @objc(removeCacheItems:)
    @NSManaged public func removeFromCacheItems(_ values: NSSet)

}

// MARK: Generated accessors for mustHaveCacheItems
extension PersistentCacheGroup {

    @objc(addMustHaveCacheItemsObject:)
    @NSManaged public func addToMustHaveCacheItems(_ value: PersistentCacheItem)

    @objc(removeMustHaveCacheItemsObject:)
    @NSManaged public func removeFromMustHaveCacheItems(_ value: PersistentCacheItem)

    @objc(addMustHaveCacheItems:)
    @NSManaged public func addToMustHaveCacheItems(_ values: NSSet)

    @objc(removeMustHaveCacheItems:)
    @NSManaged public func removeFromMustHaveCacheItems(_ values: NSSet)

}
