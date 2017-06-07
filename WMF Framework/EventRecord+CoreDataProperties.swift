import Foundation
import CoreData


extension EventRecord {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<EventRecord> {
        return NSFetchRequest<EventRecord>(entityName: "EventRecord")
    }

    @NSManaged public var eventCapsule: NSObject?
    @NSManaged public var recorded: NSDate?
    @NSManaged public var posted: NSDate?

}
