
import UIKit

class SignificantEventsSideScrollingCollectionViewCell: SideScrollingCollectionViewCell {
    public let timelineView = OnThisDayTimelineView()
    
    override public func updateFonts(with traitCollection: UITraitCollection) {
        super.updateFonts(with: traitCollection)
        let titleFont = UIFont.wmf_font(.title3, compatibleWithTraitCollection: traitCollection)
        titleLabel.font = titleFont
        
        let subTitleFont = UIFont.wmf_font(.subheadline, compatibleWithTraitCollection: traitCollection)
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
    
    public func configure(with event: TimelineEventViewModel, theme: Theme) {

        apply(theme: theme)
    
        titleLabel.text = ""
        subTitleLabel.text = ""
        descriptionLabel.text = ""
        titleLabel.attributedText = nil
        subTitleLabel.attributedText = nil
        descriptionLabel.attributedText = nil
        
        switch event {
        case .smallEvent(let smallEvent):
            titleLabel.attributedText = smallEvent.eventDescriptionForTraitCollection(traitCollection, theme: theme)
        case .sectionHeader(let sectionHeader):
            titleLabel.text = sectionHeader.title
        case .largeEvent(let largeEvent):
            descriptionLabel.attributedText = largeEvent.eventDescriptionForTraitCollection(traitCollection, theme: theme)
        }
        
        isImageViewHidden = true
        resetContentOffset()
        setNeedsLayout()
    }
}
