
import Foundation
import CoreData


extension CacheGroup {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CacheGroup> {
        return NSFetchRequest<CacheGroup>(entityName: "CacheGroup")
    }

    @NSManaged public var key: String?
    @NSManaged public var cacheItems: NSSet?
    @NSManaged public var mustHaveCacheItems: NSSet?

}

// MARK: Generated accessors for cacheItems
extension CacheGroup {

    @objc(addCacheItemsObject:)
    @NSManaged public func addToCacheItems(_ value: CacheItem)

    @objc(removeCacheItemsObject:)
    @NSManaged public func removeFromCacheItems(_ value: CacheItem)

    @objc(addCacheItems:)
    @NSManaged public func addToCacheItems(_ values: NSSet)

    @objc(removeCacheItems:)
    @NSManaged public func removeFromCacheItems(_ values: NSSet)

}

// MARK: Generated accessors for mustHaveCacheItems
extension CacheGroup {

    @objc(addMustHaveCacheItemsObject:)
    @NSManaged public func addToMustHaveCacheItems(_ value: CacheItem)

    @objc(removeMustHaveCacheItemsObject:)
    @NSManaged public func removeFromMustHaveCacheItems(_ value: CacheItem)

    @objc(addMustHaveCacheItems:)
    @NSManaged public func addToMustHaveCacheItems(_ values: NSSet)

    @objc(removeMustHaveCacheItems:)
    @NSManaged public func removeFromMustHaveCacheItems(_ values: NSSet)

}
