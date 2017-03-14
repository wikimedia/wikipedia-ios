import UIKit
import Masonry

// MARK: - Delegate
@objc public protocol WMFTableOfContentsPresentationControllerTapDelegate {
    
    func tableOfContentsPresentationControllerDidTapBackground(_ controller: WMFTableOfContentsPresentationController)
}

open class WMFTableOfContentsPresentationController: UIPresentationController {
    
    var displaySide = WMFTableOfContentsDisplaySide.left
    var displayMode = WMFTableOfContentsDisplayMode.modal
    
    // MARK: - init
    public required init(presentedViewController: UIViewController, presentingViewController: UIViewController?, tapDelegate: WMFTableOfContentsPresentationControllerTapDelegate) {
        self.tapDelegate = tapDelegate
        super.init(presentedViewController: presentedViewController, presenting: presentedViewController)
    }

    weak open var tapDelegate: WMFTableOfContentsPresentationControllerTapDelegate?

    open var minimumVisibleBackgroundWidth: CGFloat = 60.0
    open var maximumTableOfContentsWidth: CGFloat = 300.0
    open var closeButtonLeadingPadding: CGFloat = 10.0
    open var closeButtonTopPadding: CGFloat = 0.0
    open var statusBarEstimatedHeight: CGFloat = 20.0
    
    // MARK: - Views
    lazy var statusBarBackground: UIView = {
        let view = UIView(frame: CGRect(x: self.containerView!.bounds.minX, y: self.containerView!.bounds.minY, width: self.containerView!.bounds.width, height: self.statusBarEstimatedHeight))
        view.autoresizingMask = .flexibleWidth
        let statusBarBackgroundBottomBorder = UIView(frame: CGRect(x: view.bounds.minX, y: view.bounds.maxY, width: view.bounds.width, height: 0.5))
        statusBarBackgroundBottomBorder.autoresizingMask = .flexibleWidth
        view.backgroundColor = UIColor.white
        statusBarBackgroundBottomBorder.backgroundColor = UIColor.lightGray
        view.addSubview(statusBarBackgroundBottomBorder)

        return view
    }()
    
