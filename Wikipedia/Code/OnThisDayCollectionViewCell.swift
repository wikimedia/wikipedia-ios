import UIKit

@objc(WMFOnThisDayCollectionViewCell)
class OnThisDayCollectionViewCell: SideScrollingCollectionViewCell {

    let timelineView = OnThisDayTimelineView()

    @objc(configureForExploreWithOnThisDayEvent:previousEvent:dataStore:layoutOnly:)
    func configureForExplore(with onThisDayEvent: WMFFeedOnThisDayEvent,  previousEvent: WMFFeedOnThisDayEvent, dataStore: MWKDataStore, layoutOnly: Bool) {
        bottomTitleLabel.textColor = .wmf_blue
        bottomTitleLabel.text = previousEvent.yearWithEraString()
        configure(with: onThisDayEvent, dataStore: dataStore, layoutOnly: layoutOnly, shouldAnimateDots: false)
    }
    
    @objc(configureWithOnThisDayEvent:dataStore:layoutOnly:shouldAnimateDots:)
    func configure(with onThisDayEvent: WMFFeedOnThisDayEvent, dataStore: MWKDataStore, layoutOnly: Bool, shouldAnimateDots: Bool) {
        let previews = onThisDayEvent.articlePreviews ?? []
        let currentYear = Calendar.current.component(.year, from: Date())
        
        titleLabel.textColor = .wmf_blue
        subTitleLabel.textColor = .wmf_customGray
        
        titleLabel.text = onThisDayEvent.yearWithEraString()

        if let eventYear = onThisDayEvent.year {
            let yearsSinceEvent = currentYear - eventYear.intValue
            subTitleLabel.text = String.localizedStringWithFormat(WMFLocalizedDateFormatStrings.yearsAgo(), yearsSinceEvent)
        } else {
            subTitleLabel.text = nil
        }
            
        descriptionLabel.text = onThisDayEvent.text
        
        articles = previews.map { (articlePreview) -> CellArticle in
            return CellArticle(articleURL:articlePreview.articleURL, title: articlePreview.displayTitle, description: articlePreview.descriptionOrSnippet(), imageURL: articlePreview.thumbnailURL)
        }
        
        let articleLanguage = (onThisDayEvent.articlePreviews?.first?.articleURL as NSURL?)?.wmf_language
        descriptionLabel.accessibilityLanguage = articleLanguage
        semanticContentAttributeOverride = MWLanguageInfo.semanticContentAttribute(forWMFLanguage: articleLanguage)
        
        isImageViewHidden = true
        timelineView.shouldAnimateDots = shouldAnimateDots

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
        bottomTitleLabel.font = titleFont
        subTitleLabel.font = subTitleFont
        descriptionLabel.font = descriptionFont
    }
    
    override func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {

        let timelineViewWidth:CGFloat = 66.0
        timelineView.frame = CGRect(x: bounds.origin.x, y: bounds.origin.y, width: timelineViewWidth, height: bounds.size.height)
        
        margins.left = timelineViewWidth
        return super.sizeThatFits(size, apply: apply)
    }
    
    override open func setup() {
        super.setup()
        collectionView.backgroundColor = .clear
        insertSubview(timelineView, belowSubview: collectionView)
    }
    
    var pauseDotsAnimation: Bool = true {
        didSet {
            timelineView.pauseDotsAnimation = pauseDotsAnimation
        }
    }
    
    override var isHidden: Bool {
        didSet {
            pauseDotsAnimation = isHidden
        }
    }
    
    override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)
        timelineView.topDotsY = titleLabel.convert(titleLabel.bounds, to: timelineView).midY
        timelineView.bottomDotY = bottomTitleLabel.convert(bottomTitleLabel.bounds, to: timelineView).midY
    }
}
