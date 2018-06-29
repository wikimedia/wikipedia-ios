import UIKit

@objc(WMFViewControllerTransitionsController)
class ViewControllerTransitionsController: NSObject, UINavigationControllerDelegate {
    @objc func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationControllerOperation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard !(toVC is WMFArticleViewController) && !(fromVC is WMFArticleViewController) else {
            return nil
        }
        if let searchVC = toVC as? SearchViewController {
            return SearchTransition(searchViewController: searchVC, isEnteringSearch: true)
        } else if let searchVC = fromVC as? SearchViewController {
            return SearchTransition(searchViewController: searchVC, isEnteringSearch: false)
        }
        return nil
    }
    
    @objc func navigationController(_ navigationController: UINavigationController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return nil
    }
}
