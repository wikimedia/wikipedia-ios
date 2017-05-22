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
        tintColor = UIColor.wmf_blue
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.wmf_showPlaceholder()
        addSubview(imageView)
        addSubview(titleLabel)
        addSubview(descriptionLabel)
        descriptionLabel.textColor = UIColor.wmf_customGray
        addSubview(saveButton)
        saveButton.tintColor = UIColor.wmf_blue
        saveButton.setTitleColor(UIColor.wmf_blue, for: .normal)
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
    
    var titleFontFamily = WMFFontFamily.georgia
    var titleTextStyle  = UIFontTextStyle.title1
    
    var descriptionFontFamily = WMFFontFamily.system
    var descriptionTextStyle  = UIFontTextStyle.subheadline
    
    var extractFontFamily = WMFFontFamily.system
    var extractTextStyle  = UIFontTextStyle.subheadline
    
    var saveButtonFontFamily = WMFFontFamily.systemMedium
    var saveButtonTextStyle  = UIFontTextStyle.subheadline
    
    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        titleLabel.font = UIFont.wmf_preferredFontForFontFamily(titleFontFamily, withTextStyle: titleTextStyle, compatibleWithTraitCollection: traitCollection)
        descriptionLabel.font = UIFont.wmf_preferredFontForFontFamily(descriptionFontFamily, withTextStyle:  descriptionTextStyle, compatibleWithTraitCollection: traitCollection)
        extractLabel?.font = UIFont.wmf_preferredFontForFontFamily(extractFontFamily, withTextStyle: extractTextStyle, compatibleWithTraitCollection: traitCollection)
        saveButton.titleLabel?.font = UIFont.wmf_preferredFontForFontFamily(saveButtonFontFamily, withTextStyle: saveButtonTextStyle, compatibleWithTraitCollection: traitCollection)
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
