import Foundation
import CoreData

public enum ReadingListActionType: Int16 {
    case unknown = 0
    case createList = 1
    case updateList = 2
    case deleteList = 3
    case createEntry = 4
    case updateEntry = 5
    case deleteEntry = 6
}

extension ReadingListAction {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ReadingListAction> {
        return NSFetchRequest<ReadingListAction>(entityName: "ReadingListAction")
    }
    
    @NSManaged public var actionTypeInteger: Int16
    @NSManaged public var date: NSDate?
    @NSManaged public var readingListEntryIDs: [String]?
    @NSManaged public var readingListIDs: [String]?
    @NSManaged public var bodyParameters: [String: Any]?
}

extension ReadingListAction {
    var actionType: ReadingListActionType {
        get {
            return ReadingListActionType(rawValue: actionTypeInteger) ?? .unknown
        }
        set {
            actionTypeInteger = newValue.rawValue
        }
    }
}
