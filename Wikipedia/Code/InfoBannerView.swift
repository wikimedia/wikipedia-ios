
import UIKit

class InfoBannerView: SetupView {
    
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    
    var isDynamicFont: Bool = true {
        didSet {
            updateFonts(with: traitCollection)
        }
    }

    func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        
        let semanticContentAttribute: UISemanticContentAttribute = traitCollection.layoutDirection == .rightToLeft ? .forceRightToLeft : .forceLeftToRight
        let isRTL = semanticContentAttribute == .forceRightToLeft
        
        let adjustedMargins = UIEdgeInsets(top: layoutMargins.top, left: layoutMargins.left + 13, bottom: layoutMargins.bottom, right: layoutMargins.right + 13)
        
        let iconImageSideLength = CGFloat(26)
        let iconTextSpacing = CGFloat(10)
        let titleSubtitleSpacing = UIStackView.spacingUseSystem
        
        let titleLabelOrigin = isRTL ? CGPoint(x: adjustedMargins.left, y: adjustedMargins.top) : CGPoint(x: adjustedMargins.left + iconImageSideLength + iconTextSpacing, y: adjustedMargins.top)
        let titleLabelWidth = size.width - adjustedMargins.left - adjustedMargins.right - iconImageSideLength - iconTextSpacing

        let titleLabelFrame = titleLabel.wmf_preferredFrame(at: titleLabelOrigin, maximumWidth: titleLabelWidth, minimumWidth: titleLabelWidth, alignedBy: semanticContentAttribute, apply: apply)
        
        let subtitleLabelOrigin = CGPoint(x: titleLabelOrigin.x, y: titleLabelFrame.maxY + titleSubtitleSpacing)
        let subtitleLabelWidth = titleLabelWidth
        
        let subtitleLabelFrame = subtitleLabel.wmf_preferredFrame(at: subtitleLabelOrigin, maximumWidth: subtitleLabelWidth, minimumWidth: subtitleLabelWidth, alignedBy: semanticContentAttribute, apply: apply)
        
        let finalHeight = adjustedMargins.top + titleLabelFrame.size.height + subtitleLabelFrame.height + adjustedMargins.bottom
        
        if (apply) {
            iconImageView.frame = isRTL ? CGRect(x: adjustedMargins.left + titleLabelWidth + iconTextSpacing, y: (finalHeight / 2) - (iconImageSideLength / 2), width: iconImageSideLength, height: iconImageSideLength) : CGRect(x: adjustedMargins.left, y: (finalHeight / 2) - (iconImageSideLength / 2), width: iconImageSideLength, height: iconImageSideLength)
        }
        
        return CGSize(width: size.width, height: finalHeight)
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return sizeThatFits(size, apply: false)
    }
    
    func configure(iconName: String, title: String, subtitle: String) {
        iconImageView.image = UIImage.init(named: iconName)
        titleLabel.text = title
        subtitleLabel.text = subtitle
        
        accessibilityLabel = "\(title)\n\(subtitle)"
    }
    
    // MARK - Dynamic Type
    // Only applies new fonts if the content size category changes
    
    open override func setNeedsLayout() {
        maybeUpdateFonts(with: traitCollection)
        super.setNeedsLayout()
    }
    
    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        setNeedsLayout()
    }
    
    var contentSizeCategory: UIContentSizeCategory?
    fileprivate func maybeUpdateFonts(with traitCollection: UITraitCollection) {
        guard contentSizeCategory == nil || contentSizeCategory != traitCollection.wmf_preferredContentSizeCategory else {
            return
        }
        contentSizeCategory = traitCollection.wmf_preferredContentSizeCategory
        updateFonts(with: traitCollection)
    }
    
    func updateFonts(with traitCollection: UITraitCollection) {
        if !isDynamicFont {
            titleLabel.font = UIFont.systemFont(ofSize: 13.0, weight: .medium)
            subtitleLabel.font = UIFont.systemFont(ofSize: 12.0, weight: .regular)
        } else {
            titleLabel.font = UIFont.wmf_font(.mediumFootnote, compatibleWithTraitCollection: traitCollection)
            subtitleLabel.font = UIFont.wmf_font(.caption1, compatibleWithTraitCollection: traitCollection)
        }
    }

    override func setup() {
        autoresizesSubviews = false
        titleLabel.numberOfLines = 0
        subtitleLabel.numberOfLines = 0
        addSubview(iconImageView)
        addSubview(titleLabel)
        addSubview(subtitleLabel)
        
        titleLabel.isAccessibilityElement = false
        subtitleLabel.isAccessibilityElement = false
        
        isAccessibilityElement = true

        updateFonts(with: traitCollection)
    }
}

//MARK: Themable

extension InfoBannerView: Themeable {
    func apply(theme: Theme) {
        backgroundColor = theme.colors.hintBackground
        titleLabel.textColor = theme.colors.link
        subtitleLabel.textColor = theme.colors.link
    }
}
