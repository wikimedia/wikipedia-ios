import Foundation

public extension ArticleCollectionViewCell {
    fileprivate func adjustMargins(for index: Int, count: Int) {
        var newMargins = margins ?? UIEdgeInsets.zero
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
                imageView.wmf_setImage(with: imageURL, detectFaces: true, onGPU: true, failure: { (error) in }, success: { })
            }
        } else {
            isImageViewHidden = true
        }
        let articleLanguage = (article.url as NSURL?)?.wmf_language
        titleLabel.text = article.displayTitle
        

        switch displayType {
        case .random:
            imageViewDimension = 196
            isSaveButtonHidden = false
            descriptionLabel.text = article.capitalizedWikidataDescription
            extractLabel?.text = article.snippet
            var newMargins = margins ?? UIEdgeInsets.zero
            newMargins.bottom = 0
            margins = newMargins
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

public extension RankedArticleCollectionViewCell {
    override func configure(article: WMFArticle, displayType: WMFFeedDisplayType, index: Int, count: Int, layoutOnly: Bool) {
        rankView.rank = index + 1
        let startColor = UIColor.wmf_blue
        let endColor = UIColor.wmf_green
        var r1: CGFloat = 0
        var g1: CGFloat = 0
        var b1: CGFloat = 0
        var a1: CGFloat = 0
        startColor.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        var r2: CGFloat = 0
        var g2: CGFloat = 0
        var b2: CGFloat = 0
        var a2: CGFloat = 0
        endColor.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        let percent = CGFloat(index + 1) / CGFloat(count)
        let r = r1 + percent * (r2 - r1)
        let g = g1 + percent * (g2 - g1)
        let b = b1 + percent * (b2 - b1)
        let a = a1 + percent * (a2 - a1)
        rankView.tintColor = UIColor(red: r, green: g, blue: b, alpha: a)
        super.configure(article: article, displayType: displayType, index: index, count: count, layoutOnly: layoutOnly)
    }
}
