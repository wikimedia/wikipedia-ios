import UIKit

protocol CollectionViewHeaderDelegate: class {
    func collectionViewHeaderButtonWasPressed(_ collectionViewHeader: CollectionViewHeader)
}

class CollectionViewHeader: SizeThatFitsReusableView {
    weak var delegate: CollectionViewHeaderDelegate?
    
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
            titleLabel.text = newValue
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
        addSubview(titleLabel)
        addSubview(button)
        button.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
        button.isHidden = true
    }
    
    @objc func buttonPressed(_ sender: UIButton?) {
        delegate?.collectionViewHeaderButtonWasPressed(self)
    }
    
    override func updateFonts(with traitCollection: UITraitCollection) {
        super.updateFonts(with: traitCollection)
        let titleTextStyle: DynamicTextStyle
        let buttonTextStyle: DynamicTextStyle = .subheadline
        switch style {
        case .explore:
            titleTextStyle = .boldTitle2
        default:
            titleTextStyle = .semiboldHeadline
        }
        titleLabel.font = UIFont.wmf_font(titleTextStyle, compatibleWithTraitCollection: traitCollection)
        button.titleLabel?.font = UIFont.wmf_font(buttonTextStyle, compatibleWithTraitCollection: traitCollection)
    }
    
    override func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        let additionalMargins: UIEdgeInsets
        switch style {
        case .history:
            additionalMargins = UIEdgeInsets(top: 30, left: 0, bottom: 10, right: 0)
        case .recentSearches:
            additionalMargins = UIEdgeInsets(top: 10, left: 0, bottom: 5, right: 0)
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
        let frame = titleLabel.wmf_preferredFrame(at: origin, maximumSize: CGSize(width: widthMinusMargins, height: UIViewNoIntrinsicMetric), horizontalAlignment: labelHorizontalAlignment, apply: apply)
        origin.y += frame.layoutHeight(with: layoutMargins.bottom)
        return CGSize(width: size.width, height: origin.y)
    }
    
}

extension CollectionViewHeader: Themeable {
    func apply(theme: Theme) {
        titleLabel.textColor = theme.colors.primaryText
        titleLabel.backgroundColor = theme.colors.paperBackground
        backgroundColor = theme.colors.paperBackground
        tintColor = theme.colors.link
        button.setTitleColor(theme.colors.link, for: .normal)
    }
}
