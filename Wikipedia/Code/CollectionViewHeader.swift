import UIKit

class CollectionViewHeader: SizeThatFitsReusableView {
    var label = UILabel()
    let insets = UIEdgeInsets(top: 30, left: 15, bottom: 15, right: 15)
    override func setup() {
        addSubview(label)
        super.setup()
    }
    
    override func updateFonts(with traitCollection: UITraitCollection) {
        super.updateFonts(with: traitCollection)
        label.font = UIFont.wmf_preferredFontForFontFamily(.system, withTextStyle: .subheadline, compatibleWithTraitCollection: traitCollection)
    }
    
    override func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        let frame = label.wmf_preferredFrame(at:  CGPoint(x: insets.left, y: insets.top), fitting: CGSize(width: size.width - insets.left - insets.right, height: UIViewNoIntrinsicMetric), alignedBy: .unspecified, apply: apply)
        return CGSize(width: size.width, height: frame.maxY + insets.bottom)
    }
    
    var text: String? {
        didSet {
            label.text = text?.uppercased()
            setNeedsLayout()
        }
    }
}

extension CollectionViewHeader: Themeable {
    func apply(theme: Theme) {
        label.textColor = theme.colors.secondaryText
    }
}
