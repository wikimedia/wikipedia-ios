import UIKit

public protocol CardContent {
    var view: UIView! { get }
}
    
public class ExploreCardCollectionViewCell: CollectionViewCell, Themeable {
    public let titleLabel = UILabel()
    public let subtitleLabel = UILabel()
    public let customizationButton = UIButton()
    public let footerButton = AlignedImageButton()
    
    public override func setup() {
        super.setup()
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        customizationButton.setTitle(":", for: UIControlState.normal)
        contentView.addSubview(customizationButton)
        contentView.addSubview(footerButton)
    }
    
    // This method is called to reset the cell to the default configuration. It is called on initial setup and prepareForReuse. Subclassers should call super.
    override open func reset() {
        super.reset()
        layoutMargins = UIEdgeInsets(top: 15, left: 13, bottom: 15, right: 13)
        cardContent = nil
        cardContentSize = .zero
    }
    
    public var cardContent: CardContent? = nil {
        didSet {
            defer {
                setNeedsLayout()
            }
            oldValue?.view?.removeFromSuperview()
            guard let view = cardContent?.view else {
                return
            }
            view.removeFromSuperview()
            view.isHidden = false
            view.autoresizingMask = []
            view.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(view)
        }
    }
    
    public var cardContentSize: CGSize = .zero {
        didSet {
            setNeedsLayout()
        }
    }
    
    public func contentWidth(for cellWidth: CGFloat) -> CGFloat {
        return cellWidth - layoutMargins.left - layoutMargins.right
    }
    
    override public func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        let size = super.sizeThatFits(size, apply: apply) // intentionally shade size
        var origin = CGPoint(x: layoutMargins.left, y: layoutMargins.top)
        let widthMinusMargins = size.width - layoutMargins.left - layoutMargins.right
        let isRTL = semanticContentAttribute == .forceRightToLeft

        var customizationButtonSize = CGSize.zero
        if !customizationButton.isHidden {
            customizationButtonSize = customizationButton.sizeThatFits(CGSize(width: widthMinusMargins, height: UIViewNoIntrinsicMetric))
            var x = layoutMargins.right
            if !isRTL {
                x = size.width - x - customizationButtonSize.width
            }
            if apply {
                customizationButton.frame = CGRect(origin: CGPoint(x: x, y: origin.y), size: customizationButtonSize)
            }
        }
        
        let titleLabelFrame = titleLabel.wmf_preferredFrame(at: origin, fitting: widthMinusMargins - customizationButtonSize.width, alignedBy: semanticContentAttribute, apply: apply)
        origin.y += titleLabelFrame.layoutHeight(with: 4)
        let subtitleLabelFrame = subtitleLabel.wmf_preferredFrame(at: origin, fitting: widthMinusMargins - customizationButtonSize.width, alignedBy: semanticContentAttribute, apply: apply)
        origin.y += subtitleLabelFrame.layoutHeight(with: 8)
        
        let cardContentViewFrame = CGRect(origin: origin, size: cardContentSize)
        if apply, let view = cardContent?.view {
            assert(view.superview == contentView)
            view.frame = cardContentViewFrame
        }
        origin.y += cardContentViewFrame.layoutHeight(with: 8)

        
        let footerButtonFrame = footerButton.wmf_preferredFrame(at: origin, fitting: widthMinusMargins, alignedBy: semanticContentAttribute, apply: apply)
        origin.y += footerButtonFrame.layoutHeight(with: 8)
        
        return CGSize(width: size.width, height: origin.y)
    }
    
    public override func updateFonts(with traitCollection: UITraitCollection) {
        super.updateFonts(with: traitCollection)
        titleLabel.font = UIFont.wmf_font(.headline, compatibleWithTraitCollection: traitCollection)
        subtitleLabel.font = UIFont.wmf_font(.subheadline, compatibleWithTraitCollection: traitCollection)
    }
    
    
    public func apply(theme: Theme) {
        setBackgroundColors(theme.colors.paperBackground, selected: theme.colors.midBackground)
        titleLabel.textColor = theme.colors.primaryText
        subtitleLabel.textColor = theme.colors.secondaryText
        customizationButton.setTitleColor(theme.colors.link, for: .normal)
        footerButton.setTitleColor(theme.colors.link, for: .normal)
        updateSelectedOrHighlighted()
    }
    
}
