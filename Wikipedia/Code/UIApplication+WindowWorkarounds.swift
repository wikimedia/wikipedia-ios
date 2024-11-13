import Foundation

extension UIApplication {
    @objc var workaroundKeyWindow: UIWindow? {
        return UIApplication
            .shared
            .connectedScenes
            .flatMap { ($0 as? UIWindowScene)?.windows ?? [] }
            .last { $0.isKeyWindow }
    }
    
    var workaroundStatusBarFrame: CGRect {
        workaroundKeyWindow?.windowScene?.statusBarManager?.statusBarFrame ?? .zero
    }
}
