
struct WMFAuthLinkLabelStrings {
    /// String containing "$1" substring.
    var dollarSignString: String
    
    /// String which will replace "$1" in "dollarSignString".
    var substitutionString: String
}

class WMFAuthLinkLabel: UILabel {
    override open func awakeFromNib() {
        super.awakeFromNib()
        textColor = UIColor.wmf_blueTint()
        numberOfLines = 0
        lineBreakMode = .byWordWrapping
        textAlignment = .natural
    }

    /// Some auth labels display a string from two localized strings, each styled differently.
    public var strings: WMFAuthLinkLabelStrings?

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        let boldSubheadlineFont = UIFont.wmf_preferredFontForFontFamily(WMFFontFamily.systemBold, withTextStyle: .subheadline, compatibleWithTraitCollection: self.traitCollection)!

        guard let strings = strings else {
            // Not combining two strings.
            font = boldSubheadlineFont
            return
        }

        // Combine and style 'dollarSignString' and 'substitutionString'.
        // https://github.com/wikimedia/wikipedia-ios/pull/1216#discussion_r104224511
        let subheadlineFont = UIFont.wmf_preferredFontForFontFamily(WMFFontFamily.system, withTextStyle: .subheadline, compatibleWithTraitCollection: self.traitCollection)!
        let dollarSignStringAttributes: [String:Any] = [NSForegroundColorAttributeName : UIColor.black, NSFontAttributeName : subheadlineFont]
        let substitutionStringAttributes: [String:Any] = [NSForegroundColorAttributeName : UIColor.wmf_blueTint(), NSFontAttributeName : boldSubheadlineFont]
        assert(strings.dollarSignString.contains("$1"), "Expected dollar sign substitution placeholder not found")
        attributedText = strings.dollarSignString.attributedString(attributes: dollarSignStringAttributes, substitutionStrings: [strings.substitutionString], substitutionAttributes: [substitutionStringAttributes])
    }
}
