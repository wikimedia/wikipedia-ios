import UIKit

class CollectionViewHeader: SizeThatFitsReusableView {
    public enum Style {
        case explore
        case history
        case recentSearches
        case readingLists
    }
    
    
    public var style: Style = .explore {
        didSet {
            updateFonts(with: traitCollection)
        }
    }

    private let titleLabel: UILabel = UILabel()
    private let button: UIButton = UIButton(type: .system)
    
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

    public func addTarget(_ target: Any?, action: Selector, for controlEvents: UIControlEvents) {
        button.addTarget(target, action: action, for: controlEvents)
    }

    var horizontalAlignment: HorizontalAlignment {
        switch style {
        case .readingLists:
            return .center
        default:
            return effectiveUserInterfaceLayoutDirection == .rightToLeft ? .right : .left
        }
    }

    override func setup() {
        super.setup()
        addSubview(titleLabel)
        addSubview(button)
    }
    
    override func updateFonts(with traitCollection: UITraitCollection) {
        super.updateFonts(with: traitCollection)
        let titleTextStyle: DynamicTextStyle?
        let buttonTextStyle: DynamicTextStyle?
        switch style {
        case .explore:
            titleTextStyle = .heavyTitle1
            buttonTextStyle = nil
        case .history:
            titleTextStyle = .subheadline
            buttonTextStyle = nil
        case .recentSearches:
            titleTextStyle = .heavyHeadline
            buttonTextStyle = nil
        case .readingLists:
            buttonTextStyle = .body
            titleTextStyle = nil
        }
        if let titleTextStyle = titleTextStyle {
            titleLabel.font = UIFont.wmf_font(titleTextStyle, compatibleWithTraitCollection: traitCollection)
        }
        if let buttonTextStyle = buttonTextStyle {
            button.titleLabel?.font = UIFont.wmf_font(buttonTextStyle, compatibleWithTraitCollection: traitCollection)
        }
    }
    
    override func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        button.isHidden = buttonTitle == nil
        let additionalMargins = style == .history ? UIEdgeInsets(top: 30, left: 0, bottom: 5, right: 0) : .zero
        let baseMargins = self.layoutMargins
        let layoutMargins = UIEdgeInsets(top: baseMargins.top + additionalMargins.top, left: baseMargins.left + additionalMargins.left, bottom: baseMargins.bottom + additionalMargins.bottom, right: baseMargins.right + additionalMargins.right)
        let size = super.sizeThatFits(size, apply: apply)
        let widthMinusMargins = size.width - layoutMargins.left - layoutMargins.right
        var origin = CGPoint(x: layoutMargins.left, y: layoutMargins.top)
        let mainView = button.isHidden ? titleLabel : button
        let frame = mainView.wmf_preferredFrame(at: origin, maximumSize: CGSize(width: widthMinusMargins, height: UIViewNoIntrinsicMetric), horizontalAlignment: horizontalAlignment, apply: apply)
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
        button.tintColor = theme.colors.link
        self.backgroundColor = backgroundColor
    }
}
