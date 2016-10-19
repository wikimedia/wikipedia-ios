
import UIKit

// MARK: - Delegate
@objc public protocol WMFTableOfContentsAnimatorDelegate {
    
    func tableOfContentsAnimatorDidTapBackground(controller: WMFTableOfContentsAnimator)
}

public class WMFTableOfContentsAnimator: UIPercentDrivenInteractiveTransition, UIViewControllerTransitioningDelegate, UIViewControllerAnimatedTransitioning, UIGestureRecognizerDelegate, WMFTableOfContentsPresentationControllerTapDelegate {
    
    var displaySide = WMFTableOfContentsDisplaySideLeft
    var displayMode = WMFTableOfContentsDisplayModeModal
    
    // MARK: - init
    public required init(presentingViewController: UIViewController, presentedViewController: UIViewController) {
        self.presentingViewController = presentingViewController
        self.presentedViewController = presentedViewController
        self.isPresenting = true
        self.isInteractive = false
        super.init()
        self.presentingViewController!.view.addGestureRecognizer(self.presentationGesture)
    }
    
    deinit {
        removeDismissalGestureRecognizer()
        self.presentationGesture.removeTarget(self, action: #selector(WMFTableOfContentsAnimator.handlePresentationGesture(_:)))
        self.presentationGesture.view?.removeGestureRecognizer(self.presentationGesture)
    }
    
    weak var presentingViewController: UIViewController?
    
    weak var presentedViewController: UIViewController?

    public var gesturePercentage: CGFloat = 0.4

    weak public var delegate: WMFTableOfContentsAnimatorDelegate?
    
    private(set) public var isPresenting: Bool
    
    private(set) public var isInteractive: Bool
    
    // MARK: - WMFTableOfContentsPresentationControllerTapDelegate
    public func tableOfContentsPresentationControllerDidTapBackground(controller: WMFTableOfContentsPresentationController) {
        delegate?.tableOfContentsAnimatorDidTapBackground(self)
    }
    
    // MARK: - UIViewControllerTransitioningDelegate
    public func presentationControllerForPresentedViewController(presented: UIViewController, presentingViewController presenting: UIViewController?, sourceViewController source: UIViewController) -> UIPresentationController? {
        guard presented == self.presentedViewController else {
            return nil
        }
        return WMFTableOfContentsPresentationController(presentedViewController: presented, presentingViewController: self.presentingViewController, tapDelegate: self)
    }
    
    public func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard presented == self.presentedViewController else {
            return nil
        }
        self.isPresenting = true
        return self
    }
    