    lazy var closeButton:UIButton = {
        let button = UIButton(frame: CGRect.zero)
        
        button.setImage(UIImage(named: "close"), for: UIControlState())
        button.tintColor = UIColor.black
        button.addTarget(self, action: #selector(WMFTableOfContentsPresentationController.didTap(_:)), for: .touchUpInside)
        
        button.accessibilityHint = localizedStringForKeyFallingBackOnEnglish("table-of-contents-close-accessibility-hint")
        button.accessibilityLabel = localizedStringForKeyFallingBackOnEnglish("table-of-contents-close-accessibility-label")

        return button
    }()

    lazy var backgroundView :UIVisualEffectView = {
        let view = UIVisualEffectView(frame: CGRect.zero)
        view.autoresizingMask = .flexibleWidth
        view.effect = UIBlurEffect(style: .light)
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
            _ = make?.width.equalTo()(44)
            _ = make?.height.equalTo()(44)
            switch self.displaySide {
            case .left:
                _ = make?.trailing.equalTo()(self.closeButton.superview!.mas_trailing)?.offset()(0 - self.closeButtonLeadingPadding)
                if(self.traitCollection.verticalSizeClass == .compact){
                    _ = make?.top.equalTo()(self.closeButtonTopPadding)
                }else{
                    _ = make?.top.equalTo()(self.closeButtonTopPadding + self.statusBarEstimatedHeight)
                }
                break
            case .right:
                _ = make?.leading.equalTo()(self.closeButton.superview!.mas_leading)?.offset()(self.closeButtonLeadingPadding)
                if(self.traitCollection.verticalSizeClass == .compact){
                    _ = make?.top.equalTo()(self.closeButtonTopPadding)
                }else{
                    _ = make?.top.equalTo()(self.closeButtonTopPadding + self.statusBarEstimatedHeight)
                }
                break
            case .center:
                fallthrough
            default:
                _ = make?.leading.equalTo()(self.closeButton.superview!.mas_leading)?.offset()(self.closeButtonLeadingPadding)
                _ = make?.bottom.equalTo()(self.closeButton.superview!.mas_bottom)?.offset()(self.closeButtonTopPadding)
            }
            return ()
        })
    }

    
    func didTap(_ tap: UITapGestureRecognizer) {
        self.tapDelegate?.tableOfContentsPresentationControllerDidTapBackground(self);
    }
    
    // MARK: - Accessibility
    func togglePresentingViewControllerAccessibility(_ accessible: Bool) {
        self.presentingViewController.view.accessibilityElementsHidden = !accessible
    }

    // MARK: - UIPresentationController
    override open func presentationTransitionWillBegin() {
        // Add the dimming view and the presented view to the heirarchy
        self.backgroundView.frame = self.containerView!.bounds
        self.containerView!.addSubview(self.backgroundView)
        
        if(self.traitCollection.verticalSizeClass == .compact){
            self.statusBarBackground.isHidden = true
        }
        
        updateButtonConstraints()

        self.containerView!.addSubview(self.presentedView!)
        
        // Hide the presenting view controller for accessibility
        self.togglePresentingViewControllerAccessibility(false)

        switch displaySide {
        case .center:
            self.presentedView?.layer.cornerRadius = 10
            self.presentedView?.clipsToBounds = true
            self.presentedView?.layer.borderColor = UIColor.wmf_lightGray.cgColor
            self.presentedView?.layer.borderWidth = 1.0
            self.closeButton.setImage(UIImage(named: "toc-close-blue"), for: UIControlState())
            self.statusBarBackground.isHidden = true
            break
        default:
            //Add shadow to the presented view
            self.presentedView?.layer.shadowOpacity = 0.5
            self.presentedView?.layer.shadowOffset = CGSize(width: 3, height: 5)
            self.presentedView?.clipsToBounds = false
            self.closeButton.setImage(UIImage(named: "close"), for: UIControlState())
            self.statusBarBackground.isHidden = false
        }
        
        // Fade in the dimming view alongside the transition
        if let transitionCoordinator = self.presentingViewController.transitionCoordinator {
            transitionCoordinator.animate(alongsideTransition: {(context: UIViewControllerTransitionCoordinatorContext!) -> Void in
                self.backgroundView.alpha  = 1.0
                }, completion:nil)
        }
    }
    
    override open func presentationTransitionDidEnd(_ completed: Bool)  {
        if !completed {
            self.backgroundView.removeFromSuperview()

        }
    }
    
    override open func dismissalTransitionWillBegin()  {
        if let transitionCoordinator = self.presentingViewController.transitionCoordinator {
            transitionCoordinator.animate(alongsideTransition: {(context: UIViewControllerTransitionCoordinatorContext!) -> Void in
                self.backgroundView.alpha  = 0.0
                }, completion:nil)
        }

    }
    
    override open func dismissalTransitionDidEnd(_ completed: Bool) {

        if completed {

            self.backgroundView.removeFromSuperview()
            self.togglePresentingViewControllerAccessibility(true)

            self.presentedView?.layer.cornerRadius = 0
            self.presentedView?.layer.borderWidth = 0
            self.presentedView?.layer.shadowOpacity = 0
            self.presentedView?.clipsToBounds = true
        }
    }
    
    override open var frameOfPresentedViewInContainerView : CGRect {
        var frame = self.containerView!.bounds;
        var bgWidth = self.minimumVisibleBackgroundWidth
        var tocWidth = frame.size.width - bgWidth
        if(tocWidth > self.maximumTableOfContentsWidth){
            tocWidth = self.maximumTableOfContentsWidth
            bgWidth = frame.size.width - tocWidth
        }
        
        frame.origin.y = UIApplication.shared.statusBarFrame.size.height + 0.5;
        
        switch displaySide {
        case .center:
            frame.origin.y += 10
            frame.origin.x += 0.5*bgWidth
            frame.size.height -= 80
            break
        case .right:
            frame.origin.x += bgWidth
            break
        default:
            break
        }

        frame.size.width = tocWidth
        
        return frame
    }
    
    override open func viewWillTransition(to size: CGSize, with transitionCoordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: transitionCoordinator)

        transitionCoordinator.animate(alongsideTransition: {(context: UIViewControllerTransitionCoordinatorContext!) -> Void in
            self.backgroundView.frame = self.containerView!.bounds
            let frame = self.frameOfPresentedViewInContainerView
            self.presentedView!.frame = frame


            }, completion:nil)
    }
    
    override open func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        
        super.willTransition(to: newCollection, with: coordinator)
        
        if newCollection.verticalSizeClass == .compact
        {
            self.statusBarBackground.isHidden = true;
            
        }
        
        if newCollection.verticalSizeClass == .regular
        {
            self.statusBarBackground.isHidden = false;
        }
        
        coordinator.animate(alongsideTransition: {(context: UIViewControllerTransitionCoordinatorContext!) -> Void in
            self.updateButtonConstraints()
            
            }, completion:nil)

    }
}
