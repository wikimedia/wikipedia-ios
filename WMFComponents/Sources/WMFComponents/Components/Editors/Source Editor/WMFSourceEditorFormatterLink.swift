// This Swift file was auto-generated from Objective-C.

import UIKit

// MARK: - Custom Attributed String Keys

extension NSAttributedString.Key {
    static let wmfSourceEditorColorBlue = NSAttributedString.Key("WMFSourceEditorCustomKeyColorBlue")
    static let wmfSourceEditorLink = NSAttributedString.Key("WMFSourceEditorCustomKeyLink")
    static let wmfSourceEditorLinkWithNestedLink = NSAttributedString.Key("WMFSourceEditorCustomKeyLinkWithNestedLink")
}

class WMFSourceEditorFormatterLink: WMFSourceEditorFormatter {

    private var simpleLinkAttributes: [NSAttributedString.Key: Any]
    private var linkWithNestedLinkAttributes: [NSAttributedString.Key: Any]
    private let simpleLinkRegex: NSRegularExpression
    private let linkWithNestedLinkRegex: NSRegularExpression

    // MARK: - Public

    init(colors: WMFSourceEditorColors, fonts: WMFSourceEditorFonts) {
        simpleLinkAttributes = [
            .wmfSourceEditorLink: true,
            .foregroundColor: colors.blueForegroundColor,
            .wmfSourceEditorColorBlue: true
        ]
        linkWithNestedLinkAttributes = [
            .wmfSourceEditorLinkWithNestedLink: true,
            .foregroundColor: colors.blueForegroundColor,
            .wmfSourceEditorColorBlue: true
        ]
        simpleLinkRegex = Self.regex(pattern: "(\\[{2})([^\\[\\]\\n]*)(\\]{2})")
        linkWithNestedLinkRegex = Self.regex(pattern: "\\[{2}[^\\[\\]\\n]*\\[{2}")
    }


    func addSyntaxHighlighting(to attributedString: NSMutableAttributedString, in range: NSRange) {
        guard canEvaluateAttributedString(attributedString, againstRange: range) else { return }

        // Reset
        attributedString.removeAttribute(.wmfSourceEditorColorBlue, range: range)
        attributedString.removeAttribute(.wmfSourceEditorLink, range: range)
        attributedString.removeAttribute(.wmfSourceEditorLinkWithNestedLink, range: range)

        // This section finds and highlights simple links that do NOT contain nested links, e.g. [[Cat]] and [[Dog|puppy]].
        simpleLinkRegex.enumerateMatches(in: attributedString.string, range: range) { result, _, _ in
            guard let result else { return }
            let openingRange = result.range(at: 1)
            let contentRange = result.range(at: 2)
            let closingRange = result.range(at: 3)

            if openingRange.location != NSNotFound { attributedString.addAttributes(self.simpleLinkAttributes, range: openingRange) }
            if contentRange.location != NSNotFound { attributedString.addAttributes(self.simpleLinkAttributes, range: contentRange) }
            if closingRange.location != NSNotFound { attributedString.addAttributes(self.simpleLinkAttributes, range: closingRange) }
        }

        // Note: This section finds and highlights links with nested links, which is common in image links. The regex matches any opening markup [[ followed by non-markup characters, then another opening markup [[. We then start to loop character-by-character, matching opening and closing tags to find and highlight links that contain other links.
        // Originally I tried to allow for infinite nested links via regex alone, but it performed too poorly.
        linkWithNestedLinkRegex.enumerateMatches(in: attributedString.string, range: range) { result, _, _ in
            guard let result else { return }
            let match = result.range(at: 0)
            if match.location != NSNotFound {
                let linkRanges = self.linkWithNestedLinkRanges(in: attributedString.string, startingIndex: match.location)
                for linkRange in linkRanges where linkRange.location != NSNotFound {
                    attributedString.addAttributes(self.linkWithNestedLinkAttributes, range: linkRange)
                }
            }
        }
    }

