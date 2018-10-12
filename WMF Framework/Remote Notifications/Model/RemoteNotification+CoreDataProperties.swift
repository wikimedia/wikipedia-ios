import Foundation
import CoreData

extension RemoteNotification {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<RemoteNotification> {
        return NSFetchRequest<RemoteNotification>(entityName: "RemoteNotification")
    }

    @NSManaged public var agent: String?
    @NSManaged public var affectedPageID: String?
    @NSManaged public var categoryString: String?
    @NSManaged public var date: NSDate?
    @NSManaged public var id: String?
    @NSManaged public var message: String?
    @NSManaged public var typeString: String?
    @NSManaged public var wiki: String?
    @NSManaged public var stateNumber: NSNumber?

}
