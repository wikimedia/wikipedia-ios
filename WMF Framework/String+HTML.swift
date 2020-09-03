import Foundation

extension String {
    public func byAttributingHTML(with textStyle: DynamicTextStyle, boldWeight: UIFont.Weight = .semibold, matching traitCollection: UITraitCollection, withBoldedString: String? = nil, color: UIColor? = nil, linkColor: UIColor? = nil, handlingLists: Bool = false, handlingSuperSubscripts: Bool = false, tagMapping: [String: String]? = nil, additionalTagAttributes: [String: [NSAttributedString.Key: Any]]? = nil) -> NSMutableAttributedString {
        let font = UIFont.wmf_font(textStyle, compatibleWithTraitCollection: traitCollection)
        let boldFont = UIFont.wmf_font(textStyle.with(weight: boldWeight), compatibleWithTraitCollection: traitCollection)
        let italicFont = UIFont.wmf_font(textStyle.with(traits: [.traitItalic]), compatibleWithTraitCollection: traitCollection)
        let boldItalicFont = UIFont.wmf_font(textStyle.with(weight: boldWeight, traits: [.traitItalic]), compatibleWithTraitCollection: traitCollection)
        return (self as NSString).wmf_attributedStringFromHTML(with: font, boldFont: boldFont, italicFont: italicFont, boldItalicFont: boldItalicFont, color: color, linkColor: linkColor, handlingLists: handlingLists, handlingSuperSubscripts: handlingSuperSubscripts, withAdditionalBoldingForMatchingSubstring: withBoldedString, tagMapping: tagMapping, additionalTagAttributes: additionalTagAttributes)
    }
    
    public var removingHTML: String {
        return (self as NSString).wmf_stringByRemovingHTML()
    }
}
