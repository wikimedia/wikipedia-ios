
import UIKit

// MARK: - Delegate
@objc public protocol WMFTableOfContentsPresentationControllerTapDelegate {
    
    func tableOfContentsPresentationControllerDidTapBackground(controller: WMFTableOfContentsPresentationController)
}

public class WMFTableOfContentsPresentationController: UIPresentationController {
    
    // MARK: - init
    public required init(presentedViewController: UIViewController, presentingViewController: UIViewController, tapDelegate: WMFTableOfContentsPresentationControllerTapDelegate) {
        self.tapDelegate = tapDelegate
        super.init(presentedViewController: presentedViewController, presentingViewController: presentedViewController)
    }

    weak public var tapDelegate: WMFTableOfContentsPresentationControllerTapDelegate?

    public var visibleBackgroundWidth: CGFloat = 60.0
    
    // MARK: - Views
    lazy var backgroundView :UIView = {
        let view = UIView(frame: CGRectZero)
        view.backgroundColor = UIColor(white: 1.0, alpha: 0.8)
        view.alpha = 0.0
        let tap = UITapGestureRecognizer.init()
        tap.addTarget(self, action: Selector("didTap:"))
        view.addGestureRecognizer(tap)
        return view
        }()

    // MARK: - Tap Gesture
    lazy var tapGesture :UIView = {
        let view = UIView(frame: CGRectZero)
        view.backgroundColor = UIColor(white: 1.0, alpha: 0.5)
        view.alpha = 0.0
        return view
        }()
    
    
    func didTap(tap: UITapGestureRecognizer) {
        self.tapDelegate?.tableOfContentsPresentationControllerDidTapBackground(self);
    }
    
    // MARK: - Accessibility
    func togglePresentingViewControllerAccessibility(accessible: Bool) {
        self.presentingViewController.view.accessibilityElementsHidden = !accessible
    }

    // MARK: - UIPresentationController
    override public func presentationTransitionWillBegin() {
        // Add the dimming view and the presented view to the heirarchy
        self.backgroundView.frame = self.containerView!.bounds
        self.containerView!.addSubview(self.backgroundView)
        self.containerView!.addSubview(self.presentedView()!)
        
        // Hide the presenting view controller for accessibility
        self.togglePresentingViewControllerAccessibility(false)

        //Add shadow to the presented view
        self.presentedView()?.layer.shadowOpacity = 0.5
        self.presentedView()?.clipsToBounds = false
        
        // Fade in the dimming view alongside the transition
        if let transitionCoordinator = self.presentingViewController.transitionCoordinator() {
            transitionCoordinator.animateAlongsideTransition({(context: UIViewControllerTransitionCoordinatorContext!) -> Void in
                self.backgroundView.alpha  = 1.0
                }, completion:nil)
        }
    }
    
    override public func presentationTransitionDidEnd(completed: Bool)  {
        if !completed {
            self.backgroundView.removeFromSuperview()
        }
    }
    
    override public func dismissalTransitionWillBegin()  {
        if let transitionCoordinator = self.presentingViewController.transitionCoordinator() {
            transitionCoordinator.animateAlongsideTransition({(context: UIViewControllerTransitionCoordinatorContext!) -> Void in
                self.backgroundView.alpha  = 0.0
                }, completion:nil)
        }
    }
    
    override public func dismissalTransitionDidEnd(completed: Bool) {
        if completed {
            self.backgroundView.removeFromSuperview()
            self.togglePresentingViewControllerAccessibility(true)
            //Remove shadow from the presented View
            self.presentedView()?.layer.shadowOpacity = 0.0
            self.presentedView()?.clipsToBounds = true

        }
    }
    
    override public func frameOfPresentedViewInContainerView() -> CGRect {
        var frame = self.containerView!.bounds;
        if !UIApplication.sharedApplication().wmf_tocShouldBeOnLeft{
            frame.origin.x += self.visibleBackgroundWidth
        }
        frame.size.width -= self.visibleBackgroundWidth
        
        return frame
    }
    
    override public func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator transitionCoordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: transitionCoordinator)
        
        transitionCoordinator.animateAlongsideTransition({(context: UIViewControllerTransitionCoordinatorContext!) -> Void in
            self.backgroundView.frame = self.containerView!.bounds
            }, completion:nil)
    }
}
