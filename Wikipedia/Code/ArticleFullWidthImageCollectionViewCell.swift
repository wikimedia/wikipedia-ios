import WMFComponents

@objc(WMFArticleFullWidthImageCollectionViewCell)
open class ArticleFullWidthImageCollectionViewCell: ArticleCollectionViewCell {
    public let saveButton = SaveButton()
    
    fileprivate let headerBackgroundView = UIView()

    public var headerBackgroundColor: UIColor? {
        get {
            return headerBackgroundView.backgroundColor
        }
        set {
            headerBackgroundView.backgroundColor = newValue
            titleLabel.backgroundColor = newValue
            descriptionLabel.backgroundColor = newValue
        }
    }
    
    public var isHeaderBackgroundViewHidden: Bool {
        get {
            return headerBackgroundView.superview == nil
        }
        set {
            if newValue {
                headerBackgroundView.removeFromSuperview()
            } else {
                contentView.insertSubview(headerBackgroundView, at: 0)
            }
        }
    }
    
    var saveButtonObservation: NSKeyValueObservation?
    
    override open func setup() {
        let extractLabel = UILabel()
        extractLabel.isOpaque = true
        extractLabel.numberOfLines = 4
        addSubview(extractLabel)
        self.extractLabel = extractLabel
        super.setup()
        descriptionLabel.numberOfLines = 2
        titleLabel.numberOfLines = 0
        
        saveButton.isOpaque = true
        
        contentView.addSubview(saveButton)
        
        saveButton.verticalPadding = 8
        saveButton.rightPadding = 16
        saveButton.leftPadding = 12
        saveButton.saveButtonState = .longSave
        saveButton.titleLabel?.numberOfLines = 0
        
        saveButtonObservation = saveButton.observe(\.titleLabel?.text) { [weak self] (saveButton, change) in
            self?.setNeedsLayout()
        }
    }
    
    deinit {
        saveButtonObservation?.invalidate()
    }
    
    open override func reset() {
        super.reset()
        spacing = 6
        imageViewDimension = 150
    }
    
    override open func updateStyles() {
        styles = HtmlUtils.Styles(font: WMFFont.for(.georgiaTitle3, compatibleWith: traitCollection), boldFont: WMFFont.for(.boldGeorgiaTitle3, compatibleWith: traitCollection), italicsFont: WMFFont.for(.italicGeorgiaTitle3, compatibleWith: traitCollection), boldItalicsFont: WMFFont.for(.boldItalicGeorgiaTitle3, compatibleWith: traitCollection), color: theme.colors.primaryText, linkColor: theme.colors.link, lineSpacing: 1)
    }
    
    open override func updateBackgroundColorOfLabels() {
        super.updateBackgroundColorOfLabels()
        if !isHeaderBackgroundViewHidden {
            titleLabel.backgroundColor = headerBackgroundColor
            descriptionLabel.backgroundColor = headerBackgroundColor
        }
        saveButton.backgroundColor = labelBackgroundColor
        saveButton.titleLabel?.backgroundColor = labelBackgroundColor
    }
    
    open override func updateFonts(with traitCollection: UITraitCollection) {
        super.updateFonts(with: traitCollection)
        saveButton.titleLabel?.font = WMFFont.for(saveButtonTextStyle, compatibleWith: traitCollection)
    }
    
    public var isSaveButtonHidden = false {
        didSet {
            saveButton.isHidden = isSaveButtonHidden
            setNeedsLayout()
        }
    }
    
    open override var isSwipeEnabled: Bool {
        return isSaveButtonHidden
    }
    
    open override func updateAccessibilityElements() {
        super.updateAccessibilityElements()
        if !isSaveButtonHidden {
            var updatedAccessibilityElements = accessibilityElements ?? []
            updatedAccessibilityElements.append(saveButton)
            accessibilityElements = updatedAccessibilityElements
        }
    }
    
    open override func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        let widthMinusMargins = layoutWidth(for: size)
        var origin = CGPoint(x: layoutMargins.left, y: 0)
        
        if !isImageViewHidden {
            if apply {
                imageView.frame = CGRect(x: 0, y: 0, width: size.width, height: imageViewDimension)
            }
            origin.y += imageViewDimension
        }
        
        origin.y += layoutMargins.top + spacing
        
        origin.y += titleLabel.wmf_preferredHeight(at: origin, maximumWidth: widthMinusMargins, alignedBy: articleSemanticContentAttribute, spacing: spacing, apply: apply)
        origin.y += descriptionLabel.wmf_preferredHeight(at: origin, maximumWidth: widthMinusMargins, alignedBy: articleSemanticContentAttribute, spacing: spacing, apply: apply)
        
        if apply {
            titleLabel.isHidden = !titleLabel.wmf_hasText
            descriptionLabel.isHidden = !descriptionLabel.wmf_hasText
        }
        
        if !isHeaderBackgroundViewHidden && apply {
            headerBackgroundView.frame = CGRect(x: 0, y: 0, width: size.width, height: origin.y)
        }
        
        if let extractLabel = extractLabel, extractLabel.wmf_hasText {
            origin.y += spacing // double spacing before extract
            origin.y += extractLabel.wmf_preferredHeight(at: origin, maximumWidth: widthMinusMargins, alignedBy: articleSemanticContentAttribute, spacing: spacing, apply: apply)
            if apply {
                extractLabel.isHidden = false
            }
        } else if apply {
            extractLabel?.isHidden = true
        }

        if !isSaveButtonHidden {
            origin.y += spacing - 1
            let saveButtonFrame = saveButton.wmf_preferredFrame(at: origin, maximumWidth: widthMinusMargins, horizontalAlignment: isDeviceRTL ? .right : .left, apply: apply)
            origin.y += saveButtonFrame.height - 2 * saveButton.verticalPadding
        } else {
            origin.y += spacing
        }
        
        origin.y += layoutMargins.bottom
        return CGSize(width: size.width, height: origin.y)
    }
}

public class ArticleFullWidthImageExploreCollectionViewCell: ArticleFullWidthImageCollectionViewCell {
    override open func apply(theme: Theme) {
        super.apply(theme: theme)
        setBackgroundColors(theme.colors.cardBackground, selected: theme.colors.selectedCardBackground)
    }
}
