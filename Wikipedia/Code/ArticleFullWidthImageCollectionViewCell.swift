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
        let widthMinusMargins = layoutWidth(for: size)
        var origin = CGPoint(x: layoutMargins.left, y: 0)
        
        if !isImageViewHidden {
            if apply {
                imageView.frame = CGRect(x: 0, y: 0, width: size.width, height: imageViewDimension)
            }
            origin.y += imageViewDimension
        }
        
        origin.y += layoutMargins.top
        
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
            origin.y += spacing
            let saveButtonFrame = saveButton.wmf_preferredFrame(at: origin, maximumWidth: widthMinusMargins, horizontalAlignment: isDeviceRTL ? .right : .left, apply: apply)
            origin.y += saveButtonFrame.height - 2 * saveButton.verticalPadding + spacing
        }
        
        origin.y += layoutMargins.bottom
        return CGSize(width: size.width, height: origin.y)
    }
}

public class ArticleFullWidthImageExploreCollectionViewCell: ArticleFullWidthImageCollectionViewCell {
    override open func apply(theme: Theme) {
        super.apply(theme: theme)
        setBackgroundColors(theme.colors.cardBackground, selected: theme.colors.cardBackground)
    }
}
