import Foundation

public extension ArticleCollectionViewCell {
    func adjustMargins(for index: Int, count: Int) {
        var newMultipliers: UIEdgeInsets = ArticleCollectionViewCell.defaultMarginsMultipliers
        let maxIndex = count - 1
        if index < maxIndex {
            newMultipliers.bottom = 0.5
        }
        if index > 0 {
            newMultipliers.top = 0.5
        }
        layoutMarginsMultipliers = newMultipliers
    }
    
    @objc(setTitleText:highlightingText:locale:)
    func set(titleTextToAttribute: String?, highlightingText: String?, locale: Locale?) {
        guard let titleTextToAttribute = titleTextToAttribute, let titleFont = UIFont.wmf_preferredFontForFontFamily(.system, withTextStyle: .subheadline) else {
            titleLabel.text = nil
            return
        }
        let attributedTitle = NSMutableAttributedString(string: titleTextToAttribute, attributes: [NSAttributedStringKey.font: titleFont])
        if let highlightingText = highlightingText {
            let range = (titleTextToAttribute.lowercased(with: locale) as NSString).range(of: highlightingText.lowercased(with: locale))
            if !WMFRangeIsNotFoundOrEmpty(range), let boldFont = UIFont.wmf_preferredFontForFontFamily(.systemSemiBold, withTextStyle: .subheadline) {
                attributedTitle.setAttributes([NSAttributedStringKey.font: boldFont], range: range)
            }
        }
        titleTextStyle = nil
        titleFontFamily = nil
        titleLabel.attributedText = attributedTitle
    }
    
    @objc(configureWithArticle:displayType:index:count:shouldAdjustMargins:theme:layoutOnly:)
    public func configure(article: WMFArticle, displayType: WMFFeedDisplayType, index: Int, count: Int, shouldAdjustMargins: Bool = true, theme: Theme, layoutOnly: Bool) {
        apply(theme: theme)
        
        let imageWidthToRequest = imageView.frame.size.width < 300 ? traitCollection.wmf_nearbyThumbnailWidth : traitCollection.wmf_leadImageWidth // 300 is used to distinguish between full-awidth images and thumbnails. Ultimately this (and other thumbnail requests) should be updated with code that checks all the available buckets for the width that best matches the size of the image view.
        if displayType != .mainPage, let imageURL = article.imageURL(forWidth: imageWidthToRequest) {
            isImageViewHidden = false
            if !layoutOnly {
                imageView.wmf_setImage(with: imageURL, detectFaces: true, onGPU: true, failure: { (error) in }, success: { })
            }
        } else {
            isImageViewHidden = true
        }
        let articleLanguage = article.url?.wmf_language
        titleLabel.text = article.displayTitle
        
        switch displayType {
        case .random:
            imageViewDimension = 196
            isSaveButtonHidden = false
            descriptionLabel.text = article.capitalizedWikidataDescription
            extractLabel?.text = article.snippet
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
            setBackgroundColors(theme.colors.midBackground, selected: theme.colors.baseBackground)
            updateSelectedOrHighlighted()
            imageViewDimension = 150
            extractLabel?.text = nil
            isSaveButtonHidden = true
            descriptionLabel.text = article.capitalizedWikidataDescriptionOrSnippet
            extractLabel?.text = nil
        case .relatedPages:
            isSaveButtonHidden = false
            descriptionLabel.text = article.capitalizedWikidataDescriptionOrSnippet
            extractLabel?.text = nil
            if (shouldAdjustMargins) {
                adjustMargins(for: index - 1, count: count - 1) // related pages start at 1 due to the source article at 0
            }
        case .mainPage:
            isSaveButtonHidden = true
            titleFontFamily = .georgia
            titleTextStyle = .title1
            descriptionFontFamily = .system
            descriptionTextStyle = .subheadline
            updateFonts(with: traitCollection)
            descriptionLabel.text = article.capitalizedWikidataDescription ?? WMFLocalizedString("explore-main-page-description", value: "Main page of Wikimedia projects", comment: "Main page description that shows when the main page lacks a Wikidata description.")
            extractLabel?.text = nil
        case .compactList:
            configureForCompactList(at: index)
            fallthrough
        case .page:
            fallthrough
        default:
            imageViewDimension = 40
            isSaveButtonHidden = true
            descriptionLabel.text = article.capitalizedWikidataDescriptionOrSnippet
            extractLabel?.text = nil
            if (shouldAdjustMargins) {
                adjustMargins(for: index, count: count)
            }
        }
        
        titleLabel.accessibilityLanguage = articleLanguage
        descriptionLabel.accessibilityLanguage = articleLanguage
        extractLabel?.accessibilityLanguage = articleLanguage
        articleSemanticContentAttribute = MWLanguageInfo.semanticContentAttribute(forWMFLanguage: articleLanguage)
        setNeedsLayout()
    }
}

public extension ArticleRightAlignedImageCollectionViewCell {
    @objc public func configure(article: WMFArticle, displayType: WMFFeedDisplayType, index: Int, count: Int, shouldAdjustMargins: Bool = true, shouldShowSeparators: Bool = false, theme: Theme, layoutOnly: Bool) {
        if shouldShowSeparators {
            self.topSeparator.isHidden = index != 0
            self.bottomSeparator.isHidden = false
        } else {
            self.bottomSeparator.isHidden = true
        }
        super.configure(article: article, displayType: displayType, index: index, count: count, shouldAdjustMargins: shouldAdjustMargins, theme: theme, layoutOnly: layoutOnly)
    }
}

public extension RankedArticleCollectionViewCell {
    public override func configure(article: WMFArticle, displayType: WMFFeedDisplayType, index: Int, count: Int, shouldAdjustMargins: Bool = true, shouldShowSeparators: Bool = false, theme: Theme, layoutOnly: Bool) {
        rankView.rank = index + 1
        let percent = CGFloat(index + 1) / CGFloat(count)
        rankView.tintColor = theme.colors.linkToAccent.color(at: percent)
        super.configure(article: article, displayType: displayType, index: index, count: count, shouldAdjustMargins: shouldAdjustMargins, shouldShowSeparators: shouldShowSeparators, theme: theme, layoutOnly: layoutOnly)
    }
    
    public override func configure(article: WMFArticle, displayType: WMFFeedDisplayType, index: Int, count: Int, shouldAdjustMargins: Bool, theme: Theme, layoutOnly: Bool) {
        configure(article: article, displayType: displayType, index: index, count: count, shouldAdjustMargins: shouldAdjustMargins, shouldShowSeparators: false, theme: theme, layoutOnly: layoutOnly)
    }
}
