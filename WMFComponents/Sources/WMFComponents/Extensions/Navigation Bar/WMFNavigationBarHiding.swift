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
        if #available(iOS 26.0, *) {
            topSafeAreaOverlayView?.backgroundColor = .clear
            topSafeAreaOverlayView?.alpha = 1.0
            return
        }

        topSafeAreaOverlayView?.backgroundColor = WMFAppEnvironment.current.theme.paperBackground
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
    
    /// Call from a UIViewController's scrollViewDidScroll method to swap the logo image on scroll
    /// - Parameter scrollView: The scroll view to track scroll position
    func updateLogoImageOnScroll(scrollView: UIScrollView) {
        let finalOffset = scrollView.contentOffset.y + scrollView.safeAreaInsets.top
        let isCompactMode = finalOffset > 75
        
        // Get stored state using associated object
        let key = UnsafeRawPointer(bitPattern: "logoCompactModeKey".hashValue)!
        let currentState = objc_getAssociatedObject(self, key) as? NSNumber
        let wasCompactMode = currentState?.boolValue ?? false
        
        // Only update if state changed
        if isCompactMode != wasCompactMode {
            objc_setAssociatedObject(self, key, NSNumber(value: isCompactMode), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            
            if isCompactMode {
                swapLogoToCompact()
            } else {
                swapLogoToFull()
            }
        }
    }
    
    /// Swap logo to the compact W icon
    private func swapLogoToCompact() {
        navigationItem.leftBarButtonItem?.image = UIImage(named: "W")
    }

    /// Swap logo back to the full Wikipedia logo
    private func swapLogoToFull() {
        navigationItem.leftBarButtonItem?.image = UIImage(named: "wikipedia")
    }
}
