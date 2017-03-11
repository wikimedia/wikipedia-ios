
extension UILabel {
    /// Makes an attributed string from two strings performing a **$1** substitution and applying a common color scheme (black/blue) used by a few auth view controllers.
    /// Also re-uses the label's font so the resulting attributed string respects storyboard dynamic type font choice and responds to dynamic type size changes.
    /// https://github.com/wikimedia/wikipedia-ios/pull/1216#discussion_r104224511
    ///
    /// - Parameters:
    ///   - dollarSignString: A localization string which has a **$1** subtitution for the string from the **substitutionString** parameter.
    ///   - substitutionString: The string which will replace **$1** in the **dollarSignString** parameter.
    /// - Returns: Attributed string from the two parameter strings, with the **dollarSignString** in black and the **substitutionString** in blue.
    func wmf_authAttributedStringReusingFont(withDollarSignString dollarSignString: String, substitutionString: String) -> NSAttributedString {
        return dollarSignString.attributedString(attributes: [NSForegroundColorAttributeName : UIColor.black, NSFontAttributeName : font], substitutionStrings: [substitutionString], substitutionAttributes: [[NSForegroundColorAttributeName : UIColor.wmf_blueTint]])
    }
}
