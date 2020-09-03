import UIKit

struct FontDescriptor {
    let family: WMFFontFamily
    let textStyle: UIFontTextStyle
}

extension UILabel {
    func set(fontFamily: WMFFontFamily?, textStyle: UIFontTextStyle?, traitCollection: UITraitCollection) {
        guard let family = fontFamily, let style = textStyle else {
            return
        }
        font = UIFont.wmf_preferredFontForFontFamily(family, withTextStyle: style, compatibleWithTraitCollection: traitCollection)
    }
}
