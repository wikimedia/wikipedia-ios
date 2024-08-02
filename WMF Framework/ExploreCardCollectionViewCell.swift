import WMFComponents

public protocol CardContent {
    var view: UIView! { get }
    func contentHeight(forWidth: CGFloat) -> CGFloat
}

// Allows the card background view to communicate with the cell to detect taps in the title area
// A Random article card navigates to different destinations depending on whether the area
// above or below the card content is tapped.
fileprivate protocol CardBackgroundViewDelegate: UIView {
    func titleAreaYThreshold(for cardBackgroundView: CardBackgroundView) -> CGFloat // Return value in the coordinate system of the card background view
    var titleAreaTapped: Bool { get set }
}
private class CardBackgroundView: UIView {
    fileprivate weak var delegate: CardBackgroundViewDelegate?
    override public func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if let delegate = delegate {
            let yThreshold = delegate.titleAreaYThreshold(for: self)
            delegate.titleAreaTapped = point.y < yThreshold
        }
        return super.hitTest(point, with: event)
    }
}

public protocol ExploreCardCollectionViewCellDelegate: AnyObject {
    func exploreCardCollectionViewCellWantsCustomization(_ cell: ExploreCardCollectionViewCell)
    func exploreCardCollectionViewCellWantsToUndoCustomization(_ cell: ExploreCardCollectionViewCell)
}
    
public class ExploreCardCollectionViewCell: CollectionViewCell, CardBackgroundViewDelegate, Themeable {
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    public let customizationButton = UIButton()
    private let undoButton = UIButton()
    private let undoLabel = UILabel()
    private let footerButton = AlignedImageButton()
    public weak var delegate: ExploreCardCollectionViewCellDelegate?
    private let cardBackgroundView = CardBackgroundView()
    private let cardCornerRadius = Theme.exploreCardCornerRadius
    private let cardShadowRadius = CGFloat(10)
    private let cardShadowOffset =  CGSize(width: 0, height: 2)
    public var titleAreaTapped: Bool = false

    static let overflowImage = UIImage(named: "overflow")
    
