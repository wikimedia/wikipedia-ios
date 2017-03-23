import Foundation
import CoreData


extension CacheItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CacheItem> {
        return NSFetchRequest<CacheItem>(entityName: "CacheItem");
    }

    @NSManaged public var key: String?
    @NSManaged public var variant: Int32
    @NSManaged public var date: NSDate?

}
