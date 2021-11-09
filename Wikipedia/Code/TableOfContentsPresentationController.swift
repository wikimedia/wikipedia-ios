import UIKit

// MARK: - Delegate
@objc public protocol TableOfContentsPresentationControllerTapDelegate {
    
    func tableOfContentsPresentationControllerDidTapBackground(_ controller: TableOfContentsPresentationController)
}

open class TableOfContentsPresentationController: UIPresentationController, Themeable {
    var theme = Theme.standard
    
    var displaySide = TableOfContentsDisplaySide.left
    var displayMode = TableOfContentsDisplayMode.modal
    
    // MARK: - init
    public required init(presentedViewController: UIViewController, presentingViewController: UIViewController?, tapDelegate: TableOfContentsPresentationControllerTapDelegate) {
        self.tapDelegate = tapDelegate
        super.init(presentedViewController: presentedViewController, presenting: presentedViewController)
    }

    weak open var tapDelegate: TableOfContentsPresentationControllerTapDelegate?

    open var minimumVisibleBackgroundWidth: CGFloat = 60.0
    open var maximumTableOfContentsWidth: CGFloat = 300.0
    open var statusBarEstimatedHeight: CGFloat {
        return max(UIApplication.shared.workaroundStatusBarFrame.size.height, presentedView?.safeAreaInsets.top ?? 0)
    }
    
    // MARK: - Views
    

    
    lazy var statusBarBackground: UIView = {
        let view = UIView(frame: CGRect.zero)
        view.autoresizingMask = .flexibleWidth
        view.layer.shadowOpacity = 0.8
        view.layer.shadowOffset = CGSize(width: 0, height: 5)
        view.clipsToBounds = false
        return view
    }()
    
