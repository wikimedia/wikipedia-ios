import WMF

class SavedCollectionViewCell: ArticleRightAlignedImageCollectionViewCell {
    
    func configure(readingList: ReadingList, index: Int, count: Int, shouldAdjustMargins: Bool = true, shouldShowSeparators: Bool = false, theme: Theme) {
        isImageViewHidden = true
        titleLabel.text = readingList.name
        descriptionLabel.text = readingList.readingListDescription
        configureCommon(shouldShowSeparators: shouldShowSeparators, index: index, theme: theme, shouldAdjustMargins: shouldAdjustMargins, count: count)
    }
    
    func configure(article: WMFArticle, index: Int, count: Int, shouldAdjustMargins: Bool = true, shouldShowSeparators: Bool = false, theme: Theme, layoutOnly: Bool) {
        titleLabel.text = article.displayTitle
        descriptionLabel.text = article.capitalizedWikidataDescriptionOrSnippet
        
        let imageWidthToRequest = imageView.frame.size.width < 300 ? traitCollection.wmf_nearbyThumbnailWidth : traitCollection.wmf_leadImageWidth // 300 is used to distinguish between full-awidth images and thumbnails. Ultimately this (and other thumbnail requests) should be updated with code that checks all the available buckets for the width that best matches the size of the image view.
        if let imageURL = article.imageURL(forWidth: imageWidthToRequest) {
            isImageViewHidden = false
            if !layoutOnly {
                imageView.wmf_setImage(with: imageURL, detectFaces: true, onGPU: true, failure: { (error) in }, success: { })
            }
        } else {
            isImageViewHidden = true
        }
        
        let articleLanguage = article.url?.wmf_language
        titleLabel.accessibilityLanguage = articleLanguage
        descriptionLabel.accessibilityLanguage = articleLanguage
        extractLabel?.accessibilityLanguage = articleLanguage
        articleSemanticContentAttribute = MWLanguageInfo.semanticContentAttribute(forWMFLanguage: articleLanguage)
        
        configureCommon(shouldShowSeparators: shouldShowSeparators, index: index, theme: theme, shouldAdjustMargins: shouldAdjustMargins, count: count)
    }
    
    fileprivate func configureCommon(shouldShowSeparators: Bool = false, index: Int, theme: Theme, shouldAdjustMargins: Bool = true, count: Int) {
        if shouldShowSeparators {
            topSeparator.isHidden = index != 0
            bottomSeparator.isHidden = false
        } else {
            bottomSeparator.isHidden = true
        }
        apply(theme: theme)
        isSaveButtonHidden = true
        extractLabel?.text = nil
        imageViewDimension = 40
        if (shouldAdjustMargins) {
            adjustMargins(for: index, count: count)
        }
        setNeedsLayout()
    }
    
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
    
}
