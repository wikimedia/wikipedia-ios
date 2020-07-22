import UIKit

class WMFSecureUnarchiveFromDataTransformer: NSSecureUnarchiveFromDataTransformer {
    override class var allowedTopLevelClasses: [AnyClass] {
        return super.allowedTopLevelClasses + [MTLModel.self]
    }
}