    lazy var closeButton:UIButton = {
        let button = UIButton(frame: CGRect.zero)
        
        button.setImage(UIImage(named: "close"), for: .normal)
        button.addTarget(self, action: #selector(TableOfContentsPresentationController.didTap(_:)), for: .touchUpInside)
        
        button.accessibilityHint = WMFLocalizedString("table-of-contents-close-accessibility-hint", value:"Close", comment:"Accessibility hint for closing table of contents {{Identical|Close}}")
        button.accessibilityLabel = WMFLocalizedString("table-of-contents-close-accessibility-label", value:"Close Table of contents", comment:"Accessibility label for closing table of contents")

        button.translatesAutoresizingMaskIntoConstraints = false

        return button
    }()

    var closeButtonTrailingConstraint: NSLayoutConstraint?
    var closeButtonLeadingConstraint: NSLayoutConstraint?
    var closeButtonTopConstraint: NSLayoutConstraint?
    var closeButtonBottomConstraint: NSLayoutConstraint?

    lazy var backgroundView :UIVisualEffectView = {
        let view = UIVisualEffectView(frame: CGRect.zero)
        view.autoresizingMask = .flexibleWidth
        view.effect = UIBlurEffect(style: .light)
        view.alpha = 0.0
        let tap = UITapGestureRecognizer.init()
        tap.addTarget(self, action: #selector(TableOfContentsPresentationController.didTap(_:)))
        view.addGestureRecognizer(tap)
        view.contentView.addSubview(self.statusBarBackground)

        let closeButtonDimension: CGFloat = 44
        let widthConstraint = self.closeButton.widthAnchor.constraint(equalToConstant: closeButtonDimension)
        let heightConstraint = self.closeButton.heightAnchor.constraint(equalToConstant: closeButtonDimension)

        let leadingConstraint = view.contentView.layoutMarginsGuide.leadingAnchor.constraint(equalTo: self.closeButton.leadingAnchor, constant: 0)
        let trailingConstraint = view.contentView.layoutMarginsGuide.trailingAnchor.constraint(equalTo: self.closeButton.trailingAnchor, constant: 0)
        let topConstraint = view.contentView.layoutMarginsGuide.topAnchor.constraint(equalTo: self.closeButton.topAnchor, constant: 0)
        let bottomConstraint = view.contentView.layoutMarginsGuide.bottomAnchor.constraint(equalTo: self.closeButton.bottomAnchor, constant: 0)
        trailingConstraint.isActive = false
        bottomConstraint.isActive = false
        closeButtonLeadingConstraint = leadingConstraint
        closeButtonTrailingConstraint = trailingConstraint
        closeButtonTopConstraint = topConstraint
        closeButtonBottomConstraint = bottomConstraint
        self.closeButton.frame = CGRect(x: 0, y: 0, width: closeButtonDimension, height: closeButtonDimension)
        self.closeButton.addConstraints([widthConstraint, heightConstraint])
        view.contentView.addSubview(self.closeButton)
        view.contentView.addConstraints([leadingConstraint, trailingConstraint, topConstraint, bottomConstraint])

        return view
    }()

    func updateStatusBarBackgroundFrame() {
        self.statusBarBackground.frame = CGRect(x: self.backgroundView.bounds.minX, y: self.backgroundView.bounds.minY, width: self.backgroundView.bounds.width, height: self.frameOfPresentedViewInContainerView.origin.y)
    }

    func updateButtonConstraints() {
        switch self.displaySide {
        case .right:
            fallthrough
        case .left:
            closeButtonLeadingConstraint?.isActive = false
            closeButtonBottomConstraint?.isActive = false
            closeButtonTrailingConstraint?.isActive = true
            closeButtonTopConstraint?.isActive = true
            break
        }
        return ()
    }

    
    @objc func didTap(_ tap: UITapGestureRecognizer) {
        self.tapDelegate?.tableOfContentsPresentationControllerDidTapBackground(self)
    }
    
    // MARK: - Accessibility
    func togglePresentingViewControllerAccessibility(_ accessible: Bool) {
        self.presentingViewController.view.accessibilityElementsHidden = !accessible
    }

    // MARK: - UIPresentationController
    override open func presentationTransitionWillBegin() {
        guard let containerView = self.containerView, let presentedView = self.presentedView else {
            return
        }
        
        // Add the dimming view and the presented view to the heirarchy
        self.backgroundView.frame = containerView.bounds
        updateStatusBarBackgroundFrame()

        containerView.addSubview(self.backgroundView)
        
        if(self.traitCollection.verticalSizeClass == .compact){
            self.statusBarBackground.isHidden = true
        }
        
        updateButtonConstraints()

        containerView.addSubview(presentedView)

        // Hide the presenting view controller for accessibility
        self.togglePresentingViewControllerAccessibility(false)

        apply(theme: theme)
        
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
        guard let containerView = containerView else {
            return .zero
        }
        var frame = containerView.bounds
        var bgWidth = self.minimumVisibleBackgroundWidth
        var tocWidth = frame.size.width - bgWidth
        if(tocWidth > self.maximumTableOfContentsWidth){
            tocWidth = self.maximumTableOfContentsWidth
            bgWidth = frame.size.width - tocWidth
        }
        
        frame.origin.y = self.statusBarEstimatedHeight + 0.5
        frame.size.height -= frame.origin.y
        
        switch displaySide {
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
            guard let containerView = self.containerView else {
                return
            }
            self.backgroundView.frame = containerView.bounds
            let frame = self.frameOfPresentedViewInContainerView
            self.presentedView!.frame = frame
            self.updateStatusBarBackgroundFrame()
            self.updateButtonConstraints()
            }, completion:nil)
    }
    
    public func apply(theme: Theme) {
        self.theme = theme
        guard self.containerView != nil else {
            return
        }
        
        //Add shadow to the presented view
        self.presentedView?.layer.shadowOpacity = 0.8
        self.presentedView?.layer.shadowColor = theme.colors.shadow.cgColor
        self.presentedView?.layer.shadowOffset = CGSize(width: 3, height: 5)
        self.presentedView?.clipsToBounds = false
        self.closeButton.setImage(UIImage(named: "close"), for: .normal)
        self.statusBarBackground.isHidden = false
        
        self.backgroundView.effect = UIBlurEffect(style: theme.blurEffectStyle)
        
        self.statusBarBackground.backgroundColor = theme.colors.paperBackground
        self.statusBarBackground.layer.shadowColor = theme.colors.shadow.cgColor

        self.closeButton.tintColor = theme.colors.primaryText
    }
}
