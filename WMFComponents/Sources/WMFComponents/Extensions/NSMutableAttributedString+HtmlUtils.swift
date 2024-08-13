import Foundation

extension NSMutableAttributedString {
    public static func mutableAttributedStringFromHtml(_ htmlString: String, styles: HtmlUtils.Styles) -> NSMutableAttributedString {
        if let attributedString = (try? HtmlUtils.nsAttributedStringFromHtml(htmlString, styles: styles)) {
            return NSMutableAttributedString(attributedString: attributedString)
        }
        return NSMutableAttributedString(string: htmlString)
    }
}
