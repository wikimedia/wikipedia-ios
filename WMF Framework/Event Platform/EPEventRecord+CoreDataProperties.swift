import Foundation
import CoreData

extension EPEventRecord {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<EPEventRecord> {
        return NSFetchRequest<EPEventRecord>(entityName: "WMFEPEventRecord")
    }

    @NSManaged public var data: Data
    @NSManaged public var stream: String
    @NSManaged public var recorded: Date?
    @NSManaged public var purgeable: Bool

}
