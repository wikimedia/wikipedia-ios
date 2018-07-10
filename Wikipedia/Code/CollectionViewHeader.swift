import UIKit

class CollectionViewHeader: SizeThatFitsReusableView {
    public enum Style {
        case explore
        case history
        case recentSearches
    }
    
    
    public var style: Style = .explore {
        didSet {
            updateFonts(with: traitCollection)
        }
    }

    private let titleLabel: UILabel = UILabel()
    private let button: UIButton = UIButton()
    
    var title: String? {
        get {
            return titleLabel.text
        }
        set {
            switch style {
            case .history:
                titleLabel.text = newValue?.uppercased()
            default:
                titleLabel.text = newValue
            }
            setNeedsLayout()
        }
    }
    
    var buttonTitle: String? {
        get {
            return button.title(for: .normal)
        }
        set {
            button.setTitle(newValue, for: .normal)
        }
    }

    override func setup() {
        super.setup()
        addSubview(titleLabel)
        addSubview(button)
    }
    
    override func updateFonts(with traitCollection: UITraitCollection) {
        super.updateFonts(with: traitCollection)
        let titleTextStyle: DynamicTextStyle
        let buttonTextStyle: DynamicTextStyle = .subheadline
        switch style {
        case .explore:
            titleTextStyle = .heavyTitle1
        case .history:
            titleTextStyle = .subheadline
        case .recentSearches:
            titleTextStyle = .heavyHeadline
        }
        titleLabel.font = UIFont.wmf_font(titleTextStyle, compatibleWithTraitCollection: traitCollection)
        button.titleLabel?.font = UIFont.wmf_font(buttonTextStyle, compatibleWithTraitCollection: traitCollection)
    }
    
    override func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        button.isHidden = buttonTitle == nil
        let additionalMargins = style == .history ? UIEdgeInsets(top: 30, left: 0, bottom: 5, right: 0) : .zero
        let baseMargins = self.layoutMargins
        let layoutMargins = UIEdgeInsets(top: baseMargins.top + additionalMargins.top, left: baseMargins.left + additionalMargins.left, bottom: baseMargins.bottom + additionalMargins.bottom, right: baseMargins.right + additionalMargins.right)
        let size = super.sizeThatFits(size, apply: apply)
        let widthMinusMargins = size.width - layoutMargins.left - layoutMargins.right
        var origin = CGPoint(x: layoutMargins.left, y: layoutMargins.top)
        let horizontalAlignment: HorizontalAlignment = effectiveUserInterfaceLayoutDirection == .rightToLeft ? .right : .left
        let frame = titleLabel.wmf_preferredFrame(at: origin, maximumSize: CGSize(width: widthMinusMargins, height: UIViewNoIntrinsicMetric), horizontalAlignment: horizontalAlignment, apply: apply)
        origin.y += frame.layoutHeight(with: layoutMargins.bottom)
        return CGSize(width: size.width, height: origin.y)
    }
    
}

extension CollectionViewHeader: Themeable {
    func apply(theme: Theme) {
        let titleTextColor: UIColor = style == .history ? theme.colors.secondaryText : theme.colors.primaryText
        let backgroundColor: UIColor = style == .history ? theme.colors.baseBackground : theme.colors.paperBackground
        titleLabel.textColor = titleTextColor
        titleLabel.backgroundColor = backgroundColor
        self.backgroundColor = backgroundColor
    }
}
