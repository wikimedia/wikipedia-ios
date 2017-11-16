import Foundation
import CoreData


extension ReadingListEntry {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ReadingListEntry> {
        return NSFetchRequest<ReadingListEntry>(entityName: "ReadingListEntry")
    }

    @NSManaged public var order: Int64
    @NSManaged public var readingListEntryID: Int64
    @NSManaged public var project: String?
    @NSManaged public var title: String?
    @NSManaged public var createdDate: NSDate?
    @NSManaged public var updatedDate: NSDate?
    @NSManaged public var articleKey: String?
    @NSManaged public var list: ReadingList?
    @NSManaged public var actions: ReadingListAction?

}
