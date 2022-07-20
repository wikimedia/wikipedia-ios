import Foundation

extension UIApplication {
    @objc var wmf_isRTL: Bool {
        return self.userInterfaceLayoutDirection == .rightToLeft
    }
}
