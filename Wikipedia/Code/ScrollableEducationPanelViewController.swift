import UIKit

typealias ScrollableEducationPanelButtonTapHandler = ((_ sender: Any) -> ())
typealias ScrollableEducationPanelDismissHandler = (() -> ())
typealias ScrollableEducationPanelTraceableDismissHandler = ((ScrollableEducationPanelViewController.LastAction) -> ())

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
    
    enum LastAction {
        case tappedPrimary
        case tappedSecondary
        case tappedClose
        case tappedBackground
        case none
    }
    
    @IBOutlet fileprivate weak var closeButton: UIButton!
    @IBOutlet fileprivate weak var imageView: UIImageView!
    @IBOutlet fileprivate weak var headingLabel: UILabel!
    @IBOutlet fileprivate weak var subheadingLabel: UILabel!
    
    //use as an indication of what triggered a dismissal
    private var lastAction: LastAction = .none
    
    let originalSubheadingTopConstraint = CGFloat(0)
    let originalSubheadingBottomConstraint = CGFloat(0)
    
    @IBOutlet var subheadingTopConstraint: NSLayoutConstraint! {
        didSet {
            subheadingTopConstraint.constant = originalSubheadingTopConstraint
        }
    }
    
    @IBOutlet var subheadingBottomConstraint: NSLayoutConstraint! {
       didSet {
           subheadingBottomConstraint.constant = originalSubheadingBottomConstraint
       }
    }
    
    @IBOutlet fileprivate weak var primaryButton: AutoLayoutSafeMultiLineButton!
    @IBOutlet fileprivate weak var secondaryButton: AutoLayoutSafeMultiLineButton!
    @IBOutlet fileprivate weak var footerTextView: UITextView!

    @IBOutlet fileprivate weak var scrollViewContainer: UIView!
    @IBOutlet fileprivate weak var stackView: UIStackView!
    @IBOutlet fileprivate weak var roundedCornerContainer: UIView!

    fileprivate var primaryButtonTapHandler: ScrollableEducationPanelButtonTapHandler?
    fileprivate var secondaryButtonTapHandler: ScrollableEducationPanelButtonTapHandler?
    
    //traceableDismissHandler takes priority if it's populated. It will pass back a LastAction indicating the action that triggered the dismissal, for the caller to react with.
    fileprivate var dismissHandler: ScrollableEducationPanelDismissHandler?
    fileprivate var traceableDismissHandler: ScrollableEducationPanelTraceableDismissHandler?
    
    fileprivate var showCloseButton = true
    private var discardDismissHandlerOnPrimaryButtonTap = false
    private var primaryButtonTapped = false
    var theme: Theme = Theme.standard

    @IBOutlet private var widthConstraint: NSLayoutConstraint!
    @IBOutlet private var buttonTopSpacingConstraint: NSLayoutConstraint!
    @IBOutlet private var stackViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet private var stackViewTrailingConstraint: NSLayoutConstraint!

    var width: CGFloat = 280 {
        didSet {
            widthConstraint.constant = width
        }
    }
    
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

    var subheadingHTML: String? {
        didSet {
            guard let html = subheadingHTML else {
                subheadingLabel.attributedText = nil
                return
            }
            let attributedText = html.byAttributingHTML(with: .subheadline,
                                                        boldWeight: .bold,
                                                        matching: traitCollection,
                                                        color: theme.colors.primaryText,
                                                        tagMapping: ["em": "i"], // em tags are generally italicized by default, match this behavior
                                                        additionalTagAttributes: [
                "u": [
                    NSAttributedString.Key.underlineColor: theme.colors.error,
                    NSAttributedString.Key.underlineStyle: NSNumber(value: NSUnderlineStyle.single.rawValue)
                ],
                "strong": [
                    NSAttributedString.Key.foregroundColor: theme.colors.primaryText
                ]
            ])
            
            var attributes: [NSAttributedString.Key : Any] = [:]
            if let subheadingParagraphStyle = subheadingParagraphStyle {
                attributes[NSAttributedString.Key.paragraphStyle] = subheadingParagraphStyle
            }
            attributedText.addAttributes(attributes, range: NSMakeRange(0, attributedText.length))
            subheadingLabel.attributedText = attributedText
        }
    }

    var subheadingTextAlignment: NSTextAlignment = .center {
        didSet {
            subheadingLabel.textAlignment = subheadingTextAlignment
        }
    }

    var contentHorizontalPadding: CGFloat = 15 {
        didSet {
            stackViewLeadingConstraint.constant = contentHorizontalPadding
            stackViewTrailingConstraint.constant = contentHorizontalPadding
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
            return footerTextView.text
        }
        set {
            footerTextView.text = newValue
            view.setNeedsLayout()
        }
    }

    var footerHTML: String? {
        didSet {
            updateFooterHTML()
        }
    }

    var footerLinkAction: ((URL) -> Void)? = nil
    
    var subheadingParagraphStyle: NSParagraphStyle? {
        let pStyle = NSMutableParagraphStyle()
        pStyle.lineHeightMultiple = 1.2
        return pStyle.copy() as? NSParagraphStyle
    }
    
    var footerParagraphStyle: NSParagraphStyle? {
        let pStyle = NSMutableParagraphStyle()
        pStyle.lineBreakMode = .byWordWrapping
        pStyle.baseWritingDirection = .natural
        return pStyle.copy() as? NSParagraphStyle
    }

    private func updateFooterHTML() {
        guard let footerHTML = footerHTML else {
            footerTextView.attributedText = nil
            return
        }
        let attributedText = footerHTML.byAttributingHTML(with: .footnote, matching: traitCollection, color: footerTextView.textColor)
        let pStyle = NSMutableParagraphStyle()
        pStyle.lineBreakMode = .byWordWrapping
        pStyle.baseWritingDirection = .natural
        var attributes: [NSAttributedString.Key : Any] = [:]
        if let footerParagraphStyle = footerParagraphStyle {
            attributes[NSAttributedString.Key.paragraphStyle] = footerParagraphStyle
        }
        attributedText.addAttributes(attributes, range: NSMakeRange(0, attributedText.length))
        footerTextView.attributedText = attributedText
    }

    var primaryButtonBorderWidth: CGFloat = 1 {
        didSet {
            primaryButton?.layer.borderWidth = primaryButtonBorderWidth
        }
    }
    
    var isUrgent: Bool = false
    var spacing: CGFloat = 14 {
        didSet {
            stackView.spacing = spacing
        }
    }

    var buttonCornerRadius: CGFloat = 5 {
        didSet {
            primaryButton.cornerRadius = buttonCornerRadius
        }
    }

    var buttonTopSpacing: CGFloat = 0 {
        didSet {
            buttonTopSpacingConstraint.constant = buttonTopSpacing
        }
    }

    var primaryButtonTitleEdgeInsets: UIEdgeInsets = UIEdgeInsets(top: 10, left: 14, bottom: 10, right: 14) {
        didSet {
            primaryButton.titleEdgeInsets = primaryButtonTitleEdgeInsets
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
    
    init(showCloseButton: Bool, primaryButtonTapHandler: ScrollableEducationPanelButtonTapHandler?, secondaryButtonTapHandler: ScrollableEducationPanelButtonTapHandler?, traceableDismissHandler: ScrollableEducationPanelTraceableDismissHandler?, discardDismissHandlerOnPrimaryButtonTap: Bool = false, theme: Theme) {
        super.init(nibName: "ScrollableEducationPanelView", bundle: nil)
        self.modalPresentationStyle = .overFullScreen
        self.modalTransitionStyle = .crossDissolve
        self.theme = theme
        self.showCloseButton = showCloseButton
        self.primaryButtonTapHandler = primaryButtonTapHandler
        self.secondaryButtonTapHandler = secondaryButtonTapHandler
        self.traceableDismissHandler = traceableDismissHandler
        self.discardDismissHandlerOnPrimaryButtonTap = discardDismissHandlerOnPrimaryButtonTap
    }
    
    required public init?(coder aDecoder: NSCoder) {
        return nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        assert(stackView.wmf_firstArrangedSubviewWithRequiredNonZeroHeightConstraint() == nil, stackView.wmf_anArrangedSubviewHasRequiredNonZeroHeightConstraintAssertString())
        
        reset()
        
        primaryButton.titleLabel?.textAlignment = .center
        secondaryButton.titleLabel?.textAlignment = .center
        
        closeButton.isHidden = !showCloseButton
        [self.view, self.roundedCornerContainer].forEach {view in
            view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.overlayTapped(_:))))
        }
        
        closeButton.setImage(UIImage(named:"places-auth-close")?.withRenderingMode(.alwaysTemplate), for: .normal)
        closeButton.accessibilityLabel = CommonStrings.closeButtonAccessibilityLabel

        updateFonts()

        stackView.spacing = spacing

        footerTextView.delegate = self
        
        apply(theme: theme)
    }

    var dismissWhenTappedOutside: Bool = false
    
    @IBAction func overlayTapped(_ sender: UITapGestureRecognizer) {
        lastAction = .tappedBackground
        if (showCloseButton || dismissWhenTappedOutside) && sender.view == view  {
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
        footerTextView.text = nil
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
        updateFonts()
    }

    var secondaryButtonTextStyle: DynamicTextStyle = .semiboldFootnote {
        didSet {
            updateFonts()
        }
    }

    private func updateFonts() {
        secondaryButton.titleLabel?.font = UIFont.wmf_font(secondaryButtonTextStyle, compatibleWithTraitCollection: traitCollection)
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
        footerTextView.isHidden = !footerTextView.wmf_hasAnyNonWhitespaceText
        primaryButton.isHidden = !primaryButton.wmf_hasAnyNonWhitespaceText
        secondaryButton.isHidden = !secondaryButton.wmf_hasAnyNonWhitespaceText
    }
    
    @IBAction fileprivate func close(_ sender: Any) {
        lastAction = .tappedClose
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction fileprivate func primaryButtonTapped(_ sender: Any) {
        lastAction = .tappedPrimary
        guard let primaryButtonTapHandler = primaryButtonTapHandler else {
            return
        }
        primaryButtonTapped = true
        primaryButtonTapHandler(sender)
    }

    @IBAction fileprivate func secondaryButtonTapped(_ sender: Any) {
        lastAction = .tappedSecondary
        guard let secondaryButtonTapHandler = secondaryButtonTapHandler else {
            return
        }
        secondaryButtonTapHandler(sender)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        callDismissHandler()
    }
    
    func callDismissHandler() {
        
        guard !(discardDismissHandlerOnPrimaryButtonTap && primaryButtonTapped) else {
            return
        }
        
        if let traceableDismissHandler = traceableDismissHandler {
            traceableDismissHandler(lastAction)
            return
        }
        
        dismissHandler?()
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
        footerTextView?.textColor = theme.colors.secondaryText
        closeButton.tintColor = theme.colors.primaryText
        primaryButton?.tintColor = theme.colors.link
        secondaryButton?.tintColor = theme.colors.secondaryText
        primaryButton?.layer.borderColor = theme.colors.link.cgColor
        primaryButton.backgroundColor = theme.colors.cardButtonBackground

        if isUrgent {
            roundedCornerContainer.layer.borderWidth = 3
            roundedCornerContainer.layer.borderColor = theme.colors.error.cgColor
        } else {
            roundedCornerContainer.layer.borderWidth = 0
        }
        roundedCornerContainer.backgroundColor = theme.colors.cardBackground
        updateFooterHTML()
    }
}

extension ScrollableEducationPanelViewController: UITextViewDelegate {
    public func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        footerLinkAction?(URL)
        return false
    }
}
