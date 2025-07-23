import UIKit

// Protocol that provides some default helper methods to add a transparent top safe area overlay and prevent the navigation bar from sticking in a hidden state when scrolled to the top.
public protocol WMFNavigationBarHiding: AnyObject {
    var topSafeAreaOverlayView: UIView? { get set }
    var topSafeAreaOverlayHeightConstraint: NSLayoutConstraint? { get set }
}

public extension WMFNavigationBarHiding where Self:UIViewController {
    
    /// Call from UIViewController's viewDidLoad
    func setupTopSafeAreaOverlay(scrollView: UIScrollView) {
        
        // Insert UIView covering below navigation bar, but above scroll view of content. This hides content beneath top transparent background as it scrolls

        let overlayView = UIView()
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(overlayView, aboveSubview: scrollView)

        let overlayHeightConstraint = overlayView.heightAnchor.constraint(equalToConstant: 0)
        topSafeAreaOverlayHeightConstraint = overlayHeightConstraint
        calculateTopSafeAreaOverlayHeight()
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: overlayView.topAnchor),
            view.leadingAnchor.constraint(equalTo: overlayView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: overlayView.trailingAnchor),
            overlayHeightConstraint
        ])
        
        topSafeAreaOverlayView = overlayView
        themeTopSafeAreaOverlay()
    }
    
    /// Call from UIViewController when theme changes
    ///     - from apply(theme:) if legacy
    ///     - from appEnvironmentDidChange() if WMFComponents
    func themeTopSafeAreaOverlay() {
        topSafeAreaOverlayView?.backgroundColor =   WMFAppEnvironment.current.theme.paperBackground
        topSafeAreaOverlayView?.alpha = 0.95
    }
    
    /// Call from UIViewController when the status bar height might change (like upon rotation)
    func calculateTopSafeAreaOverlayHeight() {
        let statusBarHeight = UIApplication.shared.statusBarFrame.height
        topSafeAreaOverlayHeightConstraint?.constant = statusBarHeight
    }
    
    /// Call from a UIViewController's scrollViewDidScroll method to unstick a hidden navigation bar when scrolled to the top.
    func calculateNavigationBarHiddenState(scrollView: UIScrollView) {
        let finalOffset = scrollView.contentOffset.y + scrollView.safeAreaInsets.top
        if finalOffset < 5 && (navigationController?.navigationBar.isHidden ?? true) {
            navigationController?.setNavigationBarHidden(false, animated: true)
        }
    }
}

private extension UIApplication {
    var keyWindow: UIWindow? {
        return UIApplication
            .shared
            .connectedScenes
            .flatMap { ($0 as? UIWindowScene)?.windows ?? [] }
            .last { $0.isKeyWindow }
    }
    
    var statusBarFrame: CGRect {
        keyWindow?.windowScene?.statusBarManager?.statusBarFrame ?? .zero
    }
}
