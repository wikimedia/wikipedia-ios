import UIKit
import CocoaLumberjackSwift

// MARK: - Delegate
protocol TableOfContentsAnimatorDelegate: NSObjectProtocol {
    
    func tableOfContentsAnimatorDidTapBackground(_ controller: TableOfContentsAnimator)
}

class TableOfContentsAnimator: UIPercentDrivenInteractiveTransition, UIViewControllerTransitioningDelegate, UIViewControllerAnimatedTransitioning, UIGestureRecognizerDelegate, TableOfContentsPresentationControllerTapDelegate, Themeable {
    
    fileprivate var theme = Theme.standard
    public func apply(theme: Theme) {
        self.theme = theme
        self.presentationController?.apply(theme: theme)
    }
    
    var displaySide = TableOfContentsDisplaySide.left {
        didSet {
            presentationController?.displaySide = displaySide
        }
    }
    var displayMode = TableOfContentsDisplayMode.modal {
        didSet {
            presentationController?.displayMode = displayMode
        }
    }
    
    // MARK: - init
    required init(presentingViewController: UIViewController, presentedViewController: UIViewController) {
        self.presentingViewController = presentingViewController
        self.presentedViewController = presentedViewController
        self.isPresenting = true
        self.isInteractive = false
        presentationGesture = UIPanGestureRecognizer()
        super.init()
        presentationGesture.addTarget(self, action: #selector(TableOfContentsAnimator.handlePresentationGesture(_:)))
        presentationGesture.maximumNumberOfTouches = 1
        presentationGesture.delegate = self
        self.presentingViewController!.view.addGestureRecognizer(presentationGesture)
    }
    
    deinit {
        removeDismissalGestureRecognizer()
        presentationGesture.removeTarget(self, action: #selector(TableOfContentsAnimator.handlePresentationGesture(_:)))
        presentationGesture.view?.removeGestureRecognizer(presentationGesture)
    }
    
    weak var presentingViewController: UIViewController?
    
    weak var presentedViewController: UIViewController?

    open var gesturePercentage: CGFloat = 0.4

    weak open var delegate: TableOfContentsAnimatorDelegate?
    
    fileprivate(set) open var isPresenting: Bool
    
    fileprivate(set) open var isInteractive: Bool
    
    // MARK: - TableOfContentsPresentationControllerTapDelegate
    open func tableOfContentsPresentationControllerDidTapBackground(_ controller: TableOfContentsPresentationController) {
        delegate?.tableOfContentsAnimatorDidTapBackground(self)
    }
    
    // MARK: - UIViewControllerTransitioningDelegate
    
    weak var presentationController: TableOfContentsPresentationController?
    
    open func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        guard presented == self.presentedViewController else {
            return nil
        }
        let presentationController = TableOfContentsPresentationController(presentedViewController: presented, presentingViewController: self.presentingViewController, tapDelegate: self)
        presentationController.apply(theme: theme)
        presentationController.displayMode = displayMode
        presentationController.displaySide = displaySide
        self.presentationController = presentationController
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
        } else {
            return nil
        }
    }
    
