import UIKit

public protocol CardContent {
    var view: UIView! { get }
    func contentHeight(forWidth: CGFloat) -> CGFloat
}

public protocol ExploreCardCollectionViewCellDelegate: class {
    func exploreCardCollectionViewCellWantsCustomization(_ cell: ExploreCardCollectionViewCell)
}
    
public class ExploreCardCollectionViewCell: CollectionViewCell, Themeable {
    public let titleLabel = UILabel()
    public let subtitleLabel = UILabel()
    public let customizationButton = UIButton()
    public let footerButton = AlignedImageButton()
    public weak var delegate: ExploreCardCollectionViewCellDelegate?
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
        customizationButton.addTarget(self, action: #selector(customizationButtonPressed), for: .touchUpInside)
        cardBackgroundView.layer.cornerRadius = cardCornerRadius
        cardBackgroundView.layer.shadowOffset = cardShadowOffset
        cardBackgroundView.layer.shadowRadius = cardShadowRadius
        cardBackgroundView.layer.shadowColor = cardShadowColor.cgColor
        cardBackgroundView.layer.shadowOpacity = cardShadowOpacity
        cardBackgroundView.layer.masksToBounds = false
        contentView.addSubview(cardBackgroundView)
        contentView.addSubview(customizationButton)
        footerButton.imageIsRightAligned = true
        footerButton.setImage(#imageLiteral(resourceName: "places-more"), for: .normal)
        footerButton.isUserInteractionEnabled = false
        footerButton.titleLabel?.numberOfLines = 0
        contentView.addSubview(footerButton)
    }
    
    // This method is called to reset the cell to the default configuration. It is called on initial setup and prepareForReuse. Subclassers should call super.
    override open func reset() {
        super.reset()
        layoutMargins = UIEdgeInsets(top: 15, left: 13, bottom: 15, right: 13)
        footerButton.isHidden = true
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
            customizationButtonSize = customizationButton.wmf_sizeThatFits(CGSize(width: widthMinusMargins, height: UIViewNoIntrinsicMetric))
            var x = layoutMargins.right
            if !isRTL {
                x = size.width - x - customizationButtonSize.width
            }
            if apply {
                customizationButton.frame = CGRect(origin: CGPoint(x: x, y: origin.y), size: customizationButtonSize)
            }
        }
        
        origin.y += titleLabel.wmf_preferredHeight(at: origin, maximumWidth: widthMinusMargins - customizationButtonSize.width, alignedBy: semanticContentAttribute, spacing: 4, apply: apply)
        origin.y += subtitleLabel.wmf_preferredHeight(at: origin, maximumWidth: widthMinusMargins - customizationButtonSize.width, alignedBy: semanticContentAttribute, spacing: 20, apply: apply)
        
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
    
        if footerButton.title(for: .normal) != nil {
            footerButton.isHidden = false
            origin.y += footerButton.wmf_preferredHeight(at: origin, maximumWidth: widthMinusMargins, horizontalAlignment: semanticContentAttribute == .forceRightToLeft ? .left : .right, spacing: 20, apply: apply)
        } else {
            footerButton.isHidden = true
        }

        return CGSize(width: size.width, height: ceil(origin.y))
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
        contentView.tintColor = theme.colors.link
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
    
    @objc func customizationButtonPressed() {
        delegate?.exploreCardCollectionViewCellWantsCustomization(self)
    }
}
