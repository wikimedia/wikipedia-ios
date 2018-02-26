import UIKit

@objc(WMFArticleRightAlignedImageCollectionViewCell)
open class ArticleRightAlignedImageCollectionViewCell: ArticleCollectionViewCell {
    public var bottomSeparator = UIView()
    public var topSeparator = UIView()

    public var singlePixelDimension: CGFloat = 0.5
    
    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        singlePixelDimension = traitCollection.displayScale > 0 ? 1.0/traitCollection.displayScale : 0.5
    }
    
    override open func setup() {
        imageView.layer.cornerRadius = 3
        bottomSeparator.isOpaque = true
        contentView.addSubview(bottomSeparator)
        topSeparator.isOpaque = true
        contentView.addSubview(topSeparator)
        super.setup()
    }
    
    open override func reset() {
        super.reset()
        bottomSeparator.isHidden = true
        topSeparator.isHidden = true
        titleFontFamily = .system
        titleTextStyle = .body
        updateFonts(with: traitCollection)
    }
    
    override open func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        let size = super.sizeThatFits(size, apply: apply)
        let isRTL = articleSemanticContentAttribute == .forceRightToLeft

        let margins = self.layoutMargins
        let multipliers = self.layoutMarginsMultipliers
        let layoutMargins = UIEdgeInsets(top: round(margins.top * multipliers.top) + layoutMarginsAdditions.top, left: round(margins.left * multipliers.left) + layoutMarginsAdditions.left, bottom: round(margins.bottom * multipliers.bottom) + layoutMarginsAdditions.bottom, right: round(margins.right * multipliers.right) + layoutMarginsAdditions.right)

        var widthMinusMargins = size.width - layoutMargins.left - layoutMargins.right
        let minHeight = imageViewDimension + layoutMargins.top + layoutMargins.bottom
        let minHeightMinusMargins = minHeight - layoutMargins.top - layoutMargins.bottom
        
        if !isImageViewHidden {
            widthMinusMargins = widthMinusMargins - spacing - imageViewDimension
        }
        
        var x = layoutMargins.left
        if isRTL {
            x = size.width - x - widthMinusMargins
        }
        var origin = CGPoint(x: x, y: layoutMargins.top)
        
        if descriptionLabel.wmf_hasText || !isSaveButtonHidden || !isImageViewHidden {
            let titleLabelFrame = titleLabel.wmf_preferredFrame(at: origin, fitting: widthMinusMargins, alignedBy: articleSemanticContentAttribute, apply: apply)
            origin.y += titleLabelFrame.layoutHeight(with: spacing)
            
            let descriptionLabelFrame = descriptionLabel.wmf_preferredFrame(at: origin, fitting: widthMinusMargins, alignedBy: articleSemanticContentAttribute, apply: apply)
            origin.y += descriptionLabelFrame.layoutHeight(with: 0)
            descriptionLabel.isHidden = false
            
            if !isSaveButtonHidden {
                origin.y += spacing
                origin.y += saveButtonTopSpacing
                let saveButtonFrame = saveButton.wmf_preferredFrame(at: origin, fitting: widthMinusMargins, alignedBy: articleSemanticContentAttribute, apply: apply)
                origin.y += saveButtonFrame.height - 2 * saveButton.verticalPadding
            }
        } else {
            let horizontalAlignment: HorizontalAlignment = isRTL ? .right : .left
            let titleLabelFrame = titleLabel.wmf_preferredFrame(at: CGPoint(x: layoutMargins.left, y: layoutMargins.top), maximumViewSize: CGSize(width: widthMinusMargins, height: UIViewNoIntrinsicMetric), minimumLayoutAreaSize: CGSize(width: UIViewNoIntrinsicMetric, height: minHeightMinusMargins), horizontalAlignment: horizontalAlignment, verticalAlignment: .center, apply: apply)
            origin.y += titleLabelFrame.layoutHeight(with: 0)
            descriptionLabel.isHidden = true
        }

        origin.y += layoutMargins.bottom
        let height = max(origin.y, minHeight)
        
        if (apply && !bottomSeparator.isHidden) {
            bottomSeparator.frame = CGRect(x: 0, y: height - singlePixelDimension, width: size.width, height: singlePixelDimension)
        }
        
        if (apply && !topSeparator.isHidden) {
            topSeparator.frame = CGRect(x: 0, y: 0, width: size.width, height: singlePixelDimension)
        }
        
        if (apply && !isImageViewHidden) {
            let imageViewY = floor(0.5*height - 0.5*imageViewDimension)
            var x = layoutMargins.right
            if !isRTL {
                x = size.width - x - imageViewDimension
            }
            imageView.frame = CGRect(x: x, y: imageViewY, width: imageViewDimension, height: imageViewDimension)
        }
        
        return CGSize(width: size.width, height: height)
    }
}

