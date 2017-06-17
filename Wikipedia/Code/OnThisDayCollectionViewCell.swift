import UIKit

@objc(WMFOnThisDayCollectionViewCell)
class OnThisDayCollectionViewCell: SideScrollingCollectionViewCell {

    @objc(configureWithOnThisDayEvent:dataStore:layoutOnly:)
    func configure(with onThisDayEvent: WMFFeedOnThisDayEvent, dataStore: MWKDataStore, layoutOnly: Bool) {
        let previews = onThisDayEvent.articlePreviews ?? []
        
        let eventYear = (onThisDayEvent.year!).intValue
        
        let currentYear = Calendar.current.component(.year, from: Date())
        
//TODO:
// - format `eventYear` so negative `BC` years use lang appropriate `BC` string instead of negative dash
// - use proper number formatter on `yearsSinceEvent` so number formatting is localized, has commas etc.
// - fix endpoint off-by-one bug on BC years (it's not accounting for there being no year zero)
// - add guarding to this method 

        let yearsSinceEvent = currentYear - eventYear

        storyHTML = "\(eventYear)\n\(String.localizedStringWithFormat(WMFLocalizedDateFormatStrings.yearsAgo(), yearsSinceEvent))\n\(onThisDayEvent.text!)"
        
        articles = previews.map { (articlePreview) -> CellArticle in
            let articleLanguage = (articlePreview.articleURL as NSURL?)?.wmf_language
            let description = articlePreview.wikidataDescription?.wmf_stringByCapitalizingFirstCharacter(usingWikipediaLanguage: articleLanguage)
            return CellArticle(articleURL:articlePreview.articleURL, title: articlePreview.displayTitle, description: description, imageURL: articlePreview.thumbnailURL)
        }
        
        let articleLanguage = (onThisDayEvent.articlePreviews?.first?.articleURL as NSURL?)?.wmf_language
        storyLabel.accessibilityLanguage = articleLanguage
        semanticContentAttributeOverride = MWLanguageInfo.semanticContentAttribute(forWMFLanguage: articleLanguage)
        
        isImageViewHidden = true

        setNeedsLayout()
    }
}
