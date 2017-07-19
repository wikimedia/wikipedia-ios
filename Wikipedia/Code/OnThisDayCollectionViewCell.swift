import UIKit

@objc(WMFOnThisDayCollectionViewCell)
class OnThisDayCollectionViewCell: SideScrollingCollectionViewCell {

    let timelineView = OnThisDayTimelineView()
        
    override func updateFonts(with traitCollection: UITraitCollection) {
        super.updateFonts(with: traitCollection)
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
        timelineView.isOpaque = true
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
    
    override func apply(theme: Theme) {
        super.apply(theme: theme)
        timelineView.backgroundColor = theme.colors.paperBackground
        titleLabel.textColor = theme.colors.link
        bottomTitleLabel.textColor = theme.colors.link
        subTitleLabel.textColor = theme.colors.secondaryText
        collectionView.backgroundColor = .clear
    }
    
    override func updateSelectedOrHighlighted() {
        super.updateSelectedOrHighlighted()
        let backgroundColor = labelBackgroundColor
        timelineView.backgroundColor = backgroundColor
    }
}
