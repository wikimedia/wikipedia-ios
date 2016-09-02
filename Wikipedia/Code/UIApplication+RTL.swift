import Foundation

extension UIApplication {
    var wmf_tocShouldBeOnLeft: Bool {
        get { return  !self.wmf_isRTL }
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
