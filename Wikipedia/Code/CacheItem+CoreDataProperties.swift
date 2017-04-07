import Foundation
import CoreData


extension CacheItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CacheItem> {
        return NSFetchRequest<CacheItem>(entityName: "CacheItem")
    }

    @NSManaged public var date: NSDate?
    @NSManaged public var key: String?
    @NSManaged public var variant: Int64
    @NSManaged public var cacheGroups: NSSet?

}

// MARK: Generated accessors for cacheGroups
extension CacheItem {

    @objc(addCacheGroupsObject:)
    @NSManaged public func addToCacheGroups(_ value: CacheGroup)

    @objc(removeCacheGroupsObject:)
    @NSManaged public func removeFromCacheGroups(_ value: CacheGroup)

    @objc(addCacheGroups:)
    @NSManaged public func addToCacheGroups(_ values: NSSet)

    @objc(removeCacheGroups:)
    @NSManaged public func removeFromCacheGroups(_ values: NSSet)

}
