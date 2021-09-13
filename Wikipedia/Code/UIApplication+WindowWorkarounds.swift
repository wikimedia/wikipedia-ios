
import Foundation

extension UIApplication {
    private var workaroundKeyWindow: UIWindow? {
        return windows.first { $0.isKeyWindow }
    }
    
    var workaroundStatusBarFrame: CGRect {
        workaroundKeyWindow?.windowScene?.statusBarManager?.statusBarFrame ?? .zero
    }
}
