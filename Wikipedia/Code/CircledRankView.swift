class CircledRankView: SizeThatFitsView {
    fileprivate let label: UILabel = UILabel()
    let padding = UIEdgeInsetsMake(3, 3, 3, 3)
    
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
    
    override func tintColorDidChange() {
        label.textColor = tintColor
        layer.borderColor = tintColor.cgColor
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        label.font = UIFont.wmf_font(.footnote, compatibleWithTraitCollection: traitCollection)
    }
    
    override func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        let insetSize = UIEdgeInsetsInsetRect(CGRect(origin: .zero, size: size), padding)
        let labelSize = label.sizeThatFits(insetSize.size)
        if (apply) {
            layer.cornerRadius = 0.5*size.width
            label.frame = CGRect(origin: CGPoint(x: 0.5*size.width - 0.5*labelSize.width, y: 0.5*size.height - 0.5*labelSize.height), size: labelSize)
        }
        let width = labelSize.width + padding.left + padding.right
        let height = labelSize.height + padding.top + padding.bottom
        let dimension = max(width, height)
        return CGSize(width: dimension, height: dimension)
    }
}
