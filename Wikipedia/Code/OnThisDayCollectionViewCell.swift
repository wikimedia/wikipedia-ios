import UIKit

@objc(WMFOnThisDayExploreCollectionViewCell)
class OnThisDayExploreCollectionViewCell: OnThisDayCollectionViewCell {

    @objc(configureWithOnThisDayEvent:previousEvent:dataStore:layoutOnly:)
    func configure(with onThisDayEvent: WMFFeedOnThisDayEvent,  previousEvent: WMFFeedOnThisDayEvent, dataStore: MWKDataStore, layoutOnly: Bool) {
        bottomTitleLabel.textColor = .wmf_blue
        bottomTitleLabel.text = previousEvent.yearWithEraString()
        super.configure(with: onThisDayEvent, dataStore: dataStore, layoutOnly: layoutOnly, shouldAnimateDots: false)
    }

    private lazy var whiteTopAndBottomGradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        let white = UIColor.white.cgColor
        let clear = UIColor(white: 1, alpha: 0).cgColor // https://stackoverflow.com/a/24895385
        layer.colors = [white, clear, clear, white, white]
        layer.locations = [0.0, 0.07, 0.77, 0.97, 1.0]
        layer.startPoint = CGPoint(x: 0.5, y: 0.0)
        layer.endPoint = CGPoint(x: 0.5, y: 1.0)
        return layer
    }()

    override func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        whiteTopAndBottomGradientLayer.frame = bounds
        return super.sizeThatFits(size, apply: apply)
    }

    override open func setup() {
        super.setup()
        layer.addSublayer(whiteTopAndBottomGradientLayer)
    }
}

@objc(WMFOnThisDayCollectionViewCell)
class OnThisDayCollectionViewCell: SideScrollingCollectionViewCell {

    let timelineView = OnThisDayTimelineView()
    
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
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        let titleFont = UIFont.wmf_preferredFontForFontFamily(.system, withTextStyle: .title3, compatibleWithTraitCollection: traitCollection)
        titleLabel.font = titleFont
        bottomTitleLabel.font = titleFont
        
        let subTitleFont = UIFont.wmf_preferredFontForFontFamily(.system, withTextStyle: .subheadline, compatibleWithTraitCollection: traitCollection)
        subTitleLabel.font = subTitleFont
        descriptionLabel.font = subTitleFont
    }
    
    override func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        let timelineViewWidth:CGFloat = 66.0
        let x: CGFloat
        
        if semanticContentAttributeOverride == .forceRightToLeft {
            margins.right = timelineViewWidth
            x = size.width - timelineViewWidth
        } else {
            margins.left = timelineViewWidth
            x = 0
        }
        
        if apply {
            timelineView.frame = CGRect(x: x, y: 0, width: timelineViewWidth, height: size.height)
        }
        
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
