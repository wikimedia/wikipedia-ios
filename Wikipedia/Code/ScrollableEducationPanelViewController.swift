import WMFComponents
import WMF

typealias ScrollableEducationPanelButtonTapHandler = ((_ button: UIButton, _ viewController: UIViewController) -> Void)
typealias ScrollableEducationPanelDismissHandler = (() -> Void)
typealias ScrollableEducationPanelTraceableDismissHandler = ((ScrollableEducationPanelViewController.LastAction) -> Void)

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
        case tappedOptional
        case tappedClose
        case tappedBackground
        case none
    }

    
    /// Enum for customizing button styles
    /// `legacyStyle` stands for the default apperance
    /// `updatedStyle` stands for the component-like style
    enum ButtonStyle {
        case legacyStyle
        case updatedStyle
    }

    @IBOutlet fileprivate weak var inlineCloseButton: UIButton!
    @IBOutlet fileprivate weak var pinnedCloseButton: UIButton!
    @IBOutlet fileprivate weak var imageView: UIImageView!
    @IBOutlet fileprivate weak var headingLabel: UILabel!
    @IBOutlet weak var subheadingTextView: UITextView!
    
    @IBOutlet weak var inlineActionButtonContainerView: UIView!
    @IBOutlet weak var inlineCloseButtonStackView: UIStackView!
    @IBOutlet weak var pinnedCloseButtonContainerView: UIView!
    @IBOutlet weak var pinnedActionButtonContainerView: UIView!
    @IBOutlet weak var pinnedCloseButtonStackView: UIStackView!
    
    // use as an indication of what triggered a dismissal
    private var lastAction: LastAction = .none
    
    let originalSubheadingTopConstraint = CGFloat(0)
    let originalSubheadingBottomConstraint = CGFloat(0)
    
    @IBOutlet var subheadingTopConstraint: NSLayoutConstraint! {
        didSet {
            subheadingTopConstraint.constant = originalSubheadingTopConstraint
        }
    }
    
    @IBOutlet weak var containerStackViewBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet var subheadingBottomConstraint: NSLayoutConstraint! {
       didSet {
           subheadingBottomConstraint.constant = originalSubheadingBottomConstraint
       }
    }
    
    @IBOutlet fileprivate weak var inlinePrimaryButton: AutoLayoutSafeMultiLineButton!
    @IBOutlet weak var inlinePrimaryButtonSpinner: UIActivityIndicatorView!
    @IBOutlet fileprivate weak var pinnedPrimaryButton: AutoLayoutSafeMultiLineButton!
    @IBOutlet fileprivate weak var inlineSecondaryButton: AutoLayoutSafeMultiLineButton!
    @IBOutlet fileprivate weak var pinnedSecondaryButton: AutoLayoutSafeMultiLineButton!
    @IBOutlet fileprivate weak var footerTextView: UITextView!

    @IBOutlet fileprivate weak var inlineOptionalButton: AutoLayoutSafeMultiLineButton!

    @IBOutlet private(set) weak var scrollView: UIScrollView!
    @IBOutlet fileprivate weak var scrollViewContainer: UIView!
    @IBOutlet fileprivate weak var roundedCornerContainer: UIView!
    
    @IBOutlet weak var gradientViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var gradientViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var gradientView: ScrollViewGradientView!
    
    fileprivate var primaryButtonTapHandler: ScrollableEducationPanelButtonTapHandler?
    fileprivate var secondaryButtonTapHandler: ScrollableEducationPanelButtonTapHandler?
    fileprivate var optionalButtonTapHandler: ScrollableEducationPanelButtonTapHandler?

    // traceableDismissHandler takes priority if it's populated. It will pass back a LastAction indicating the action that triggered the dismissal, for the caller to react with.
    fileprivate var dismissHandler: ScrollableEducationPanelDismissHandler?
    fileprivate var traceableDismissHandler: ScrollableEducationPanelTraceableDismissHandler?
    
    fileprivate var showCloseButton = true
    fileprivate var buttonStyle: ButtonStyle = .legacyStyle
    private(set) public var showOptionalButton = false
    private var discardDismissHandlerOnPrimaryButtonTap = false
    private var primaryButtonTapped = false
    var theme: Theme = Theme.standard

    @IBOutlet weak var imageHeightConstraint: NSLayoutConstraint!
    @IBOutlet private var widthConstraint: NSLayoutConstraint!
    @IBOutlet private var buttonTopSpacingConstraint: NSLayoutConstraint!
    @IBOutlet weak var contentStackView: UIStackView!

    @IBOutlet weak var separatorView: UIView!
    var width: CGFloat = 280 {
        didSet {
            widthConstraint.constant = width
        }
    }
    
    var image: UIImage? {
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
            return subheadingTextView.attributedText.string
        }
        set {
            subheadingHTML = newValue
            updateSubheadingHTML()
        }
    }

    var subheadingHTML: String? {
        didSet {
            updateSubheadingHTML()
            view.setNeedsLayout()
        }
    }
    
    var subheadingTextAlignment: NSTextAlignment = .center {
        didSet {
            updateSubheadingHTML()
        }
    }

    var contentHorizontalPadding: CGFloat = 15 {
        didSet {
            let oldLayoutMargins = contentStackView.directionalLayoutMargins
            contentStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: oldLayoutMargins.top, leading: contentHorizontalPadding, bottom: oldLayoutMargins.bottom, trailing: contentHorizontalPadding)
        }
    }

    var primaryButtonTitle:String? {
        get {
            return inlinePrimaryButton.title(for: .normal)
        }
        set {
            inlinePrimaryButton.setTitle(newValue, for: .normal)
            pinnedPrimaryButton.setTitle(newValue, for: .normal)
            view.setNeedsLayout()
        }
    }

    var secondaryButtonTitle:String? {
        get {
            return inlineSecondaryButton.title(for: .normal)
        }
        set {
            inlineSecondaryButton.setTitle(newValue, for: .normal)
            pinnedSecondaryButton.setTitle(newValue, for: .normal)
            view.setNeedsLayout()
        }
    }

    var optionalButtonTitle: String? {
        get {
            return inlineOptionalButton.title(for: .normal)
        }
        set {
            inlineOptionalButton.setTitle(newValue, for: .normal)
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
    
    var isLoading: Bool = false {
        didSet {
            if isLoading {
                inlinePrimaryButtonSpinner.startAnimating()
                inlinePrimaryButtonSpinner.isHidden = false
                inlinePrimaryButton.titleLabel?.alpha = 0
            } else {
                inlinePrimaryButtonSpinner.stopAnimating()
                inlinePrimaryButton.titleLabel?.alpha = 1
                inlinePrimaryButtonSpinner.isHidden = true
            }
            
        }
    }

    var footerLinkAction: ((URL) -> Void)? = nil
    var subheadingLinkAction: ((URL) -> Void)? = nil
    
    var subheadingParagraphStyle: NSParagraphStyle? {
        let pStyle = NSMutableParagraphStyle()
        pStyle.lineHeightMultiple = 1.2
        pStyle.alignment = subheadingTextAlignment
        return pStyle.copy() as? NSParagraphStyle
    }
    
    private func updateSubheadingHTML() {
        guard let subheadingHTML = subheadingHTML else {
            subheadingTextView.attributedText = nil
            return
        }

        let styles = HtmlUtils.Styles(font: WMFFont.for(.subheadline, compatibleWith: traitCollection), boldFont: WMFFont.for(.boldSubheadline, compatibleWith: traitCollection), italicsFont: WMFFont.for(.italicSubheadline, compatibleWith: traitCollection), boldItalicsFont: WMFFont.for(.boldItalicSubheadline, compatibleWith: traitCollection), color: theme.colors.primaryText, linkColor: theme.colors.link, lineSpacing: 1)

        let attributedText =  NSMutableAttributedString.mutableAttributedStringFromHtml(subheadingHTML, styles: styles)
        var attributes: [NSAttributedString.Key : Any] = [:]
        if let subheadingParagraphStyle = subheadingParagraphStyle {
            attributes[NSAttributedString.Key.paragraphStyle] = subheadingParagraphStyle
        }
        attributedText.addAttributes(attributes, range: NSRange(location: 0, length: attributedText.length))
        
        subheadingTextView.attributedText = attributedText.removingInitialNewlineCharacters().removingRepetitiveNewlineCharacters()
        subheadingTextView.linkTextAttributes = [.foregroundColor: theme.colors.link]
        subheadingTextView.tintColor = theme.colors.link
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
        let styles = HtmlUtils.Styles(font: WMFFont.for(.footnote, compatibleWith: traitCollection), boldFont: WMFFont.for(.boldFootnote, compatibleWith: traitCollection), italicsFont: WMFFont.for(.italicFootnote, compatibleWith: traitCollection), boldItalicsFont: WMFFont.for(.boldItalicFootnote, compatibleWith: traitCollection), color: theme.colors.primaryText, linkColor: theme.colors.link, lineSpacing: 1)
        let attributedText = NSMutableAttributedString.mutableAttributedStringFromHtml(footerHTML, styles: styles)
        let pStyle = NSMutableParagraphStyle()
        pStyle.lineBreakMode = .byWordWrapping
        pStyle.baseWritingDirection = .natural
        var attributes: [NSAttributedString.Key : Any] = [:]
        if let footerParagraphStyle = footerParagraphStyle {
            attributes[NSAttributedString.Key.paragraphStyle] = footerParagraphStyle
        }
        attributedText.addAttributes(attributes, range: NSRange(location: 0, length: attributedText.length))
        footerTextView.attributedText = attributedText
        footerTextView.linkTextAttributes = [NSAttributedString.Key.foregroundColor: theme.colors.link]
        footerTextView.textContainerInset = .zero
    }

    var primaryButtonBorderWidth: CGFloat = 0 {
        didSet {
            inlinePrimaryButton?.layer.borderWidth = primaryButtonBorderWidth
        }
    }
    
    var isUrgent: Bool = false
    private let hasPinnedButtons: Bool
    
    var spacing: CGFloat = 14 {
        didSet {
            contentStackView.spacing = spacing
        }
    }

    var buttonCornerRadius: CGFloat = 5 {
        didSet {
            inlinePrimaryButton.cornerRadius = buttonCornerRadius
            pinnedPrimaryButton.cornerRadius = buttonCornerRadius
        }
    }

    var buttonTopSpacing: CGFloat = 0 {
        didSet {
            buttonTopSpacingConstraint.constant = buttonTopSpacing
        }
    }

    var primaryButtonTitleEdgeInsets: UIEdgeInsets = UIEdgeInsets(top: 10, left: 14, bottom: 10, right: 14) {
        didSet {
            var deprecatedInlinePrimaryButton = inlinePrimaryButton as DeprecatedButton
            var deprecatedPinnedPrimaryButton = pinnedPrimaryButton as DeprecatedButton
            deprecatedInlinePrimaryButton.deprecatedTitleEdgeInsets = primaryButtonTitleEdgeInsets
            deprecatedPinnedPrimaryButton.deprecatedTitleEdgeInsets = primaryButtonTitleEdgeInsets
        }
    }

    init(showCloseButton: Bool, primaryButtonTapHandler: ScrollableEducationPanelButtonTapHandler?, secondaryButtonTapHandler: ScrollableEducationPanelButtonTapHandler?, dismissHandler: ScrollableEducationPanelDismissHandler?, discardDismissHandlerOnPrimaryButtonTap: Bool = false, hasPinnedButtons: Bool = false, theme: Theme) {
        self.hasPinnedButtons = hasPinnedButtons
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
    
    init(showCloseButton: Bool, showOptionalButton: Bool = false, buttonStyle: ButtonStyle = .legacyStyle, primaryButtonTapHandler: ScrollableEducationPanelButtonTapHandler?, secondaryButtonTapHandler: ScrollableEducationPanelButtonTapHandler?, optionalButtonTapHandler: ScrollableEducationPanelButtonTapHandler? = nil,traceableDismissHandler: ScrollableEducationPanelTraceableDismissHandler?, discardDismissHandlerOnPrimaryButtonTap: Bool = false, hasPinnedButtons: Bool = false, theme: Theme) {
        self.hasPinnedButtons = hasPinnedButtons
        super.init(nibName: "ScrollableEducationPanelView", bundle: nil)
        self.modalPresentationStyle = .overFullScreen
        self.modalTransitionStyle = .crossDissolve
        self.theme = theme
        self.showCloseButton = showCloseButton
        self.showOptionalButton = showOptionalButton
        self.buttonStyle = buttonStyle
        self.primaryButtonTapHandler = primaryButtonTapHandler
        self.secondaryButtonTapHandler = secondaryButtonTapHandler
        self.optionalButtonTapHandler = optionalButtonTapHandler
        self.traceableDismissHandler = traceableDismissHandler
        self.discardDismissHandlerOnPrimaryButtonTap = discardDismissHandlerOnPrimaryButtonTap
    }
    
    required public init?(coder aDecoder: NSCoder) {
        return nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        assert(contentStackView.wmf_firstArrangedSubviewWithRequiredNonZeroHeightConstraint() == nil, contentStackView.wmf_anArrangedSubviewHasRequiredNonZeroHeightConstraintAssertString())
        
        reset()
        
        inlinePrimaryButton.titleLabel?.textAlignment = .center
        pinnedPrimaryButton.titleLabel?.textAlignment = .center
        inlineSecondaryButton.titleLabel?.textAlignment = .center
        pinnedSecondaryButton.titleLabel?.textAlignment = .center
        inlineOptionalButton.titleLabel?.textAlignment = .center

        inlineCloseButton.isHidden = !showCloseButton
        pinnedCloseButton.isHidden = !showCloseButton
        inlineOptionalButton.isHidden = !showOptionalButton
        separatorView.isHidden = buttonStyle == .legacyStyle ? true : false
        [self.view, self.roundedCornerContainer].forEach {view in
            view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.overlayTapped(_:))))
        }
        
        inlineCloseButton.setImage(UIImage(named:"places-auth-close")?.withRenderingMode(.alwaysTemplate), for: .normal)
        inlineCloseButton.accessibilityLabel = CommonStrings.closeButtonAccessibilityLabel
        pinnedCloseButton.setImage(UIImage(named:"places-auth-close")?.withRenderingMode(.alwaysTemplate), for: .normal)
        pinnedCloseButton.accessibilityLabel = CommonStrings.closeButtonAccessibilityLabel

        updateFonts()

        contentStackView.spacing = spacing

        footerTextView.delegate = self
        subheadingTextView.delegate = self
        
        if hasPinnedButtons {
            inlineCloseButtonStackView.alpha = 0
            inlineActionButtonContainerView.alpha = 0
            pinnedCloseButtonContainerView.alpha = 1
            pinnedActionButtonContainerView.alpha = 1
        } else {
            inlineCloseButtonStackView.alpha = 1
            inlineActionButtonContainerView.alpha = 1
            pinnedCloseButtonContainerView.alpha = 0
            pinnedActionButtonContainerView.alpha = 0
        }

        if buttonStyle == .updatedStyle {
            inlineCloseButtonStackView.alignment = .trailing
            inlineCloseButton.isHidden = false

            let image = UIImage(systemName: "xmark.circle.fill")?.withTintColor(theme.colors.secondaryText, renderingMode: .alwaysOriginal)
            let button = UIButton(type: .system)
            button.setImage(image, for: .normal)
            inlineCloseButton.setImage(image, for: .normal)
            inlineCloseButtonStackView.layoutMargins = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
            inlineCloseButtonStackView.isLayoutMarginsRelativeArrangement = true
        }
        
        inlinePrimaryButtonSpinner.isHidden = true

        apply(theme: theme)
    }

    var dismissWhenTappedOutside: Bool = false
    
    @IBAction func overlayTapped(_ sender: UITapGestureRecognizer) {
        lastAction = .tappedBackground
        if (showCloseButton || dismissWhenTappedOutside) && sender.view == view {
            dismiss(animated: true, completion: nil)
        }
    }
    
    // Clear out xib defaults. Needed because we check these for nil to conditionally collapse stackview subviews.
    fileprivate func reset() {
        imageView.image = nil
        headingLabel.text = nil
        subheadingTextView.attributedText = nil
        inlinePrimaryButton.setTitle(nil, for: .normal)
        pinnedPrimaryButton.setTitle(nil, for: .normal)
        inlineSecondaryButton.setTitle(nil, for: .normal)
        pinnedSecondaryButton.setTitle(nil, for: .normal)
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

    var secondaryButtonTextStyle: WMFFont = .mediumFootnote {
        didSet {
            updateFonts()
        }
    }

    var optionalButtonTextStyle: WMFFont = .boldSubheadline {
        didSet {
            updateFonts()
        }
    }

    private func updateFonts() {

        switch buttonStyle {
        case .legacyStyle:
            inlineSecondaryButton.titleLabel?.font = WMFFont.for(secondaryButtonTextStyle, compatibleWith: traitCollection)
            pinnedSecondaryButton.titleLabel?.font = WMFFont.for(secondaryButtonTextStyle, compatibleWith: traitCollection)

            inlineOptionalButton.titleLabel?.font = WMFFont.for(secondaryButtonTextStyle, compatibleWith: traitCollection)
        case .updatedStyle:
            inlinePrimaryButton.titleLabel?.font = WMFFont.for(optionalButtonTextStyle, compatibleWith: traitCollection)
            inlineSecondaryButton.titleLabel?.font = WMFFont.for(optionalButtonTextStyle, compatibleWith: traitCollection)
            inlineOptionalButton.titleLabel?.font = WMFFont.for(optionalButtonTextStyle, compatibleWith: traitCollection)
        }
    }
    
    fileprivate func adjustImageViewVisibility(for verticalSizeClass: UIUserInterfaceSizeClass) {
        imageView.isHidden = (imageView.image == nil || verticalSizeClass == .compact)
    }
    
    fileprivate func adjustStackViewSubviewsVisibility() {
        // Collapse stack view cell for image if no image or compact vertical size class.
        adjustImageViewVisibility(for: traitCollection.verticalSizeClass)
        // Collapse stack view cells for labels/buttons if no text.
        headingLabel.isHidden = !headingLabel.wmf_hasAnyNonWhitespaceText
        subheadingTextView.isHidden = !subheadingTextView.wmf_hasAnyNonWhitespaceText
        footerTextView.isHidden = !footerTextView.wmf_hasAnyNonWhitespaceText
        inlinePrimaryButton.isHidden = !inlinePrimaryButton.wmf_hasAnyNonWhitespaceText
        pinnedPrimaryButton.isHidden = !pinnedPrimaryButton.wmf_hasAnyNonWhitespaceText
        inlineSecondaryButton.isHidden = !inlineSecondaryButton.wmf_hasAnyNonWhitespaceText
        pinnedSecondaryButton.isHidden = !inlineSecondaryButton.wmf_hasAnyNonWhitespaceText
    }
    
    @IBAction fileprivate func close(_ sender: Any) {
        lastAction = .tappedClose
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction fileprivate func primaryButtonTapped(_ button: UIButton) {
        lastAction = .tappedPrimary
        guard let primaryButtonTapHandler = primaryButtonTapHandler else {
            return
        }
        primaryButtonTapped = true
        primaryButtonTapHandler(button, self)
    }

    @IBAction fileprivate func secondaryButtonTapped(_ button: UIButton) {
        lastAction = .tappedSecondary
        guard let secondaryButtonTapHandler = secondaryButtonTapHandler else {
            return
        }
        secondaryButtonTapHandler(button, self)
    }

    @IBAction fileprivate func optionalButtonTapped(_ button: UIButton) {
        lastAction = .tappedOptional
        guard let optionalButtonTapHandler = optionalButtonTapHandler else {
            return
        }
        optionalButtonTapHandler(button, self)
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
        inlineCloseButton.tintColor = theme.colors.primaryText
        pinnedCloseButton.tintColor = theme.colors.primaryText
        inlinePrimaryButton?.tintColor = theme.colors.link
        pinnedPrimaryButton?.tintColor = theme.colors.link
        inlineSecondaryButton?.tintColor = theme.colors.secondaryText
        pinnedSecondaryButton?.tintColor = theme.colors.secondaryText
        inlinePrimaryButton?.layer.borderColor = theme.colors.link.cgColor
        pinnedPrimaryButton?.layer.borderColor = theme.colors.link.cgColor
        inlinePrimaryButton.backgroundColor = theme.colors.baseBackground
        pinnedPrimaryButton.backgroundColor = theme.colors.baseBackground
        inlineOptionalButton.backgroundColor = theme.colors.baseBackground
        separatorView.backgroundColor = theme.colors.border.withAlphaComponent(0.2)

        if isUrgent {
            gradientViewTopConstraint.constant = 3
            gradientViewBottomConstraint.constant = -3
            roundedCornerContainer.layer.borderWidth = 3
            roundedCornerContainer.layer.borderColor = theme.colors.error.cgColor
        } else {
            roundedCornerContainer.layer.borderWidth = 0
        }
        roundedCornerContainer.backgroundColor = theme.colors.cardBackground
        pinnedActionButtonContainerView.backgroundColor = theme.colors.cardBackground
        pinnedCloseButtonContainerView.backgroundColor = theme.colors.cardBackground
        updateSubheadingHTML()
        updateFooterHTML()

        if buttonStyle == .updatedStyle {
            inlinePrimaryButton.backgroundColor = theme.colors.link
            inlinePrimaryButton.setTitleColor(theme.colors.paperBackground, for: .normal)

            inlineSecondaryButton.backgroundColor = .clear
            inlineSecondaryButton.setTitleColor(theme.colors.link, for: .normal)

            inlineOptionalButton.backgroundColor = .clear
            inlineOptionalButton.setTitleColor(theme.colors.link, for: .normal)
        }
        
        self.inlinePrimaryButtonSpinner.color = theme.colors.paperBackground
    }
}

extension ScrollableEducationPanelViewController: UITextViewDelegate {
    public func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        if textView == footerTextView {
            footerLinkAction?(URL)
        } else if textView == subheadingTextView {
            subheadingLinkAction?(URL)
        }
        
        return false
    }
}
