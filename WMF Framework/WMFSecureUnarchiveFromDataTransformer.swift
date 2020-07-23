import UIKit

@objc(WMFSecureUnarchiveFromDataTransformer)
class SecureUnarchiveFromDataTransformer: NSSecureUnarchiveFromDataTransformer {
    override class var allowedTopLevelClasses: [AnyClass] {
        return  super.allowedTopLevelClasses + [WMFMTLModel.self]
    }
}
