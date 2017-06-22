import UIKit

@objc(WMFNewsCollectionViewCell)
class NewsCollectionViewCell: SideScrollingCollectionViewCell {
    @objc(configureWithStory:dataStore:layoutOnly:)
    func configure(with story: WMFFeedNewsStory, dataStore: MWKDataStore, layoutOnly: Bool) {
        let previews = story.articlePreviews ?? []
        descriptionHTML = story.storyHTML
        
        articles = previews.map { (articlePreview) -> CellArticle in
            let articleLanguage = (articlePreview.articleURL as NSURL?)?.wmf_language
            let description = articlePreview.wikidataDescription?.wmf_stringByCapitalizingFirstCharacter(usingWikipediaLanguage: articleLanguage)
            return CellArticle(articleURL:articlePreview.articleURL, title: articlePreview.displayTitle, description: description, imageURL: articlePreview.thumbnailURL)
        }
        
        let articleLanguage = (story.articlePreviews?.first?.articleURL as NSURL?)?.wmf_language
        descriptionLabel.accessibilityLanguage = articleLanguage
        semanticContentAttributeOverride = MWLanguageInfo.semanticContentAttribute(forWMFLanguage: articleLanguage)
        
        let imageWidthToRequest = traitCollection.wmf_potdImageWidth
        if let articleURL = story.featuredArticlePreview?.articleURL ?? previews.first?.articleURL, let article = dataStore.fetchArticle(with: articleURL), let imageURL = article.imageURL(forWidth: imageWidthToRequest) {
            isImageViewHidden = false
            if !layoutOnly {
                imageView.wmf_setImage(with: imageURL, detectFaces: true, onGPU: true, failure: {(error) in }, success: { })
            }
        } else {
            isImageViewHidden = true
        }
        setNeedsLayout()
    }
    
    static let descriptionTextStyle = UIFontTextStyle.subheadline
    var descriptionFont = UIFont.preferredFont(forTextStyle: descriptionTextStyle)
    var descriptionLinkFont = UIFont.preferredFont(forTextStyle: descriptionTextStyle)
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        descriptionFont = UIFont.preferredFont(forTextStyle: NewsCollectionViewCell.descriptionTextStyle)
        descriptionLinkFont = UIFont.boldSystemFont(ofSize: descriptionFont.pointSize)
        updateDescriptionHTMLStyle()
    }
    
    func updateDescriptionHTMLStyle() {
        guard let descriptionHTML = descriptionHTML else {
            descriptionLabel.text = nil
            return
        }
        let attributedString = descriptionHTML.wmf_attributedStringByRemovingHTML(with: descriptionFont, linkFont: descriptionLinkFont)
        descriptionLabel.attributedText = attributedString
    }
    
    var descriptionHTML: String? {
        didSet {
            updateDescriptionHTMLStyle()
        }
    }
}
