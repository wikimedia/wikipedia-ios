import UIKit

public protocol CardContent {
    var view: UIView! { get }
    func contentHeight(forWidth: CGFloat) -> CGFloat
}

public protocol ExploreCardCollectionViewCellDelegate: class {
    func exploreCardCollectionViewCellWantsCustomization(_ cell: ExploreCardCollectionViewCell)
    func exploreCardCollectionViewCellWantsToUndoCustomization(_ cell: ExploreCardCollectionViewCell)
}
    
public class ExploreCardCollectionViewCell: CollectionViewCell, Themeable {
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    public let customizationButton = UIButton()
    private let undoButton = UIButton()
    private let undoLabel = UILabel()
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
        undoLabel.numberOfLines = 0
        undoLabel.isOpaque = true
        contentView.addSubview(undoLabel)
        undoButton.isOpaque = true
        undoButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        undoButton.setTitle("Undo", for: .normal)
        undoButton.addTarget(self, action: #selector(undoButtonPressed), for: .touchUpInside)
        undoButton.isUserInteractionEnabled = true
        undoButton.titleLabel?.textAlignment = .right
        contentView.addSubview(undoButton)
    }
    
    // This method is called to reset the cell to the default configuration. It is called on initial setup and prepareForReuse. Subclassers should call super.
    override open func reset() {
        super.reset()
        layoutMargins = UIEdgeInsets(top: 15, left: 13, bottom: 15, right: 13)
        footerButton.isHidden = true
        undoButton.isHidden = true
        undoLabel.isHidden = true
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

    private var undoTitle: String? {
        didSet {
            undoLabel.text = undoTitle
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

    public var undoType: WMFContentGroupUndoType = .none {
        didSet {
            switch undoType {
            case .none:
                isCollapsed = false
            case .contentGroup:
                undoTitle = WMFLocalizedString("explore-feed-preferences-card-hidden-title", value: "Card hidden", comment: "Title for button that appears in place of feed card hidden by user via the overflow button")
                isCollapsed = true
            case .contentGroupKind:
                guard let title = title else {
                    return
                }
                undoTitle = String.localizedStringWithFormat(WMFLocalizedString("explore-feed-preferences-feed-cards-hidden-title", value: "All %@ cards hidden", comment: "Title for cell that appears in place of feed card hidden by user via the overflow button - %@ is replaced with feed card type"), title)
                isCollapsed = true
            }
        }
    }

    private var isCollapsed: Bool = false {
        didSet {
            if isCollapsed {
                undoLabel.isHidden = false
                customizationButton.isHidden = true
                undoButton.isHidden = false
                cardContent?.view.isHidden = true
                titleLabel.isHidden = true
                subtitleLabel.isHidden = true
                footerButton.isHidden = true
            } else {
                cardContent?.view.isHidden = false
                undoLabel.isHidden = true
                undoButton.isHidden = true
                titleLabel.isHidden = title == nil
                subtitleLabel.isHidden = subtitle == nil
                footerButton.isHidden = footerTitle == nil
            }
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

        if !titleLabel.isHidden {
            origin.y += titleLabel.wmf_preferredHeight(at: labelOrigin, maximumWidth: widthMinusMargins - customizationButtonDeltaWidthMinusMargins, horizontalAlignment: labelHorizontalAlignment, spacing: 4, apply: apply)
            labelOrigin.y = origin.y
        }
        if !subtitleLabel.isHidden {
            origin.y += subtitleLabel.wmf_preferredHeight(at: labelOrigin, maximumWidth: widthMinusMargins - customizationButtonDeltaWidthMinusMargins, horizontalAlignment: labelHorizontalAlignment, spacing: 20, apply: apply)
        }
        
        if let cardContent = cardContent, !cardContent.view.isHidden {
            let view = cardContent.view
            let height = cardContent.contentHeight(forWidth: widthMinusMargins)
            let cardContentViewFrame = CGRect(origin: origin, size: CGSize(width: widthMinusMargins, height: height))
            if apply {
                view?.frame = cardContentViewFrame
                cardBackgroundView.frame = cardContentViewFrame.insetBy(dx: -singlePixelDimension, dy: -singlePixelDimension)
            }
            origin.y += cardContentViewFrame.layoutHeight(with: 20)
        } else if isCollapsed {
            if apply {
                let cardBackgroundViewFrame = CGRect(x: layoutMargins.left, y: labelOrigin.y, width: widthMinusMargins, height: contentView.frame.height)
                cardBackgroundView.frame = cardBackgroundViewFrame
            }
        }

        if !undoLabel.isHidden {
            let undoLabelOrigin = CGPoint(x: labelOrigin.x + 8, y: cardBackgroundView.frame.midY)
            var undoLabelFrame = undoLabel.wmf_preferredFrame(at: undoLabelOrigin, maximumWidth: widthMinusMargins, minimumWidth: widthMinusMargins, horizontalAlignment: labelHorizontalAlignment, apply: false)
            let halfHeight = round(0.5 * undoLabelFrame.height)
            undoLabelFrame.origin.y -= halfHeight
            undoLabel.frame = undoLabelFrame
        }

        if !undoButton.isHidden {
            let undoButtonOrigin = CGPoint(x: origin.x, y: undoLabel.frame.origin.y)
            origin.y += undoButton.wmf_preferredHeight(at: undoButtonOrigin, maximumWidth: widthMinusMargins, horizontalAlignment: buttonHorizontalAlignment, spacing: 20, apply: apply)
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
        undoLabel.font = UIFont.wmf_font(.subheadline, compatibleWithTraitCollection: traitCollection)
        undoButton.titleLabel?.font = UIFont.wmf_font(.semiboldSubheadline, compatibleWithTraitCollection: traitCollection)
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
        undoLabel.backgroundColor = labelBackgroundColor
        undoButton.backgroundColor = labelBackgroundColor
        customizationButton.backgroundColor = labelBackgroundColor
    }
    
    public func apply(theme: Theme) {
        contentView.tintColor = theme.colors.link
        contentView.backgroundColor = theme.colors.paperBackground
        let backgroundColor = isCollapsed ? theme.colors.cardButtonBackground : theme.colors.paperBackground
        let selectedBackgroundColor = isCollapsed ? theme.colors.cardButtonBackground : theme.colors.midBackground
        let cardBackgroundViewBorderColor = isCollapsed ? backgroundColor.cgColor : theme.colors.cardBorder.cgColor
        cardBackgroundView.layer.borderColor = cardBackgroundViewBorderColor
        setBackgroundColors(backgroundColor, selected: selectedBackgroundColor)
        titleLabel.textColor = theme.colors.primaryText
        subtitleLabel.textColor = theme.colors.secondaryText
        customizationButton.setTitleColor(theme.colors.link, for: .normal)
        footerButton.setTitleColor(theme.colors.link, for: .normal)
        undoLabel.textColor = theme.colors.primaryText
        undoButton.setTitleColor(theme.colors.link, for: .normal)
        updateSelectedOrHighlighted()
        cardBackgroundView.backgroundColor = backgroundColor
        cardShadowColor = theme.colors.cardShadow
        cardContent?.apply(theme: theme)
    }
    
    @objc func customizationButtonPressed() {
        delegate?.exploreCardCollectionViewCellWantsCustomization(self)
    }

    @objc func undoButtonPressed() {
        delegate?.exploreCardCollectionViewCellWantsToUndoCustomization(self)
    }
}
