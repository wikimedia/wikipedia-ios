// This Swift file was auto-generated from Objective-C.

import UIKit

// MARK: - Custom Attributed String Keys

extension NSAttributedString.Key {
    // Font custom keys span across entire match, i.e. "== Test ==". The entire match is a particular font. This helps us quickly seek and update fonts upon popover change.
    static let wmfSourceEditorFontHeading = NSAttributedString.Key("WMFSourceEditorCustomKeyFontHeading")
    static let wmfSourceEditorFontSubheading1 = NSAttributedString.Key("WMFSourceEditorCustomKeyFontSubheading1")
    static let wmfSourceEditorFontSubheading2 = NSAttributedString.Key("WMFSourceEditorCustomKeyFontSubheading2")
    static let wmfSourceEditorFontSubheading3 = NSAttributedString.Key("WMFSourceEditorCustomKeyFontSubheading3")
    static let wmfSourceEditorFontSubheading4 = NSAttributedString.Key("WMFSourceEditorCustomKeyFontSubheading4")
    
    // Content custom keys span across only the content, i.e. " Test ". This helps us detect for button selection states.
    static let wmfSourceEditorContentHeading = NSAttributedString.Key("WMFSourceEditorCustomKeyContentHeading")
    static let wmfSourceEditorContentSubheading1 = NSAttributedString.Key("WMFSourceEditorCustomKeyContentSubheading1")
    static let wmfSourceEditorContentSubheading2 = NSAttributedString.Key("WMFSourceEditorCustomKeyContentSubheading2")
    static let wmfSourceEditorContentSubheading3 = NSAttributedString.Key("WMFSourceEditorCustomKeyContentSubheading3")
    static let wmfSourceEditorContentSubheading4 = NSAttributedString.Key("WMFSourceEditorCustomKeyContentSubheading4")
}

class WMFSourceEditorFormatterHeading: WMFSourceEditorFormatter {

    private var headingFontAttributes: [NSAttributedString.Key: Any]
    private var subheading1FontAttributes: [NSAttributedString.Key: Any]
    private var subheading2FontAttributes: [NSAttributedString.Key: Any]
    private var subheading3FontAttributes: [NSAttributedString.Key: Any]
    private var subheading4FontAttributes: [NSAttributedString.Key: Any]
    private var orangeAttributes: [NSAttributedString.Key: Any]

    private let headingContentAttributes: [NSAttributedString.Key: Any]
    private let subheading1ContentAttributes: [NSAttributedString.Key: Any]
    private let subheading2ContentAttributes: [NSAttributedString.Key: Any]
    private let subheading3ContentAttributes: [NSAttributedString.Key: Any]
    private let subheading4ContentAttributes: [NSAttributedString.Key: Any]

    private let headingRegex: NSRegularExpression
    private let subheading1Regex: NSRegularExpression
    private let subheading2Regex: NSRegularExpression
    private let subheading3Regex: NSRegularExpression
    private let subheading4Regex: NSRegularExpression

    // MARK: - Public

