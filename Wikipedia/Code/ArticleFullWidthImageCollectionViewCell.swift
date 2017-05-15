@objc(WMFArticleFullWidthImageCollectionViewCell)
open class ArticleFullWidthImageCollectionViewCell: ArticleCollectionViewCell {
    
    override open func setup() {
        let extractLabel = UILabel()
        extractLabel.numberOfLines = 4
        addSubview(extractLabel)
        self.extractLabel = extractLabel
        super.setup()
        descriptionLabel.numberOfLines = 0
    }
    
    open override func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        let margins = UIEdgeInsetsMake(15, 13, 15, 13)
        let widthMinusMargins = size.width - margins.left - margins.right
        
        var y: CGFloat = 0
        
        if !isImageViewHidden {
            if (apply) {
                imageView.frame = CGRect(x: 0, y: y, width: size.width, height: imageViewHeight)
            }
            y += imageViewHeight
        }
        
        y += margins.top
        
        y = layout(for: titleLabel, x: margins.left, y: y, width: widthMinusMargins, apply:apply)
        y = layout(for: descriptionLabel, x: margins.left, y: y, width: widthMinusMargins, apply:apply)
        if let extractLabel = extractLabel, extractLabel.wmf_hasText {
            y += 7
            y = layout(for: extractLabel, x: margins.left, y: y, width: widthMinusMargins, apply:apply)
        }

        if !isSaveButtonHidden {
            y += 20
            y = layout(forView: saveButton, x: margins.left, y: y, width: widthMinusMargins, apply: apply)
            y += 5
        }
        y += margins.bottom
        return CGSize(width: size.width, height: y)
    }
    
}



