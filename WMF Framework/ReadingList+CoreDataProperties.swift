import Foundation
import CoreData

extension ReadingList {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ReadingList> {
        return NSFetchRequest<ReadingList>(entityName: "ReadingList")
    }
    
    @NSManaged public var createdDate: NSDate?
    @NSManaged public var isDeletedLocally: Bool
    @NSManaged public var isUpdatedLocally: Bool
    @NSManaged public var readingListID: NSNumber?
    @NSManaged public var readingListDescription: String?
    @NSManaged public var canonicalName: String?
    @NSManaged public var order: Int64
    @NSManaged public var countOfEntries: Int64
    @NSManaged public var updatedDate: NSDate?
    @NSManaged public var color: String?
    @NSManaged public var imageName: String?
    @NSManaged public var iconName: String?
    @NSManaged public var entries: Set<ReadingListEntry>?
    @NSManaged public var isDefault: NSNumber?
    
    
    public var name: String? {
        set {
            canonicalName = newValue?.precomposedStringWithCanonicalMapping
        }
        get {
            return canonicalName
        }
    }
}

// MARK: Generated accessors for entries
extension ReadingList {

    @objc(addEntriesObject:)
    @NSManaged public func addToEntries(_ value: ReadingListEntry)

    @objc(removeEntriesObject:)
    @NSManaged public func removeFromEntries(_ value: ReadingListEntry)

    @objc(addEntries:)
    @NSManaged public func addToEntries(_ values: NSOrderedSet)

    @objc(removeEntries:)
    @NSManaged public func removeFromEntries(_ values: NSOrderedSet)

}
