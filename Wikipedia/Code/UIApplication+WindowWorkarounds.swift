
import Foundation

extension UIApplication {
    @objc var workaroundKeyWindow: UIWindow? {
        return windows.first { $0.isKeyWindow }
    }
    
    @objc var workaroundStatusBarFrame: CGRect {
        workaroundKeyWindow?.windowScene?.statusBarManager?.statusBarFrame ?? .zero
    }
}
