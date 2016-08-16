
import Foundation

extension UIApplication {
    var wmf_tocShouldBeOnLeft: Bool {
        get { return  !self.wmf_isRTL || NSProcessInfo.processInfo().wmf_isOperatingSystemVersionLessThan9_0_0() }
    }
    
    var wmf_tocRTLMultiplier: CGFloat {
        get {
            return self.wmf_tocShouldBeOnLeft ? -1.0 : 1.0
        }
    }
    
    var wmf_isRTL: Bool {
        get { return self.userInterfaceLayoutDirection == .RightToLeft }
    }
}
