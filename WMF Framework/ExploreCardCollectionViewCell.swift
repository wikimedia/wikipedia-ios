import UIKit

public protocol CardContent {
    var view: UIView! { get }
    func contentHeight(forWidth: CGFloat) -> CGFloat
}

public protocol ExploreCardCollectionViewCellDelegate: class {
    func exploreCardCollectionViewCellWantsCustomization(_ cell: ExploreCardCollectionViewCell)
}
    
public class ExploreCardCollectionViewCell: CollectionViewCell, Themeable {
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    public let customizationButton = UIButton()
    private let footerButton = AlignedImageButton()
    public weak var delegate: ExploreCardCollectionViewCellDelegate?
    private let cardBackgroundView = UIView()
    private let cardCornerRadius = CGFloat(10)
    private let cardShadowRadius = CGFloat(10)
    private let cardShadowOpacity = Float(0.13)
    private let cardShadowOffset =  CGSize(width: 0, height: 2)
    
    static let overflowImage = UIImage(named: "overflow")
    
    public var singlePixelDimension: CGFloat = 0.5
    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        singlePixelDimension = traitCollection.displayScale > 0 ? 1.0/traitCollection.displayScale : 0.5
    }
    
    public override func setup() {
        super.setup()
        titleLabel.numberOfLines = 0
        titleLabel.isOpaque = true
        contentView.addSubview(titleLabel)
        subtitleLabel.numberOfLines = 0
        subtitleLabel.isOpaque = true
        contentView.addSubview(subtitleLabel)
        customizationButton.setImage(ExploreCardCollectionViewCell.overflowImage, for: .normal)
        customizationButton.contentEdgeInsets = .zero
        customizationButton.imageEdgeInsets = .zero
        customizationButton.titleEdgeInsets = .zero
        customizationButton.titleLabel?.textAlignment = .center
        customizationButton.isOpaque = true
        customizationButton.addTarget(self, action: #selector(customizationButtonPressed), for: .touchUpInside)
        cardBackgroundView.layer.borderWidth = singlePixelDimension
        cardBackgroundView.layer.cornerRadius = cardCornerRadius
        cardBackgroundView.layer.shadowOffset = cardShadowOffset
        cardBackgroundView.layer.shadowRadius = cardShadowRadius
        cardBackgroundView.layer.shadowColor = cardShadowColor.cgColor
        cardBackgroundView.layer.shadowOpacity = cardShadowOpacity
        cardBackgroundView.layer.masksToBounds = false
        cardBackgroundView.isOpaque = true
        contentView.addSubview(cardBackgroundView)
        contentView.addSubview(customizationButton)
        footerButton.imageIsRightAligned = true
        footerButton.isOpaque = true
        let image = #imageLiteral(resourceName: "places-more").imageFlippedForRightToLeftLayoutDirection()
        footerButton.setImage(image, for: .normal)
        footerButton.isUserInteractionEnabled = false
        footerButton.titleLabel?.numberOfLines = 0
        footerButton.titleLabel?.textAlignment = .right
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
    
    public var footerTitle: String? {
        get {
            return footerButton.title(for: .normal)
        }
        set {
            footerButton.setTitle(newValue, for: .normal)
            footerButton.isHidden = newValue == nil
            setNeedsLayout()
        }
    }
    
    public var title: String? {
        get {
            return titleLabel.text
        }
        set {
            titleLabel.text = newValue
            setNeedsLayout()
        }
    }
    
    public var subtitle: String? {
        get {
            return subtitleLabel.text
        }
        set {
            subtitleLabel.text = newValue
            setNeedsLayout()
        }
    }
    
    public var isCustomizationButtonHidden: Bool {
        get {
            return customizationButton.isHidden
        }
        set {
            customizationButton.isHidden = newValue
            setNeedsLayout()
        }
    }
    
    override public func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        let size = super.sizeThatFits(size, apply: apply) // intentionally shade size
        var origin = CGPoint(x: layoutMargins.left, y: layoutMargins.top)
        let widthMinusMargins = size.width - layoutMargins.left - layoutMargins.right
        let isRTL = traitCollection.layoutDirection == .rightToLeft
        let labelHorizontalAlignment: HorizontalAlignment = isRTL ? .right : .left
        let buttonHorizontalAlignment: HorizontalAlignment = isRTL ? .left : .right
        
        var customizationButtonDeltaWidthMinusMargins: CGFloat = 0
        if !customizationButton.isHidden {
            var customizationButtonFrame = customizationButton.wmf_preferredFrame(at: origin, maximumWidth: widthMinusMargins, minimumWidth: 44, horizontalAlignment: buttonHorizontalAlignment, apply: false)
            let halfWidth = round(0.5 * customizationButtonFrame.width)
            customizationButtonFrame.origin.x = isRTL ? layoutMargins.left - halfWidth : size.width - layoutMargins.right - halfWidth
            customizationButtonDeltaWidthMinusMargins = halfWidth
            if apply {
                customizationButton.frame = customizationButtonFrame
            }
        }
        
        var labelOrigin = origin
        if isRTL {
            labelOrigin.x += customizationButtonDeltaWidthMinusMargins
        }
        origin.y += titleLabel.wmf_preferredHeight(at: labelOrigin, maximumWidth: widthMinusMargins - customizationButtonDeltaWidthMinusMargins, horizontalAlignment: labelHorizontalAlignment, spacing: 4, apply: apply)
        labelOrigin.y = origin.y
        origin.y += subtitleLabel.wmf_preferredHeight(at: labelOrigin, maximumWidth: widthMinusMargins - customizationButtonDeltaWidthMinusMargins, horizontalAlignment: labelHorizontalAlignment, spacing: 20, apply: apply)
        
        if let cardContent = cardContent {
            let view = cardContent.view
            let height = cardContent.contentHeight(forWidth: widthMinusMargins)
            let cardContentViewFrame = CGRect(origin: origin, size: CGSize(width: widthMinusMargins, height: height))
            if apply {
                view?.frame = cardContentViewFrame
                cardBackgroundView.frame = cardContentViewFrame.insetBy(dx: -singlePixelDimension, dy: -singlePixelDimension)
            }
            origin.y += cardContentViewFrame.layoutHeight(with: 20)
        }
    
        if !footerButton.isHidden {
            origin.y += footerButton.wmf_preferredHeight(at: origin, maximumWidth: widthMinusMargins, horizontalAlignment: buttonHorizontalAlignment, spacing: 20, apply: apply)
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
    
    public override func updateBackgroundColorOfLabels() {
        super.updateBackgroundColorOfLabels()
        titleLabel.backgroundColor = labelBackgroundColor
        subtitleLabel.backgroundColor = labelBackgroundColor
        footerButton.backgroundColor = labelBackgroundColor
        customizationButton.backgroundColor = labelBackgroundColor
    }
    
    public func apply(theme: Theme) {
        contentView.tintColor = theme.colors.link
        cardBackgroundView.layer.borderColor = theme.colors.cardBorder.cgColor
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
