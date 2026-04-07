import UIKit

@objc(WMFViewControllerTransitionsController)
class ViewControllerTransitionsController: NSObject, UINavigationControllerDelegate {
    @objc func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        // Don't use custom animations for interactive pops
        if operation == .pop &&
           navigationController.transitionCoordinator?.isInteractive == true {
            return nil
        }

        // If either participating view controller prefers standard animations, use a standard transition
        let participatingViewControllerPrefersStandardAnimationStyle = [fromVC, toVC].filter { vc in
            prefersStandardAnimationStyleTypes.contains(where: { standardType in type(of: vc) == standardType })
        }.isEmpty ? false : true

        guard !participatingViewControllerPrefersStandardAnimationStyle else {
            return nil
        }
        
        if let detailController = detailAnimationController(for: operation, from: fromVC, to: toVC) {
            // Looks better if we opt out entirely with iPad floating tab bar
            if #available(iOS 18, *) {
                if UIDevice.current.userInterfaceIdiom == .pad {
                    return nil
                }
            }
            
            return detailController
        }
        
        if let revisionController = diffRevisionAnimationController(for: operation, from: fromVC, to: toVC) {
            return revisionController
        }
       
        return nil
    }
    
    private func diffRevisionAnimationController(for operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard
            let fromDiffVC = fromVC as? (DiffRevisionAnimating & DiffContainerViewController),
            toVC is (DiffRevisionAnimating & DiffContainerViewController),
            let direction = fromDiffVC.animateDirection,
            operation == .push else {
                return nil
        }
        
        return DiffRevisionTransition(direction: direction)
    }
    
    private func detailAnimationController(for operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let actualFromVC: UIViewController?
        if let fromTab = fromVC as? UITabBarController {
            actualFromVC = fromTab.selectedViewController ?? fromVC
        } else {
            actualFromVC = fromVC
        }
        
        let actualToVC: UIViewController?
        if let toTab = toVC as? UITabBarController {
            actualToVC = toTab.selectedViewController ?? toVC
        } else {
            actualToVC = toVC
        }
        
        guard let source = actualFromVC as? (DetailTransitionSourceProviding & ThemeableViewController) ?? actualToVC as? (DetailTransitionSourceProviding & ThemeableViewController)
        else {
            return nil
        }
        
        let incomingImageScaleTransitionProvider = actualToVC as? ImageScaleTransitionProviding
        let outgoingImageScaleTransitionProvider = actualFromVC as? ImageScaleTransitionProviding
        return DetailTransition(detailSourceViewController: source, incomingImageScaleTransitionProvider: incomingImageScaleTransitionProvider, outgoingImageScaleTransitionProvider: outgoingImageScaleTransitionProvider)
    }
    
    @objc func navigationController(_ navigationController: UINavigationController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return nil
    }
}

extension ViewControllerTransitionsController {

    /// These `UIViewController` types prefer a standard `UINavigationController` push/pop style animation.
    var prefersStandardAnimationStyleTypes: [UIViewController.Type] {
        return [NotificationsCenterViewController.self]
    }

}
