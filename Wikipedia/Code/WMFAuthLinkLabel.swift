
struct WMFAuthLinkLabelStrings {
    /// String containing "%1$@" substring.
    var dollarSignString: String
    
    /// String which will replace "%1$@" in "dollarSignString".
    var substitutionString: String
}

class WMFAuthLinkLabel: UILabel {
    override open func awakeFromNib() {
        super.awakeFromNib()
        textColor = UIColor.wmf_blueTint
        numberOfLines = 0
        lineBreakMode = .byWordWrapping
        textAlignment = .natural
    }

    /// Some auth labels display a string from two localized strings, each styled differently.
    public var strings: WMFAuthLinkLabelStrings?

    fileprivate var boldSubheadlineFont: UIFont? {
        get {
            return UIFont.wmf_preferredFontForFontFamily(WMFFontFamily.systemBold, withTextStyle: .subheadline, compatibleWithTraitCollection: self.traitCollection)
        }
    }

    fileprivate var subheadlineFont: UIFont? {
        get {
            return UIFont.wmf_preferredFontForFontFamily(WMFFontFamily.system, withTextStyle: .subheadline, compatibleWithTraitCollection: self.traitCollection)
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard let strings = strings else {
            if let boldSubheadlineFont = boldSubheadlineFont {
                font = boldSubheadlineFont
            }
            return
        }
        attributedText = combinedAttributedString(from: strings)
    }
    
    fileprivate func combinedAttributedString(from strings: WMFAuthLinkLabelStrings) -> NSAttributedString {
        // Combine and style 'dollarSignString' and 'substitutionString': https://github.com/wikimedia/wikipedia-ios/pull/1216#discussion_r104224511
        
        var dollarSignStringAttributes: [String:Any] = [NSForegroundColorAttributeName : UIColor.black]
        if let subheadlineFont = subheadlineFont {
            dollarSignStringAttributes[NSFontAttributeName] = subheadlineFont
        }

        var substitutionStringAttributes: [String:Any] = [NSForegroundColorAttributeName : UIColor.wmf_blueTint]
        if let boldSubheadlineFont = boldSubheadlineFont {
            substitutionStringAttributes[NSFontAttributeName] = boldSubheadlineFont
        }
        
        assert(strings.dollarSignString.contains("%1$@"), "Expected dollar sign substitution placeholder not found")
        
        return strings.dollarSignString.attributedString(attributes: dollarSignStringAttributes, substitutionStrings: [strings.substitutionString], substitutionAttributes: [substitutionStringAttributes])
    }
}
