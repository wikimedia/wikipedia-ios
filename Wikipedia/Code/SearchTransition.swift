import Foundation

class SearchTransition: NSObject, UIViewControllerAnimatedTransitioning {
    let searchViewController: SearchViewController
    let isEnteringSearch: Bool
    
    required init(searchViewController: SearchViewController, isEnteringSearch: Bool) {
        self.searchViewController = searchViewController
        self.isEnteringSearch = isEnteringSearch
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard
            let toViewController = transitionContext.viewController(forKey: .to),
            let fromViewController = transitionContext.viewController(forKey: .from)
            else {
                return
        }
        let containerView = transitionContext.containerView
        let toFinalFrame = transitionContext.finalFrame(for: toViewController)
        toViewController.view.frame = toFinalFrame
        let explore: ExploreViewController? = fromViewController as? ExploreViewController ?? toViewController as? ExploreViewController
        if isEnteringSearch {
            searchViewController.nonSearchAlpha = 0
            explore?.searchBar.alpha = 0
            containerView.insertSubview(toViewController.view, aboveSubview: fromViewController.view)
        } else {
            searchViewController.nonSearchAlpha = 1
            explore?.searchBar.alpha = 0
            containerView.insertSubview(toViewController.view, belowSubview: fromViewController.view)
        }
        let duration = self.transitionDuration(using: transitionContext)

        UIView.animate(withDuration: duration, animations: {
            if self.isEnteringSearch {
                self.searchViewController.nonSearchAlpha = 1
            } else {
                self.searchViewController.nonSearchAlpha = 0
            }
        }) { (finished) in
            self.searchViewController.nonSearchAlpha = 1
            explore?.searchBar.alpha = 1
            transitionContext.completeTransition(true)
        }
    }
}
