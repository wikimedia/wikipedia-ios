@objc(WMFArticleCollectionViewCell)
open class ArticleCollectionViewCell: UICollectionViewCell {
    let titleLabel = UILabel()
    let descriptionLabel = UILabel()
    let imageView = UIImageView()
    let saveButton = SaveButton()
    var extractLabel: UILabel?
    
    private var kvoButtonTitleContext = 0

    // MARK - Initialization & setup
    
    open func setup() {
        tintColor = UIColor.wmf_blueTint
        imageView.contentMode = .scaleAspectFill
        imageView.masksToBounds = true
        imageView.wmf_showPlaceholder()
        addSubview(imageView)
        addSubview(titleLabel)
        addSubview(descriptionLabel)
        descriptionLabel.textColor = UIColor.wmf_customGray
        addSubview(saveButton)
        saveButton.tintColor = UIColor.wmf_blueTint
        saveButton.setTitleColor(UIColor.wmf_blueTint, for: .normal)
        saveButton.saveButtonState = .longSave
        saveButton.addObserver(self, forKeyPath: "titleLabel.text", options: .new, context: &kvoButtonTitleContext)
        backgroundColor = .white
        layoutSubviews()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    // MARK - Cell lifecycle
    
    open override func prepareForReuse() {
        super.prepareForReuse()
        imageView.wmf_reset()
        imageView.wmf_showPlaceholder()
        saveButton.saveButtonState = .longSave
    }
    
    // MARK - View configuration
    
    var imageViewHeight: CGFloat = 150 {
        didSet {
            setNeedsLayout()
        }
    }
    
    var isImageViewHidden = false {
        didSet {
            imageView.isHidden = isImageViewHidden
            setNeedsLayout()
        }
    }
    
    var isSaveButtonHidden = false {
        didSet {
            saveButton.isHidden = isSaveButtonHidden
            setNeedsLayout()
        }
    }
    
    // MARK - Dynamic type
    
    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        saveButton.titleLabel?.font = UIFont.wmf_preferredFontForFontFamily(.systemMedium, withTextStyle: .subheadline, compatibleWithTraitCollection: traitCollection)
        descriptionLabel.font = UIFont.wmf_preferredFontForFontFamily(.system, withTextStyle: .subheadline, compatibleWithTraitCollection: traitCollection)
        titleLabel.font = UIFont.wmf_preferredFontForFontFamily(.georgia, withTextStyle: .title1, compatibleWithTraitCollection: traitCollection)
        extractLabel?.font = UIFont.wmf_preferredFontForFontFamily(.system, withTextStyle: .subheadline, compatibleWithTraitCollection: traitCollection)
    }
    
    // MARK - Layout
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        let size = bounds.size
        let _ = sizeThatFits(size, apply: true)
        updateAccessibilityElements()
    }
    
    open func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        return size
    }
    
    open override func sizeThatFits(_ size: CGSize) -> CGSize {
        return sizeThatFits(size, apply: false)
    }
    
    public final func layout(for label: UILabel, x: CGFloat, y: CGFloat, width: CGFloat, apply: Bool) -> CGFloat {
        guard label.wmf_hasText else {
            return y
        }
        return layout(forView: label, x: x, y: y, width: width, apply: apply) + 6
    }
    
    public final func layout(forView view: UIView, x: CGFloat, y: CGFloat, width: CGFloat, apply: Bool) -> CGFloat {
        let sizeToFit = CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
        let viewSize = view.sizeThatFits(sizeToFit)
        if apply {
            var actualX = x
            let actualWidth = min(viewSize.width, width)
            if view.wmf_isRightToLeft {
                actualX = x + width - actualWidth
            }
            view.frame = CGRect(x: actualX, y: y, width: actualWidth, height: viewSize.height)
        }
        return y + viewSize.height
    }
    
    open override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        if let attributesToFit = layoutAttributes as? WMFCVLAttributes, attributesToFit.precalculated {
            return attributesToFit
        }
        
        var sizeToFit = layoutAttributes.size
        sizeToFit.height = CGFloat.greatestFiniteMagnitude
        var fitSize = self.sizeThatFits(sizeToFit)
        if fitSize == sizeToFit {
            return layoutAttributes
        } else  if let attributes = layoutAttributes.copy() as? UICollectionViewLayoutAttributes {
            fitSize.width = sizeToFit.width
            if fitSize.height == CGFloat.greatestFiniteMagnitude {
                fitSize.height = layoutAttributes.size.height
            }
            attributes.frame = CGRect(origin: layoutAttributes.frame.origin, size: fitSize)
            return attributes
        } else {
            return layoutAttributes
        }
    }
    
    // MARK - Accessibility
    
    func updateAccessibilityElements() {
        var updatedAccessibilityElements: [Any] = []
        var groupedLabels = [titleLabel, descriptionLabel]
        if let extract = extractLabel {
            groupedLabels.append(extract)
        }
        updatedAccessibilityElements.append(LabelGroupAccessibilityElement(view: self, labels: groupedLabels))
        
        if !isSaveButtonHidden {
            updatedAccessibilityElements.append(saveButton)
        }
        
        accessibilityElements = updatedAccessibilityElements
    }
    
    // MARK - KVO
    
    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &kvoButtonTitleContext {
            setNeedsLayout()
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
}
