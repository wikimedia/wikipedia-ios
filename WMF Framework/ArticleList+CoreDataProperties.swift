import Foundation
import CoreData

extension ArticleList {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ArticleList> {
        return NSFetchRequest<ArticleList>(entityName: "ArticleList")
    }
    
    @NSManaged public var createdDate: NSDate?
    @NSManaged public var articleListID: Int64
    @NSManaged public var articleListDescription: String?
    @NSManaged public var name: String?
    @NSManaged public var order: Int64
    @NSManaged public var updatedDate: NSDate?
    @NSManaged public var color: String?
    @NSManaged public var imageName: String?
    @NSManaged public var iconName: String?
    @NSManaged public var entries: NSOrderedSet?
    @NSManaged public var actions: NSSet?
}

// MARK: Generated accessors for entries
extension ArticleList {

    @objc(insertObject:inEntriesAtIndex:)
    @NSManaged public func insertIntoEntries(_ value: ArticleListEntry, at idx: Int)

    @objc(removeObjectFromEntriesAtIndex:)
    @NSManaged public func removeFromEntries(at idx: Int)

    @objc(insertEntries:atIndexes:)
    @NSManaged public func insertIntoEntries(_ values: [ArticleListEntry], at indexes: NSIndexSet)

    @objc(removeEntriesAtIndexes:)
    @NSManaged public func removeFromEntries(at indexes: NSIndexSet)

    @objc(replaceObjectInEntriesAtIndex:withObject:)
    @NSManaged public func replaceEntries(at idx: Int, with value: ArticleListEntry)

    @objc(replaceEntriesAtIndexes:withEntries:)
    @NSManaged public func replaceEntries(at indexes: NSIndexSet, with values: [ArticleListEntry])

    @objc(addEntriesObject:)
    @NSManaged public func addToEntries(_ value: ArticleListEntry)

    @objc(removeEntriesObject:)
    @NSManaged public func removeFromEntries(_ value: ArticleListEntry)

    @objc(addEntries:)
    @NSManaged public func addToEntries(_ values: NSOrderedSet)

    @objc(removeEntries:)
    @NSManaged public func removeFromEntries(_ values: NSOrderedSet)

}

// MARK: Generated accessors for actions
extension ArticleList {

    @objc(addActionsObject:)
    @NSManaged public func addToActions(_ value: ArticleListAction)

    @objc(removeActionsObject:)
    @NSManaged public func removeFromActions(_ value: ArticleListAction)

    @objc(addActions:)
    @NSManaged public func addToActions(_ values: NSSet)

    @objc(removeActions:)
    @NSManaged public func removeFromActions(_ values: NSSet)

}
