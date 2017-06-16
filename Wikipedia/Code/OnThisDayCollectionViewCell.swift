import UIKit

@objc(WMFOnThisDayCollectionViewCell)
class OnThisDayCollectionViewCell: SideScrollingCollectionViewCell {

    @objc(configureWithOnThisDayEvent:dataStore:layoutOnly:)
    func configure(with onThisDayEvent: WMFFeedOnThisDayEvent, dataStore: MWKDataStore, layoutOnly: Bool) {
        let previews = onThisDayEvent.articlePreviews ?? []
        storyHTML = onThisDayEvent.text
        
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