    public override func setup() {
        super.setup()
        titleLabel.numberOfLines = 0
        contentView.addSubview(titleLabel)
        subtitleLabel.numberOfLines = 0
        contentView.addSubview(subtitleLabel)
        customizationButton.setImage(ExploreCardCollectionViewCell.overflowImage, for: .normal)
        var deprecatedCustomizationButton = customizationButton as DeprecatedButton
        deprecatedCustomizationButton.deprecatedContentEdgeInsets = .zero
        deprecatedCustomizationButton.deprecatedImageEdgeInsets = .zero
        deprecatedCustomizationButton.deprecatedTitleEdgeInsets = .zero
        customizationButton.titleLabel?.textAlignment = .center
        customizationButton.addTarget(self, action: #selector(customizationButtonPressed), for: .touchUpInside)
        cardBackgroundView.layer.cornerRadius = cardCornerRadius
        cardBackgroundView.layer.shadowOffset = cardShadowOffset
        cardBackgroundView.layer.shadowRadius = cardShadowRadius
        cardBackgroundView.layer.shadowColor = cardShadowColor.cgColor
        cardBackgroundView.layer.shadowOpacity = cardShadowOpacity
        cardBackgroundView.layer.masksToBounds = false
        cardBackgroundView.isOpaque = true
        cardBackgroundView.delegate = self
        contentView.addSubview(cardBackgroundView)
        contentView.addSubview(customizationButton)
        footerButton.imageIsRightAligned = true
        let image = #imageLiteral(resourceName: "places-more").imageFlippedForRightToLeftLayoutDirection()
        footerButton.setImage(image, for: .normal)
        footerButton.isUserInteractionEnabled = false
        footerButton.titleLabel?.numberOfLines = 0
        footerButton.titleLabel?.textAlignment = .right
        contentView.addSubview(footerButton)
        undoLabel.numberOfLines = 0
        contentView.addSubview(undoLabel)
        undoButton.titleLabel?.numberOfLines = 0
        undoButton.setTitle(CommonStrings.undo, for: .normal)
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
    
    fileprivate func titleAreaYThreshold(for cardBackgroundView: CardBackgroundView) -> CGFloat {
        // The title area is defined to include card background from its top down to the bottom of the card content
        // This registers taps on the side margins of the card content as in the title area
        let yThreshold = cardContent?.view?.frame.maxY ?? 0.0
        let convertedPoint = convert(CGPoint(x: 0.0, y: yThreshold), to: cardBackgroundView)
        return convertedPoint.y
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
            case .contentGroup:
                undoTitle = WMFLocalizedString("explore-feed-preferences-card-hidden-title", value: "Card hidden", comment: "Title for button that appears in place of feed card hidden by user via the overflow button")
                isCollapsed = true
            case .contentGroupKind:
                guard let title = title else {
                    return
                }
                undoTitle = String.localizedStringWithFormat(WMFLocalizedString("explore-feed-preferences-feed-cards-hidden-title", value: "All %@ cards hidden", comment: "Title for cell that appears in place of feed card hidden by user via the overflow button - %@ is replaced with feed card type"), title)
                isCollapsed = true
            default:
               isCollapsed = false
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
                UIAccessibility.post(notification: UIAccessibility.Notification.layoutChanged, argument: undoButton)
            } else {
                cardContent?.view.isHidden = false
                undoLabel.isHidden = true
                undoButton.isHidden = true
                titleLabel.isHidden = title == nil
                subtitleLabel.isHidden = subtitle == nil || subtitle == ""
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
            let customizationButtonSize = CGSize(width: 50, height: 50)
            let customizationButtonNudgeWidth = round(0.55 * customizationButtonSize.width)
            customizationButtonDeltaWidthMinusMargins = customizationButtonNudgeWidth
            if apply {
                let originX = isRTL ? layoutMargins.left - customizationButtonSize.width + customizationButtonNudgeWidth : size.width - layoutMargins.right - customizationButtonNudgeWidth
                let originY = origin.y - round(0.25 * customizationButtonSize.height)
                let customizationButtonOrigin = CGPoint(x: originX, y: originY)
                customizationButton.frame = CGRect(origin: customizationButtonOrigin, size: customizationButtonSize)
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
        } else {
            origin.y += 20
        }

        if let cardContent = cardContent, !cardContent.view.isHidden {
            let view = cardContent.view
            let height = cardContent.contentHeight(forWidth: widthMinusMargins)
            let cardContentViewFrame = CGRect(origin: origin, size: CGSize(width: widthMinusMargins, height: height))
            if apply {
                view?.frame = cardContentViewFrame
                cardBackgroundView.frame = cardContentViewFrame.insetBy(dx: -cardBorderWidth, dy: -cardBorderWidth)
            }
            origin.y += cardContentViewFrame.height
        }

        if isCollapsed, !undoLabel.isHidden, !undoButton.isHidden {
            let undoOffset: UIOffset = UIOffset(horizontal: 15, vertical: 16)
            labelOrigin.x += undoOffset.horizontal
            labelOrigin.y += undoOffset.vertical

            let undoButtonMaxWidthPercentage: CGFloat = 0.25

            let undoLabelMaxWidth = widthMinusMargins - (widthMinusMargins * undoButtonMaxWidthPercentage)
            let undoLabelMinWidth = widthMinusMargins * 0.5
            let undoLabelX = isRTL ? widthMinusMargins - undoLabelMaxWidth : labelOrigin.x
            let undoLabelFrameHeight = undoLabel.wmf_preferredHeight(at: CGPoint(x: undoLabelX, y: labelOrigin.y), maximumWidth: undoLabelMaxWidth, minimumWidth: undoLabelMinWidth, horizontalAlignment: labelHorizontalAlignment, spacing: 0, apply: apply)

            let undoButtonMaxWidth = widthMinusMargins * undoButtonMaxWidthPercentage
            let undoButtonX = isRTL ? labelOrigin.x : widthMinusMargins - undoButtonMaxWidth
            let undoButtonMinSize = CGSize(width: UIView.noIntrinsicMetric, height: undoLabelFrameHeight)
            let undoButtonMaxSize = CGSize(width: undoButtonMaxWidth, height: UIView.noIntrinsicMetric)
            let undoButtonFrame = undoButton.wmf_preferredFrame(at: CGPoint(x: undoButtonX, y: labelOrigin.y), maximumSize: undoButtonMaxSize, minimumSize: undoButtonMinSize, horizontalAlignment: buttonHorizontalAlignment, apply: apply)
            let undoHeight = max(undoLabelFrameHeight, undoButtonFrame.height)
            
            // If cardBackgroundView metrics change double check the hitTest() override in CardBackgroundView
            let cardBackgroundViewHeight = undoHeight + undoOffset.vertical * 2
            let cardBackgroundViewFrame = CGRect(x: layoutMargins.left, y: layoutMargins.top, width: widthMinusMargins, height: cardBackgroundViewHeight)
            if apply {
                cardBackgroundView.frame = cardBackgroundViewFrame
            }

            origin.y += cardBackgroundViewFrame.height
        }
    
        if !footerButton.isHidden {
            origin.y += layoutMargins.bottom
            origin.y += footerButton.wmf_preferredHeight(at: origin, maximumWidth: widthMinusMargins, horizontalAlignment: buttonHorizontalAlignment, spacing: 0, apply: apply)
        }

        origin.y += layoutMargins.bottom
        
        let totalSize = CGSize(width: size.width, height: ceil(origin.y))
        
        if apply {
            cardBackgroundView.layer.shadowPath = UIBezierPath(roundedRect: cardBackgroundView.bounds, cornerRadius: cardBackgroundView.layer.cornerRadius).cgPath
        }

        return totalSize
    }
    
    public override func updateFonts(with traitCollection: UITraitCollection) {
        super.updateFonts(with: traitCollection)
        titleLabel.font = WMFFont.for(.semiboldSubheadline, compatibleWith: traitCollection)
        subtitleLabel.font = WMFFont.for(.subheadline, compatibleWith: traitCollection)
        footerButton.titleLabel?.font = WMFFont.for(.mediumSubheadline, compatibleWith: traitCollection)
        undoLabel.font = WMFFont.for(.subheadline, compatibleWith: traitCollection)
        undoButton.titleLabel?.font = WMFFont.for(.mediumSubheadline, compatibleWith: traitCollection)
        customizationButton.titleLabel?.font = WMFFont.for(.boldTitle1, compatibleWith: traitCollection)
    }
    
    private var cardShadowColor: UIColor = .black {
        didSet {
            cardBackgroundView.layer.shadowColor = cardShadowColor.cgColor
        }
    }
    
    private var cardShadowOpacity: Float = 0 {
        didSet {
            guard cardBackgroundView.layer.shadowOpacity != cardShadowOpacity else {
                return
            }
            cardBackgroundView.layer.shadowOpacity = cardShadowOpacity
        }
    }
    
    private var cardBorderWidth: CGFloat = 1 {
        didSet {
            cardBackgroundView.layer.borderWidth = cardBorderWidth
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
        let backgroundColor = isCollapsed ? theme.colors.cardButtonBackground : theme.colors.paperBackground
        let selectedBackgroundColor = isCollapsed ? theme.colors.cardButtonBackground : theme.colors.midBackground
        let cardBackgroundViewBorderColor = isCollapsed ? backgroundColor.cgColor : theme.colors.cardBorder.cgColor
        cardBackgroundView.layer.borderColor = cardBackgroundViewBorderColor
        setBackgroundColors(.clear, selected: selectedBackgroundColor)
        titleLabel.textColor = theme.colors.primaryText
        subtitleLabel.textColor = theme.colors.secondaryText
        customizationButton.setTitleColor(theme.colors.link, for: .normal)
        footerButton.setTitleColor(theme.colors.link, for: .normal)
        undoLabel.textColor = theme.colors.primaryText
        undoButton.setTitleColor(theme.colors.link, for: .normal)
        updateSelectedOrHighlighted()
        cardBackgroundView.backgroundColor = backgroundColor
        cardShadowOpacity = theme.cardShadowOpacity
        cardShadowColor = theme.colors.cardShadow
        cardContent?.apply(theme: theme)
        let displayScale = max(1, traitCollection.displayScale)
        cardBorderWidth = CGFloat(theme.cardBorderWidthInPixels) / displayScale
    }
    
    @objc func customizationButtonPressed() {
        delegate?.exploreCardCollectionViewCellWantsCustomization(self)
    }

    @objc func undoButtonPressed() {
        delegate?.exploreCardCollectionViewCellWantsToUndoCustomization(self)
    }
    
    // MARK: - Accessibility
    
    override open func updateAccessibilityElements() {
        var updatedAccessibilityElements: [Any] = []

        if isCollapsed {
            updatedAccessibilityElements.append(undoLabel)
            updatedAccessibilityElements.append(undoButton)
        } else {
            let groupedLabels = [titleLabel, subtitleLabel]
            let customizeActionTitle = WMFLocalizedString("explore-feed-customize-accessibility-title", value: "Customize", comment: "Accessibility title for feed customization")
            let customizeAction = UIAccessibilityCustomAction(name: customizeActionTitle, target: self, selector: #selector(customizationButtonPressed))
            updatedAccessibilityElements.append(LabelGroupAccessibilityElement(view: self, labels: groupedLabels, actions: [customizeAction]))
            if let contentView = cardContent?.view {
                updatedAccessibilityElements.append(contentView)
            }
            if !footerButton.isHidden, let label = footerButton.titleLabel {
                let footerElement = UIAccessibilityElement(accessibilityContainer: self)
                footerElement.isAccessibilityElement = true
                footerElement.accessibilityLabel = label.text
                footerElement.accessibilityTraits = UIAccessibilityTraits.link
                footerElement.accessibilityFrameInContainerSpace = footerButton.frame
                updatedAccessibilityElements.append(footerElement)
            }
        }
        
        accessibilityElements = updatedAccessibilityElements
    }
}
