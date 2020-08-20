import UIKit

open class ArticleRightAlignedImageCollectionViewCell: ArticleCollectionViewCell {
    public var bottomSeparator = UIView()
    public var topSeparator = UIView()
    public var areSeparatorsAlignedWithLabels: Bool = false

    public var singlePixelDimension: CGFloat = 0.5

    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateSinglePixelDimension()
    }

    private func updateSinglePixelDimension() {
        singlePixelDimension = traitCollection.displayScale > 0 ? 1.0/traitCollection.displayScale : 0.5
    }
    
    override open func setup() {
        imageView.layer.cornerRadius = 3
        bottomSeparator.isOpaque = true
        contentView.addSubview(bottomSeparator)
        topSeparator.isOpaque = true
        contentView.addSubview(topSeparator)
        updateSinglePixelDimension()
        super.setup()
    }
    
    open override func reset() {
        super.reset()
        bottomSeparator.isHidden = true
        topSeparator.isHidden = true
        titleTextStyle = .callout
        updateFonts(with: traitCollection)
    }
    
    override open func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        let size = super.sizeThatFits(size, apply: apply)
        let isRTL = articleSemanticContentAttribute == .forceRightToLeft
    
        var widthMinusMargins = layoutWidth(for: size)
        if !isImageViewHidden {
            widthMinusMargins = widthMinusMargins - self.layoutMargins.right - imageViewDimension
        }
        
        let layoutMargins = calculatedLayoutMargins
        let minHeight = imageViewDimension + layoutMargins.top + layoutMargins.bottom
        let minHeightMinusMargins = minHeight - layoutMargins.top - layoutMargins.bottom
        
        var x = layoutMargins.left
        if isRTL {
            x = size.width - x - widthMinusMargins
        }
        var origin = CGPoint(x: x, y: layoutMargins.top)
        
        if descriptionLabel.wmf_hasText || !isImageViewHidden {
            let titleLabelFrame = titleLabel.wmf_preferredFrame(at: origin, maximumWidth: widthMinusMargins, alignedBy: articleSemanticContentAttribute, apply: apply)
            origin.y += titleLabelFrame.layoutHeight(with: spacing)
            
            let descriptionLabelFrame = descriptionLabel.wmf_preferredFrame(at: origin, maximumWidth: widthMinusMargins, alignedBy: articleSemanticContentAttribute, apply: apply)
            origin.y += descriptionLabelFrame.layoutHeight(with: 0)
            descriptionLabel.isHidden = false
        } else {
            let horizontalAlignment: HorizontalAlignment = isRTL ? .right : .left
            let titleLabelFrame = titleLabel.wmf_preferredFrame(at: CGPoint(x: layoutMargins.left, y: layoutMargins.top), maximumSize: CGSize(width: widthMinusMargins, height: UIView.noIntrinsicMetric), minimumSize: CGSize(width: UIView.noIntrinsicMetric, height: minHeightMinusMargins), horizontalAlignment: horizontalAlignment, verticalAlignment: .center, apply: apply)
            origin.y += titleLabelFrame.layoutHeight(with: 0)
            descriptionLabel.isHidden = true
        }

        origin.y += layoutMargins.bottom
        let height = ceil(max(origin.y, minHeight))
        
        if (apply && !bottomSeparator.isHidden) {
            bottomSeparator.frame = CGRect(x: areSeparatorsAlignedWithLabels ? origin.x : 0, y: bounds.maxY - singlePixelDimension, width: areSeparatorsAlignedWithLabels ? widthMinusMargins : size.width, height: singlePixelDimension)
        }
        
        if (apply && !topSeparator.isHidden) {
            topSeparator.frame = CGRect(x: areSeparatorsAlignedWithLabels ? origin.x : 0, y: 0, width: areSeparatorsAlignedWithLabels ? widthMinusMargins : size.width, height: singlePixelDimension)
        }
        
        if (apply && !isImageViewHidden) {
            let imageViewY = floor(0.5*height - 0.5*imageViewDimension)
            var x = layoutMargins.right
            if !isRTL {
                x = size.width - x - imageViewDimension
            }
            imageView.frame = CGRect(x: x, y: imageViewY, width: imageViewDimension, height: imageViewDimension)
        }
        
        let totalSize = CGSize(width: size.width, height: height)
        
        if apply {
            layer.shadowPath = UIBezierPath(roundedRect: CGRect(origin: .zero, size: totalSize), cornerRadius: backgroundView?.layer.cornerRadius ?? 0).cgPath
        }
        
        return totalSize
    }
}

open class ArticleRightAlignedImageExploreCollectionViewCell: ArticleRightAlignedImageCollectionViewCell {
    override open func apply(theme: Theme) {
        super.apply(theme: theme)
        setBackgroundColors(theme.colors.cardBackground, selected: theme.colors.selectedCardBackground)
    }
}
