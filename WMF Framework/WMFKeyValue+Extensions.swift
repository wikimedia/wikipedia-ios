import Foundation

extension WMFKeyValue {
    var stringValue: String? {
        get {
            return value as? NSString as String?
        }
        set {
            value = newValue as NSString?
        }
    }
}
