import UIKit

@objc(WMFOnThisDayCollectionViewCell)
class OnThisDayCollectionViewCell: SideScrollingCollectionViewCell {

    @objc(configureWithOnThisDayEvent:dataStore:layoutOnly:)
    func configure(with onThisDayEvent: WMFFeedOnThisDayEvent, dataStore: MWKDataStore, layoutOnly: Bool) {
        let previews = onThisDayEvent.articlePreviews ?? []
        
        let eventYear = (onThisDayEvent.year!).intValue
        
        let currentYear = Calendar.current.component(.year, from: Date())
        
        titleLabel.textColor = .wmf_blue
        subTitleLabel.textColor = .wmf_customGray
        
//TODO:
// - format `eventYear` so negative `BC` years use lang appropriate `BC` string instead of negative dash
// - use proper number formatter on `yearsSinceEvent` so number formatting is localized, has commas etc.
// - fix endpoint off-by-one bug on BC years (it's not accounting for there being no year zero)
// - add guarding to this method 

        let yearsSinceEvent = currentYear - eventYear

        titleLabel.text = "\(eventYear)"
        subTitleLabel.text = String.localizedStringWithFormat(WMFLocalizedDateFormatStrings.yearsAgo(), yearsSinceEvent)
        descriptionLabel.text = onThisDayEvent.text
        
        articles = previews.map { (articlePreview) -> CellArticle in
            let articleLanguage = (articlePreview.articleURL as NSURL?)?.wmf_language
            let description = articlePreview.wikidataDescription?.wmf_stringByCapitalizingFirstCharacter(usingWikipediaLanguage: articleLanguage)
            return CellArticle(articleURL:articlePreview.articleURL, title: articlePreview.displayTitle, description: description, imageURL: articlePreview.thumbnailURL)
        }
        
        let articleLanguage = (onThisDayEvent.articlePreviews?.first?.articleURL as NSURL?)?.wmf_language
        descriptionLabel.accessibilityLanguage = articleLanguage
        semanticContentAttributeOverride = MWLanguageInfo.semanticContentAttribute(forWMFLanguage: articleLanguage)
        
        isImageViewHidden = true

        setNeedsLayout()
    }
    
    static let descriptionTextStyle = UIFontTextStyle.subheadline
    var descriptionFont = UIFont.preferredFont(forTextStyle: descriptionTextStyle)
    
    static let titleTextStyle = UIFontTextStyle.title3
    var titleFont = UIFont.preferredFont(forTextStyle: titleTextStyle)
    
    static let subTitleTextStyle = UIFontTextStyle.subheadline
    var subTitleFont = UIFont.preferredFont(forTextStyle: subTitleTextStyle)
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        titleLabel.font = titleFont
        subTitleLabel.font = subTitleFont
        descriptionLabel.font = descriptionFont
    }
}
