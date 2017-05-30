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
        titleFontFamily = .georgia
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
        prepareForReuse()
        super.setup()
    }
    
    // This method is called to reset the cell to the default configuration. It is called on initial setup and prepareForReuse.
    open func reset() {
        backgroundColor = .white
        titleFontFamily = .georgia
        titleTextStyle = .title1
        descriptionFontFamily = .system
        descriptionTextStyle  = .subheadline
        extractFontFamily = .system
        extractTextStyle  = .subheadline
        saveButtonFontFamily = .systemMedium
        saveButtonTextStyle  = .subheadline
        margins = UIEdgeInsetsMake(15, 13, 15, 13)
        spacing = 6
        imageViewDimension = 70
        saveButtonTopSpacing = 10
    }
    
    deinit {
        saveButton.removeObserver(self, forKeyPath: "titleLabel.text", context: &kvoButtonTitleContext)
    }
    
    // MARK - Cell lifecycle
    
    open override func prepareForReuse() {
        super.prepareForReuse()
        reset()
        imageView.wmf_reset()
        imageView.wmf_showPlaceholder()
    }
    
    // MARK - View configuration
    // These properties can mutate with each use of the cell. They should be reset by the `reset` function. Call setsNeedLayout after adjusting any of these properties
    
    var titleFontFamily: WMFFontFamily!
    var titleTextStyle: UIFontTextStyle!
    
    var descriptionFontFamily: WMFFontFamily!
    var descriptionTextStyle: UIFontTextStyle!
    
    var extractFontFamily: WMFFontFamily!
    var extractTextStyle: UIFontTextStyle!
    
    var saveButtonFontFamily: WMFFontFamily!
    var saveButtonTextStyle: UIFontTextStyle!
    
    var imageViewDimension: CGFloat! //used as height on full width cell, width & height on right aligned
    var margins: UIEdgeInsets!
    var spacing: CGFloat!
    var saveButtonTopSpacing: CGFloat!
    
    var isImageViewHidden = false {
        didSet {
            imageView.isHidden = isImageViewHidden
        }
    }
    
    var isSaveButtonHidden = false {
        didSet {
            saveButton.isHidden = isSaveButtonHidden
        }
    }
    
    open override func setNeedsLayout() {
        updateLabelFonts()
        super.setNeedsLayout()
    }
    
    // MARK - Dynamic type
    
    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateLabelFonts()
    }
    
    open func updateLabelFonts() {
        titleLabel.font = UIFont.wmf_preferredFontForFontFamily(titleFontFamily, withTextStyle: titleTextStyle, compatibleWithTraitCollection: traitCollection)
        descriptionLabel.font = UIFont.wmf_preferredFontForFontFamily(descriptionFontFamily, withTextStyle:  descriptionTextStyle, compatibleWithTraitCollection: traitCollection)
        extractLabel?.font = UIFont.wmf_preferredFontForFontFamily(extractFontFamily, withTextStyle: extractTextStyle, compatibleWithTraitCollection: traitCollection)
        saveButton.titleLabel?.font = UIFont.wmf_preferredFontForFontFamily(saveButtonFontFamily, withTextStyle: saveButtonTextStyle, compatibleWithTraitCollection: traitCollection)
    }
    
    // MARK - Semantic content
    
    open var articleSemanticContentAttribute: UISemanticContentAttribute = .unspecified {
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
