import WMF

class SavedCollectionViewCell: ArticleRightAlignedImageCollectionViewCell {
    
    override func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        let superSize = super.sizeThatFits(size, apply: apply)
        let isRTL = articleSemanticContentAttribute == .forceRightToLeft
        let minHeight = imageViewDimension + layoutMargins.top + layoutMargins.bottom
        var widthMinusMargins = size.width - layoutMargins.left - layoutMargins.right
        
        if !isImageViewHidden {
            widthMinusMargins = widthMinusMargins - layoutMargins.right - imageViewDimension
        }
        
        var x = layoutMargins.left
        if isRTL {
            x = size.width - x - widthMinusMargins
        }
        
        let origin = CGPoint(x: x, y: layoutMargins.top)
        let height = max(origin.y, minHeight)
        
        if (apply && !isImageViewHidden) {
            let imageViewY = floor(0.5*height - 0.5*imageViewDimension)
            var x = layoutMargins.right
            if !isRTL {
                x = size.width - x - imageViewDimension
            }
            imageView.frame = CGRect(x: x, y: imageViewY, width: imageViewDimension, height: imageViewDimension)
        }
        
        let separatorWidth: CGFloat = isImageViewHidden ? size.width : size.width - (imageViewDimension * 1.8)
        if (apply && !bottomSeparator.isHidden) {
            bottomSeparator.frame = CGRect(x: 0, y: height - singlePixelDimension, width: separatorWidth, height: singlePixelDimension)
        }
        
        if (apply && !topSeparator.isHidden) {
            topSeparator.frame = CGRect(x: 0, y: 0, width: separatorWidth, height: singlePixelDimension)
        }
        
        return superSize
    }
    
    func updateSelected(theme: Theme) {
        if isSelected {
            contentView.backgroundColor = theme.colors.midBackground
            batchEditActionView.backgroundColor = theme.colors.midBackground
        } else {
            contentView.backgroundColor = theme.colors.paperBackground
            batchEditActionView.backgroundColor = theme.colors.paperBackground
        }
    }
}