    init(colors: WMFSourceEditorColors, fonts: WMFSourceEditorFonts) {
        orangeAttributes = [
            .foregroundColor: colors.orangeForegroundColor,
            .wmfSourceEditorColorOrange: true
        ]
        headingFontAttributes = [.font: fonts.headingFont, .wmfSourceEditorFontHeading: true]
        subheading1FontAttributes = [.font: fonts.subheading1Font, .wmfSourceEditorFontSubheading1: true]
        subheading2FontAttributes = [.font: fonts.subheading2Font, .wmfSourceEditorFontSubheading2: true]
        subheading3FontAttributes = [.font: fonts.subheading3Font, .wmfSourceEditorFontSubheading3: true]
        subheading4FontAttributes = [.font: fonts.subheading4Font, .wmfSourceEditorFontSubheading4: true]

        headingContentAttributes = [.wmfSourceEditorContentHeading: true]
        subheading1ContentAttributes = [.wmfSourceEditorContentSubheading1: true]
        subheading2ContentAttributes = [.wmfSourceEditorContentSubheading2: true]
        subheading3ContentAttributes = [.wmfSourceEditorContentSubheading3: true]
        subheading4ContentAttributes = [.wmfSourceEditorContentSubheading4: true]

        headingRegex = Self.regex(pattern: "^(={2})([^=]*)(={2})(?!=)$", options: .anchorsMatchLines)
        subheading1Regex = Self.regex(pattern: "^(={3})([^=]*)(={3})(?!=)$", options: .anchorsMatchLines)
        subheading2Regex = Self.regex(pattern: "^(={4})([^=]*)(={4})(?!=)$", options: .anchorsMatchLines)
        subheading3Regex = Self.regex(pattern: "^(={5})([^=]*)(={5})(?!=)$", options: .anchorsMatchLines)
        subheading4Regex = Self.regex(pattern: "^(={6})([^=]*)(={6})(?!=)$", options: .anchorsMatchLines)
    }


    func addSyntaxHighlighting(to attributedString: NSMutableAttributedString, in range: NSRange) {
        guard canEvaluateAttributedString(attributedString, againstRange: range) else { return }

        let allKeys: [NSAttributedString.Key] = [
            .wmfSourceEditorFontHeading, .wmfSourceEditorFontSubheading1, .wmfSourceEditorFontSubheading2,
            .wmfSourceEditorFontSubheading3, .wmfSourceEditorFontSubheading4,
            .wmfSourceEditorContentHeading, .wmfSourceEditorContentSubheading1, .wmfSourceEditorContentSubheading2,
            .wmfSourceEditorContentSubheading3, .wmfSourceEditorContentSubheading4
        ]
        for key in allKeys { attributedString.removeAttribute(key, range: range) }

        enumerateAndHighlight(attributedString, range: range, regex: headingRegex, fontAttributes: headingFontAttributes, contentAttributes: headingContentAttributes)
        enumerateAndHighlight(attributedString, range: range, regex: subheading1Regex, fontAttributes: subheading1FontAttributes, contentAttributes: subheading1ContentAttributes)
        enumerateAndHighlight(attributedString, range: range, regex: subheading2Regex, fontAttributes: subheading2FontAttributes, contentAttributes: subheading2ContentAttributes)
        enumerateAndHighlight(attributedString, range: range, regex: subheading3Regex, fontAttributes: subheading3FontAttributes, contentAttributes: subheading3ContentAttributes)
        enumerateAndHighlight(attributedString, range: range, regex: subheading4Regex, fontAttributes: subheading4FontAttributes, contentAttributes: subheading4ContentAttributes)
    }

    func update(_ colors: WMFSourceEditorColors, in attributedString: NSMutableAttributedString, in range: NSRange) {
        orangeAttributes[.foregroundColor] = colors.orangeForegroundColor

        guard canEvaluateAttributedString(attributedString, againstRange: range) else { return }

        attributedString.enumerateAttribute(.wmfSourceEditorColorOrange, in: range) { value, localRange, _ in
            if (value as? Bool) == true {
                attributedString.addAttributes(self.orangeAttributes, range: localRange)
            }
        }
    }

    func update(_ fonts: WMFSourceEditorFonts, in attributedString: NSMutableAttributedString, in range: NSRange) {
        headingFontAttributes[.font] = fonts.headingFont
        subheading1FontAttributes[.font] = fonts.subheading1Font
        subheading2FontAttributes[.font] = fonts.subheading2Font
        subheading3FontAttributes[.font] = fonts.subheading3Font
        subheading4FontAttributes[.font] = fonts.subheading4Font

        guard canEvaluateAttributedString(attributedString, againstRange: range) else { return }

        let fontKeys: [(NSAttributedString.Key, [NSAttributedString.Key: Any])] = [
            (.wmfSourceEditorFontHeading, headingFontAttributes),
            (.wmfSourceEditorFontSubheading1, subheading1FontAttributes),
            (.wmfSourceEditorFontSubheading2, subheading2FontAttributes),
            (.wmfSourceEditorFontSubheading3, subheading3FontAttributes),
            (.wmfSourceEditorFontSubheading4, subheading4FontAttributes)
        ]
        for (key, attrs) in fontKeys {
            attributedString.enumerateAttribute(key, in: range, options: [.longestEffectiveRangeNotRequired]) { value, localRange, _ in
                if (value as? Bool) == true {
                    attributedString.addAttributes(attrs, range: localRange)
                }
            }
        }
    }

