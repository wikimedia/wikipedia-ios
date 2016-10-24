import Foundation

extension UIApplication {
    var wmf_tocShouldBeOnLeft: Bool {
        get { return  !self.wmf_isRTL }
    }
    
    var wmf_isRTL: Bool {
        get { return self.userInterfaceLayoutDirection == .RightToLeft }
    }
}
