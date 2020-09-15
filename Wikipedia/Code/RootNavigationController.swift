import UIKit

/// Root view controller for the entire app. Handles splash screen presentation.
@objc(WMFRootNavigationController)
class RootNavigationController: WMFThemeableNavigationController {
    
    @objc var splashScreenViewController: SplashScreenViewController?
    
    @objc func showSplashView() {
        guard splashScreenViewController == nil else {
            return
        }
        let splashVC = SplashScreenViewController()
        // Explicit appearance transitions need to be used here because UINavigationController overrides
        // a lot of behaviors when adding the VC as a child and causes layout issues for our use case.
        splashVC.beginAppearanceTransition(true, animated: false)
        splashVC.apply(theme: theme)
        view.wmf_addSubviewWithConstraintsToEdges(splashVC.view)
        splashVC.endAppearanceTransition()
        splashScreenViewController = splashVC
    }
    
    @objc(hideSplashViewAnimated:)
    func hideSplashView(animated: Bool) {
        guard let splashVC = splashScreenViewController else {
            return
        }
        splashVC.ensureMinimumShowDuration {
            // Explicit appearance transitions need to be used here because UINavigationController overrides
            // a lot of behaviors when adding the VC as a child and causes layout issues for our use case.
            splashVC.beginAppearanceTransition(false, animated: true)
            let duration: TimeInterval = animated ? 0.15 : 0.0
            UIView.animate(withDuration: duration, delay: 0, options: .allowUserInteraction, animations: {
                splashVC.view.alpha = 0.0
            }) { finished in
                splashVC.view.removeFromSuperview()
                splashVC.endAppearanceTransition()
            }
        }
        splashScreenViewController = nil
    }
    
    @objc func triggerMigratingAnimation() {
        splashScreenViewController?.triggerMigratingAnimation()
    }

    func pruneSearchControllers() {
        let count = viewControllers.count
        guard count - 2 > 1 else {
            return
        }

        /// `1..<count-2`: If first controller is Search (from tab bar item Search), it must be kept. Also, if VC prior to top one is Search, it is kept.
        viewControllers[1..<count-2].forEach({ ($0 as? SearchViewController)?.removeFromParent() })
    }
}
