import WMFComponents

public class OnThisDayCollectionViewCell: SideScrollingCollectionViewCell {

    public let timelineView = TimelineView()
        
    override public func updateFonts(with traitCollection: UITraitCollection) {
        super.updateFonts(with: traitCollection)
        let titleFont = WMFFont.for(.title3, compatibleWith: traitCollection)
        titleLabel.font = titleFont
        let subTitleFont = WMFFont.for(.subheadline, compatibleWith: traitCollection)
        subTitleLabel.font = subTitleFont
        descriptionLabel.font = subTitleFont
    }
    
    let timelineViewWidth:CGFloat = 66.0

    override public func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        let x: CGFloat
        if semanticContentAttributeOverride == .forceRightToLeft {
            x = size.width - timelineViewWidth - layoutMargins.right
            layoutMarginsAdditions = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: timelineViewWidth)
        } else {
            x = layoutMargins.left
            layoutMarginsAdditions = UIEdgeInsets(top: 0, left: timelineViewWidth, bottom: 0, right: 0)
        }
        if apply {
            timelineView.frame = CGRect(x: x, y: 0, width: timelineViewWidth, height: size.height)
        }
        return super.sizeThatFits(size, apply: apply)
    }
    
    override open func setup() {
        super.setup()
        timelineView.isOpaque = true
        contentView.insertSubview(timelineView, belowSubview: collectionView)
    }
    
    public var pauseDotsAnimation: Bool = true {
        didSet {
            timelineView.pauseDotsAnimation = pauseDotsAnimation
        }
    }
    
    override public var isHidden: Bool {
        didSet {
            pauseDotsAnimation = isHidden
        }
    }
    
    override public func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)
        timelineView.dotsY = titleLabel.convert(titleLabel.bounds, to: timelineView).midY
    }
    
    override public func apply(theme: Theme) {
        super.apply(theme: theme)
        timelineView.backgroundColor = theme.colors.paperBackground
        timelineView.tintColor = theme.colors.link
        titleLabel.textColor = theme.colors.link
        subTitleLabel.textColor = theme.colors.secondaryText
        collectionView.backgroundColor = .clear
    }
    
    override public func updateBackgroundColorOfLabels() {
        super.updateBackgroundColorOfLabels()
        timelineView.backgroundColor = labelBackgroundColor
    }
}
