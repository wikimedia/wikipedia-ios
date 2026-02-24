// This Swift file was auto-generated from Objective-C.

import UIKit

// MARK: - Custom Attributed String Keys

extension NSAttributedString.Key {
    static let wmfSourceEditorContentSuperscript = NSAttributedString.Key("WMFSourceEditorCustomKeyContentSuperscript")
}

class WMFSourceEditorFormatterSuperscript: WMFSourceEditorFormatter {

    private var superscriptAttributes: [NSAttributedString.Key: Any]
    private let superscriptContentAttributes: [NSAttributedString.Key: Any]
    private let superscriptRegex: NSRegularExpression

    init(colors: WMFSourceEditorColors, fonts: WMFSourceEditorFonts) {
        superscriptAttributes = [
            .foregroundColor: colors.greenForegroundColor,
            .wmfSourceEditorColorGreen: true
        ]
        superscriptContentAttributes = [.wmfSourceEditorContentSuperscript: true]
        superscriptRegex = Self.regex(pattern: "(<sup>)(.*?)(<\\/sup>)")
    }

    func addSyntaxHighlighting(to attributedString: NSMutableAttributedString, in range: NSRange) {
        guard canEvaluateAttributedString(attributedString, againstRange: range) else { return }
        attributedString.removeAttribute(.wmfSourceEditorContentSuperscript, range: range)

        superscriptRegex.enumerateMatches(in: attributedString.string, range: range) { result, _, _ in
            guard let result else { return }
            let openingRange = result.range(at: 1)
            let contentRange = result.range(at: 2)
            let closingRange = result.range(at: 3)

            if openingRange.location != NSNotFound { attributedString.addAttributes(self.superscriptAttributes, range: openingRange) }
            if contentRange.location != NSNotFound { attributedString.addAttributes(self.superscriptContentAttributes, range: contentRange) }
            if closingRange.location != NSNotFound { attributedString.addAttributes(self.superscriptAttributes, range: closingRange) }
        }
    }

    func update(_ fonts: WMFSourceEditorFonts, in attributedString: NSMutableAttributedString, in range: NSRange) {
        // No special font handling needed
    }

    func update(_ colors: WMFSourceEditorColors, in attributedString: NSMutableAttributedString, in range: NSRange) {
        superscriptAttributes[.foregroundColor] = colors.greenForegroundColor
        guard canEvaluateAttributedString(attributedString, againstRange: range) else { return }
        attributedString.enumerateAttribute(.wmfSourceEditorColorGreen, in: range) { value, localRange, _ in
            if (value as? Bool) == true {
                attributedString.addAttributes(self.superscriptAttributes, range: localRange)
            }
        }
    }

    // MARK: - Public

    func attributedString(_ attributedString: NSMutableAttributedString, isSuperscriptIn range: NSRange) -> Bool {
        guard canEvaluateAttributedString(attributedString, againstRange: range) else { return false }
        if range.length == 0 {
            let attrs = attributedString.attributes(at: range.location, effectiveRange: nil)
            if attrs[.wmfSourceEditorContentSuperscript] != nil { return true }
            
            // Edge case, check previous character if we are up against closing string
            if range.location > 0, attrs[.wmfSourceEditorColorGreen] != nil {
                let newRange = NSRange(location: range.location - 1, length: 0)
                if canEvaluateAttributedString(attributedString, againstRange: newRange) {
                    let prevAttrs = attributedString.attributes(at: newRange.location, effectiveRange: nil)
                    if prevAttrs[.wmfSourceEditorContentSuperscript] != nil { return true }
                }
            }
            return false
        } else {
            var unionRange = NSRange(location: NSNotFound, length: 0)
            attributedString.enumerateAttributes(in: range) { attrs, loopRange, _ in
                if attrs[.wmfSourceEditorContentSuperscript] != nil {
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
