import UIKit

public protocol CardContent {
    var view: UIView! { get }
    func contentHeight(forWidth: CGFloat) -> CGFloat
}
    
public class ExploreCardCollectionViewCell: CollectionViewCell, Themeable {
    public let titleLabel = UILabel()
    public let subtitleLabel = UILabel()
    public let customizationButton = UIButton()
    public let footerButton = AlignedImageButton()
    
    private let cardBackgroundView = UIView()
    private let cardCornerRadius = CGFloat(10)
    private let cardShadowRadius = CGFloat(5)
    private let cardShadowOpacity = Float(0.25)
    private let cardShadowOffset =  CGSize(width: 0, height: 5)
    
    public override func setup() {
        super.setup()
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        customizationButton.setTitle("⋮", for: UIControlState.normal)
        cardBackgroundView.layer.cornerRadius = cardCornerRadius
        cardBackgroundView.layer.shadowOffset = cardShadowOffset
        cardBackgroundView.layer.shadowRadius = cardShadowRadius
        cardBackgroundView.layer.shadowColor = cardShadowColor.cgColor
        cardBackgroundView.layer.shadowOpacity = cardShadowOpacity
        cardBackgroundView.layer.masksToBounds = false
        contentView.addSubview(cardBackgroundView)
        contentView.addSubview(customizationButton)
        contentView.addSubview(footerButton)
    }
    
    // This method is called to reset the cell to the default configuration. It is called on initial setup and prepareForReuse. Subclassers should call super.
    override open func reset() {
        super.reset()
        layoutMargins = UIEdgeInsets(top: 15, left: 13, bottom: 15, right: 13)
    }
    
    public var cardContent: (CardContent & Themeable)? = nil {
        didSet {
            oldValue?.view?.removeFromSuperview()
            guard let view = cardContent?.view else {
                return
            }
            view.layer.cornerRadius = cardCornerRadius
            contentView.addSubview(view)
        }
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
        origin.y += subtitleLabelFrame.layoutHeight(with: 20)
        
        if let cardContent = cardContent {
            let view = cardContent.view
            let height = cardContent.contentHeight(forWidth: widthMinusMargins)
            let cardContentViewFrame = CGRect(origin: origin, size: CGSize(width: widthMinusMargins, height: height))
            if apply {
                view?.frame = cardContentViewFrame
                cardBackgroundView.frame = cardContentViewFrame
            }
            origin.y += cardContentViewFrame.layoutHeight(with: 20)
        }
    
        if footerButton.titleLabel?.wmf_hasAnyNonWhitespaceText ?? false {
            let footerButtonFrame = footerButton.wmf_preferredFrame(at: origin, fitting: widthMinusMargins, alignedBy: semanticContentAttribute, apply: apply)
            origin.y += footerButtonFrame.layoutHeight(with: 20)
        }
       
        
        return CGSize(width: size.width, height: origin.y)
    }
    
    public override func updateFonts(with traitCollection: UITraitCollection) {
        super.updateFonts(with: traitCollection)
        titleLabel.font = UIFont.wmf_font(.semiboldSubheadline, compatibleWithTraitCollection: traitCollection)
        subtitleLabel.font = UIFont.wmf_font(.subheadline, compatibleWithTraitCollection: traitCollection)
        footerButton.titleLabel?.font = UIFont.wmf_font(.semiboldSubheadline, compatibleWithTraitCollection: traitCollection)
        customizationButton.titleLabel?.font = UIFont.wmf_font(.boldTitle1, compatibleWithTraitCollection: traitCollection)
    }
    
    private var cardShadowColor: UIColor = .black {
        didSet {
            cardBackgroundView.layer.shadowColor = cardShadowColor.cgColor
        }
    }
    
    public func apply(theme: Theme) {
        setBackgroundColors(theme.colors.paperBackground, selected: theme.colors.midBackground)
        titleLabel.textColor = theme.colors.primaryText
        subtitleLabel.textColor = theme.colors.secondaryText
        customizationButton.setTitleColor(theme.colors.link, for: .normal)
        footerButton.setTitleColor(theme.colors.link, for: .normal)
        updateSelectedOrHighlighted()
        cardBackgroundView.backgroundColor = theme.colors.paperBackground
        cardShadowColor = theme.colors.cardShadow
        cardContent?.apply(theme: theme)
    }
    
}
