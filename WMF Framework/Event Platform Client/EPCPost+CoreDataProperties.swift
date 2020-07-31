
import Foundation
import CoreData


extension EPCPost {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<EPCPost> {
        return NSFetchRequest<EPCPost>(entityName: "EPCPost")
    }

    @NSManaged public var body: NSObject?
    @NSManaged public var recorded: Date?
    @NSManaged public var posted: Date?
    @NSManaged public var failed: Bool
    @NSManaged public var url: URL?
    @NSManaged public var userAgent: String?

}
