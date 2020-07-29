import Foundation

/// SecureUnarchiveFromDataTransformer allows us to utilize transformable properties with a list of allowed classes
@objc(WMFSecureUnarchiveFromDataTransformer)
class SecureUnarchiveFromDataTransformer: NSSecureUnarchiveFromDataTransformer {
    override class var allowedTopLevelClasses: [AnyClass] {
        return  super.allowedTopLevelClasses + [WMFMTLModel.self, NSSet.self, CLLocation.self, CLPlacemark.self]
    }
}