    public func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard dismissed == self.presentedViewController else {
            return nil
        }
        self.isPresenting = false
        return self
    }
    
    public func interactionControllerForPresentation(animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        if self.isInteractive {
            return self
        }else{
            return nil
        }
    }
    
    public func interactionControllerForDismissal(animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        if self.isInteractive {
            return self
        }else{
            return nil
        }
    }

    // MARK: - UIViewControllerAnimatedTransitioning
    public func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return self.isPresenting ? 0.5 : 0.8
    }
    
    public func animateTransition(transitionContext: UIViewControllerContextTransitioning)  {
        if isPresenting {
            removeDismissalGestureRecognizer()
            addDismissalGestureRecognizer(transitionContext.containerView())
            animatePresentationWithTransitionContext(transitionContext)
        }
        else {
            animateDismissalWithTransitionContext(transitionContext)
        }
    }
    
    var tocMultiplier:CGFloat {
        switch displaySide {
        case WMFTableOfContentsDisplaySideLeft:
            return -1.0
        case WMFTableOfContentsDisplaySideRight:
            return 1.0
        case WMFTableOfContentsDisplaySideCenter:
            fallthrough
        default:
            return UIApplication.sharedApplication().wmf_isRTL ? -1.0 : 1.0
        }
    }
    
    // MARK: - Animation
    func animatePresentationWithTransitionContext(transitionContext: UIViewControllerContextTransitioning) {
        let presentedController = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)!
        let presentedControllerView = transitionContext.viewForKey(UITransitionContextToViewKey)!
        let containerView = transitionContext.containerView()
        
        // Position the presented view off the top of the container view
        var f = transitionContext.finalFrameForViewController(presentedController)
        f.origin.x += f.size.width * tocMultiplier
        presentedControllerView.frame = f
        
        containerView.addSubview(presentedControllerView)
        
        animateTransition(self.isInteractive, duration: self.transitionDuration(transitionContext), animations: { () -> Void in
            var f = presentedControllerView.frame
            f.origin.x -= f.size.width * self.tocMultiplier
            presentedControllerView.frame = f
            }, completion: {(completed: Bool) -> Void in
                let cancelled = transitionContext.transitionWasCancelled()
                transitionContext.completeTransition(!cancelled)
        })
    }
    
    func animateDismissalWithTransitionContext(transitionContext: UIViewControllerContextTransitioning) {
        let presentedControllerView = transitionContext.viewForKey(UITransitionContextFromViewKey)!
        
        animateTransition(self.isInteractive, duration: self.transitionDuration(transitionContext), animations: { () -> Void in
            var f = presentedControllerView.frame
            f.origin.x += f.size.width * self.tocMultiplier
            presentedControllerView.frame = f

            }, completion: {(completed: Bool) -> Void in
                let cancelled = transitionContext.transitionWasCancelled()
                transitionContext.completeTransition(!cancelled)
        })
    }
    
    func animateTransition(interactive: Bool, duration: NSTimeInterval, animations: () -> Void, completion: ((Bool) -> Void)?){
        
        if(interactive){
            UIView.animateWithDuration(duration, delay: 0.0, options: .CurveEaseInOut, animations: { () -> Void in
                animations()
                }, completion: { (completed: Bool) -> Void in
                    completion?(completed)
            })
    
        }else{
            UIView.animateWithDuration(duration, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: .AllowUserInteraction, animations: {
                animations()
                }, completion: {(completed: Bool) -> Void in
                    completion?(completed)
            })
        }
    }
    
    
    // MARK: - Gestures
    lazy var presentationGesture: UIPanGestureRecognizer = {
        let gesture = UIPanGestureRecognizer.init(target: self, action: #selector(WMFTableOfContentsAnimator.handlePresentationGesture(_:)))
        gesture.maximumNumberOfTouches = 1
        gesture.delegate = self
        return gesture
    }()
    
    var dismissalGesture: UIPanGestureRecognizer?
    
    func addDismissalGestureRecognizer(containerView: UIView) {
        let gesture = UIPanGestureRecognizer.init(target: self, action: #selector(WMFTableOfContentsAnimator.handleDismissalGesture(_:)))
        gesture.delegate = self
        containerView.addGestureRecognizer(gesture)
        self.dismissalGesture = gesture
    }

    func removeDismissalGestureRecognizer() {
        if let dismissalGesture = self.dismissalGesture {
            dismissalGesture.view?.removeGestureRecognizer(dismissalGesture)
            dismissalGesture.removeTarget(self, action: #selector(WMFTableOfContentsAnimator.handleDismissalGesture(_:)))
        }
        self.dismissalGesture = nil
    }
    func handlePresentationGesture(gesture: UIScreenEdgePanGestureRecognizer) {
        
        switch(gesture.state) {
        case (.Began):
            self.isInteractive = true
            self.presentingViewController?.presentViewController(self.presentedViewController!, animated: true, completion: nil)
        case (.Changed):
            let translation = gesture.translationInView(gesture.view)
            let transitionProgress = translation.x * -tocMultiplier / CGRectGetMaxX(self.presentedViewController!.view.bounds)
            self.updateInteractiveTransition(transitionProgress)
        case (.Ended):
            self.isInteractive = false
            let velocityRequiredToPresent = -CGRectGetWidth(gesture.view!.bounds) * tocMultiplier
            let velocityRequiredToDismiss = -velocityRequiredToPresent
            
            let velocityX = gesture.velocityInView(gesture.view).x
            if velocityX*velocityRequiredToDismiss > 1 && abs(velocityX) > abs(velocityRequiredToDismiss){
                cancelInteractiveTransition()
                return
            }
            
            if velocityX*velocityRequiredToPresent > 1 && abs(velocityX) > abs(velocityRequiredToPresent){
                finishInteractiveTransition()
                return
            }
            
            let progressRequiredToPresent = 0.33
            
            if(self.percentComplete >= CGFloat(progressRequiredToPresent)){
                finishInteractiveTransition()
                return
            }
            
            cancelInteractiveTransition()
            
        case (.Cancelled):
            self.isInteractive = false
            cancelInteractiveTransition()
            
        default :
            break
        }
    }
    
    func handleDismissalGesture(gesture: UIScreenEdgePanGestureRecognizer) {
        
        switch(gesture.state) {
        case .Began:
            self.isInteractive = true
            self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
        case .Changed:
            let translation = gesture.translationInView(gesture.view)
            let transitionProgress = translation.x * tocMultiplier / CGRectGetMaxX(self.presentedViewController!.view.bounds)
            self.updateInteractiveTransition(transitionProgress)
            DDLogVerbose("TOC transition progress: \(transitionProgress)")
        case .Ended:
            self.isInteractive = false
            let velocityRequiredToPresent = -CGRectGetWidth(gesture.view!.bounds) * tocMultiplier
            let velocityRequiredToDismiss = -velocityRequiredToPresent
            
            let velocityX = gesture.velocityInView(gesture.view).x
            if velocityX*velocityRequiredToDismiss > 1 && abs(velocityX) > abs(velocityRequiredToDismiss){
                finishInteractiveTransition()
                return
            }
            
            if velocityX*velocityRequiredToPresent > 1 && abs(velocityX) > abs(velocityRequiredToPresent){
                cancelInteractiveTransition()
                return
            }
            
            let progressRequiredToDismiss = 0.50
            
            if(self.percentComplete >= CGFloat(progressRequiredToDismiss)){
                finishInteractiveTransition()
                return
            }
            
            cancelInteractiveTransition()
            
        case .Cancelled:
            self.isInteractive = false
            cancelInteractiveTransition()
            
        default :
            break
        }
    }
    
    // MARK: - UIGestureRecognizerDelegate
    public func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == self.dismissalGesture {
            
            if let translation = self.dismissalGesture?.translationInView(dismissalGesture?.view) {
                if(translation.x * tocMultiplier > 0){
                    return true
                }else{
                    return false
                }
            }else{
                return false
            }
            
        }else if gestureRecognizer == self.presentationGesture {
            
            let translation = self.presentationGesture.translationInView(presentationGesture.view)
            let location = self.presentationGesture.locationInView(presentationGesture.view)
            let gestureWidth = presentationGesture.view!.frame.width * gesturePercentage
            let maxLocation = displaySide == WMFTableOfContentsDisplaySideLeft
                 ? gestureWidth: presentationGesture.view!.frame.maxX - gestureWidth
            let isInStartBoundry = displaySide == WMFTableOfContentsDisplaySideLeft ? maxLocation - location.x > 0 : location.x - maxLocation > 0
            if(translation.x * tocMultiplier < 0) && isInStartBoundry{
                return true
            }else{
                return false
            }
        }else{
            return true
        }
        
        
    }
}
