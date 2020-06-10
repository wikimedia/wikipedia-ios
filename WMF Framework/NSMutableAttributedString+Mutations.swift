import Foundation

extension NSMutableAttributedString {
    /// Applies a bold font to the first portion of the string that matches the given string
    /// - Parameter matchingString: the string to search for and bold
    /// - Parameter textStyle: The text style to use for the bolded string
    /// - Parameter weight: The font weight to use for the bolded string
    /// - Parameter traitCollection: The trait collection used for generating the font
    public func applyBoldFont(to matchingString: String, textStyle: DynamicTextStyle, weight: UIFont.Weight = .semibold, matching traitCollection: UITraitCollection) {
        // NSString and NSRange are used here for better compatability with NSAttributedString
        let range = (string as NSString).range(of: matchingString, options: .caseInsensitive)
        guard range.location != NSNotFound else {
            return
        }
        let boldFont = UIFont.wmf_font(textStyle.with(weight: weight), compatibleWithTraitCollection: traitCollection)
        addAttribute(.font, value: boldFont, range: range)
    }
}
