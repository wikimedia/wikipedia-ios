import Foundation
import CoreData

@objc public enum RemoteNotificationCategory: Int {
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

@objc(RemoteNotification)
public class RemoteNotification: NSManagedObject {

    public var category: RemoteNotificationCategory {
        guard let categoryString = categoryString else {
            return .unknown
        }
        return RemoteNotificationCategory(stringValue: categoryString)
    }

    public enum State: Int16 {
        case seen
        case read
        case excluded

        public var number: NSNumber{
            return NSNumber(value: rawValue)
        }
    }

    public var state: State? {
        get {
            guard let value = stateNumber?.int16Value else {
                return nil
            }
            return State(rawValue: value)
        }
        set {
            guard let value = newValue?.rawValue else {
                return
            }
            stateNumber = NSNumber(value: value)
        }
    }

}
