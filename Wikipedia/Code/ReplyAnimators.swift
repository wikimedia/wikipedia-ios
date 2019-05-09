
import Foundation
class ReplyPresentAnimator: NSObject, UIViewControllerAnimatedTransitioning {

    private let duration: TimeInterval
    private let lastSeenView: UIView
    private let additionalAnimations: (() -> Void)?
    private let topChromeHeight: CGFloat
    private let navigationBarHeight: CGFloat
    private let topChromeExtraOffset: CGFloat
    
    init(duration: TimeInterval = 0.25, lastSeenView: UIView, additionalAnimations: (() -> Void)? = nil, topChromeHeight: CGFloat, navigationBarHeight: CGFloat, topChromeExtraOffset: CGFloat = 0) {
        self.duration = duration
        self.lastSeenView = lastSeenView
        self.additionalAnimations = additionalAnimations
        self.topChromeHeight = topChromeHeight
        self.navigationBarHeight = navigationBarHeight
        self.topChromeExtraOffset = topChromeExtraOffset
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let toViewController = transitionContext.viewController(forKey: .to),
         let fromViewController = transitionContext.viewController(forKey: .from),
        let convertedLastViewRect = lastSeenView.superview?.convert(lastSeenView.frame, to: transitionContext.containerView) else {
            return
        }
        
        let containerView = transitionContext.containerView
        let modalTopY = containerView.bounds.minY + (topChromeHeight + navigationBarHeight) - topChromeExtraOffset
        let fromDelta = convertedLastViewRect.maxY - modalTopY

        containerView.addSubview(toViewController.view)
        toViewController.view.frame = CGRect(x: containerView.bounds.minX, y: containerView.bounds.height, width: toViewController.view.frame.width, height: toViewController.view.frame.height)
        
        UIView.animate(withDuration: duration, delay: 0.0, options: .curveEaseInOut, animations: {
            toViewController.view.frame = CGRect(x: containerView.bounds.minX, y: modalTopY, width: toViewController.view.frame.width, height: toViewController.view.frame.height)
            fromViewController.view.frame = CGRect(x: fromViewController.view.frame.minX, y: fromViewController.view.frame.minY - fromDelta, width: fromViewController.view.frame.width, height: fromViewController.view.frame.height)
            
            self.additionalAnimations?()
        }) { _ in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
}


class ReplyDismissAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    
    let interactionController: ReplySwipeInteractionController?
    private let duration: TimeInterval
    private let lastSeenView: UIView
    private let additionalAnimations: (() -> Void)?
    
    init(duration: TimeInterval = 0.25,
         interactionController: ReplySwipeInteractionController? = nil, lastSeenView: UIView, additionalAnimations: (() -> Void)? = nil) {
        self.interactionController = interactionController
        self.duration = duration
        self.lastSeenView = lastSeenView
        self.additionalAnimations = additionalAnimations
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromViewController = transitionContext.viewController(forKey: .from),
        let toViewController = transitionContext.viewController(forKey: .to),
        let fromView = fromViewController.view,
        let toView = toViewController.view else {
            return
        }
        
        let containerView = transitionContext.containerView
       
        
        UIView.animate(withDuration: duration, delay: 0.0, options: .curveEaseInOut, animations: {
            fromViewController.view.frame = CGRect(x: fromView.frame.minX, y: containerView.bounds.height, width: fromView.frame.width, height: fromView.frame.height)
            toViewController.view.frame = CGRect(x: toView.frame.minX, y: 0, width: toView.frame.width, height: toView.frame.height)
            self.additionalAnimations?()
        }, completion: { _ in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }
}
