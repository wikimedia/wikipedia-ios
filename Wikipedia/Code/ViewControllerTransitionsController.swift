import UIKit

@objc(WMFViewControllerTransitionsController)
class ViewControllerTransitionsController: NSObject, UINavigationControllerDelegate {
    @objc func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {

        if let searchController = searchAnimationController(for: operation, from: fromVC, to: toVC) {
            return searchController
        }
        
        if let detailController = detailAnimationController(for: operation, from: fromVC, to: toVC) {
            return detailController
        }
       
        return nil
    }
    
    
    private func searchAnimationController(for operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard
            let exploreVC = fromVC as? ExploreViewController ?? toVC as? ExploreViewController,
            exploreVC.wantsCustomSearchTransition
            else {
                let searchVC = toVC as? SearchViewController ?? fromVC as? SearchViewController
                searchVC?.shouldAnimateSearchBar = false // disable search bar animation on standard push
                return nil
        }
        
        if let searchVC = toVC as? SearchViewController {
            return SearchTransition(searchViewController: searchVC, exploreViewController: exploreVC, isEnteringSearch: true)
        } else if let searchVC = fromVC as? SearchViewController  {
            return SearchTransition(searchViewController: searchVC, exploreViewController: exploreVC, isEnteringSearch: false)
        }
        
        return nil
    }

    
    private func detailAnimationController(for operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard let source = fromVC as? (DetailTransitionSourceProviding & ViewController) ?? toVC as? (DetailTransitionSourceProviding & ViewController)
        else {
            return nil
        }
        
        return DetailTransition(detailSourceViewController: source)
    }
    
    @objc func navigationController(_ navigationController: UINavigationController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return nil
    }
}
