@objc(WMFArticleRightAlignedImageCollectionViewCell)
open class ArticleRightAlignedImageCollectionViewCell: ArticleCollectionViewCell {
    
    override open func setup() {
        imageView.cornerRadius = 3
        super.setup()
    }
    
    override open func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        let margins = UIEdgeInsetsMake(15, 13, 15, 13)
        let isRTL = titleLabel.wmf_isRightToLeft
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
        
        var y: CGFloat = margins.top
        let x = isRTL ? size.width - widthMinusMargins - margins.right : margins.left
        y = layout(for: titleLabel, x: x, y: y, width: widthMinusMargins, apply:apply)
        y = layout(for: descriptionLabel, x: x, y: y, width: widthMinusMargins, apply:apply)
        
        if !isSaveButtonHidden {
            y += 10
            y = layout(forView: saveButton, x: x, y: y, width: widthMinusMargins, apply: apply)
        }
        y += margins.bottom
        return CGSize(width: size.width, height: y)
    }
    
    
    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        titleLabel.font = UIFont.wmf_preferredFontForFontFamily(.system, withTextStyle: .body, compatibleWithTraitCollection: traitCollection)
    }
    
}

