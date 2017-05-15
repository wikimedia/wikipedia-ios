import UIKit

extension UILabel {
    var hasText: Bool {
        return (text as NSString?)?.length ?? 0 > 0
    }
}

extension UIView {
    var wmf_effectiveUserInterfaceLayoutDirection: UIUserInterfaceLayoutDirection {
        if #available(iOS 10.0, *) {
            return self.effectiveUserInterfaceLayoutDirection
        } else {
            return UIView.userInterfaceLayoutDirection(for: semanticContentAttribute)
        }
    }
    var wmf_isRightToLeft: Bool {
        return semanticContentAttribute == .forceRightToLeft || wmf_effectiveUserInterfaceLayoutDirection == .rightToLeft
    }
}

@objc(WMFArticleCollectionViewCell)
open class ArticleCollectionViewCell: UICollectionViewCell {
    let titleLabel = UILabel()
    let descriptionLabel = UILabel()
    let imageView = UIImageView()
    let saveButton = SaveButton()
    var extractLabel: UILabel?
    
    private var kvoButtonTitleContext = 0

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
    
    open override func prepareForReuse() {
        super.prepareForReuse()
        imageView.wmf_reset()
        imageView.wmf_showPlaceholder()
        saveButton.saveButtonState = .longSave
    }
    
    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        saveButton.titleLabel?.font = UIFont.wmf_preferredFontForFontFamily(.systemMedium, withTextStyle: .subheadline, compatibleWithTraitCollection: traitCollection)
        descriptionLabel.font = UIFont.wmf_preferredFontForFontFamily(.system, withTextStyle: .subheadline, compatibleWithTraitCollection: traitCollection)
        titleLabel.font = UIFont.wmf_preferredFontForFontFamily(.georgia, withTextStyle: .title1, compatibleWithTraitCollection: traitCollection)
        extractLabel?.font = UIFont.wmf_preferredFontForFontFamily(.system, withTextStyle: .subheadline, compatibleWithTraitCollection: traitCollection)
    }
    
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
        guard label.hasText else {
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
    
    open func backgroundColor(for displayType: WMFFeedDisplayType) -> UIColor {
        return displayType == .relatedPages ? UIColor.wmf_lightGrayCellBackground : UIColor.white
    }
    
    open func isSaveButtonHidden(for displayType: WMFFeedDisplayType) -> Bool {
        return displayType == .pageWithPreview ? false : true
    }
    
    public func configure(article: WMFArticle, contentGroup: WMFContentGroup, layoutOnly: Bool) {
        let displayType = contentGroup.displayType()
        
        let imageWidthToRequest = imageView.frame.size.width < 300 ? traitCollection.wmf_nearbyThumbnailWidth : traitCollection.wmf_leadImageWidth
        if displayType != .mainPage, let imageURL = article.imageURL(forWidth: imageWidthToRequest) {
            isImageViewHidden = false
            if !layoutOnly {
                imageView.wmf_setImage(with: imageURL, detectFaces: true, onGPU: true, failure: { (error) in }, success: { })
            }
        } else {
            isImageViewHidden = true
        }
        
        titleLabel.text = article.displayTitle
        isSaveButtonHidden = isSaveButtonHidden(for: displayType)
        if displayType == .pageWithPreview {
            descriptionLabel.text = article.wikidataDescription?.wmf_stringByCapitalizingFirstCharacter()
            extractLabel?.text = article.snippet
            imageViewHeight = 196
            backgroundColor = .white
        } else {
            if displayType == .mainPage {
                descriptionLabel.text = article.wikidataDescription ?? WMFLocalizedString("explore-main-page-description", value: "Main page of Wikimedia projects", comment: "Main page description that shows when the main page lacks a Wikidata description.")
            } else {
                descriptionLabel.text = article.wikidataDescriptionOrSnippet?.wmf_stringByCapitalizingFirstCharacter()
            }
            backgroundColor = backgroundColor(for: displayType)
            extractLabel?.text = nil
            imageViewHeight = 150
        }
        
        let articleLanguage = (article.url as NSURL?)?.wmf_language
        let articleSemanticContentAttribute = MWLanguageInfo.semanticContentAttribute(forWMFLanguage: articleLanguage)
        titleLabel.accessibilityLanguage = articleLanguage
        titleLabel.semanticContentAttribute = articleSemanticContentAttribute
        descriptionLabel.accessibilityLanguage = articleLanguage
        descriptionLabel.semanticContentAttribute = articleSemanticContentAttribute
        extractLabel?.accessibilityLanguage = articleLanguage
        extractLabel?.semanticContentAttribute = articleSemanticContentAttribute
        
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
