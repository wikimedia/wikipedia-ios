
import UIKit

class WMFTableOfContentsAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    
    // MARK: - init
    let isPresenting :Bool
    
    init(isPresenting: Bool) {
        self.isPresenting = isPresenting
        super.init()
    }
    
    // MARK: - UIViewControllerAnimatedTransitioning
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return self.isPresenting ? 0.5 : 0.8
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning)  {
        if isPresenting {
            animatePresentationWithTransitionContext(transitionContext)
        }
        else {
            animateDismissalWithTransitionContext(transitionContext)
        }
    }
    
    // MARK: - Animation
    func animatePresentationWithTransitionContext(transitionContext: UIViewControllerContextTransitioning) {
        let presentedController = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)!
        let presentedControllerView = transitionContext.viewForKey(UITransitionContextToViewKey)!
        let containerView = transitionContext.containerView()!
        
        // Position the presented view off the top of the container view
        presentedControllerView.frame = transitionContext.finalFrameForViewController(presentedController)
        presentedControllerView.center.x += containerView.bounds.size.width
        
        containerView.addSubview(presentedControllerView)
        
        // Animate the presented view to it's final position
        UIView.animateWithDuration(self.transitionDuration(transitionContext), delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.0, options: .AllowUserInteraction, animations: {
            presentedControllerView.center.x -= containerView.bounds.size.width
            }, completion: {(completed: Bool) -> Void in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
        })
    }
    
    func animateDismissalWithTransitionContext(transitionContext: UIViewControllerContextTransitioning) {
        let presentedControllerView = transitionContext.viewForKey(UITransitionContextFromViewKey)!
        let containerView = transitionContext.containerView()!
        
        // Animate the presented view off the bottom of the view
        UIView.animateWithDuration(self.transitionDuration(transitionContext), delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.0, options: .AllowUserInteraction, animations: {
            presentedControllerView.center.x += containerView.bounds.size.width
            }, completion: {(completed: Bool) -> Void in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
        })
    }
}
