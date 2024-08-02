import WMFComponents

public extension ArticleCollectionViewCell {
    @objc(configureWithArticle:displayType:index:theme:layoutOnly:completion:)
    func configure(article: WMFArticle, displayType: WMFFeedDisplayType, index: Int, theme: Theme, layoutOnly: Bool, completion:(() -> Void)? = nil) {
        self.theme = theme
        apply(theme: theme)
        updateStyles()
        
        let group = DispatchGroup()
        
        let imageWidthToRequest = displayType.imageWidthCompatibleWithTraitCollection(traitCollection)
        if displayType != .mainPage, let imageURL = article.imageURL(forWidth: imageWidthToRequest) {
            isImageViewHidden = false
            if !layoutOnly {
                group.enter()
                imageView.wmf_setImage(with: imageURL, detectFaces: true, onGPU: true, failure: { (error) in group.leave() }, success: { group.leave() })
            }
        } else {
            isImageViewHidden = true
        }
        
        let articleLanguageCode = article.url?.wmf_languageCode
        
        titleHTML = article.displayTitleHTML
        
        switch displayType {
        case .random:
            imageViewDimension = 196
            descriptionLabel.text = article.capitalizedWikidataDescription
            extractLabel?.text = article.snippet
        case .pageWithPreview:
            imageViewDimension = 196
            descriptionLabel.text = article.capitalizedWikidataDescription
            extractLabel?.text = article.snippet
        case .continueReading:
            imageViewDimension = 130
            extractLabel?.text = nil
            descriptionLabel.text = article.capitalizedWikidataDescriptionOrSnippet
            extractLabel?.text = nil
        case .relatedPagesSourceArticle:
            setBackgroundColors(theme.colors.midBackground, selected: theme.colors.baseBackground)
            updateSelectedOrHighlighted()
            imageViewDimension = 130
            extractLabel?.text = nil
            descriptionLabel.text = article.capitalizedWikidataDescriptionOrSnippet
        case .relatedPages:
            extractLabel?.text = nil
            descriptionLabel.text = article.wikidataDescription
            configureForCompactList(at: index)
            if let cell = self as? ArticleRightAlignedImageCollectionViewCell {
                cell.topSeparator.isHidden = true
                cell.bottomSeparator.isHidden = true
            }
        case .mainPage:
            styles =  HtmlUtils.Styles(font: WMFFont.for(.georgiaTitle3, compatibleWith: traitCollection), boldFont: WMFFont.for(.boldGeorgiaTitle3, compatibleWith: traitCollection), italicsFont: WMFFont.for(.italicGeorgiaTitle3, compatibleWith: traitCollection), boldItalicsFont: WMFFont.for(.boldItalicGeorgiaTitle3, compatibleWith: traitCollection), color: theme.colors.primaryText, linkColor: theme.colors.link, lineSpacing: 1)
            descriptionTextStyle = .subheadline
            updateFonts(with: traitCollection)
            descriptionLabel.text = article.capitalizedWikidataDescription ?? WMFLocalizedString("explore-main-page-description", value: "Main page of Wikimedia projects", comment: "Main page description that shows when the main page lacks a Wikidata description.")
            extractLabel?.text = nil
        case .pageWithLocationPlaceholder:
            fallthrough
        case .pageWithLocation:
            isImageViewHidden = false
            descriptionLabel.text = article.capitalizedWikidataDescriptionOrSnippet
            extractLabel?.text = nil
            break
        case .compactList:
            configureForCompactList(at: index)
            fallthrough
        case .page:
            fallthrough
        default:
            imageViewDimension = 40
            descriptionLabel.text = article.capitalizedWikidataDescriptionOrSnippet
            extractLabel?.text = nil
        }
        
        titleLabel.accessibilityLanguage = articleLanguageCode
        descriptionLabel.accessibilityLanguage = articleLanguageCode
        extractLabel?.accessibilityLanguage = articleLanguageCode
        articleSemanticContentAttribute = MWKLanguageLinkController.semanticContentAttribute(forContentLanguageCode: article.url?.wmf_contentLanguageCode)
        setNeedsLayout()
        group.notify(queue: .main) {
            completion?()
        }
    }
}

public extension ArticleRightAlignedImageCollectionViewCell {
    @objc func configure(article: WMFArticle, displayType: WMFFeedDisplayType, index: Int, shouldShowSeparators: Bool = false, theme: Theme, layoutOnly: Bool, completion:(() -> Void)? = nil) {
        if shouldShowSeparators {
            self.topSeparator.isHidden = index != 0
            self.bottomSeparator.isHidden = false
        } else {
            self.bottomSeparator.isHidden = true
        }
        super.configure(article: article, displayType: displayType, index: index, theme: theme, layoutOnly: layoutOnly, completion: completion)
    }
}

public extension RankedArticleCollectionViewCell {
    override func configure(article: WMFArticle, displayType: WMFFeedDisplayType, index: Int, shouldShowSeparators: Bool = false, theme: Theme, layoutOnly: Bool, completion:(() -> Void)? = nil) {
        rankView.rank = index + 1
        let percent = CGFloat(index + 1) / CGFloat(5)
        rankView.rankColor = theme.colors.rankGradient.color(at: percent)
        super.configure(article: article, displayType: displayType, index: index, shouldShowSeparators: shouldShowSeparators, theme: theme, layoutOnly: layoutOnly, completion: completion)
    }
    
    override func configure(article: WMFArticle, displayType: WMFFeedDisplayType, index: Int, theme: Theme, layoutOnly: Bool, completion:(() -> Void)? = nil) {
        configure(article: article, displayType: displayType, index: index, shouldShowSeparators: false, theme: theme, layoutOnly: layoutOnly, completion: completion)
    }
}

public extension ArticleFullWidthImageCollectionViewCell {
    override func configure(article: WMFArticle, displayType: WMFFeedDisplayType, index: Int, theme: Theme, layoutOnly: Bool, completion:(() -> Void)? = nil) {
        switch displayType {
        case .random:
            fallthrough
        case .pageWithPreview:
            isSaveButtonHidden = false
        default:
            isSaveButtonHidden = true
        }
        super.configure(article: article, displayType: displayType, index: index, theme: theme, layoutOnly: layoutOnly, completion: completion)
    }
}
