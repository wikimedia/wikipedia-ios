import UIKit

class CollectionViewHeader: SizeThatFitsReusableView {
    var label = UILabel()
    let margins = UIEdgeInsets(top: 30, left: 15, bottom: 15, right: 15)
    var adjustedMargins: UIEdgeInsets {
        return UIEdgeInsetsMake(margins.top, max(layoutMargins.left, margins.left), margins.bottom, max(layoutMargins.right, margins.right))
    }
    override func setup() {
        addSubview(label)
        super.setup()
    }
    
    override func updateFonts(with traitCollection: UITraitCollection) {
        super.updateFonts(with: traitCollection)
        label.font = UIFont.wmf_preferredFontForFontFamily(.system, withTextStyle: .subheadline, compatibleWithTraitCollection: traitCollection)
    }
    
    override func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        let margins = adjustedMargins
        let frame = label.wmf_preferredFrame(at:  CGPoint(x: margins.left, y: margins.top), fitting: CGSize(width: size.width - margins.left - margins.right, height: UIViewNoIntrinsicMetric), alignedBy: .unspecified, apply: apply)
        return CGSize(width: size.width, height: frame.maxY + margins.bottom)
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
