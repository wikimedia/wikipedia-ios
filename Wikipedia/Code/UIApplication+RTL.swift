import Foundation

extension UIApplication {
    @objc var wmf_tocShouldBeOnLeft: Bool {
        get { return  !self.wmf_isRTL }
    }
    
    @objc var wmf_isRTL: Bool {
        get { return self.userInterfaceLayoutDirection == .rightToLeft }
    }
}
