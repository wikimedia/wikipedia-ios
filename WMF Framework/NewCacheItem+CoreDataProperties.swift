//
//  NewCacheItem+CoreDataProperties.swift
//  WMF
//
//  Created by Toni Sevener on 12/16/19.
//  Copyright © 2019 Wikimedia Foundation. All rights reserved.
//
//

import Foundation
import CoreData


extension NewCacheItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<NewCacheItem> {
        return NSFetchRequest<NewCacheItem>(entityName: "NewCacheItem")
    }

    @NSManaged public var date: Date?
    @NSManaged public var key: String?
    @NSManaged public var isDownloaded: Bool
    @NSManaged public var cacheGroups: NSSet?

}

// MARK: Generated accessors for cacheGroups
extension NewCacheItem {

    @objc(addCacheGroupsObject:)
    @NSManaged public func addToCacheGroups(_ value: NewCacheGroup)

    @objc(removeCacheGroupsObject:)
    @NSManaged public func removeFromCacheGroups(_ value: NewCacheGroup)

    @objc(addCacheGroups:)
    @NSManaged public func addToCacheGroups(_ values: NSSet)

    @objc(removeCacheGroups:)
    @NSManaged public func removeFromCacheGroups(_ values: NSSet)

}
