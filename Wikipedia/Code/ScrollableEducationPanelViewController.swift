import UIKit

typealias ScrollableEducationPanelButtonTapHandler = ((_ sender: Any) -> ())
typealias ScrollableEducationPanelDismissHandler = (() -> ())

/*
 Education panels typically have the following items, from top to bottom:
    == Close button ==
    == Image ==
    == Heading text ==
    == Subheading text ==
    == Primary button ==
    == Secondary button ==
    == Footer text ==
 
 This class pairs with a xib with roughly the following structure:
    view
        scroll view
            stack view
                close button
                image view
                heading label
                subheading label
                primary button
                secondary button
                footer label
 
 - Stackview management of its subviews makes it easy to collapse space for unneeded items.
 - Scrollview containment makes long translations or landscape on small phones scrollable when needed.
*/
class ScrollableEducationPanelViewController: UIViewController, Themeable {
    @IBOutlet fileprivate weak var closeButton: UIButton!
    @IBOutlet fileprivate weak var imageView: UIImageView!
    @IBOutlet fileprivate weak var headingLabel: UILabel!
    @IBOutlet fileprivate weak var subheadingLabel: UILabel!
    @IBOutlet fileprivate weak var primaryButton: UIButton!
    @IBOutlet fileprivate weak var secondaryButton: UIButton!
    @IBOutlet fileprivate weak var footerLabel: UILabel!

    @IBOutlet fileprivate weak var scrollViewContainer: UIView!
    @IBOutlet fileprivate weak var stackView: UIStackView!
    @IBOutlet fileprivate weak var roundedCornerContainer: UIView!
    @IBOutlet fileprivate weak var effectsView: UIVisualEffectView!

    fileprivate var primaryButtonTapHandler: ScrollableEducationPanelButtonTapHandler?
    fileprivate var secondaryButtonTapHandler: ScrollableEducationPanelButtonTapHandler?
    fileprivate var dismissHandler: ScrollableEducationPanelDismissHandler?
    fileprivate var showCloseButton = true
    private var discardDismissHandlerOnPrimaryButtonTap = false
    private var primaryButtonTapped = false
    private var theme: Theme = Theme.standard
    
    var image:UIImage? {
        get {
            return imageView.image
        }
        set {
            imageView.image = newValue
            view.setNeedsLayout() // Ensures stackview will collapse if image is set to nil.
        }
    }

    var heading:String? {
        get {
            return headingLabel.text
        }
        set {
            headingLabel.text = newValue
            view.setNeedsLayout()
        }
    }

    var subheading:String? {
        get {
            return subheadingLabel.text
        }
        set {
            subheadingLabel.text = newValue
            view.setNeedsLayout()
        }
    }

    var primaryButtonTitle:String? {
        get {
            return primaryButton.title(for: .normal)
        }
        set {
            primaryButton.setTitle(newValue, for: .normal)
            view.setNeedsLayout()
        }
    }

    var secondaryButtonTitle:String? {
        get {
            return secondaryButton.title(for: .normal)
        }
        set {
            secondaryButton.setTitle(newValue, for: .normal)
            view.setNeedsLayout()
        }
    }

    var footer:String? {
        get {
            return footerLabel.text
        }
        set {
            footerLabel.text = newValue
            view.setNeedsLayout()
        }
    }
    
