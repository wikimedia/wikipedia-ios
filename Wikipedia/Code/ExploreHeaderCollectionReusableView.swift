import UIKit

class ExploreHeaderCollectionReusableView: SizeThatFitsReusableView {
    let titleLabel = UILabel()
    
    override func setup() {
        super.setup()
        addSubview(titleLabel)
    }
    
    override func updateFonts(with traitCollection: UITraitCollection) {
        super.updateFonts(with: traitCollection)
        titleLabel.font = UIFont.wmf_font(.heavyTitle1, compatibleWithTraitCollection: traitCollection)
    }
    
    override func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        let size = super.sizeThatFits(size, apply: apply)
        let widthMinusMargins = size.width - layoutMargins.left - layoutMargins.right
        var origin = CGPoint(x: layoutMargins.left, y: layoutMargins.top)
        let frame = titleLabel.wmf_preferredFrame(at: origin, maximumSize: CGSize(width: widthMinusMargins, height: UIViewNoIntrinsicMetric), alignedBy: semanticContentAttribute, apply: apply)
        origin.y += frame.layoutHeight(with: layoutMargins.bottom)
        return CGSize(width: size.width, height: origin.y)
    }
    
}

extension ExploreHeaderCollectionReusableView: Themeable {
    func apply(theme: Theme) {
        titleLabel.textColor = theme.colors.primaryText
        titleLabel.backgroundColor = theme.colors.paperBackground
        backgroundColor = theme.colors.paperBackground
    }
}
