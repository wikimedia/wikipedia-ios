import Foundation

extension UIApplication {
    @objc var wmf_isRTL: Bool {
        get { return self.userInterfaceLayoutDirection == .rightToLeft }
    }
}
