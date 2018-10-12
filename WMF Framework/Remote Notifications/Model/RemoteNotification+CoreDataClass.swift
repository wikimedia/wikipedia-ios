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

public struct RemoteNotificationState: OptionSet {
    public let rawValue: Int16

    public static let wasSeen = RemoteNotificationState(rawValue: 1 << 0)
    public static let wasRead = RemoteNotificationState(rawValue: 1 << 1)
    public static let isExcluded = RemoteNotificationState(rawValue: 1 << 2)

    public init(rawValue: RawValue) {
        self.rawValue = rawValue
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

    public var state: RemoteNotificationState? {
        get {
            guard let value = stateNumber?.int16Value else {
                return nil
            }
            return RemoteNotificationState(rawValue: value)
        }
        set {
            guard let value = newValue?.rawValue else {
                return
            }
            stateNumber = NSNumber(value: value)
        }
    }

}
