import UIKit

/// Builds the passage of a card from the snippet HTML of the API. The markup goes through
/// `HtmlUtils` like the rest of the app: the `searchmatch` span of the highlight is a custom
/// tag, links and reference markers are the standard ones. Three touches follow: runs of
/// whitespace become one space, links are an indication only, and links inside the highlight
/// are underlined instead of blue.
public enum WMFSemanticSearchSnippet {

    /// The passage with the styles of the card.
    static func attributedString(
        html: String,
        font: UIFont,
        textColor: UIColor,
        highlightColor: UIColor,
        highlightTextColor: UIColor,
        linkColor: UIColor
    ) -> NSAttributedString {
        let highlight = HtmlUtils.CustomTag(
            tagName: "span",
            attributeName: "class",
            attributeValue: "searchmatch",
            attributes: [.backgroundColor: highlightColor, .foregroundColor: highlightTextColor]
        )

        let styles = HtmlUtils.Styles(
            font: font,
            boldFont: font.withTraits(.traitBold),
            italicsFont: font.withTraits(.traitItalic),
            boldItalicsFont: font.withTraits([.traitBold, .traitItalic]),
            color: textColor,
            linkColor: linkColor,
            lineSpacing: 0,
            customTags: [highlight]
        )

        let passage: NSMutableAttributedString
        if let styled = try? HtmlUtils.nsAttributedStringFromHtml(html, styles: styles) {
            passage = NSMutableAttributedString(attributedString: styled)
        } else {
            passage = NSMutableAttributedString(string: html, attributes: [.font: font, .foregroundColor: textColor])
        }

        collapseWhitespace(in: passage)
        trimHighlightEdges(in: passage, textColor: textColor)
        styleLinksAsIndication(in: passage, textColor: textColor, highlightTextColor: highlightTextColor)

        return passage
    }

    /// The text of every highlighted run of the snippet, without reference markers, to find the
    /// passage again inside the article.
    public static func highlightedTexts(html: String) -> [String] {
        let passage = attributedString(html: html, font: .systemFont(ofSize: 16), textColor: .black, highlightColor: .yellow, highlightTextColor: .black, linkColor: .blue)
        var texts: [String] = []
        passage.enumerateAttribute(.backgroundColor, in: NSRange(location: 0, length: passage.length)) { value, highlightRange, _ in
            guard value != nil else { return }

            var text = ""
            passage.enumerateAttribute(.baselineOffset, in: highlightRange) { offset, range, _ in
                guard offset == nil else { return }
                text += passage.attributedSubstring(from: range).string
            }
            text = collapsedWhitespace(text)
            if !text.isEmpty {
                texts.append(text)
            }
        }
        return texts
    }

    /// The passage as plain text, for VoiceOver.
    static func plainText(html: String) -> String {
        let text = (try? HtmlUtils.stringFromHTML(html)) ?? html
        return collapsedWhitespace(text)
    }

    // MARK: - Whitespace

    // Any Unicode whitespace except the non-breaking space: French punctuation depends on it.
    private static let whitespaceRunRegex = try? NSRegularExpression(pattern: "[\\s&&[^\\u00A0]]+")

    private static func collapsedWhitespace(_ text: String) -> String {
        guard let whitespaceRunRegex else { return text }

        let collapsed = whitespaceRunRegex.stringByReplacingMatches(in: text, range: NSRange(location: 0, length: (text as NSString).length), withTemplate: " ")
        return collapsed.trimmingCharacters(in: [" "])
    }

    /// Replaces each run of whitespace by one space, in place, so the attributes of the text
    /// around it stay where they are.
    private static func collapseWhitespace(in passage: NSMutableAttributedString) {
        guard let whitespaceRunRegex else { return }

        let matches = whitespaceRunRegex.matches(in: passage.string, range: NSRange(location: 0, length: passage.length))

        for match in matches.reversed() {
            let isAtEdge = match.range.location == 0 || NSMaxRange(match.range) == passage.length
            passage.replaceCharacters(in: match.range, with: isAtEdge ? "" : " ")
        }
    }

    /// A space at the edge of a highlight span is not part of the answer, so it is not painted.
    private static func trimHighlightEdges(in passage: NSMutableAttributedString, textColor: UIColor) {
        let text = passage.string as NSString
        var edges: [NSRange] = []

        passage.enumerateAttribute(.backgroundColor, in: NSRange(location: 0, length: passage.length)) { background, range, _ in
            guard background != nil else { return }
            if text.character(at: range.location) == 0x20 {
                edges.append(NSRange(location: range.location, length: 1))
            }
            if range.length > 1, text.character(at: NSMaxRange(range) - 1) == 0x20 {
                edges.append(NSRange(location: NSMaxRange(range) - 1, length: 1))
            }
        }
        
        for edge in edges {
            passage.removeAttribute(.backgroundColor, range: edge)
            passage.addAttribute(.foregroundColor, value: textColor, range: edge)
        }
    }

    // MARK: - Links and reference markers

    /// Links keep the link color but are not tappable, and inside the highlight they are
    /// underlined in the highlight text color. Reference markers keep the text color.
    private static func styleLinksAsIndication(in passage: NSMutableAttributedString, textColor: UIColor, highlightTextColor: UIColor) {
        let fullRange = NSRange(location: 0, length: passage.length)

        passage.enumerateAttribute(.link, in: fullRange) { link, range, _ in
            guard link != nil else { return }
            passage.removeAttribute(.link, range: range)
            passage.enumerateAttribute(.backgroundColor, in: range) { background, highlightedRange, _ in
                guard background != nil else { return }
                passage.addAttributes([.foregroundColor: highlightTextColor, .underlineStyle: NSUnderlineStyle.single.rawValue], range: highlightedRange)
            }
        }

        passage.enumerateAttribute(.baselineOffset, in: fullRange) { offset, range, _ in
            guard offset != nil else { return }
            passage.removeAttribute(.underlineStyle, range: range)
            passage.enumerateAttribute(.backgroundColor, in: range) { background, markerRange, _ in
                passage.addAttribute(.foregroundColor, value: background != nil ? highlightTextColor : textColor, range: markerRange)
            }
        }
    }
}

private extension UIFont {
    func withTraits(_ traits: UIFontDescriptor.SymbolicTraits) -> UIFont {
        guard let descriptor = fontDescriptor.withSymbolicTraits(fontDescriptor.symbolicTraits.union(traits)) else {
            return self
        }
        return UIFont(descriptor: descriptor, size: pointSize)
    }
}
