import UIKit

@objc(WMFArticleRightAlignedImageCollectionViewCell)
open class ArticleRightAlignedImageCollectionViewCell: ArticleCollectionViewCell {
    let separator = UIView()
    
    override open func setup() {
        imageView.cornerRadius = 3
        separator.isOpaque = true
        addSubview(separator)
        super.setup()
    }
    
    open override func reset() {
        super.reset()
        separator.isHidden = true
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
            if (apply) {
                let imageViewY = margins.top + round(0.5*minHeightMinusMargins - 0.5*imageViewDimension)
                var x = margins.right
                if !isRTL {
                    x = size.width - x - imageViewDimension
                }
                imageView.frame = CGRect(x: x, y: imageViewY, width: imageViewDimension, height: imageViewDimension)
            }
            widthMinusMargins = widthMinusMargins - margins.right - imageViewDimension
        }
        
        var x = margins.left
        if isRTL {
            x = size.width - x - widthMinusMargins
        }
        var origin = CGPoint(x: x, y: margins.top)
        
        if descriptionLabel.wmf_hasText || !isSaveButtonHidden {
            let titleLabelFrame = titleLabel.wmf_preferredFrame(at: origin, fitting: widthMinusMargins, alignedBy: articleSemanticContentAttribute, apply: apply)
            origin.y += titleLabelFrame.layoutHeight(with: spacing)
            
            let descriptionLabelFrame = descriptionLabel.wmf_preferredFrame(at: origin, fitting: widthMinusMargins, alignedBy: articleSemanticContentAttribute, apply: apply)
            origin.y += descriptionLabelFrame.layoutHeight(with: spacing)
            descriptionLabel.isHidden = false
        } else {
            let horizontalAlignment: HorizontalAlignment = articleSemanticContentAttribute == .forceRightToLeft ? .right : .left
            let titleLabelFrame = titleLabel.wmf_preferredFrame(at: origin, maximumViewSize: CGSize(width: widthMinusMargins, height: UIViewNoIntrinsicMetric), minimumLayoutAreaSize: CGSize(width: UIViewNoIntrinsicMetric, height: minHeightMinusMargins), horizontalAlignment: horizontalAlignment, verticalAlignment: .center, apply: apply)
            origin.y += titleLabelFrame.layoutHeight(with: spacing)
            descriptionLabel.isHidden = true
        }

        if !isSaveButtonHidden {
            origin.y += saveButtonTopSpacing
            let saveButtonFrame = saveButton.wmf_preferredFrame(at: origin, fitting: widthMinusMargins, alignedBy: articleSemanticContentAttribute, apply: apply)
            origin.y += saveButtonFrame.height
        }
        origin.y += margins.bottom
        
        if (apply && !separator.isHidden) {
            let singlePixelDimension = traitCollection.displayScale > 0 ? 1.0/traitCollection.displayScale : 0.5
            separator.frame = CGRect(x: 0, y: origin.y - singlePixelDimension, width: size.width, height: singlePixelDimension)
        }
        
        let height = max(origin.y, minHeight)
        return CGSize(width: size.width, height: height)
    }
}