    // MARK: - Public

    func attributedString(_ attributedString: NSMutableAttributedString, isHeadingIn range: NSRange) -> Bool {
        isContentKey(.wmfSourceEditorContentHeading, in: attributedString, range: range)
    }

    func attributedString(_ attributedString: NSMutableAttributedString, isSubheading1In range: NSRange) -> Bool {
        isContentKey(.wmfSourceEditorContentSubheading1, in: attributedString, range: range)
    }

    func attributedString(_ attributedString: NSMutableAttributedString, isSubheading2In range: NSRange) -> Bool {
        isContentKey(.wmfSourceEditorContentSubheading2, in: attributedString, range: range)
    }

    func attributedString(_ attributedString: NSMutableAttributedString, isSubheading3In range: NSRange) -> Bool {
        isContentKey(.wmfSourceEditorContentSubheading3, in: attributedString, range: range)
    }

    func attributedString(_ attributedString: NSMutableAttributedString, isSubheading4In range: NSRange) -> Bool {
        isContentKey(.wmfSourceEditorContentSubheading4, in: attributedString, range: range)
    }

    // MARK: - Private

    private func isContentKey(_ contentKey: NSAttributedString.Key, in attributedString: NSMutableAttributedString, range: NSRange) -> Bool {
        guard canEvaluateAttributedString(attributedString, againstRange: range) else { return false }

        if range.length == 0 {
            let attrs = attributedString.attributes(at: range.location, effectiveRange: nil)
            if attrs[contentKey] != nil { return true }

            // Edge case, check previous character if we are up against closing string
            if range.location > 0, attrs[.wmfSourceEditorColorOrange] != nil {
                let newRange = NSRange(location: range.location - 1, length: 0)
                if canEvaluateAttributedString(attributedString, againstRange: newRange) {
                    let prevAttrs = attributedString.attributes(at: newRange.location, effectiveRange: nil)
                    if prevAttrs[contentKey] != nil { return true }
                }
            }
            return false
        } else {
            var unionRange = NSRange(location: NSNotFound, length: 0)
            attributedString.enumerateAttributes(in: range) { attrs, loopRange, _ in
                if attrs[contentKey] != nil {
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

    private func enumerateAndHighlight(_ attributedString: NSMutableAttributedString, range: NSRange, regex: NSRegularExpression, fontAttributes: [NSAttributedString.Key: Any], contentAttributes: [NSAttributedString.Key: Any]) {
        guard canEvaluateAttributedString(attributedString, againstRange: range) else { return }

        regex.enumerateMatches(in: attributedString.string, range: range) { result, _, _ in
            guard let result else { return }
            let fullMatch = result.range(at: 0)
            let openingRange = result.range(at: 1)
            let textRange = result.range(at: 2)
            let closingRange = result.range(at: 3)

            if fullMatch.location != NSNotFound { attributedString.addAttributes(fontAttributes, range: fullMatch) }
            if openingRange.location != NSNotFound { attributedString.addAttributes(self.orangeAttributes, range: openingRange) }
            if textRange.location != NSNotFound { attributedString.addAttributes(contentAttributes, range: textRange) }
            if closingRange.location != NSNotFound { attributedString.addAttributes(self.orangeAttributes, range: closingRange) }
        }
    }
}
