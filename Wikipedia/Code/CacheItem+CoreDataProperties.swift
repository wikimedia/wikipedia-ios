import Foundation
import CoreData


extension CacheItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CacheItem> {
        return NSFetchRequest<CacheItem>(entityName: "CacheItem");
    }

    @NSManaged public var date: NSDate?
    @NSManaged public var key: String?
    @NSManaged public var permanent: Bool
    @NSManaged public var variant: Int64

}