    func update(_ colors: WMFSourceEditorColors, in attributedString: NSMutableAttributedString, in range: NSRange) {
        simpleLinkAttributes[.foregroundColor] = colors.blueForegroundColor
        linkWithNestedLinkAttributes[.foregroundColor] = colors.blueForegroundColor

        guard canEvaluateAttributedString(attributedString, againstRange: range) else { return }

        attributedString.enumerateAttribute(.wmfSourceEditorColorBlue, in: range) { value, localRange, _ in
            if (value as? Bool) == true {
                attributedString.addAttributes([.foregroundColor: colors.blueForegroundColor], range: localRange)
            }
        }
    }

    func update(_ fonts: WMFSourceEditorFonts, in attributedString: NSMutableAttributedString, in range: NSRange) {
        // No special font handling needed
    }

    // MARK: - Public

    func attributedString(_ attributedString: NSMutableAttributedString, isSimpleLinkIn range: NSRange) -> Bool {
        isKey(.wmfSourceEditorLink, in: attributedString, range: range)
    }

    func attributedString(_ attributedString: NSMutableAttributedString, isLinkWithNestedLinkIn range: NSRange) -> Bool {
        isKey(.wmfSourceEditorLinkWithNestedLink, in: attributedString, range: range)
    }

    // MARK: - Private

    private func linkWithNestedLinkRanges(in string: String, startingIndex index: Int) -> [NSRange] {
        let nsString = string as NSString
        var openingRanges: [NSRange] = []
        var completedLinkWithNestedLinkRanges: [NSRange] = []

        // Loop through and evaluate characters in pairs, keeping track of opening and closing pairs
        var lastCompletedLinkRangeWasNested = false
        var i = index
        while i < nsString.length {
            let currentChar = nsString.character(at: i)

            if currentChar == 0x0A { break } // '\n'

            if i + 1 >= nsString.length { break }

            let nextChar = nsString.character(at: i + 1)
            let currentStr = String(utf16CodeUnits: [currentChar], count: 1)
            let nextStr = String(utf16CodeUnits: [nextChar], count: 1)
            let pair = currentStr + nextStr

            if pair == "[[" {
                openingRanges.append(NSRange(location: i, length: 2))
            }

            if pair == "]]" && openingRanges.isEmpty {
                // invalid, closed markup before opening
                break
            }

            if pair == "]]", let lastOpeningRange = openingRanges.last {
                openingRanges.removeLast()
                let unionRange = NSUnionRange(lastOpeningRange, NSRange(location: i, length: 2))

                if lastCompletedLinkRangeWasNested && openingRanges.isEmpty {
                    completedLinkWithNestedLinkRanges.append(unionRange)
                }

                lastCompletedLinkRangeWasNested = !openingRanges.isEmpty
            }

            i += 1
        }

        return completedLinkWithNestedLinkRanges
    }

    private func isKey(_ key: NSAttributedString.Key, in attributedString: NSMutableAttributedString, range: NSRange) -> Bool {
        guard canEvaluateAttributedString(attributedString, againstRange: range) else { return false }

        if range.length == 0 {
            let attrs = attributedString.attributes(at: range.location, effectiveRange: nil)
            if attrs[key] != nil { return true }

            // Edge case, check previous character if we are up against opening markup
            if range.location > 0, attrs[.wmfSourceEditorLink] != nil {
                let newRange = NSRange(location: range.location - 1, length: 0)
                if canEvaluateAttributedString(attributedString, againstRange: newRange) {
                    let prevAttrs = attributedString.attributes(at: newRange.location, effectiveRange: nil)
                    if prevAttrs[key] == nil { return false }
                }
            }

            return attrs[key] != nil
        } else {
            var unionRange = NSRange(location: NSNotFound, length: 0)
            attributedString.enumerateAttributes(in: range) { attrs, loopRange, _ in
                if attrs[key] != nil {
                    if unionRange.location == NSNotFound {
                        unionRange = loopRange
                    } else {
                        unionRange = NSUnionRange(unionRange, loopRange)
                    }
                }
            }
            return unionRange == range
        }
    }
}
