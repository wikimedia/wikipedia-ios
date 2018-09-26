import Foundation
import CoreData

@objc(RemoteNotification)
public class RemoteNotification: NSManagedObject {

    enum Category: String {
        case editReverted = "reverted"
        case unknown
    }

    private var category: Category {
        guard let categoryString = categoryString else {
            return .unknown
        }
        return Category(rawValue: categoryString) ?? .unknown
    }

}
