import WMFComponents

protocol CollectionViewFooterDelegate: AnyObject {
    func collectionViewFooterButtonWasPressed(_ collectionViewFooter: CollectionViewFooter)
}

class CollectionViewFooter: SizeThatFitsReusableView {
    private let button = UIButton(type: .system)
    weak var delegate: CollectionViewFooterDelegate?

    var buttonTitle: String? {
        didSet {
            button.setTitle(buttonTitle, for: .normal)
            button.isHidden = buttonTitle == nil
        }
    }

    override func setup() {
        super.setup()
        button.layer.cornerRadius = 8
        var deprecatedButton = button as DeprecatedButton
        deprecatedButton.deprecatedContentEdgeInsets = contentEdgeInsets
        button.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
        addSubview(button)
    }

    var contentEdgeInsets: UIEdgeInsets = UIEdgeInsets(top: 12, left: 24, bottom: 12, right: 24)

    @objc private func buttonPressed() {
        delegate?.collectionViewFooterButtonWasPressed(self)
    }

    override func updateFonts(with traitCollection: UITraitCollection) {
        super.updateFonts(with: traitCollection)
        button.titleLabel?.font = WMFFont.for(.mediumSubheadline, compatibleWith: traitCollection)
    }

    override func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        let size = super.sizeThatFits(size, apply: apply)
        let widthMinusMargins = size.width - layoutMargins.left - layoutMargins.right
        var origin = CGPoint(x: layoutMargins.left, y: layoutMargins.top)
        let additionalMargins = UIEdgeInsets(top: 40, left: 0, bottom: 40, right: 0)

        if !button.isHidden {
            let buttonFrame = button.wmf_preferredFrame(at: origin, maximumWidth: widthMinusMargins, horizontalAlignment: .center, apply: apply)
            button.center = CGPoint(x: size.width / 2, y: size.height / 2)
            origin.y += buttonFrame.height + additionalMargins.top + additionalMargins.bottom
            origin.y += layoutMargins.bottom
        } else {
            origin.y = 0
        }

        return CGSize(width: size.width, height: origin.y)
    }
}

extension CollectionViewFooter: Themeable {
    func apply(theme: Theme) {
        backgroundColor = theme.colors.paperBackground
        button.setTitleColor(theme.colors.link, for: .normal)
        button.backgroundColor = theme.colors.cardButtonBackground
    }
}
