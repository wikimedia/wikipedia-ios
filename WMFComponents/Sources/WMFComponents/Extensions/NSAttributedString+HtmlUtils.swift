import Foundation

extension NSAttributedString {
    public static func attributedStringFromHtml(_ htmlString: String, styles: HtmlUtils.Styles) -> NSAttributedString {
        return (try? HtmlUtils.nsAttributedStringFromHtml(htmlString, styles: styles)) ?? NSAttributedString(string: htmlString)
    }
}
