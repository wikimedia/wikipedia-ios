import Foundation
import CoreData


extension ArticleListEntry {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ArticleListEntry> {
        return NSFetchRequest<ArticleListEntry>(entityName: "ArticleListEntry")
    }

    @NSManaged public var order: Int64
    @NSManaged public var id: Int64
    @NSManaged public var project: String?
    @NSManaged public var title: String?
    @NSManaged public var createdDate: NSDate?
    @NSManaged public var updatedDate: NSDate?
    @NSManaged public var articleKey: String?
    @NSManaged public var list: ArticleList?
    @NSManaged public var actions: ArticleListAction?

}
