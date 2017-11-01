import UIKit


extension UILabel {
    public func setFont(with family: WMFFontFamily?, style: UIFontTextStyle?, traitCollection: UITraitCollection) {
        guard let family = family, let style = style else {
            return
        }
        font = UIFont.wmf_preferredFontForFontFamily(family, withTextStyle: style, compatibleWithTraitCollection: traitCollection)
    }
}
