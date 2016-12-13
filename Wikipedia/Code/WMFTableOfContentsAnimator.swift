
import UIKit
import CocoaLumberjackSwift

// MARK: - Delegate
@objc public protocol WMFTableOfContentsAnimatorDelegate {
    
    func tableOfContentsAnimatorDidTapBackground(_ controller: WMFTableOfContentsAnimator)
}

open class WMFTableOfContentsAnimator: UIPercentDrivenInteractiveTransition, UIViewControllerTransitioningDelegate, UIViewControllerAnimatedTransitioning, UIGestureRecognizerDelegate, WMFTableOfContentsPresentationControllerTapDelegate {
    
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

    open var gesturePercentage: CGFloat = 0.4

    weak open var delegate: WMFTableOfContentsAnimatorDelegate?
    
    fileprivate(set) open var isPresenting: Bool
    
    fileprivate(set) open var isInteractive: Bool
    
    // MARK: - WMFTableOfContentsPresentationControllerTapDelegate
    open func tableOfContentsPresentationControllerDidTapBackground(_ controller: WMFTableOfContentsPresentationController) {
        delegate?.tableOfContentsAnimatorDidTapBackground(self)
    }
    
    // MARK: - UIViewControllerTransitioningDelegate
    open func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        guard presented == self.presentedViewController else {
            return nil
        }
        let presentationController = WMFTableOfContentsPresentationController(presentedViewController: presented, presentingViewController: self.presentingViewController, tapDelegate: self)
        presentationController.displayMode = displayMode
        presentationController.displaySide = displaySide
        return presentationController
    }
    
    open func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard presented == self.presentedViewController else {
            return nil
        }
        self.isPresenting = true
        return self
    }
    
    open func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard dismissed == self.presentedViewController else {
            return nil
        }
        self.isPresenting = false
        return self
    }
    
    open func interactionControllerForPresentation(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        if self.isInteractive {
            return self
        }else{
            return nil
        }
    }
    
    open func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        if self.isInteractive {
            return self
        }else{
            return nil
        }
    }

    // MARK: - UIViewControllerAnimatedTransitioning
    open func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return self.isPresenting ? 0.5 : 0.8
    }
    
    open func animateTransition(using transitionContext: UIViewControllerContextTransitioning)  {
        if isPresenting {
            removeDismissalGestureRecognizer()
            addDismissalGestureRecognizer(transitionContext.containerView)
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
            return UIApplication.shared.wmf_isRTL ? -1.0 : 1.0
        }
    }
    
    // MARK: - Animation
    func animatePresentationWithTransitionContext(_ transitionContext: UIViewControllerContextTransitioning) {
        let presentedController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)!
        let presentedControllerView = transitionContext.view(forKey: UITransitionContextViewKey.to)!
        let containerView = transitionContext.containerView
        
        // Position the presented view off the top of the container view
        var f = transitionContext.finalFrame(for: presentedController)
        f.origin.x += f.size.width * tocMultiplier
        presentedControllerView.frame = f
        
        containerView.addSubview(presentedControllerView)
        
        animateTransition(self.isInteractive, duration: self.transitionDuration(using: transitionContext), animations: { () -> Void in
            var f = presentedControllerView.frame
            f.origin.x -= f.size.width * self.tocMultiplier
            presentedControllerView.frame = f
            }, completion: {(completed: Bool) -> Void in
                let cancelled = transitionContext.transitionWasCancelled
                transitionContext.completeTransition(!cancelled)
        })
    }
    
    func animateDismissalWithTransitionContext(_ transitionContext: UIViewControllerContextTransitioning) {
        let presentedControllerView = transitionContext.view(forKey: UITransitionContextViewKey.from)!
        
        animateTransition(self.isInteractive, duration: self.transitionDuration(using: transitionContext), animations: { () -> Void in
            var f = presentedControllerView.frame
            switch self.displaySide {
            case WMFTableOfContentsDisplaySideLeft:
                f.origin.x = -1*f.size.width
                break
            case WMFTableOfContentsDisplaySideRight:
                fallthrough
            case WMFTableOfContentsDisplaySideCenter:
                fallthrough
            default:
                f.origin.x = transitionContext.containerView.bounds.size.width
            }
            presentedControllerView.frame = f

            }, completion: {(completed: Bool) -> Void in
                let cancelled = transitionContext.transitionWasCancelled
                transitionContext.completeTransition(!cancelled)
        })
    }
    
    func animateTransition(_ interactive: Bool, duration: TimeInterval, animations: @escaping () -> Void, completion: ((Bool) -> Void)?){
        
        if(interactive){
            UIView.animate(withDuration: duration, delay: 0.0, options: UIViewAnimationOptions(), animations: { () -> Void in
                animations()
                }, completion: { (completed: Bool) -> Void in
                    completion?(completed)
            })
    
        }else{
            UIView.animate(withDuration: duration, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: .allowUserInteraction, animations: {
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
    
    func addDismissalGestureRecognizer(_ containerView: UIView) {
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
    func handlePresentationGesture(_ gesture: UIScreenEdgePanGestureRecognizer) {
        
        switch(gesture.state) {
        case (.began):
            self.isInteractive = true
            self.presentingViewController?.present(self.presentedViewController!, animated: true, completion: nil)
        case (.changed):
            let translation = gesture.translation(in: gesture.view)
            let transitionProgress = max(min(translation.x * -tocMultiplier / self.presentedViewController!.view.bounds.maxX, 0.99), 0.01)
            self.update(transitionProgress)
        case (.ended):
            self.isInteractive = false
            let velocityRequiredToPresent = -gesture.view!.bounds.width * tocMultiplier
            let velocityRequiredToDismiss = -velocityRequiredToPresent
            
            let velocityX = gesture.velocity(in: gesture.view).x
            if velocityX*velocityRequiredToDismiss > 1 && abs(velocityX) > abs(velocityRequiredToDismiss){
                cancel()
                return
            }
            
            if velocityX*velocityRequiredToPresent > 1 && abs(velocityX) > abs(velocityRequiredToPresent){
                finish()
                return
            }
            
            let progressRequiredToPresent = 0.33
            
            if(self.percentComplete >= CGFloat(progressRequiredToPresent)){
                finish()
                return
            }
            
            cancel()
            
        case (.cancelled):
            self.isInteractive = false
            cancel()
            
        default :
            break
        }
    }
    
    func handleDismissalGesture(_ gesture: UIScreenEdgePanGestureRecognizer) {
        
        switch(gesture.state) {
        case .began:
            self.isInteractive = true
            self.presentingViewController?.dismiss(animated: true, completion: nil)
        case .changed:
            let translation = gesture.translation(in: gesture.view)
            let transitionProgress = max(min(translation.x * tocMultiplier / self.presentedViewController!.view.bounds.maxX, 0.99), 0.01)
        
            self.update(transitionProgress)
            DDLogVerbose("TOC transition progress: \(transitionProgress)")
        case .ended:
            self.isInteractive = false
            let velocityRequiredToPresent = -gesture.view!.bounds.width * tocMultiplier
            let velocityRequiredToDismiss = -velocityRequiredToPresent
            
            let velocityX = gesture.velocity(in: gesture.view).x
            if velocityX*velocityRequiredToDismiss > 1 && abs(velocityX) > abs(velocityRequiredToDismiss){
                finish()
                return
            }
            
            if velocityX*velocityRequiredToPresent > 1 && abs(velocityX) > abs(velocityRequiredToPresent){
                cancel()
                return
            }
            
            let progressRequiredToDismiss = 0.50
            
            if(self.percentComplete >= CGFloat(progressRequiredToDismiss)){
                finish()
                return
            }
            
            cancel()
            
        case .cancelled:
            self.isInteractive = false
            cancel()
            
        default :
            break
        }
    }
    
    // MARK: - UIGestureRecognizerDelegate
    
    open func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard displayMode == WMFTableOfContentsDisplayModeModal else {
            return false
        }
        
        let isRTL = UIApplication.shared.wmf_isRTL
        guard (displaySide == WMFTableOfContentsDisplaySideCenter) || (isRTL && displaySide == WMFTableOfContentsDisplaySideLeft) || (!isRTL && displaySide == WMFTableOfContentsDisplaySideRight) else  {
            return false
        }
        
        if gestureRecognizer == self.dismissalGesture {
            
            if let translation = self.dismissalGesture?.translation(in: dismissalGesture?.view) {
                if(translation.x * tocMultiplier > 0){
                    return true
                }else{
                    return false
                }
            }else{
                return false
            }
            
        }else if gestureRecognizer == self.presentationGesture {
            
            let translation = self.presentationGesture.translation(in: presentationGesture.view)
            let location = self.presentationGesture.location(in: presentationGesture.view)
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
    
    open func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return otherGestureRecognizer.isKind(of: UIScreenEdgePanGestureRecognizer.self)
    }
}
