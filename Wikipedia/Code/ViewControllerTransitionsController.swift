import UIKit

@objc(WMFViewControllerTransitionsController)
class ViewControllerTransitionsController: NSObject, UINavigationControllerDelegate {
    @objc func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {

        // If either participating view controller prefers standard animations, use a standard transition
        let participatingViewControllerPrefersStandardAnimationStyle = [fromVC, toVC].filter { vc in
            prefersStandardAnimationStyleTypes.contains(where: { standardType in type(of: vc) == standardType })
        }.isEmpty ? false : true

        guard !participatingViewControllerPrefersStandardAnimationStyle else {
            return nil
        }

        if let searchController = searchAnimationController(for: operation, from: fromVC, to: toVC) {
            return searchController
        }
        
        if let detailController = detailAnimationController(for: operation, from: fromVC, to: toVC) {
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
    
    private func searchAnimationController(for operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
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
        
        guard
            let exploreVC = actualFromVC as? ExploreViewController ?? actualToVC as? ExploreViewController,
            exploreVC.wantsCustomSearchTransition
            else {
                let searchVC = actualToVC as? SearchViewController ?? actualFromVC as? SearchViewController
                searchVC?.shouldAnimateSearchBar = false // disable search bar animation on standard push
                return nil
        }
        
        if let searchVC = actualToVC as? SearchViewController {
            return SearchTransition(searchViewController: searchVC, exploreViewController: exploreVC, isEnteringSearch: true)
        } else if let searchVC = actualFromVC as? SearchViewController {
            return SearchTransition(searchViewController: searchVC, exploreViewController: exploreVC, isEnteringSearch: false)
        }
        
        return nil
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
        
        guard let source = actualFromVC as? (DetailTransitionSourceProviding & ViewController) ?? actualToVC as? (DetailTransitionSourceProviding & ViewController)
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
