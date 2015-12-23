
import UIKit

// MARK: - Delegate
@objc public protocol WMFTableOfContentsAnimatorDelegate {
    
    func tableOfContentsAnimatorDidTapBackground(controller: WMFTableOfContentsAnimator)
}

public class WMFTableOfContentsAnimator: UIPercentDrivenInteractiveTransition, UIViewControllerTransitioningDelegate, UIViewControllerAnimatedTransitioning, UIGestureRecognizerDelegate, WMFTableOfContentsPresentationControllerTapDelegate {
    
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
        self.presentationGesture.view?.removeGestureRecognizer(self.presentationGesture)
        self.presentationGesture.removeTarget(self, action: Selector("handlePanGesture:"))
        removeDismissalGestureRecognizer()
    }
    
    weak var presentingViewController: UIViewController?
    
    weak var presentedViewController: UIViewController?

    weak public var delegate: WMFTableOfContentsAnimatorDelegate?
    
    private(set) public var isPresenting: Bool
    
    private(set) public var isInteractive: Bool
    
    
    // MARK: - WMFTableOfContentsPresentationControllerTapDelegate
    public func tableOfContentsPresentationControllerDidTapBackground(controller: WMFTableOfContentsPresentationController) {
        delegate?.tableOfContentsAnimatorDidTapBackground(self)
    }
    
    // MARK: - UIViewControllerTransitioningDelegate
    public func presentationControllerForPresentedViewController(presented: UIViewController, presentingViewController presenting: UIViewController, sourceViewController source: UIViewController) -> UIPresentationController? {
        guard presented == self.presentedViewController else {
            return nil
        }
        return WMFTableOfContentsPresentationController(presentedViewController: presented, presentingViewController: presenting, tapDelegate: self)
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
            addDismissalGestureRecognizer(transitionContext.containerView()!)
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
        var f = transitionContext.finalFrameForViewController(presentedController)
        f.origin.x += f.size.width
        presentedControllerView.frame = f
        
        containerView.addSubview(presentedControllerView)
        
        animateTransition(self.isInteractive, duration: self.transitionDuration(transitionContext), animations: { () -> Void in
            var f = presentedControllerView.frame
            f.origin.x -= f.size.width
            presentedControllerView.frame = f
            }, completion: {(completed: Bool) -> Void in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
        })
    }
    
    func animateDismissalWithTransitionContext(transitionContext: UIViewControllerContextTransitioning) {
        let presentedControllerView = transitionContext.viewForKey(UITransitionContextFromViewKey)!
        
        animateTransition(self.isInteractive, duration: self.transitionDuration(transitionContext), animations: { () -> Void in
            var f = presentedControllerView.frame
            f.origin.x += f.size.width
            presentedControllerView.frame = f

            }, completion: {(completed: Bool) -> Void in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
        })
    }
    
    func animateTransition(interactive: Bool, duration: NSTimeInterval, animations: () -> Void, completion: ((Bool) -> Void)?){
        
        if(interactive){
            UIView.animateWithDuration(duration, delay: 0.0, options: .CurveLinear, animations: { () -> Void in
                animations()
                }, completion: { (completed: Bool) -> Void in
                    completion?(completed)
            })
    
        }else{
            UIView.animateWithDuration(duration, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.0, options: .AllowUserInteraction, animations: {
                animations()
                }, completion: {(completed: Bool) -> Void in
                    completion?(completed)
            })
        }
    }
    
    
    // MARK: - Gestures
    lazy var presentationGesture: UIScreenEdgePanGestureRecognizer = {
        let gesture = UIScreenEdgePanGestureRecognizer.init(target: self, action: Selector("handlePresentationGesture:"))
        gesture.edges = .Right
        return gesture
    }()
    
    var dismissalGesture: UIPanGestureRecognizer?
    
    func addDismissalGestureRecognizer(containerView: UIView) {
        let gesture = UIPanGestureRecognizer.init(target: self, action: Selector("handleDismissalGesture:"))
        gesture.delegate = self
        containerView.addGestureRecognizer(gesture)
        self.dismissalGesture = gesture
    }

    func removeDismissalGestureRecognizer() {
        if let dismissalGesture = self.dismissalGesture {
            dismissalGesture.view?.removeGestureRecognizer(dismissalGesture)
            dismissalGesture.removeTarget(self, action: Selector("handleDismissalGesture:"))
        }
        self.dismissalGesture = nil
    }
    func handlePresentationGesture(gesture: UIScreenEdgePanGestureRecognizer) {
        
        switch(gesture.state) {
        case (.Began):
            self.isInteractive = true
            self.presentingViewController?.presentViewController(self.presentedViewController!, animated: true, completion: nil)
        case (.Changed):
            let position = gesture.locationInView(gesture.view);
            let distanceFromRight = CGRectGetMaxX(gesture.view!.bounds) - position.x
            let transitionProgress = distanceFromRight / CGRectGetMaxX(gesture.view!.bounds)
            self.updateInteractiveTransition(transitionProgress)
        case (.Ended):
            self.isInteractive = false
            let velocityRequiredToPresent = -CGRectGetWidth(gesture.view!.bounds)
            let velocityRequiredToDismiss = CGRectGetWidth(gesture.view!.bounds)
            
            let velocityX = gesture.velocityInView(gesture.view).x
            if velocityX > velocityRequiredToDismiss{
                self.cancelInteractiveTransition()
                return
            }
            
            if velocityX > velocityRequiredToPresent{
                self.finishInteractiveTransition()
                return
            }
            
            let progressRequiredToPresent = 0.33
            
            if(self.percentComplete >= CGFloat(progressRequiredToPresent)){
                self.finishInteractiveTransition()
                return
            }
            
            self.cancelInteractiveTransition()
            
        case (.Cancelled):
            self.isInteractive = false
            self.cancelInteractiveTransition()
            
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
            let transitionProgress = translation.x / CGRectGetMaxX(self.presentedViewController!.view.bounds)
            self.updateInteractiveTransition(transitionProgress)
            DDLogVerbose("TOC transition progress: \(transitionProgress)")
        case .Ended:
            self.isInteractive = false
            let velocityRequiredToPresent = -CGRectGetMaxX(gesture.view!.bounds)
            let velocityRequiredToDismiss = CGRectGetWidth(gesture.view!.bounds)
            
            let velocityX = gesture.velocityInView(gesture.view).x
            if velocityX > velocityRequiredToDismiss{
                self.finishInteractiveTransition()
                return
            }
            
            if velocityX > velocityRequiredToPresent{
                self.cancelInteractiveTransition()
                return
            }
            
            let progressRequiredToDismiss = 0.33
            
            if(self.percentComplete >= CGFloat(progressRequiredToDismiss)){
                self.finishInteractiveTransition()
                return
            }
            
            self.cancelInteractiveTransition()
            
        case .Cancelled:
            self.isInteractive = false
            self.cancelInteractiveTransition()
            
        default :
            break
        }
    }
    
    // MARK: - UIGestureRecognizerDelegate
    public func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer == self.dismissalGesture else {
            return true
        }
        
        if let translation = self.dismissalGesture?.translationInView(dismissalGesture?.view) {
            if(translation.x > 0){
                return true
            }else{
                return false
            }
        }else{
            return false
        }
    }
}
