// This Swift file was auto-generated from Objective-C.

import UIKit

// MARK: - Custom Attributed String Keys

extension NSAttributedString.Key {
    static let wmfSourceEditorFontBoldItalics = NSAttributedString.Key("WMFSourceEditorKeyFontBoldItalics")
    static let wmfSourceEditorFontBold = NSAttributedString.Key("WMFSourceEditorKeyFontBold")
    static let wmfSourceEditorFontItalics = NSAttributedString.Key("WMFSourceEditorKeyFontItalics")
}

class WMFSourceEditorFormatterBoldItalics: WMFSourceEditorFormatter {

    private var boldItalicsAttributes: [NSAttributedString.Key: Any]
    private var boldAttributes: [NSAttributedString.Key: Any]
    private var italicsAttributes: [NSAttributedString.Key: Any]
    private var orangeAttributes: [NSAttributedString.Key: Any]

    private let boldItalicsRegex: NSRegularExpression
    private let boldRegex: NSRegularExpression
    private let italicsRegex: NSRegularExpression

    // MARK: - Public

    init(colors: WMFSourceEditorColors, fonts: WMFSourceEditorFonts) {
        orangeAttributes = [
            .foregroundColor: colors.orangeForegroundColor,
            .wmfSourceEditorColorOrange: true
        ]
        boldItalicsAttributes = [
            .font: fonts.boldItalicsFont,
            .wmfSourceEditorFontBoldItalics: true
        ]
        boldAttributes = [
            .font: fonts.boldFont,
            .wmfSourceEditorFontBold: true
        ]
        italicsAttributes = [
            .font: fonts.italicsFont,
            .wmfSourceEditorFontItalics: true
        ]

        boldItalicsRegex = Self.regex(pattern: "('{5})(.*?)('{5})")
        boldRegex = Self.regex(pattern: "('{3})(.*?)('{3})")
        italicsRegex = Self.regex(pattern: "((?<!')'{2}(?!'))(.*?)((?<!')'{2}(?!'))")
    }

    func addSyntaxHighlighting(to attributedString: NSMutableAttributedString, in range: NSRange) {
        guard canEvaluateAttributedString(attributedString, againstRange: range) else { return }

        attributedString.removeAttribute(.wmfSourceEditorFontBoldItalics, range: range)
        attributedString.removeAttribute(.wmfSourceEditorFontBold, range: range)
        attributedString.removeAttribute(.wmfSourceEditorFontItalics, range: range)

        var boldItalicsRanges: [NSRange] = []
        var boldOnlyRanges: [NSRange] = []

        boldItalicsRegex.enumerateMatches(in: attributedString.string, range: range) { result, _, _ in
            guard let result else { return }
            let fullMatch = result.range(at: 0)
            let openingRange = result.range(at: 1)
            let textRange = result.range(at: 2)
            let closingRange = result.range(at: 3)

            if fullMatch.location != NSNotFound { boldItalicsRanges.append(fullMatch) }
            if openingRange.location != NSNotFound { attributedString.addAttributes(self.orangeAttributes, range: openingRange) }
            if textRange.location != NSNotFound { attributedString.addAttributes(self.boldItalicsAttributes, range: textRange) }
            if closingRange.location != NSNotFound { attributedString.addAttributes(self.orangeAttributes, range: closingRange) }
        }

        boldRegex.enumerateMatches(in: attributedString.string, range: range) { result, _, _ in
            guard let result else { return }
            let fullMatch = result.range(at: 0)
            let openingRange = result.range(at: 1)
            let textRange = result.range(at: 2)
            let closingRange = result.range(at: 3)

            if boldItalicsRanges.contains(where: { NSIntersectionRange($0, fullMatch).length != 0 }) { return }

            if fullMatch.location != NSNotFound { boldOnlyRanges.append(fullMatch) }
            if openingRange.location != NSNotFound { attributedString.addAttributes(self.orangeAttributes, range: openingRange) }
            if textRange.location != NSNotFound { attributedString.addAttributes(self.boldAttributes, range: textRange) }
            if closingRange.location != NSNotFound { attributedString.addAttributes(self.orangeAttributes, range: closingRange) }
        }

        italicsRegex.enumerateMatches(in: attributedString.string, range: range) { result, _, _ in
            guard let result else { return }
            let fullMatch = result.range(at: 0)
            let openingRange = result.range(at: 1)
            let textRange = result.range(at: 2)
            let closingRange = result.range(at: 3)

            if boldItalicsRanges.contains(where: { NSIntersectionRange($0, fullMatch).length != 0 }) { return }

            if openingRange.location != NSNotFound { attributedString.addAttributes(self.orangeAttributes, range: openingRange) }

            if textRange.location != NSNotFound {
                
                // Italicize match
                attributedString.addAttributes(self.italicsAttributes, range: textRange)
                
                // Dig deeper to see if some areas need bold italic font instead. In this case previous line effects will be undone.
                for boldRange in boldOnlyRanges {
                    let intersectionRange = NSIntersectionRange(boldRange, fullMatch)
                    let boldSurroundsItalic = intersectionRange.length > 0 && boldRange.location < fullMatch.location && boldRange.length > fullMatch.length
                    let italicSurroundsBold = intersectionRange.length > 0 && fullMatch.location < boldRange.location && fullMatch.length > boldRange.length

                    if boldSurroundsItalic {
                        
                        // Reset range styling to prep for bold italic
                        attributedString.removeAttribute(.font, range: textRange)
                        attributedString.removeAttribute(.wmfSourceEditorFontItalics, range: textRange)
                        attributedString.removeAttribute(.wmfSourceEditorFontBold, range: intersectionRange)
                        
                        // Bold italicize instead
                        attributedString.addAttributes(self.boldItalicsAttributes, range: textRange)
                    } else if italicSurroundsBold {
                        
                        // Reset range styling to prep for bold italic
                        attributedString.removeAttribute(.font, range: intersectionRange)
                        attributedString.removeAttribute(.wmfSourceEditorFontItalics, range: intersectionRange)
                        attributedString.removeAttribute(.wmfSourceEditorFontBold, range: intersectionRange)
                        
                        // Bold italicize instead
                        attributedString.addAttributes(self.boldItalicsAttributes, range: intersectionRange)
                    }
                }
            }

            if closingRange.location != NSNotFound { attributedString.addAttributes(self.orangeAttributes, range: closingRange) }
        }
    }

