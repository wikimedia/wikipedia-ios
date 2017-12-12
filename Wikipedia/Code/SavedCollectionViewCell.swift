import WMF

class SavedCollectionViewCell: ArticleRightAlignedImageCollectionViewCell {
    
    public var readingLists: [ReadingList]? = nil {
        didSet {
            setNeedsLayout()
        }
    }
    
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
    
}
