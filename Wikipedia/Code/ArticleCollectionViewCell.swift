import WMFComponents

open class ArticleCollectionViewCell: CollectionViewCell, SwipeableCell, BatchEditableCell {
    public let titleLabel = UILabel()
    public let descriptionLabel = UILabel()
    public let imageView = UIImageView()
    public var extractLabel: UILabel?
    public let actionsView = ActionsView()
    public var alertButton = AlignedImageButton()
    open var alertType: ReadingListAlertType?
    public var alertButtonCallback: (() -> Void)?
    
    public var statusView = UIImageView() // the circle that appears next to the article name to indicate the article's status

    private var _titleHTML: String? = nil
    private var _titleBoldedString: String? = nil

    public var theme: Theme = Theme.standard

    private func updateTitleLabel() {
        if let titleHTML = _titleHTML {
            let attributedTitle = NSMutableAttributedString.mutableAttributedStringFromHtml(titleHTML, styles: styles)
            if let boldString = _titleBoldedString, let boldFont {
                let boldUIFont = WMFFont.for(boldFont, compatibleWith: traitCollection)
                let range = (attributedTitle.string as NSString).range(of: boldString, options: .caseInsensitive)
                if range.location != NSNotFound {
                    attributedTitle.addAttribute(.font, value: boldUIFont, range: range)
                }
            }
            titleLabel.attributedText = attributedTitle
        } else {
            let titleFont = WMFFont.for(.callout, compatibleWith: traitCollection)
            titleLabel.font = titleFont
        }
    }
    
    public var titleHTML: String? {
        get {
            return _titleHTML
        }
        set {
            _titleHTML = newValue
            updateTitleLabel()
        }
    }
    
    public func setTitleHTML(_ titleHTML: String?, boldedString: String?) {
        _titleHTML = titleHTML
        _titleBoldedString = boldedString
        updateTitleLabel()
    }
    
    public var actions: [Action] {
        get {
            return actionsView.actions
        }
        set {
            actionsView.actions = newValue
            updateAccessibilityElements()
        }
    }

    open override func setup() {
        updateStyles()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        statusView.clipsToBounds = true
        
        imageView.accessibilityIgnoresInvertColors = true
        
        titleLabel.isOpaque = true
        descriptionLabel.isOpaque = true
        imageView.isOpaque = true
        
        contentView.addSubview(alertButton)
        alertButton.addTarget(self, action: #selector(alertButtonTapped), for: .touchUpInside)
        alertButton.verticalPadding = spacing
        alertButton.leftPadding = spacing
        alertButton.rightPadding = spacing
        alertButton.horizontalSpacing = spacing
        contentView.addSubview(statusView)

        contentView.addSubview(imageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(descriptionLabel)
        
        super.setup()
    }
    
    // This method is called to reset the cell to the default configuration. It is called on initial setup and prepareForReuse. Subclassers should call super.
    override open func reset() {
        super.reset()
        _titleHTML = nil
        _titleBoldedString = nil
        updateStyles()
        descriptionTextStyle  = .subheadline
        extractTextStyle  = .subheadline
        saveButtonTextStyle  = .mediumFootnote
        spacing = 3
        imageViewDimension = 70
        statusViewDimension = 6
        imageView.wmf_reset()
        resetSwipeable()
        isBatchEditing = false
        isBatchEditable = false
        actions = []
        isAlertButtonHidden = true
        isStatusViewHidden = true
        updateFonts(with: traitCollection)
    }
    
    open func updateStyles() {
        styles =  HtmlUtils.Styles(font: WMFFont.for(.georgiaTitle3, compatibleWith: traitCollection), boldFont: WMFFont.for(.boldGeorgiaTitle3, compatibleWith: traitCollection), italicsFont: WMFFont.for(.italicGeorgiaTitle3, compatibleWith: traitCollection), boldItalicsFont: WMFFont.for(.boldItalicGeorgiaTitle3, compatibleWith: traitCollection), color: theme.colors.primaryText, linkColor: theme.colors.link, lineSpacing: 1)
    }

    override open func updateBackgroundColorOfLabels() {
        super.updateBackgroundColorOfLabels()
        titleLabel.backgroundColor = labelBackgroundColor
        descriptionLabel.backgroundColor = labelBackgroundColor
        extractLabel?.backgroundColor = labelBackgroundColor
        alertButton.titleLabel?.backgroundColor = labelBackgroundColor
    }
    
    open override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        if swipeState == .open {
            swipeTranslation = swipeTranslationWhenOpen
        }
        setNeedsLayout()
    }

    var actionsViewInsets: UIEdgeInsets {
        return safeAreaInsets
    }
    
    public final var statusViewDimension: CGFloat = 0 {
        didSet {
            setNeedsLayout()
        }
    }
    
    public final var alertIconDimension: CGFloat = 0 {
        didSet {
            setNeedsLayout()
        }
    }
    
    public var isStatusViewHidden: Bool = true {
        didSet {
            statusView.isHidden = isStatusViewHidden
            setNeedsLayout()
        }
    }
    
    public var isAlertButtonHidden: Bool = true {
        didSet {
            alertButton.isHidden = isAlertButtonHidden
            setNeedsLayout()
        }
    }
    
    public var isDeviceRTL: Bool {
        return effectiveUserInterfaceLayoutDirection == .rightToLeft
    }
    
    public var isArticleRTL: Bool {
        return articleSemanticContentAttribute == .forceRightToLeft
    }
    
    open override func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        let size = super.sizeThatFits(size, apply: apply)
        if apply {
            let layoutMargins = calculatedLayoutMargins
            let isBatchEditOnRight = isDeviceRTL
            var batchEditSelectViewWidth: CGFloat = 0
            var batchEditX: CGFloat = 0

            if isBatchEditingPaneOpen {
                if isArticleRTL {
                    batchEditSelectViewWidth = isBatchEditOnRight ? layoutMargins.left : layoutMargins.right // left and and right here are really leading and trailing, should change to UIDirectionalEdgeInsets when available
                } else {
                    batchEditSelectViewWidth = isBatchEditOnRight ? layoutMargins.right : layoutMargins.left
                }
                if isBatchEditOnRight {
                    batchEditX = size.width - batchEditSelectViewWidth
                } else {
                    batchEditX = 0
                }
            } else {
                if isBatchEditOnRight {
                    batchEditX = size.width
                } else {
                    batchEditX = 0 - batchEditSelectViewWidth
                }
            }
            
            let safeX = isBatchEditOnRight ? safeAreaInsets.right : safeAreaInsets.left
            batchEditSelectViewWidth -= safeX
            if !isBatchEditOnRight && isBatchEditingPaneOpen {
                batchEditX += safeX
            }
            if isBatchEditOnRight && !isBatchEditingPaneOpen {
                batchEditX -= batchEditSelectViewWidth
            }
            
            batchEditSelectView?.frame = CGRect(x: batchEditX, y: 0, width: batchEditSelectViewWidth, height: size.height)
            batchEditSelectView?.layoutIfNeeded()
            
            let actionsViewWidth = isDeviceRTL ? max(0, swipeTranslation) : -1 * min(0, swipeTranslation)
            let x = isDeviceRTL ? 0 : size.width - actionsViewWidth
            actionsView.frame = CGRect(x: x, y: 0, width: actionsViewWidth, height: size.height)
            actionsView.layoutIfNeeded()
        }
        return size
    }
    
