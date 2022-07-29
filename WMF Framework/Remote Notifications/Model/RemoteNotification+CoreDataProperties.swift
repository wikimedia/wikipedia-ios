import Foundation
import CoreData


extension RemoteNotification {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<RemoteNotification> {
        return NSFetchRequest<RemoteNotification>(entityName: "RemoteNotification")
    }

    @NSManaged public var agentId: String?
    @NSManaged public var agentName: String?
    @NSManaged public var categoryString: String?
    @NSManaged public var date: Date?
    @NSManaged public var id: String?
    @NSManaged public var isRead: Bool
    @NSManaged public var key: String?
    @NSManaged public var messageBody: String?
    @NSManaged public var messageHeader: String?
    @NSManaged public var messageLinks: RemoteNotificationLinks?
    @NSManaged public var section: String?
    @NSManaged public var titleFull: String?
    @NSManaged public var titleNamespace: String?
    @NSManaged public var titleNamespaceKey: Int16
    @NSManaged public var titleText: String?
    @NSManaged public var typeString: String?
    @NSManaged public var utcUnixString: String?
    @NSManaged public var wiki: String?
    @NSManaged public var revisionID: String?

}

extension RemoteNotification : Identifiable {

}
