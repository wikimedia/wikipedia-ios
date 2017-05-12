import UIKit

extension UILabel {
    var hasText: Bool {
        return text?.characters.count ?? 0 > 0
    }
}

@objc(WMFArticleFullWidthImageCollectionViewCell)
open class ArticleFullWidthImageCollectionViewCell: UICollectionViewCell, ArticleCollectionViewCell {
    
    private var kvoButtonTitleContext = 0
    
    final public var imageWidth: Int {
        return traitCollection.wmf_leadImageWidth
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
            saveButton?.isHidden = isSaveButtonHidden
            setNeedsLayout()
        }
    }

    let textContainerView = UIView()
    let titleLabel = UILabel()
    let descriptionLabel = UILabel()
    let extractLabel = UILabel()
    let imageView = UIImageView()
    public let saveButton: SaveButton! = SaveButton()
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        let size = bounds.size
        let _ = sizeThatFits(size, apply: true)
    }
    
    open override func sizeThatFits(_ size: CGSize) -> CGSize {
        return sizeThatFits(size, apply: false)
    }
    
    open func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        let margins = UIEdgeInsetsMake(0, 13, 0, 13)
        let widthMinusMargins = size.width - margins.left - margins.right
        
        var y: CGFloat = 0
        
        if !isImageViewHidden {
            imageView.frame = CGRect(x: 0, y: y, width: size.width, height: imageHeight)
            y = imageView.frame.maxY
        }
        y += 10
        
        y = layout(for: titleLabel, x: margins.left, y: y, width: widthMinusMargins, apply:apply)
        y = layout(for: descriptionLabel, x: margins.left, y: y, width: widthMinusMargins, apply:apply)
        y = layout(for: extractLabel, x: margins.left, y: y, width: widthMinusMargins, apply:apply)

        if !isSaveButtonHidden {
            y += 10
            y = layout(forView: saveButton, x: margins.left, y: y, width: widthMinusMargins, apply: true)
            y += 10
        }
        y += 10
        return CGSize(width: size.width, height: y)
    }
    
    fileprivate func layout(for label: UILabel, x: CGFloat, y: CGFloat, width: CGFloat, apply: Bool) -> CGFloat {
        guard label.hasText else {
            return y
        }
        return layout(forView: label, x: x, y: y, width: width, apply: apply) + 6
    }
    
    fileprivate func layout(forView view: UIView, x: CGFloat, y: CGFloat, width: CGFloat, apply: Bool) -> CGFloat {
        let sizeToFit = CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
        let viewSize = view.sizeThatFits(sizeToFit)
        if apply {
            view.frame = CGRect(x: x, y: y, width: min(viewSize.width, width), height: viewSize.height)
        }
        return y + viewSize.height
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    func setup() {
        tintColor = UIColor.wmf_blueTint
        imageView.wmf_showPlaceholder()
        addSubview(imageView)
        addSubview(titleLabel)
        addSubview(descriptionLabel)
        addSubview(extractLabel)
        extractLabel.numberOfLines = 4
        descriptionLabel.textColor = UIColor.wmf_customGray
        addSubview(saveButton)
        saveButton?.tintColor = UIColor.wmf_blueTint
        saveButton.setTitleColor(UIColor.wmf_blueTint, for: .normal)
        saveButton?.saveButtonState = .longSave
        saveButton?.addObserver(self, forKeyPath: "titleLabel.text", options: .new, context: &kvoButtonTitleContext)
        backgroundColor = .white
        layoutSubviews()
    }
    
    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        saveButton?.titleLabel?.font = UIFont.wmf_preferredFontForFontFamily(.systemMedium, withTextStyle: .subheadline, compatibleWithTraitCollection: traitCollection)
        descriptionLabel.font = UIFont.wmf_preferredFontForFontFamily(.system, withTextStyle: .subheadline, compatibleWithTraitCollection: traitCollection)
        extractLabel.font = UIFont.wmf_preferredFontForFontFamily(.system, withTextStyle: .subheadline, compatibleWithTraitCollection: traitCollection)
        titleLabel.font = UIFont.wmf_preferredFontForFontFamily(.system, withTextStyle: .body, compatibleWithTraitCollection: traitCollection)
        titleLabel.font = UIFont.wmf_preferredFontForFontFamily(.georgia, withTextStyle: .title1, compatibleWithTraitCollection: traitCollection)
    }
    
    open override func prepareForReuse() {
        super.prepareForReuse()
        imageView.wmf_reset()
        imageView.wmf_showPlaceholder()
        saveButton?.saveButtonState = .longSave
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
        if displayType == .pageWithPreview {
            textContainerView.backgroundColor = UIColor.white
            descriptionLabel.text = article.wikidataDescription?.wmf_stringByCapitalizingFirstCharacter()
            extractLabel.text = article.snippet
            isSaveButtonHidden = false
            imageHeight = 196
            backgroundColor = .white
        } else {
            if displayType == .mainPage {
                descriptionLabel.text = article.wikidataDescription ?? WMFLocalizedString("explore-main-page-description", value: "Main page of Wikimedia projects", comment: "Main page description that shows when the main page lacks a Wikidata description.")
            } else {
                descriptionLabel.text = article.wikidataDescriptionOrSnippet?.wmf_stringByCapitalizingFirstCharacter()
            }
            
            backgroundColor = displayType == .relatedPages ? UIColor.wmf_lightGrayCellBackground : UIColor.white
            extractLabel.text = nil
            isSaveButtonHidden = true
            imageHeight = 150
        }
        
        let language = (article.url as NSURL?)?.wmf_language
        titleLabel.accessibilityLanguage = language
        descriptionLabel.accessibilityLanguage = language
        extractLabel.accessibilityLanguage = language
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
}



