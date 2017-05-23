@objc(WMFArticleFullWidthImageCollectionViewCell)
open class ArticleFullWidthImageCollectionViewCell: ArticleCollectionViewCell {
    
    override open func setup() {
        let extractLabel = UILabel()
        extractLabel.numberOfLines = 4
        addSubview(extractLabel)
        self.extractLabel = extractLabel
        super.setup()
        descriptionLabel.numberOfLines = 2
        titleLabel.numberOfLines = 0
    }
    
    open override func reset() {
        super.reset()
        margins = UIEdgeInsetsMake(15, 13, 15, 13)
        spacing = 6
        imageViewDimension = 150
    }
    
    open override func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        let widthMinusMargins = size.width - margins.left - margins.right
        
        var origin = CGPoint(x: margins.left, y: 0)
        
        if !isImageViewHidden {
            if (apply) {
                imageView.frame = CGRect(x: 0, y: 0, width: size.width, height: imageViewDimension)
            }
            origin.y += imageViewDimension
        }
        
        origin.y += margins.top
        
        let titleFrame = titleLabel.wmf_preferredFrame(at: origin, fitting: widthMinusMargins, alignedBy: articleSemanticContentAttribute, apply: apply)
        origin.y += titleFrame.layoutHeight(with: spacing)
        
        let descriptionFrame = descriptionLabel.wmf_preferredFrame(at: origin, fitting: widthMinusMargins, alignedBy: articleSemanticContentAttribute, apply: apply)
        origin.y += descriptionFrame.layoutHeight(with: spacing)

        if let extractLabel = extractLabel, extractLabel.wmf_hasText {
            origin.y += spacing // double spacing before extract
            let extractFrame = extractLabel.wmf_preferredFrame(at: origin, fitting: widthMinusMargins, alignedBy: articleSemanticContentAttribute, apply: apply)
            origin.y += extractFrame.layoutHeight(with: spacing)
        }

        if !isSaveButtonHidden {
            origin.y += saveButtonTopSpacing
            let saveButtonFrame = saveButton.wmf_preferredFrame(at: origin, fitting: widthMinusMargins, alignedBy: articleSemanticContentAttribute, apply: apply)
            origin.y += saveButtonFrame.layoutHeight(with: spacing)
        }
        
        origin.y += margins.bottom
        return CGSize(width: size.width, height: origin.y)
    }
    
}



