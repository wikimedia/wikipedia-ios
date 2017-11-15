import Foundation
import CoreData

public enum ArticleListActionType: Int16 {
    case unknown = 0
    case createList = 1
    case updateList = 2
    case deleteList = 3
    case createEntry = 4
    case updateEntry = 5
    case deleteEntry = 6
}

extension ArticleListAction {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ArticleListAction> {
        return NSFetchRequest<ArticleListAction>(entityName: "ArticleListAction")
    }
    
    @NSManaged public var actionTypeInteger: Int16
    @NSManaged public var date: NSDate?
    @NSManaged public var articleListEntryIDs: [String]?
    @NSManaged public var articleListIDs: [String]?
    @NSManaged public var bodyParameters: [String: Any]?
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

extension ArticleListAction {
    var actionType: ArticleListActionType {
        get {
            return ArticleListActionType(rawValue: actionTypeInteger) ?? .unknown
        }
        set {
            actionTypeInteger = newValue.rawValue
        }
    }
}