    func update(_ colors: WMFSourceEditorColors, in attributedString: NSMutableAttributedString, in range: NSRange) {
        guard canEvaluateAttributedString(attributedString, againstRange: range) else { return }
        
        // First update orangeAttributes property so that addSyntaxHighlighting has the correct color the next time it is called
        orangeAttributes[.foregroundColor] = colors.orangeForegroundColor

        // Then update entire attributed string orange color
        attributedString.enumerateAttribute(.wmfSourceEditorColorOrange, in: range) { value, localRange, _ in
            if (value as? Bool) == true {
                attributedString.addAttributes(self.orangeAttributes, range: localRange)
            }
        }
    }

    func update(_ fonts: WMFSourceEditorFonts, in attributedString: NSMutableAttributedString, in range: NSRange) {
        guard canEvaluateAttributedString(attributedString, againstRange: range) else { return }
        
        // First update font attributes properties so that addSyntaxHighlighting has the correct fonts the next time it is called
        boldItalicsAttributes[.font] = fonts.boldItalicsFont
        boldAttributes[.font] = fonts.boldFont
        italicsAttributes[.font] = fonts.italicsFont
        
        // Then update entire attributed string fonts
        let fontKeys: [(NSAttributedString.Key, [NSAttributedString.Key: Any])] = [
            (.wmfSourceEditorFontBoldItalics, boldItalicsAttributes),
            (.wmfSourceEditorFontBold, boldAttributes),
            (.wmfSourceEditorFontItalics, italicsAttributes)
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

    func attributedString(_ attributedString: NSMutableAttributedString, isBoldIn range: NSRange) -> Bool {
        isFormatted(attributedString: attributedString, range: range, formattingKey: .wmfSourceEditorFontBold)
    }

    func attributedString(_ attributedString: NSMutableAttributedString, isItalicsIn range: NSRange) -> Bool {
        isFormatted(attributedString: attributedString, range: range, formattingKey: .wmfSourceEditorFontItalics)
    }

    // MARK: - Private

    private func isFormatted(attributedString: NSMutableAttributedString, range: NSRange, formattingKey: NSAttributedString.Key) -> Bool {
        guard canEvaluateAttributedString(attributedString, againstRange: range) else { return false }

        if range.length == 0 {
            let attrs = attributedString.attributes(at: range.location, effectiveRange: nil)
            if attrs[.wmfSourceEditorFontBoldItalics] != nil || attrs[formattingKey] != nil {
                return true
            }
            
            // Edge case, check previous character if we are up against a closing bold or italic
            if range.location > 0, attrs[.wmfSourceEditorColorOrange] != nil {
                let newRange = NSRange(location: range.location - 1, length: 0)
                if canEvaluateAttributedString(attributedString, againstRange: newRange) {
                    let prevAttrs = attributedString.attributes(at: newRange.location, effectiveRange: nil)
                    if prevAttrs[.wmfSourceEditorFontBoldItalics] != nil || prevAttrs[formattingKey] != nil {
                        return true
                    }
                }
            }

            return false
        } else {
            var unionRange = NSRange(location: NSNotFound, length: 0)
            attributedString.enumerateAttributes(in: range) { attrs, loopRange, _ in
                if attrs[.wmfSourceEditorFontBoldItalics] != nil || attrs[formattingKey] != nil {
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
