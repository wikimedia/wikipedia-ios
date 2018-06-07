import Foundation
import CoreData


extension EventRecord {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<EventRecord> {
        return NSFetchRequest<EventRecord>(entityName: "WMFEventRecord")
    }

    @NSManaged public var event: NSObject?
    @NSManaged public var userAgent: String?
    @NSManaged public var recorded: NSDate?
    @NSManaged public var posted: NSDate?
    @NSManaged public var postAttempts: Int16
    @NSManaged public var failed: Bool

    
}
