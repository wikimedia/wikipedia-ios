import Foundation


extension NSAttributedString {
    public class func with(html: String, textStyle: DynamicTextStyle, traitCollection: UITraitCollection) -> NSAttributedString {
        let font = UIFont.wmf_font(textStyle, compatibleWithTraitCollection: traitCollection)
        let boldFont = UIFont.wmf_font(textStyle.with(weight: .semibold), compatibleWithTraitCollection: traitCollection)
        let italicFont = UIFont.wmf_font(textStyle.with(traits: [.traitItalic]), compatibleWithTraitCollection: traitCollection)
        let boldItalicFont = UIFont.wmf_font(textStyle.with(weight: .semibold, traits: [.traitItalic]), compatibleWithTraitCollection: traitCollection)
        return (html as NSString).wmf_attributedStringFromHTML(with: font, boldFont: boldFont, italicFont: italicFont, boldItalicFont: boldItalicFont, withAdditionalBoldingForMatchingSubstring: nil)
    }
}
