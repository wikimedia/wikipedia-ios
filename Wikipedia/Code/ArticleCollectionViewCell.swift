import UIKit

extension UILabel {
    var hasText: Bool {
        return text?.characters.count ?? 0 > 0
    }
}

@objc(WMFArticleCollectionViewCell)
open class ArticleCollectionViewCell: UICollectionViewCell {
    open func setup() {
        tintColor = UIColor.wmf_blueTint
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
    
    private var kvoButtonTitleContext = 0
    
    open var imageWidth: Int {
        return 0
    }
    
    var imageHeight: CGFloat = 150 {
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
    
    let titleLabel = UILabel()
    let descriptionLabel = UILabel()
    let imageView = UIImageView()
    let saveButton = SaveButton()
    var extractLabel: UILabel?
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
            view.frame = CGRect(x: x, y: y, width: min(viewSize.width, width), height: viewSize.height)
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
    
    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &kvoButtonTitleContext {
            setNeedsLayout()
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    open func backgroundColor(for displayType: WMFFeedDisplayType) -> UIColor {
        return displayType == .relatedPages ? UIColor.wmf_lightGrayCellBackground : UIColor.white
    }
    
    open func isSaveButtonHidden(for displayType: WMFFeedDisplayType) -> Bool {
        return displayType == .pageWithPreview ? false : true
    }
    
    public func configure(article: WMFArticle, contentGroup: WMFContentGroup, layoutOnly: Bool) {
        if let imageURL = article.imageURL(forWidth: self.imageWidth) {
            isImageViewHidden = false
            if !layoutOnly {
                imageView.wmf_setImage(with: imageURL, detectFaces: true, onGPU: true, failure: { (error) in }, success: { })
            }
        } else {
            isImageViewHidden = true
        }
        
        titleLabel.text = article.displayTitle
        let displayType = contentGroup.displayType()
        isSaveButtonHidden = isSaveButtonHidden(for: displayType)
        if displayType == .pageWithPreview {
            descriptionLabel.text = article.wikidataDescription?.wmf_stringByCapitalizingFirstCharacter()
            extractLabel?.text = article.snippet
            imageHeight = 196
            backgroundColor = .white
        } else {
            if displayType == .mainPage {
                descriptionLabel.text = article.wikidataDescription ?? WMFLocalizedString("explore-main-page-description", value: "Main page of Wikimedia projects", comment: "Main page description that shows when the main page lacks a Wikidata description.")
            } else {
                descriptionLabel.text = article.wikidataDescriptionOrSnippet?.wmf_stringByCapitalizingFirstCharacter()
            }
            backgroundColor = backgroundColor(for: displayType)
            extractLabel?.text = nil
            imageHeight = 150
        }
        
        let language = (article.url as NSURL?)?.wmf_language
        titleLabel.accessibilityLanguage = language
        descriptionLabel.accessibilityLanguage = language
        extractLabel?.accessibilityLanguage = language
    }
    
}
