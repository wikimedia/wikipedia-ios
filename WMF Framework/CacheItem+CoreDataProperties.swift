
import Foundation
import CoreData


extension CacheItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CacheItem> {
        return NSFetchRequest<CacheItem>(entityName: "CacheItem")
    }

    @NSManaged public var date: Date?
    @NSManaged public var isDownloaded: Bool
    @NSManaged public var key: String?
    @NSManaged public var url: URL?
    @NSManaged public var variant: String?
    @NSManaged public var cacheGroups: NSSet?
    @NSManaged public var mustHaveCacheGroups: NSSet?

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

// MARK: Generated accessors for mustHaveCacheGroups
extension CacheItem {

    @objc(addMustHaveCacheGroupsObject:)
    @NSManaged public func addToMustHaveCacheGroups(_ value: CacheGroup)

    @objc(removeMustHaveCacheGroupsObject:)
    @NSManaged public func removeFromMustHaveCacheGroups(_ value: CacheGroup)

    @objc(addMustHaveCacheGroups:)
    @NSManaged public func addToMustHaveCacheGroups(_ values: NSSet)

    @objc(removeMustHaveCacheGroups:)
    @NSManaged public func removeFromMustHaveCacheGroups(_ values: NSSet)

}
