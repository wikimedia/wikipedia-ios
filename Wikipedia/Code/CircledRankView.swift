import WMFComponents

class CircledRankView: SizeThatFitsView {
    fileprivate let label: UILabel = UILabel()
    let padding = UIEdgeInsets(top: 3, left: 3, bottom: 3, right: 3)
    
    public var rankColor: UIColor = WMFColor.blue600 {
        didSet {
            guard !label.textColor.isEqual(rankColor) else {
                return
            }
            label.textColor = rankColor
            layer.borderColor = rankColor.cgColor
        }
    }
    
    override func setup() {
        super.setup()
        layer.borderWidth = 1
        label.isOpaque = true
        addSubview(label)
    }
    
    var rank: Int = 0 {
        didSet {
            label.text = String.localizedStringWithFormat("%d", rank)
            setNeedsLayout()
        }
    }
    
    var labelBackgroundColor: UIColor? {
        didSet {
            label.backgroundColor = labelBackgroundColor
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateFonts(with: traitCollection)
    }

    override func updateFonts(with traitCollection: UITraitCollection) {
        super.updateFonts(with: traitCollection)
        label.font = WMFFont.for(.footnote, compatibleWith: traitCollection)
    }
    
    override func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        let insetSize = CGRect(origin: .zero, size: size).inset(by: padding)
        let labelSize = label.sizeThatFits(insetSize.size)
        if apply {
            layer.cornerRadius = 0.5*size.width
            label.frame = CGRect(origin: CGPoint(x: 0.5*size.width - 0.5*labelSize.width, y: 0.5*size.height - 0.5*labelSize.height), size: labelSize)
        }
        let width = labelSize.width + padding.left + padding.right
        let height = labelSize.height + padding.top + padding.bottom
        let dimension = max(width, height)
        return CGSize(width: dimension, height: dimension)
    }
}
