import Foundation
import CoreData

@objc(RemoteNotification)
public class RemoteNotification: NSManagedObject {

    enum Category: String {
        case editReverted = "reverted"
        case unknown
    }

}
