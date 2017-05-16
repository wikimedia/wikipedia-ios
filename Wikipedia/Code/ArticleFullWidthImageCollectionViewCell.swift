@objc(WMFArticleFullWidthImageCollectionViewCell)
open class ArticleFullWidthImageCollectionViewCell: ArticleCollectionViewCell {
    
    override open func setup() {
        let extractLabel = UILabel()
        extractLabel.numberOfLines = 4
        addSubview(extractLabel)
        self.extractLabel = extractLabel
        super.setup()
        descriptionLabel.numberOfLines = 2
    }
    
    open override func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        let margins = UIEdgeInsetsMake(15, 13, 15, 13)
        let spacing: CGFloat = 6
        let saveButtonTopSpacing: CGFloat = 20
        let widthMinusMargins = size.width - margins.left - margins.right
        
        var origin = CGPoint(x: margins.left, y: 0)
        
        if !isImageViewHidden {
            if (apply) {
                imageView.frame = CGRect(x: 0, y: 0, width: size.width, height: imageViewHeight)
            }
            origin.y += imageViewHeight
        }
        
        origin.y += margins.top
        
        
        let titleFrame = titleLabel.wmf_prefferedFrame(at: origin, fitting: widthMinusMargins, alignedBy: articleSemanticContentAttribute, apply: apply)
        origin.y += titleFrame.height > 0 ? titleFrame.height + spacing : 0
        
        let descriptionFrame = descriptionLabel.wmf_prefferedFrame(at: origin, fitting: widthMinusMargins, alignedBy: articleSemanticContentAttribute, apply: apply)
        origin.y += descriptionFrame.height > 0 ? descriptionFrame.height + spacing : 0

        if let extractLabel = extractLabel, extractLabel.wmf_hasText {
            origin.y += spacing // double spacing
            let extractFrame = extractLabel.wmf_prefferedFrame(at: origin, fitting: widthMinusMargins, alignedBy: articleSemanticContentAttribute, apply: apply)
            origin.y += extractFrame.height > 0 ? extractFrame.height + spacing : 0
        }

        if !isSaveButtonHidden {
            origin.y += saveButtonTopSpacing
            let saveButtonFrame = saveButton.wmf_prefferedFrame(at: origin, fitting: widthMinusMargins, alignedBy: articleSemanticContentAttribute, apply: apply)
            origin.y += saveButtonFrame.height > 0 ? saveButtonFrame.height + spacing : 0
            origin.y += spacing
        }
        
        origin.y += margins.bottom
        return CGSize(width: size.width, height: origin.y)
    }
    
}



