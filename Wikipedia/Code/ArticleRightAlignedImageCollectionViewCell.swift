@objc(WMFArticleRightAlignedImageCollectionViewCell)
open class ArticleRightAlignedImageCollectionViewCell: ArticleCollectionViewCell {
    
    override open func setup() {
        imageView.cornerRadius = 3
        titleFontFamily = .system
        titleTextStyle = .body
        super.setup()
    }
    
    override open func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        let isRTL = articleSemanticContentAttribute == .forceRightToLeft
        var widthMinusMargins = size.width - margins.left - margins.right
        if !isImageViewHidden {
            if (apply) {
                let imageViewY = round(0.5*size.height - 0.5*imageViewDimension)
                let x = isRTL ? margins.left : size.width - margins.right - imageViewDimension
                imageView.frame = CGRect(x: x, y: imageViewY, width: imageViewDimension, height: imageViewDimension)
            }
            widthMinusMargins = widthMinusMargins - margins.right - imageViewDimension
        }
        
        let x = isRTL ? size.width - widthMinusMargins - margins.right : margins.left
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

