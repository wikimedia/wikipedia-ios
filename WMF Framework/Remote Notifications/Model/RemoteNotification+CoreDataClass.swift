import Foundation
import CoreData

@objc(RemoteNotification)
public class RemoteNotification: NSManagedObject {

    @objc public enum Category: Int {
        case editReverted
        case unknown

        init(stringValue: String) {
            switch stringValue {
            case "reverted":
                self = .editReverted
            default:
                self = .unknown
            }
        }
    }

    public var category: Category {
        guard let categoryString = categoryString else {
            return .unknown
        }
        return Category(stringValue: categoryString)
    }

}
