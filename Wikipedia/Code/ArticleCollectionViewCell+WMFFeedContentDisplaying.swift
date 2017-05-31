import Foundation

public extension ArticleCollectionViewCell {
    fileprivate func adjustMargins(for index: Int, count: Int) {
        var newMargins = margins!
        let maxIndex = count - 1
        if index < maxIndex {
            newMargins.bottom = round(0.5*margins.bottom)
        }
        if index > 0 {
            newMargins.top = round(0.5*margins.top)
        }
        margins = newMargins
    }
    
    public func configure(article: WMFArticle, displayType: WMFFeedDisplayType, index: Int, count: Int, layoutOnly: Bool) {
        let imageWidthToRequest = imageView.frame.size.width < 300 ? traitCollection.wmf_nearbyThumbnailWidth : traitCollection.wmf_leadImageWidth // 300 is used to distinguish between full-awidth images and thumbnails. Ultimately this (and other thumbnail requests) should be updated with code that checks all the available buckets for the width that best matches the size of the image view.
        if displayType != .mainPage, let imageURL = article.imageURL(forWidth: imageWidthToRequest) {
            isImageViewHidden = false
            if !layoutOnly {
                imageView.wmf_setImage(with: imageURL, detectFaces: true, onGPU: true, failure: { [weak self] (error) in self?.isImageViewHidden = true }, success: { })
            }
        } else {
            isImageViewHidden = true
        }
        let articleLanguage = (article.url as NSURL?)?.wmf_language
        titleLabel.text = article.displayTitle
        

        switch displayType {
        case .pageWithPreview:
            imageViewDimension = 196
            isSaveButtonHidden = false
            descriptionLabel.text = article.capitalizedWikidataDescription
            extractLabel?.text = article.snippet
        case .continueReading:
            imageViewDimension = 150
            extractLabel?.text = nil
            isSaveButtonHidden = true
            descriptionLabel.text = article.capitalizedWikidataDescriptionOrSnippet
            extractLabel?.text = nil
        case .relatedPagesSourceArticle:
            backgroundColor = .wmf_lightGrayCellBackground
            imageViewDimension = 150
            extractLabel?.text = nil
            isSaveButtonHidden = true
            descriptionLabel.text = article.capitalizedWikidataDescriptionOrSnippet
            extractLabel?.text = nil
        case .relatedPages:
            isSaveButtonHidden = false
            descriptionLabel.text = article.capitalizedWikidataDescriptionOrSnippet
            extractLabel?.text = nil
            adjustMargins(for: index - 1, count: count) // related pages start at 1 due to the source article at 0
        case .mainPage:
            isSaveButtonHidden = true
            titleFontFamily = .georgia
            titleTextStyle = .title1
            descriptionFontFamily = .system
            descriptionTextStyle = .subheadline
            descriptionLabel.text = article.capitalizedWikidataDescription ?? WMFLocalizedString("explore-main-page-description", value: "Main page of Wikimedia projects", comment: "Main page description that shows when the main page lacks a Wikidata description.")
            extractLabel?.text = nil
        case .page:
            fallthrough
        default:
            imageViewDimension = 40
            isSaveButtonHidden = true
            descriptionLabel.text = article.capitalizedWikidataDescriptionOrSnippet
            extractLabel?.text = nil
            adjustMargins(for: index, count: count)
        }
        
        titleLabel.accessibilityLanguage = articleLanguage
        descriptionLabel.accessibilityLanguage = articleLanguage
        extractLabel?.accessibilityLanguage = articleLanguage
        articleSemanticContentAttribute = MWLanguageInfo.semanticContentAttribute(forWMFLanguage: articleLanguage)
        setNeedsLayout()
    }
}
