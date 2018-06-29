import UIKit

@objc(WMFViewControllerTransitionsController)
class ViewControllerTransitionsController: NSObject, UINavigationControllerDelegate {
    @objc func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationControllerOperation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if let searchVC = toVC as? SearchViewController, let exploreVC = fromVC as? ExploreViewController {
            return SearchTransition(searchViewController: searchVC, exploreViewController: exploreVC, isEnteringSearch: true)
        } else if let searchVC = fromVC as? SearchViewController, let exploreVC = toVC as? ExploreViewController  {
            return SearchTransition(searchViewController: searchVC, exploreViewController: exploreVC, isEnteringSearch: false)
        }
        return nil
    }
    
    @objc func navigationController(_ navigationController: UINavigationController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return nil
    }
}
