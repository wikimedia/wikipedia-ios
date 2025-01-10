import WMFComponents

protocol CollectionViewHeaderDelegate: AnyObject {
    func collectionViewHeaderButtonWasPressed(_ collectionViewHeader: CollectionViewHeader)
}

class CollectionViewHeader: SizeThatFitsReusableView {
    weak var delegate: CollectionViewHeaderDelegate?
    
    public enum Style {
        case explore
        case detail
        case history
        case recentSearches
        case pageHistory
    }
    
    public var style: Style = .explore {
        didSet {
            updateFonts(with: traitCollection)
        }
    }

    private let titleLabel: UILabel = UILabel()
    private let subtitleLabel: UILabel = UILabel()
    private let button: UIButton = UIButton()
    private let spacing: CGFloat = 5
    
    var title: String? {
        get {
            return titleLabel.text
        }
        set {
            titleLabel.text = newValue
            setNeedsLayout()
        }
    }

    var titleTextColorKeyPath: KeyPath<Theme, UIColor> = \Theme.colors.primaryText
    
    var subtitle: String? {
        get {
            return subtitleLabel.text
        }
        set {
            subtitleLabel.text = newValue
            subtitleLabel.isHidden = subtitleLabel.text == nil
            setNeedsLayout()
        }
    }
    
    var buttonTitle: String? {
        get {
            return button.title(for: .normal)
        }
        set {
            button.setTitle(newValue, for: .normal)
            button.isHidden = newValue == nil
        }
    }

    override func setup() {
        super.setup()
        addSubview(button)
        addSubview(subtitleLabel)
        addSubview(titleLabel)
        button.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
        button.isHidden = true
    }
    
    @objc func buttonPressed(_ sender: UIButton?) {
        delegate?.collectionViewHeaderButtonWasPressed(self)
    }
    
    override func updateFonts(with traitCollection: UITraitCollection) {
        super.updateFonts(with: traitCollection)
        let titleTextStyle: WMFFont
        let subtitleTextStyle: WMFFont = .subheadline
        let buttonTextStyle: WMFFont = .subheadline
        switch style {
        case .detail:
            fallthrough
        case .explore:
            titleTextStyle = .boldTitle1 // used to be boldtitle2
        default:
            titleTextStyle = .semiboldHeadline
        }
        titleLabel.font = WMFFont.for(titleTextStyle, compatibleWith: traitCollection)
        subtitleLabel.font = WMFFont.for(subtitleTextStyle, compatibleWith: traitCollection)
        button.titleLabel?.font = WMFFont.for(buttonTextStyle, compatibleWith: traitCollection)
    }
    
    override func layoutMarginsDidChange() {
        super.layoutMarginsDidChange()
        setNeedsLayout()
    }
    
    override func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        let additionalMargins: UIEdgeInsets
        switch style {
        case .history:
            additionalMargins = UIEdgeInsets(top: 30, left: 0, bottom: 10, right: 0)
        case .recentSearches:
            additionalMargins = UIEdgeInsets(top: 10, left: 0, bottom: 5, right: 0)
        case .detail:
            additionalMargins = UIEdgeInsets(top: 45, left: 0, bottom: 35, right: 0)
        case .pageHistory:
            additionalMargins = UIEdgeInsets(top: 10, left: 6, bottom: 30, right: 6)
        default:
            additionalMargins = .zero
        }
        let baseMargins = self.layoutMargins
        let layoutMargins = UIEdgeInsets(top: baseMargins.top + additionalMargins.top, left: baseMargins.left + additionalMargins.left, bottom: baseMargins.bottom + additionalMargins.bottom, right: baseMargins.right + additionalMargins.right)
        let size = super.sizeThatFits(size, apply: apply)
        var widthMinusMargins = size.width - layoutMargins.left - layoutMargins.right
        let isRTL = traitCollection.layoutDirection == .rightToLeft
        let labelHorizontalAlignment: HorizontalAlignment = isRTL ? .right : .left
        let buttonHorizontalAlignment: HorizontalAlignment = isRTL ? .left : .right
        var origin = CGPoint(x: layoutMargins.left, y: layoutMargins.top)
        if !button.isHidden {
            let buttonFrame = button.wmf_preferredFrame(at: origin, maximumWidth: widthMinusMargins, horizontalAlignment: buttonHorizontalAlignment, apply: apply)
            widthMinusMargins -= (buttonFrame.width + layoutMargins.right)
        }
        origin.y += titleLabel.wmf_preferredHeight(at: origin, maximumWidth:widthMinusMargins, horizontalAlignment: labelHorizontalAlignment, spacing: 0, apply: apply)
        if subtitleLabel.text != nil {
            origin.y += spacing
            origin.y += subtitleLabel.wmf_preferredHeight(at: origin, maximumWidth: widthMinusMargins, horizontalAlignment: labelHorizontalAlignment, spacing: 0, apply: apply)
        }
        origin.y += layoutMargins.bottom
        return CGSize(width: size.width, height: origin.y)
    }
    
}

extension CollectionViewHeader: Themeable {
    func apply(theme: Theme) {
        titleLabel.textColor = theme[keyPath: titleTextColorKeyPath]
        titleLabel.backgroundColor = theme.colors.paperBackground
        subtitleLabel.textColor = theme.colors.secondaryText
        subtitleLabel.backgroundColor = theme.colors.paperBackground
        backgroundColor = theme.colors.paperBackground
        tintColor = theme.colors.link
        button.setTitleColor(theme.colors.link, for: .normal)
    }
}
