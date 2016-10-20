import UIKit
import Masonry

// MARK: - Delegate
@objc public protocol WMFTableOfContentsPresentationControllerTapDelegate {
    
    func tableOfContentsPresentationControllerDidTapBackground(controller: WMFTableOfContentsPresentationController)
}

public class WMFTableOfContentsPresentationController: UIPresentationController {
    
    var displaySide = WMFTableOfContentsDisplaySideLeft
    var displayMode = WMFTableOfContentsDisplayModeModal
    
    // MARK: - init
    public required init(presentedViewController: UIViewController, presentingViewController: UIViewController?, tapDelegate: WMFTableOfContentsPresentationControllerTapDelegate) {
        self.tapDelegate = tapDelegate
        super.init(presentedViewController: presentedViewController, presentingViewController: presentedViewController)
    }

    weak public var tapDelegate: WMFTableOfContentsPresentationControllerTapDelegate?

    public var minimumVisibleBackgroundWidth: CGFloat = 60.0
    public var maximumTableOfContentsWidth: CGFloat = 300.0
    public var closeButtonLeadingPadding: CGFloat = 10.0
    public var closeButtonTopPadding: CGFloat = 0.0
    public var statusBarEstimatedHeight: CGFloat = 20.0
    
    // MARK: - Views
    lazy var statusBarBackground: UIView = {
        let view = UIView(frame: CGRect(x: CGRectGetMinX(self.containerView!.bounds), y: CGRectGetMinY(self.containerView!.bounds), width: CGRectGetWidth(self.containerView!.bounds), height: self.statusBarEstimatedHeight))
        view.autoresizingMask = .FlexibleWidth
        let statusBarBackgroundBottomBorder = UIView(frame: CGRectMake(CGRectGetMinX(view.bounds), CGRectGetMaxY(view.bounds), CGRectGetWidth(view.bounds), 0.5))
        statusBarBackgroundBottomBorder.autoresizingMask = .FlexibleWidth
        view.backgroundColor = UIColor.whiteColor()
        statusBarBackgroundBottomBorder.backgroundColor = UIColor.lightGrayColor()
        view.addSubview(statusBarBackgroundBottomBorder)

        return view
    }()
    
    lazy var closeButton:UIButton = {
        let button = UIButton(frame: CGRectZero)
        
        button.setImage(UIImage(named: "close"), forState: UIControlState.Normal)
        button.tintColor = UIColor.blackColor()
        button.addTarget(self, action: #selector(WMFTableOfContentsPresentationController.didTap(_:)), forControlEvents: .TouchUpInside)
        
        button.accessibilityHint = localizedStringForKeyFallingBackOnEnglish("table-of-contents-close-accessibility-hint")
        button.accessibilityLabel = localizedStringForKeyFallingBackOnEnglish("table-of-contents-close-accessibility-label")

        return button
    }()

    lazy var backgroundView :UIVisualEffectView = {
        let view = UIVisualEffectView(frame: CGRectZero)
        view.autoresizingMask = .FlexibleWidth
        view.effect = UIBlurEffect(style: .Light)
        view.alpha = 0.0
        let tap = UITapGestureRecognizer.init()
        tap.addTarget(self, action: #selector(WMFTableOfContentsPresentationController.didTap(_:)))
        view.addGestureRecognizer(tap)
        view.addSubview(self.statusBarBackground)
        view.addSubview(self.closeButton)
        
        return view
    }()
    
    func updateButtonConstraints() {
        self.closeButton.mas_remakeConstraints({ make in
            make.width.equalTo()(44)
            make.height.equalTo()(44)
            switch self.displaySide {
            case WMFTableOfContentsDisplaySideLeft:
                make.trailing.equalTo()(self.closeButton.superview!.mas_trailing).offset()(0 - self.closeButtonLeadingPadding)
                if(self.traitCollection.verticalSizeClass == .Compact){
                    make.top.equalTo()(self.closeButtonTopPadding)
                }else{
                    make.top.equalTo()(self.closeButtonTopPadding + self.statusBarEstimatedHeight)
                }
                break
            case WMFTableOfContentsDisplaySideRight:
                make.leading.equalTo()(self.closeButton.superview!.mas_leading).offset()(self.closeButtonLeadingPadding)
                if(self.traitCollection.verticalSizeClass == .Compact){
                    make.top.equalTo()(self.closeButtonTopPadding)
                }else{
                    make.top.equalTo()(self.closeButtonTopPadding + self.statusBarEstimatedHeight)
                }
                break
            case WMFTableOfContentsDisplaySideCenter:
                fallthrough
            default:
                make.leading.equalTo()(self.closeButton.superview!.mas_leading).offset()(self.closeButtonLeadingPadding)
                make.bottom.equalTo()(self.closeButton.superview!.mas_bottom).offset()(self.closeButtonTopPadding)
            }
            return ()
        })
    }

    
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
        
        updateButtonConstraints()

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
        var bgWidth = self.minimumVisibleBackgroundWidth
        var tocWidth = frame.size.width - bgWidth
        if(tocWidth > self.maximumTableOfContentsWidth){
            tocWidth = self.maximumTableOfContentsWidth
            bgWidth = frame.size.width - tocWidth
        }
        
        switch displaySide {
        case WMFTableOfContentsDisplaySideCenter:
            frame.origin.x += 0.5*bgWidth
            frame.size.height -= 70
            break
        case WMFTableOfContentsDisplaySideRight:
            frame.origin.x += bgWidth
            break
        default:
            break
        }
        
        frame.origin.y = UIApplication.sharedApplication().statusBarFrame.size.height + 0.5;
        frame.size.width = tocWidth
        
        return frame
    }
    
    override public func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator transitionCoordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: transitionCoordinator)

        transitionCoordinator.animateAlongsideTransition({(context: UIViewControllerTransitionCoordinatorContext!) -> Void in
            self.backgroundView.frame = self.containerView!.bounds
            let frame = self.frameOfPresentedViewInContainerView()
            self.presentedView()!.frame = frame


            }, completion:nil)
    }
    
    override public func willTransitionToTraitCollection(newCollection: UITraitCollection, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        
        super.willTransitionToTraitCollection(newCollection, withTransitionCoordinator: coordinator)
        
        if newCollection.verticalSizeClass == .Compact
        {
            self.statusBarBackground.hidden = true;
            
        }
        
        if newCollection.verticalSizeClass == .Regular
        {
            self.statusBarBackground.hidden = false;
        }
        
        coordinator.animateAlongsideTransition({(context: UIViewControllerTransitionCoordinatorContext!) -> Void in
            self.updateButtonConstraints()
            
            }, completion:nil)

    }
}
