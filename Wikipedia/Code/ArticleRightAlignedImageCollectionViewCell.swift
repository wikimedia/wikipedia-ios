@objc(WMFArticleRightAlignedImageCollectionViewCell)
open class ArticleRightAlignedImageCollectionViewCell: ArticleCollectionViewCell {
    
    override open func setup() {
        imageView.cornerRadius = 3
        super.setup()
    }
    
    override open func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        let margins = UIEdgeInsetsMake(15, 13, 15, 13)
        let spacing: CGFloat = 6
        let saveButtonTopSpacing: CGFloat = 10
        let isRTL = articleSemanticContentAttribute == .forceRightToLeft
        var widthMinusMargins = size.width - margins.left - margins.right
        if !isImageViewHidden {
            let imageViewDimension: CGFloat = 70
            let imageViewY = 0.5*size.height - 0.5*imageViewDimension
            if (apply) {
                let x = isRTL ? margins.left : size.width - margins.right - imageViewDimension
                imageView.frame = CGRect(x: x, y: imageViewY, width: imageViewDimension, height: imageViewDimension)
            }
            widthMinusMargins = widthMinusMargins - margins.right - 70
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
        return CGSize(width: size.width, height: origin.y)
    }
    
    
    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        titleLabel.font = UIFont.wmf_preferredFontForFontFamily(.system, withTextStyle: .body, compatibleWithTraitCollection: traitCollection)
    }
    
}