    open func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        if self.isInteractive {
            return self
        } else {
            return nil
        }
    }

    // MARK: - UIViewControllerAnimatedTransitioning
    open func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.4
    }
    
    open func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        if isPresenting {
            removeDismissalGestureRecognizer()
            addDismissalGestureRecognizer(transitionContext.containerView)
            animatePresentationWithTransitionContext(transitionContext)
        } else {
            animateDismissalWithTransitionContext(transitionContext)
        }
    }
    
    var tocMultiplier:CGFloat {
        switch displaySide {
        case .left:
            return -1.0
        case .right:
            return 1.0
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
        
        animateTransition(self.isInteractive, duration: self.transitionDuration(using: transitionContext), animations: { () in
            var f = presentedControllerView.frame
            f.origin.x -= f.size.width * self.tocMultiplier
            presentedControllerView.frame = f
            }, completion: {(completed: Bool) in
                let cancelled = transitionContext.transitionWasCancelled
                transitionContext.completeTransition(!cancelled)
        })
    }
    
    func animateDismissalWithTransitionContext(_ transitionContext: UIViewControllerContextTransitioning) {
        let presentedControllerView = transitionContext.view(forKey: UITransitionContextViewKey.from)!
        
        animateTransition(self.isInteractive, duration: self.transitionDuration(using: transitionContext), animations: { () in
            var f = presentedControllerView.frame
            switch self.displaySide {
            case .left:
                f.origin.x = -1*f.size.width
                break
            case .right:
                fallthrough
            default:
                f.origin.x = transitionContext.containerView.bounds.size.width
            }
            presentedControllerView.frame = f

            }, completion: {(completed: Bool) in
                let cancelled = transitionContext.transitionWasCancelled
                transitionContext.completeTransition(!cancelled)
        })
    }
    
    func animateTransition(_ interactive: Bool, duration: TimeInterval, animations: @escaping () -> Void, completion: ((Bool) -> Void)?) {
        
        if interactive {
            UIView.animate(withDuration: duration, delay: 0.0, options: UIView.AnimationOptions(), animations: { () in
                animations()
                }, completion: { (completed: Bool) in
                    completion?(completed)
            })
    
        } else {
            UIView.animate(withDuration: duration, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: .allowUserInteraction, animations: {
                animations()
                }, completion: {(completed: Bool) in
                    completion?(completed)
            })
        }
    }
    
    
    // MARK: - Gestures
    private let presentationGesture: UIPanGestureRecognizer
    
    var dismissalGesture: UIPanGestureRecognizer?
    
    func addDismissalGestureRecognizer(_ containerView: UIView) {
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(TableOfContentsAnimator.handleDismissalGesture(_:)))
        gesture.delegate = self
        containerView.addGestureRecognizer(gesture)
        dismissalGesture = gesture
    }

    func removeDismissalGestureRecognizer() {
        if let dismissalGesture = dismissalGesture {
            dismissalGesture.view?.removeGestureRecognizer(dismissalGesture)
            dismissalGesture.removeTarget(self, action: #selector(TableOfContentsAnimator.handleDismissalGesture(_:)))
        }
        dismissalGesture = nil
    }
    @objc func handlePresentationGesture(_ gesture: UIScreenEdgePanGestureRecognizer) {
        
        switch gesture.state {
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
            if velocityX*velocityRequiredToDismiss > 1 && abs(velocityX) > abs(velocityRequiredToDismiss) {
                cancel()
                return
            }
            
            if velocityX*velocityRequiredToPresent > 1 && abs(velocityX) > abs(velocityRequiredToPresent) {
                finish()
                return
            }
            
            let progressRequiredToPresent = 0.33
            
            if self.percentComplete >= CGFloat(progressRequiredToPresent) {
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
    
    @objc func handleDismissalGesture(_ gesture: UIScreenEdgePanGestureRecognizer) {
        
        switch gesture.state {
        case .began:
            self.isInteractive = true
            self.presentingViewController?.dismiss(animated: true, completion: nil)
        case .changed:
            let translation = gesture.translation(in: gesture.view)
            let transitionProgress = max(min(translation.x * tocMultiplier / self.presentedViewController!.view.bounds.maxX, 0.99), 0.01)
        
            self.update(transitionProgress)
            DDLogDebug("TOC transition progress: \(transitionProgress)")
        case .ended:
            self.isInteractive = false
            let velocityRequiredToPresent = -gesture.view!.bounds.width * tocMultiplier
            let velocityRequiredToDismiss = -velocityRequiredToPresent
            
            let velocityX = gesture.velocity(in: gesture.view).x
            if velocityX*velocityRequiredToDismiss > 1 && abs(velocityX) > abs(velocityRequiredToDismiss) {
                finish()
                return
            }
            
            if velocityX*velocityRequiredToPresent > 1 && abs(velocityX) > abs(velocityRequiredToPresent) {
                cancel()
                return
            }
            
            let progressRequiredToDismiss = 0.50
            
            if self.percentComplete >= CGFloat(progressRequiredToDismiss) {
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
        guard displayMode == .modal else {
            return false
        }
        
        let isRTL = UIApplication.shared.wmf_isRTL
        guard (isRTL && displaySide == .left) || (!isRTL && displaySide == .right) else {
            return false
        }
        
        if gestureRecognizer == self.dismissalGesture {
            
            if let translation = self.dismissalGesture?.translation(in: dismissalGesture?.view) {
                if translation.x * tocMultiplier > 0 {
                    return true
                } else {
                    return false
                }
            } else {
                return false
            }
            
        } else if gestureRecognizer == self.presentationGesture {
            
            let translation = presentationGesture.translation(in: presentationGesture.view)
            let location = presentationGesture.location(in: presentationGesture.view)
            let gestureWidth = presentationGesture.view!.frame.width * gesturePercentage
            let maxLocation: CGFloat
            let isInStartBoundary: Bool
            switch displaySide {
            case .left:
                maxLocation = gestureWidth
                isInStartBoundary = maxLocation - location.x > 0
            default:
                maxLocation =  presentationGesture.view!.frame.maxX - gestureWidth
                isInStartBoundary = location.x - maxLocation > 0
            }
            if (translation.x * tocMultiplier < 0) && isInStartBoundary {
                return true
            } else {
                return false
            }
        } else {
            return true
        }
    }
    
    open func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return otherGestureRecognizer.isKind(of: UIScreenEdgePanGestureRecognizer.self)
    }
}
