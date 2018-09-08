import Foundation

class SearchTransition: NSObject, UIViewControllerAnimatedTransitioning {
    let searchViewController: SearchViewController
    let exploreViewController: ExploreViewController
    let isEnteringSearch: Bool
    
    required init(searchViewController: SearchViewController, exploreViewController: ExploreViewController, isEnteringSearch: Bool) {
        self.searchViewController = searchViewController
        self.exploreViewController = exploreViewController
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
        
        if isEnteringSearch {
            searchViewController.prepareForIncomingTransition(with: exploreViewController.navigationBar)
            searchViewController.nonSearchAlpha = 0
            exploreViewController.searchBar.alpha = 0
            containerView.insertSubview(toViewController.view, aboveSubview: fromViewController.view)
        } else {
            containerView.insertSubview(toViewController.view, belowSubview: fromViewController.view)
            exploreViewController.view.layoutIfNeeded()
            searchViewController.prepareForOutgoingTransition(with: exploreViewController.navigationBar)
            searchViewController.nonSearchAlpha = 1
            exploreViewController.searchBar.alpha = 0
        }

        let duration = self.transitionDuration(using: transitionContext)

        UIView.animateKeyframes(withDuration: duration, delay: 0, options: [], animations: {
            let relativeDuration: TimeInterval = 0.5
            let relativeStartTime: TimeInterval = self.isEnteringSearch ? 1 - relativeDuration : 0
            UIView.addKeyframe(withRelativeStartTime: relativeStartTime, relativeDuration: relativeDuration, animations: {
                if self.isEnteringSearch {
                    self.searchViewController.nonSearchAlpha = 1
                } else {
                    self.searchViewController.nonSearchAlpha = 0
                }
            })
        }) { (finished) in
            self.searchViewController.nonSearchAlpha = 1
            self.exploreViewController.searchBar.alpha = 1
            transitionContext.completeTransition(true)
        }
    }
}