    // MARK: - View configuration
    // These properties can mutate with each use of the cell. They should be reset by the `reset` function. Call setsNeedLayout after adjusting any of these properties
    public var styles: HtmlUtils.Styles!
    public var boldFont: WMFFont!
    public var descriptionTextStyle: WMFFont!
    public var extractTextStyle: WMFFont!
    public var saveButtonTextStyle: WMFFont!

    public var imageViewDimension: CGFloat = 0 // used as height on full width cell, width & height on right aligned
    public var spacing: CGFloat = 3

    public var isImageViewHidden = false {
        didSet {
            imageView.isHidden = isImageViewHidden
            setNeedsLayout()
        }
    }

    open override func updateFonts(with traitCollection: UITraitCollection) {
        super.updateFonts(with: traitCollection)

        updateTitleLabel()
        
        descriptionLabel.font = WMFFont.for(descriptionTextStyle, compatibleWith: traitCollection)
        extractLabel?.font = WMFFont.for(extractTextStyle, compatibleWith: traitCollection)
        alertButton.titleLabel?.font = WMFFont.for(.boldCaption1, compatibleWith: traitCollection)
    }
    
    // MARK: - Semantic content
    
    fileprivate var _articleSemanticContentAttribute: UISemanticContentAttribute = .unspecified
    fileprivate var _effectiveArticleSemanticContentAttribute: UISemanticContentAttribute = .unspecified
    open var articleSemanticContentAttribute: UISemanticContentAttribute {
        get {
            return _effectiveArticleSemanticContentAttribute
        }
        set {
            _articleSemanticContentAttribute = newValue
            updateEffectiveArticleSemanticContentAttribute()
            setNeedsLayout()
        }
    }

    // for items like the Save Button that are localized and should match the UI direction
    public var userInterfaceSemanticContentAttribute: UISemanticContentAttribute {
        return traitCollection.layoutDirection == .rightToLeft ? .forceRightToLeft : .forceLeftToRight
    }
    
