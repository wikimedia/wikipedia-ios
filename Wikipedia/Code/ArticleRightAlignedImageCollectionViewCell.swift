import UIKit

@objc(WMFArticleRightAlignedImageCollectionViewCell)
open class ArticleRightAlignedImageCollectionViewCell: ArticleCollectionViewCell {
    
    override open func setup() {
        imageView.cornerRadius = 3
        super.setup()
    }
    
    open override func reset() {
        super.reset()
        titleFontFamily = .system
        titleTextStyle = .body
        updateFonts(with: traitCollection)
    }
    
    override open func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        let isRTL = articleSemanticContentAttribute == .forceRightToLeft
        var widthMinusMargins = size.width - margins.left - margins.right
        let heightMinusMargins = size.height - margins.top - margins.bottom

        if !isImageViewHidden {
            if (apply) {
                let imageViewY = margins.top + round(0.5*heightMinusMargins - 0.5*imageViewDimension)
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
        
        let titleLabelFrame = titleLabel.wmf_preferredFrame(at: origin, fitting: widthMinusMargins, alignedBy: articleSemanticContentAttribute, apply: apply)
        origin.y += titleLabelFrame.layoutHeight(with: spacing)
        
        let descriptionLabelFrame = descriptionLabel.wmf_preferredFrame(at: origin, fitting: widthMinusMargins, alignedBy: articleSemanticContentAttribute, apply: apply)
        origin.y += descriptionLabelFrame.layoutHeight(with: spacing)

        if !isSaveButtonHidden {
            origin.y += saveButtonTopSpacing
            let saveButtonFrame = saveButton.wmf_preferredFrame(at: origin, fitting: widthMinusMargins, alignedBy: articleSemanticContentAttribute, apply: apply)
            origin.y += saveButtonFrame.height
        }
        origin.y += margins.bottom
        let height = isImageViewHidden ? origin.y : max(origin.y, imageViewDimension + margins.top + margins.bottom)
        return CGSize(width: size.width, height: height)
    }
}

