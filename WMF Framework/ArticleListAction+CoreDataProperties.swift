import Foundation
import CoreData


extension ArticleListAction {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ArticleListAction> {
        return NSFetchRequest<ArticleListAction>(entityName: "ArticleListAction")
    }

    @NSManaged public var date: NSDate?
    @NSManaged public var action: Int16
    @NSManaged public var lists: NSSet?
    @NSManaged public var entries: NSSet?

}

// MARK: Generated accessors for lists
extension ArticleListAction {

    @objc(addListsObject:)
    @NSManaged public func addToLists(_ value: ArticleList)

    @objc(removeListsObject:)
    @NSManaged public func removeFromLists(_ value: ArticleList)

    @objc(addLists:)
    @NSManaged public func addToLists(_ values: NSSet)

    @objc(removeLists:)
    @NSManaged public func removeFromLists(_ values: NSSet)

}

// MARK: Generated accessors for entries
extension ArticleListAction {

    @objc(addEntriesObject:)
    @NSManaged public func addToEntries(_ value: ArticleListEntry)

    @objc(removeEntriesObject:)
    @NSManaged public func removeFromEntries(_ value: ArticleListEntry)

    @objc(addEntries:)
    @NSManaged public func addToEntries(_ values: NSSet)

    @objc(removeEntries:)
    @NSManaged public func removeFromEntries(_ values: NSSet)

}