    fileprivate func updateEffectiveArticleSemanticContentAttribute() {
        if _articleSemanticContentAttribute == .unspecified {
            let isRTL = effectiveUserInterfaceLayoutDirection == .rightToLeft
            _effectiveArticleSemanticContentAttribute = isRTL ? .forceRightToLeft : .forceLeftToRight
        } else {
            _effectiveArticleSemanticContentAttribute = _articleSemanticContentAttribute
        }
        let alignment = _effectiveArticleSemanticContentAttribute == .forceRightToLeft ? NSTextAlignment.right : NSTextAlignment.left
        titleLabel.textAlignment = alignment
        titleLabel.semanticContentAttribute = _effectiveArticleSemanticContentAttribute
        descriptionLabel.semanticContentAttribute = _effectiveArticleSemanticContentAttribute
        descriptionLabel.textAlignment = alignment
        extractLabel?.semanticContentAttribute = _effectiveArticleSemanticContentAttribute
        extractLabel?.textAlignment = alignment
    }
    
    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        updateEffectiveArticleSemanticContentAttribute()
        super.traitCollectionDidChange(previousTraitCollection)
    }
    
    // MARK: - Accessibility
    
    open override func updateAccessibilityElements() {
        var updatedAccessibilityElements: [Any] = []
        var groupedLabels = [titleLabel, descriptionLabel]
        if let extract = extractLabel {
            groupedLabels.append(extract)
        }

        updatedAccessibilityElements.append(LabelGroupAccessibilityElement(view: self, labels: groupedLabels, actions: actions))
        
        accessibilityElements = updatedAccessibilityElements
    }
    
    // MARK: - Swipeable
    var swipeState: SwipeState = .closed {
        didSet {
            if swipeState != .closed && actionsView.superview == nil {
                contentView.addSubview(actionsView)
                contentView.backgroundColor = backgroundView?.backgroundColor
                clipsToBounds = true
            } else if swipeState == .closed && actionsView.superview != nil {
                actionsView.removeFromSuperview()
                contentView.backgroundColor = .clear
                clipsToBounds = false
            }
        }
    }
    
    public var swipeTranslation: CGFloat = 0 {
        didSet {
            assert(!swipeTranslation.isNaN && swipeTranslation.isFinite)
            let isArticleRTL = articleSemanticContentAttribute == .forceRightToLeft
            if isArticleRTL {
                layoutMarginsInteractiveAdditions.left = 0 - swipeTranslation
                layoutMarginsInteractiveAdditions.right = swipeTranslation
            } else {
                layoutMarginsInteractiveAdditions.right = 0 - swipeTranslation
                layoutMarginsInteractiveAdditions.left = swipeTranslation
            }
            setNeedsLayout()
        }
    }
    
    open var isSwipeEnabled: Bool {
        return true
    }
    
    private var isBatchEditingPaneOpen: Bool {
        return batchEditingTranslation > 0
    }

    private var batchEditingTranslation: CGFloat = 0 {
        didSet {
            let marginAddition = batchEditingTranslation / 1.5

            if isArticleRTL {
                if isDeviceRTL {
                    layoutMarginsInteractiveAdditions.left = marginAddition
                } else {
                    layoutMarginsInteractiveAdditions.right = marginAddition
                }
            } else {
                if isDeviceRTL {
                    layoutMarginsInteractiveAdditions.right = marginAddition
                } else {
                    layoutMarginsInteractiveAdditions.left = marginAddition
                }
            }
            
            if isBatchEditingPaneOpen, let batchEditSelectView = batchEditSelectView {
                contentView.addSubview(batchEditSelectView)
                batchEditSelectView.clipsToBounds = true
            }
            setNeedsLayout()
        }
    }

    public override func layoutWidth(for size: CGSize) -> CGFloat {
        let layoutWidth = super.layoutWidth(for: size) - layoutMarginsInteractiveAdditions.left - layoutMarginsInteractiveAdditions.right
        return layoutWidth
    }

    public var swipeTranslationWhenOpen: CGFloat {
        let maxWidth = actionsView.maximumWidth
        let isRTL = effectiveUserInterfaceLayoutDirection == .rightToLeft
        return isRTL ? actionsViewInsets.left + maxWidth : 0 - maxWidth - actionsViewInsets.right
    }

    // MARK: Prepare for reuse
    
    func resetSwipeable() {
        swipeTranslation = 0
        swipeState = .closed
    }
    
    // MARK: - BatchEditableCell
    
    public var batchEditSelectView: BatchEditSelectView?

    public var isBatchEditable: Bool = false {
        didSet {
            if isBatchEditable && batchEditSelectView == nil {
                batchEditSelectView = BatchEditSelectView()
                batchEditSelectView?.isSelected = isSelected
            } else if !isBatchEditable && batchEditSelectView != nil {
                batchEditSelectView?.removeFromSuperview()
                batchEditSelectView = nil
            }
        }
    }
    
    public var isBatchEditing: Bool = false {
        didSet {
            if isBatchEditing {
                isBatchEditable = true
                batchEditingTranslation = BatchEditSelectView.fixedWidth
                batchEditSelectView?.isSelected = isSelected
            } else {
                batchEditingTranslation = 0
            }
        }
    }
    
    override open var isSelected: Bool {
        didSet {
            batchEditSelectView?.isSelected = isSelected
        }
    }
    
    // MARK: - Actions
    
    @objc func alertButtonTapped() {
        alertButtonCallback?()
    }
}
