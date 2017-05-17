import UIKit

@objc(WMFArticleCollectionViewCell)
open class ArticleCollectionViewCell: CollectionViewCell {
    let titleLabel = UILabel()
    let descriptionLabel = UILabel()
    let imageView = UIImageView()
    let saveButton = SaveButton()
    var extractLabel: UILabel?
    
    private var kvoButtonTitleContext = 0
    
    open override func setup() {
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
        super.setup()
    }
    
    deinit {
        saveButton.removeObserver(self, forKeyPath: "titleLabel.text", context: &kvoButtonTitleContext)
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
    
    // MARK - Semantic content
    
    open var articleSemanticContentAttribute: UISemanticContentAttribute = .forceLeftToRight {
        didSet {
            titleLabel.semanticContentAttribute = articleSemanticContentAttribute
            descriptionLabel.semanticContentAttribute = articleSemanticContentAttribute
            extractLabel?.semanticContentAttribute = articleSemanticContentAttribute
        }
    }
    
    // MARK - Accessibility
    
    open override func updateAccessibilityElements() {
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
