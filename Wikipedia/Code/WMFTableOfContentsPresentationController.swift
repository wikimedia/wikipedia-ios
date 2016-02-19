
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
    lazy var statusBarBackground: UIView = {
        let view = UIView(frame: CGRectZero)
        view.frame = CGRect(x: CGRectGetMinX(self.containerView!.bounds), y: CGRectGetMinY(self.containerView!.bounds), width: CGRectGetWidth(self.containerView!.bounds), height: 20.0)
        let statusBarBackgroundBottomBorder = UIView(frame: CGRectMake(CGRectGetMinX(view.bounds), CGRectGetMaxY(view.bounds), CGRectGetWidth(view.bounds), 0.5))
        view.backgroundColor = UIColor.whiteColor()
        statusBarBackgroundBottomBorder.backgroundColor = UIColor.lightGrayColor()
        view.addSubview(statusBarBackgroundBottomBorder)

        return view
    }()
    
    lazy var backgroundView :UIView = {
        let view = UIView(frame: CGRectZero)
        view.backgroundColor = UIColor(white: 0, alpha: 0.5)
        view.alpha = 0.0
        let tap = UITapGestureRecognizer.init()
        tap.addTarget(self, action: Selector("didTap:"))
        view.addGestureRecognizer(tap)
        view.addSubview(self.statusBarBackground)
        
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
        
        if(self.traitCollection.verticalSizeClass == .Compact){
            self.statusBarBackground.hidden = true
        }
        
        self.containerView!.addSubview(self.presentedView()!)
        
        // Hide the presenting view controller for accessibility
        self.togglePresentingViewControllerAccessibility(false)

        //Add shadow to the presented view
        self.presentedView()?.layer.shadowOpacity = 0.5
        self.presentedView()?.layer.shadowOffset = CGSize(width: 3, height: 5)
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
        frame.origin.y =  UIApplication.sharedApplication().statusBarFrame.size.height + 0.5;
        frame.size.width -= self.visibleBackgroundWidth
        
        return frame
    }
    
    override public func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator transitionCoordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: transitionCoordinator)

        transitionCoordinator.animateAlongsideTransition({(context: UIViewControllerTransitionCoordinatorContext!) -> Void in
            self.backgroundView.frame = self.containerView!.bounds
            }, completion:nil)
    }
    
    override public func willTransitionToTraitCollection(newCollection: UITraitCollection, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        
        super.willTransitionToTraitCollection(newCollection, withTransitionCoordinator: coordinator)
        
        if newCollection.verticalSizeClass == .Compact
        {
            self.statusBarBackground.hidden = true;
            var frameL = self.containerView!.bounds;
            if !UIApplication.sharedApplication().wmf_tocShouldBeOnLeft{
                frameL.origin.x += self.visibleBackgroundWidth
            }
            frameL.size.width -= self.visibleBackgroundWidth
            self.presentedView()!.frame = frameL;
            
        }
        
        if newCollection.verticalSizeClass == .Regular
        {
            self.statusBarBackground.hidden = false;
            var frameP = self.containerView!.bounds;
            if !UIApplication.sharedApplication().wmf_tocShouldBeOnLeft{
                frameP.origin.x += self.visibleBackgroundWidth
            }
            // HAX: we are not using statusbar.size.height here and using a 20 because the statusbar hight returns 0. casuing a bug the second time you open TOC and turn from landscape to portrait.
            frameP.origin.y =  20 + 0.5;
            self.presentedView()!.frame = frameP;
        }

    }
}
