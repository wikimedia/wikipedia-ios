import UIKit

extension OnThisDayCollectionViewCell {
    @objc(configureWithOnThisDayEvent:dataStore:theme:layoutOnly:shouldAnimateDots:)
    public func configure(with onThisDayEvent: WMFFeedOnThisDayEvent, dataStore: MWKDataStore, theme: Theme, layoutOnly: Bool, shouldAnimateDots: Bool) {
        let previews = onThisDayEvent.articlePreviews ?? []
        let currentYear = Calendar.current.component(.year, from: Date())
        
        apply(theme: theme)
    
        titleLabel.text = onThisDayEvent.yearString

        let articleSiteURL = onThisDayEvent.siteURL
        let articleLanguage = onThisDayEvent.language
        
        if let eventYear = onThisDayEvent.year {
            let yearsSinceEvent = currentYear - eventYear.intValue
            subTitleLabel.text = String.localizedStringWithFormat(WMFLocalizedDateFormatStrings.yearsAgo(forSiteURL: articleSiteURL), yearsSinceEvent)
        } else {
            subTitleLabel.text = nil
        }
            
        descriptionLabel.text = onThisDayEvent.text
        
        articles = previews.map { (articlePreview) -> CellArticle in
            return CellArticle(articleURL:articlePreview.articleURL, title: articlePreview.displayTitle, description: articlePreview.descriptionOrSnippet, imageURL: articlePreview.thumbnailURL)
        }
        
        
        descriptionLabel.accessibilityLanguage = articleLanguage
        semanticContentAttributeOverride = MWLanguageInfo.semanticContentAttribute(forWMFLanguage: articleLanguage)
        
        isImageViewHidden = true
        timelineView.shouldAnimateDots = shouldAnimateDots

        setNeedsLayout()
    }
}
