import UIKit

@objc(WMFArticleFullWidthImageCollectionViewCell)
open class ArticleFullWidthImageCollectionViewCell: ArticleCollectionViewCell {
    
    fileprivate let headerBackgroundView = UIView()
    
    public var headerBackgroundColor: UIColor? {
        set {
            headerBackgroundView.backgroundColor = newValue
            titleLabel.backgroundColor = newValue
            descriptionLabel.backgroundColor = newValue
        }
        get {
            return headerBackgroundView.backgroundColor
        }
    }
    
    public var isHeaderBackgroundViewHidden: Bool {
        set {
            if newValue {
                headerBackgroundView.removeFromSuperview()
            } else {
                contentView.insertSubview(headerBackgroundView, at: 0)
            }
        }
        get {
            return headerBackgroundView.superview == nil
        }
    }
    
    
    override open func setup() {
        let extractLabel = UILabel()
        extractLabel.isOpaque = true
        extractLabel.numberOfLines = 4
        addSubview(extractLabel)
        self.extractLabel = extractLabel
        super.setup()
        descriptionLabel.numberOfLines = 2
        titleLabel.numberOfLines = 0
    }
    
    open override func reset() {
        super.reset()
        spacing = 6
        saveButtonTopSpacing = 10
        imageViewDimension = 150
    }
    
    open override func updateBackgroundColorOfLabels() {
        super.updateBackgroundColorOfLabels()
        if !isHeaderBackgroundViewHidden {
            titleLabel.backgroundColor = headerBackgroundColor
            descriptionLabel.backgroundColor = headerBackgroundColor
        }
    }
    
    open override func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        let widthMinusMargins = size.width - layoutMargins.left - layoutMargins.right
        
        var origin = CGPoint(x: layoutMargins.left, y: 0)
        
        if !isImageViewHidden {
            if apply {
                imageView.frame = CGRect(x: 0, y: 0, width: size.width, height: imageViewDimension)
            }
            origin.y += imageViewDimension
        }
        
        origin.y += layoutMargins.top
        
        let titleFrame = titleLabel.wmf_preferredFrame(at: origin, fitting: widthMinusMargins, alignedBy: articleSemanticContentAttribute, apply: apply)
        origin.y += titleFrame.layoutHeight(with: spacing)
        
        let descriptionFrame = descriptionLabel.wmf_preferredFrame(at: origin, fitting: widthMinusMargins, alignedBy: articleSemanticContentAttribute, apply: apply)
        origin.y += descriptionFrame.layoutHeight(with: spacing)
        
        if apply {
            titleLabel.isHidden = !titleLabel.wmf_hasText
            descriptionLabel.isHidden = !descriptionLabel.wmf_hasText
        }
        
        if !isHeaderBackgroundViewHidden && apply {
            headerBackgroundView.frame = CGRect(x: 0, y: 0, width: size.width, height: origin.y)
        }
        
        if let extractLabel = extractLabel, extractLabel.wmf_hasText {
            origin.y += spacing // double spacing before extract
            let extractFrame = extractLabel.wmf_preferredFrame(at: origin, fitting: widthMinusMargins, alignedBy: articleSemanticContentAttribute, apply: apply)
            origin.y += extractFrame.layoutHeight(with: spacing)
            if apply {
                extractLabel.isHidden = false
            }
        } else if apply {
            extractLabel?.isHidden = true
        }

        if !isSaveButtonHidden {
            origin.y += saveButtonTopSpacing
            let saveButtonFrame = saveButton.wmf_preferredFrame(at: origin, fitting: widthMinusMargins, alignedBy: userInterfaceSemanticContentAttribute, apply: apply)
            origin.y += saveButtonFrame.layoutHeight(with: spacing -  2 * saveButton.verticalPadding)
        }
        
        origin.y += layoutMargins.bottom
        return CGSize(width: size.width, height: origin.y)
    }
    
}



