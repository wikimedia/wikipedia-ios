import Foundation
import CoreData

extension ReadingList {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ReadingList> {
        return NSFetchRequest<ReadingList>(entityName: "ReadingList")
    }
    
    @NSManaged public var createdDate: NSDate?
    @NSManaged public var readingListID: Int64
    @NSManaged public var readingListDescription: String?
    @NSManaged public var name: String?
    @NSManaged public var order: Int64
    @NSManaged public var updatedDate: NSDate?
    @NSManaged public var color: String?
    @NSManaged public var imageName: String?
    @NSManaged public var iconName: String?
    @NSManaged public var entries: NSOrderedSet?
}

// MARK: Generated accessors for entries
extension ReadingList {

    @objc(insertObject:inEntriesAtIndex:)
    @NSManaged public func insertIntoEntries(_ value: ReadingListEntry, at idx: Int)

    @objc(removeObjectFromEntriesAtIndex:)
    @NSManaged public func removeFromEntries(at idx: Int)

    @objc(insertEntries:atIndexes:)
    @NSManaged public func insertIntoEntries(_ values: [ReadingListEntry], at indexes: NSIndexSet)

    @objc(removeEntriesAtIndexes:)
    @NSManaged public func removeFromEntries(at indexes: NSIndexSet)

    @objc(replaceObjectInEntriesAtIndex:withObject:)
    @NSManaged public func replaceEntries(at idx: Int, with value: ReadingListEntry)

    @objc(replaceEntriesAtIndexes:withEntries:)
    @NSManaged public func replaceEntries(at indexes: NSIndexSet, with values: [ReadingListEntry])

    @objc(addEntriesObject:)
    @NSManaged public func addToEntries(_ value: ReadingListEntry)

    @objc(removeEntriesObject:)
    @NSManaged public func removeFromEntries(_ value: ReadingListEntry)

    @objc(addEntries:)
    @NSManaged public func addToEntries(_ values: NSOrderedSet)

    @objc(removeEntries:)
    @NSManaged public func removeFromEntries(_ values: NSOrderedSet)

}
