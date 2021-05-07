import UIKit

extension OnThisDayCollectionViewCell {
    public func configure(with onThisDayEvent: WMFFeedOnThisDayEvent, dataStore: MWKDataStore, showArticles: Bool = true, theme: Theme, layoutOnly: Bool, shouldAnimateDots: Bool) {
        let previews = onThisDayEvent.articlePreviews ?? []
        let currentYear = Calendar.current.component(.year, from: Date())
        
        apply(theme: theme)
    
        titleLabel.text = onThisDayEvent.yearString

        let articleSiteURL = onThisDayEvent.siteURL
        let articleLanguageCode = onThisDayEvent.languageCode
        
        if let eventYear = onThisDayEvent.year {
            let yearsSinceEvent = currentYear - eventYear.intValue
            let language = articleSiteURL?.wmf_languageCode
            // String.localizedStringWithFormat uses the current locale for plural rules causing incorrect pluralization if the user is looking at content in a language different than their system default language
            let locale = NSLocale.wmf_locale(for: language)
            subTitleLabel.text = String(format: WMFLocalizedDateFormatStrings.yearsAgo(forWikiLanguage: language), locale: locale, yearsSinceEvent)
        } else {
            subTitleLabel.text = nil
        }
            
        descriptionLabel.text = onThisDayEvent.text
        
        if showArticles {
            articles = previews.map { (articlePreview) -> CellArticle in
                return CellArticle(articleURL:articlePreview.articleURL, title: articlePreview.displayTitle, titleHTML: articlePreview.displayTitleHTML, description: articlePreview.descriptionOrSnippet, imageURL: articlePreview.thumbnailURL)
            }
        }
        
        descriptionLabel.accessibilityLanguage = articleLanguageCode
        semanticContentAttributeOverride = MWKLanguageLinkController.semanticContentAttribute(forContentLanguageCode: onThisDayEvent.contentLanguageCode)
        
        isImageViewHidden = true
        timelineView.shouldAnimateDots = shouldAnimateDots
        resetContentOffset()
        setNeedsLayout()
    }
}
