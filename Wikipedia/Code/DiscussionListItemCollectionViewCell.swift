
import UIKit

class DiscussionListItemCollectionViewCell: CollectionViewCell {
    
    private let titleLabel = UILabel()
    private let unreadView = UIView()
    private let dividerView = UIView(frame: .zero)
    private let chevronImageView = UIImageView(frame: .zero)

    override func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        
        let adjustedMargins = UIEdgeInsets(top: layoutMargins.top + 4, left: layoutMargins.left + 5, bottom: layoutMargins.bottom + 4, right: layoutMargins.right + 5)
        
        let unreadIndicatorX = adjustedMargins.left
        let unreadIndicatorSideLength = CGFloat(11)
        let chevronSize = CGSize(width: 8, height: 14)
        
        let titleX = unreadIndicatorX + unreadIndicatorSideLength + 15
        let titleMaxX = size.width - adjustedMargins.right - chevronSize.width - 28
        
        let titleMaximumWidth = titleMaxX - titleX
        let titleOrigin = CGPoint(x: titleX, y: adjustedMargins.top)
        
        let semanticContentAttribute: UISemanticContentAttribute = traitCollection.layoutDirection == .rightToLeft ? .forceRightToLeft : .forceLeftToRight
        let titleLabelFrame = titleLabel.wmf_preferredFrame(at: titleOrigin, maximumWidth: titleMaximumWidth, alignedBy: semanticContentAttribute, apply: apply)
        
        let finalHeight = adjustedMargins.top + titleLabelFrame.size.height + adjustedMargins.bottom
        
        if apply {
            
            dividerView.frame = CGRect(x: 0, y: finalHeight - 1, width: size.width, height: 1)
            unreadView.frame = CGRect(x: unreadIndicatorX, y: (finalHeight / 2) - (unreadIndicatorSideLength / 2), width: unreadIndicatorSideLength, height: unreadIndicatorSideLength)
            chevronImageView.frame = CGRect(x: size.width - adjustedMargins.right - chevronSize.height, y: (finalHeight / 2) - (chevronSize.height / 2), width: chevronSize.width, height: chevronSize.height)
        }
        
        return CGSize(width: size.width, height: finalHeight)
    }
    
    func configure(title: String) {
        titleLabel.text = title
        updateFonts(with: traitCollection)
        setNeedsLayout()
    }
    
    override func updateFonts(with traitCollection: UITraitCollection) {
        super.updateFonts(with: traitCollection)
        titleLabel.font = UIFont.wmf_font(.body, compatibleWithTraitCollection: traitCollection)
    }
    
    override func setup() {
        chevronImageView.image = UIImage.wmf_imageFlipped(forRTLLayoutDirectionNamed: "chevron-right")
        unreadView.layer.cornerRadius = 5.5
        contentView.addSubview(titleLabel)
        contentView.addSubview(dividerView)
        contentView.addSubview(unreadView)
        contentView.addSubview(chevronImageView)
        super.setup()
    }
}

extension DiscussionListItemCollectionViewCell: Themeable {
    func apply(theme: Theme) {
        titleLabel.textColor = theme.colors.primaryText
        setBackgroundColors(theme.colors.paperBackground, selected: theme.colors.baseBackground)
        dividerView.backgroundColor = theme.colors.border
        unreadView.backgroundColor = theme.colors.unreadIndicator
        chevronImageView.tintColor = theme.colors.secondaryText
    }
}
