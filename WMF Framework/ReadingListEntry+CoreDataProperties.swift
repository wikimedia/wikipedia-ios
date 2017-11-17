import Foundation
import CoreData


extension ReadingListEntry {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ReadingListEntry> {
        return NSFetchRequest<ReadingListEntry>(entityName: "ReadingListEntry")
    }

    @NSManaged public var readingListEntryID: NSNumber?
    @NSManaged public var createdDate: NSDate?
    @NSManaged public var updatedDate: NSDate?
    @NSManaged public var articleKey: String?
    @NSManaged public var displayTitle: String?
    @NSManaged public var list: ReadingList?
    
}
