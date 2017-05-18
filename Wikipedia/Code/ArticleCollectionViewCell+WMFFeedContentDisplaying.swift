import Foundation

public extension ArticleCollectionViewCell {
    public func backgroundColor(for displayType: WMFFeedDisplayType) -> UIColor {
        return displayType == .relatedPages ? UIColor.wmf_lightGrayCellBackground : UIColor.white
    }
    
    public func isSaveButtonHidden(for displayType: WMFFeedDisplayType) -> Bool {
        return displayType == .pageWithPreview ? false : true
    }
    
    public func configure(article: WMFArticle, contentGroup: WMFContentGroup, layoutOnly: Bool) {
        let displayType = contentGroup.displayType()
        
        let imageWidthToRequest = imageView.frame.size.width < 300 ? traitCollection.wmf_nearbyThumbnailWidth : traitCollection.wmf_leadImageWidth // 300 is used to distinguish between full-width images and thumbnails. Ultimately this (and other thumbnail requests) should be updated with code that checks all the available buckets for the width that best matches the size of the image view. 
        if displayType != .mainPage, let imageURL = article.imageURL(forWidth: imageWidthToRequest) {
            isImageViewHidden = false
            if !layoutOnly {
                imageView.wmf_setImage(with: imageURL, detectFaces: true, onGPU: true, failure: { [weak self] (error) in self?.isImageViewHidden = true }, success: { })
            }
        } else {
            isImageViewHidden = true
        }
        
        titleLabel.text = article.displayTitle
        isSaveButtonHidden = isSaveButtonHidden(for: displayType)
        if displayType == .pageWithPreview {
            descriptionLabel.text = article.wikidataDescription?.wmf_stringByCapitalizingFirstCharacter()
            extractLabel?.text = article.snippet
            imageViewHeight = 196
            backgroundColor = .white
        } else {
            if displayType == .mainPage {
                descriptionLabel.text = article.wikidataDescription ?? WMFLocalizedString("explore-main-page-description", value: "Main page of Wikimedia projects", comment: "Main page description that shows when the main page lacks a Wikidata description.")
            } else {
                descriptionLabel.text = article.wikidataDescriptionOrSnippet?.wmf_stringByCapitalizingFirstCharacter()
            }
            backgroundColor = backgroundColor(for: displayType)
            extractLabel?.text = nil
            imageViewHeight = 150
        }
        
        let articleLanguage = (article.url as NSURL?)?.wmf_language
        titleLabel.accessibilityLanguage = articleLanguage
        descriptionLabel.accessibilityLanguage = articleLanguage
        extractLabel?.accessibilityLanguage = articleLanguage
        articleSemanticContentAttribute = MWLanguageInfo.semanticContentAttribute(forWMFLanguage: articleLanguage)
        setNeedsLayout()
    }
}

extension ArticleRightAlignedImageCollectionViewCell {
    public override func backgroundColor(for displayType: WMFFeedDisplayType) -> UIColor {
        return UIColor.white
    }
    
    public override func isSaveButtonHidden(for displayType: WMFFeedDisplayType) -> Bool {
        return false
    }
}
