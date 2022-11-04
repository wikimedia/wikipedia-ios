import Foundation

extension NSMutableAttributedString {

    /// Highlight occurrences of substring
    /// - Parameters:
    ///   - text: the text to highlight
    ///   - backgroundColor: the color to use in the background for matches
    ///   - foregroundColor: the color to use as the foreground for matches
    ///   - targetRange: if nil, highlight all matches in `self`. If non-nil, only highlight matches in the target `NSRange`
    /// - Returns: the attributed string with highlight attributes added
    func highlight(_ text: String?, backgroundColor: UIColor, foregroundColor: UIColor? = nil, targetRange: NSRange? = nil) -> NSMutableAttributedString {
        guard let text = text else { return self }
        
        let attributedString = self

        var ranges = (string as NSString).ranges(of: text)
        if let targetRange {
            ranges.removeAll(where: { $0 != targetRange })
        }

        for range in ranges {
            attributedString.addAttribute(.backgroundColor, value: backgroundColor, range: range)
            if let foregroundColor {
                attributedString.addAttribute(.foregroundColor, value: foregroundColor, range: range)
            }
        }
        return attributedString
    }

}