    init(showCloseButton: Bool, primaryButtonTapHandler: ScrollableEducationPanelButtonTapHandler?, secondaryButtonTapHandler: ScrollableEducationPanelButtonTapHandler?, dismissHandler: ScrollableEducationPanelDismissHandler?, discardDismissHandlerOnPrimaryButtonTap: Bool = false, theme: Theme) {
        super.init(nibName: "ScrollableEducationPanelView", bundle: nil)
        self.modalPresentationStyle = .overFullScreen
        self.modalTransitionStyle = .crossDissolve
        self.theme = theme
        self.showCloseButton = showCloseButton
        self.primaryButtonTapHandler = primaryButtonTapHandler
        self.secondaryButtonTapHandler = secondaryButtonTapHandler
        self.dismissHandler = dismissHandler
        self.discardDismissHandlerOnPrimaryButtonTap = discardDismissHandlerOnPrimaryButtonTap
    }
    required public init?(coder aDecoder: NSCoder) {
        return nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        assert(stackView.wmf_firstArrangedSubviewWithRequiredNonZeroHeightConstraint() == nil, stackView.wmf_anArrangedSubviewHasRequiredNonZeroHeightConstraintAssertString())
        
        reset()
        primaryButton.titleLabel?.wmf_configureToAutoAdjustFontSize()
        secondaryButton.titleLabel?.numberOfLines = 2
        secondaryButton?.titleLabel?.adjustsFontSizeToFitWidth = true
        secondaryButton.titleLabel?.textAlignment = .center
        closeButton.isHidden = !showCloseButton
        [self.view, self.roundedCornerContainer].forEach {view in
            view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.overlayTapped(_:))))
        }
        
        closeButton.setImage(UIImage(named:"places-auth-close")?.withRenderingMode(.alwaysTemplate), for: .normal)
        
        apply(theme: theme)
    }
    
    @IBAction func overlayTapped(_ sender: UITapGestureRecognizer) {
        if (showCloseButton && sender.view == view) {
            dismiss(animated: true, completion: nil)
        }
    }
    
    // Clear out xib defaults. Needed because we check these for nil to conditionally collapse stackview subviews.
    fileprivate func reset() {
        imageView.image = nil
        headingLabel.text = nil
        subheadingLabel.text = nil
        primaryButton.setTitle(nil, for: .normal)
        secondaryButton.setTitle(nil, for: .normal)
        footerLabel.text = nil
    }
    
    override func viewWillAppear(_ animated: Bool) {
        adjustStackViewSubviewsVisibility()
        super.viewWillAppear(animated)
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        adjustImageViewVisibility(for: newCollection.verticalSizeClass)
        // Call to 'layoutIfNeeded' is required to ensure changes made in 'adjustImageViewVisibility' are
        // reflected correctly on rotation.
        view.layoutIfNeeded()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        secondaryButton.titleLabel?.setFont(with: .systemSemiBold, style: .caption2, traitCollection: traitCollection)
    }
    
    fileprivate func adjustImageViewVisibility(for verticalSizeClass: UIUserInterfaceSizeClass) {
        imageView.isHidden = (imageView.image == nil || verticalSizeClass == .compact)
    }
    
    fileprivate func adjustStackViewSubviewsVisibility() {
        // Collapse stack view cell for image if no image or compact vertical size class.
        adjustImageViewVisibility(for: traitCollection.verticalSizeClass)
        // Collapse stack view cells for labels/buttons if no text.
        headingLabel.isHidden = !headingLabel.wmf_hasAnyNonWhitespaceText
        subheadingLabel.isHidden = !subheadingLabel.wmf_hasAnyNonWhitespaceText
        footerLabel.isHidden = !footerLabel.wmf_hasAnyNonWhitespaceText
        primaryButton.isHidden = !primaryButton.wmf_hasAnyNonWhitespaceText
        secondaryButton.isHidden = !secondaryButton.wmf_hasAnyNonWhitespaceText
    }
    
    @IBAction fileprivate func close(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction fileprivate func primaryButtonTapped(_ sender: Any) {
        guard let primaryButtonTapHandler = primaryButtonTapHandler else {
            return
        }
        primaryButtonTapped = true
        primaryButtonTapHandler(sender)
    }

    @IBAction fileprivate func secondaryButtonTapped(_ sender: Any) {
        guard let secondaryButtonTapHandler = secondaryButtonTapHandler else {
            return
        }
        secondaryButtonTapHandler(sender)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        guard let dismissHandler = dismissHandler else {
            return
        }
        guard !(discardDismissHandlerOnPrimaryButtonTap && primaryButtonTapped) else {
            return
        }
        dismissHandler()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        primaryButtonTapped = false
    }
    
    func apply(theme: Theme) {
        self.theme = theme
        guard viewIfLoaded != nil else {
            return
        }
        headingLabel?.textColor = theme.colors.primaryText
        subheadingLabel?.textColor = theme.colors.primaryText
        footerLabel?.textColor = theme.colors.primaryText
        closeButton.tintColor = theme.colors.primaryText
        primaryButton?.tintColor = theme.colors.link
        secondaryButton?.tintColor = theme.colors.link
        primaryButton?.layer.borderColor = theme.colors.link.cgColor
        
        effectsView.effect = UIBlurEffect(style: theme.colors.blurEffectStyle)
        effectsView.backgroundColor = theme.colors.blurEffectBackground
    }
}
