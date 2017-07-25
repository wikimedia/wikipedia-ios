import UIKit

@objc(WMFArticleRightAlignedImageCollectionViewCell)
open class ArticleRightAlignedImageCollectionViewCell: ArticleCollectionViewCell {
    let bottomSeparator = UIView()
    var singlePixelDimension: CGFloat = 0.5
    
    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        singlePixelDimension = traitCollection.displayScale > 0 ? 1.0/traitCollection.displayScale : 0.5
    }
    
    override open func setup() {
        imageView.cornerRadius = 3
        bottomSeparator.isOpaque = true
        addSubview(bottomSeparator)
        super.setup()
    }
    
    open override func reset() {
        super.reset()
        bottomSeparator.isHidden = true
        titleFontFamily = .system
        titleTextStyle = .body
        updateFonts(with: traitCollection)
    }
    
    override open func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        let isRTL = articleSemanticContentAttribute == .forceRightToLeft
        var widthMinusMargins = size.width - margins.left - margins.right
        let minHeight = imageViewDimension + margins.top + margins.bottom
        let minHeightMinusMargins = minHeight - margins.top - margins.bottom
        
        if !isImageViewHidden {
            widthMinusMargins = widthMinusMargins - margins.right - imageViewDimension
        }
        
        var x = margins.left
        if isRTL {
            x = size.width - x - widthMinusMargins
        }
        var origin = CGPoint(x: x, y: margins.top)
        
        if descriptionLabel.wmf_hasText || !isSaveButtonHidden || !isImageViewHidden {
            let titleLabelFrame = titleLabel.wmf_preferredFrame(at: origin, fitting: widthMinusMargins, alignedBy: articleSemanticContentAttribute, apply: apply)
            origin.y += titleLabelFrame.layoutHeight(with: spacing)
            
            let descriptionLabelFrame = descriptionLabel.wmf_preferredFrame(at: origin, fitting: widthMinusMargins, alignedBy: articleSemanticContentAttribute, apply: apply)
            origin.y += descriptionLabelFrame.layoutHeight(with: 0)
            descriptionLabel.isHidden = false
            
            if !isSaveButtonHidden {
                origin.y += saveButtonTopSpacing
                let saveButtonFrame = saveButton.wmf_preferredFrame(at: origin, fitting: widthMinusMargins, alignedBy: articleSemanticContentAttribute, apply: apply)
                origin.y += saveButtonFrame.height
            }
        } else {
            let horizontalAlignment: HorizontalAlignment = articleSemanticContentAttribute == .forceRightToLeft ? .right : .left
            let titleLabelFrame = titleLabel.wmf_preferredFrame(at: CGPoint(x: margins.left, y: margins.top), maximumViewSize: CGSize(width: widthMinusMargins, height: UIViewNoIntrinsicMetric), minimumLayoutAreaSize: CGSize(width: UIViewNoIntrinsicMetric, height: minHeightMinusMargins), horizontalAlignment: horizontalAlignment, verticalAlignment: .center, apply: apply)
            origin.y += titleLabelFrame.layoutHeight(with: 0)
            descriptionLabel.isHidden = true
        }

        origin.y += margins.bottom
        let height = max(origin.y, minHeight)
        
        if (apply && !bottomSeparator.isHidden) {
            bottomSeparator.frame = CGRect(x: 0, y: height - singlePixelDimension, width: size.width, height: singlePixelDimension)
        }
        
        if (apply && !isImageViewHidden) {
            let imageViewY = floor(0.5*height - 0.5*imageViewDimension)
            var x = margins.right
            if !isRTL {
                x = size.width - x - imageViewDimension
            }
            imageView.frame = CGRect(x: x, y: imageViewY, width: imageViewDimension, height: imageViewDimension)
        }
        
        return CGSize(width: size.width, height: height)
    }
}

