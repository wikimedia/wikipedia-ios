
import Foundation
import CoreData


extension PersistentCacheItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PersistentCacheItem> {
        return NSFetchRequest<PersistentCacheItem>(entityName: "PersistentCacheItem")
    }

    @NSManaged public var date: Date?
    @NSManaged public var etag: String?
    @NSManaged public var isDownloaded: Bool
    @NSManaged public var key: String?
    @NSManaged public var variantId: String?
    @NSManaged public var cacheGroups: NSSet?
    @NSManaged public var mustHaveCacheGroups: PersistentCacheGroup?
    @NSManaged public var variantGroup: PersistentCacheVariantGroup?

}

// MARK: Generated accessors for cacheGroups
extension PersistentCacheItem {

    @objc(addCacheGroupsObject:)
    @NSManaged public func addToCacheGroups(_ value: PersistentCacheGroup)

    @objc(removeCacheGroupsObject:)
    @NSManaged public func removeFromCacheGroups(_ value: PersistentCacheGroup)

    @objc(addCacheGroups:)
    @NSManaged public func addToCacheGroups(_ values: NSSet)

    @objc(removeCacheGroups:)
    @NSManaged public func removeFromCacheGroups(_ values: NSSet)

}
