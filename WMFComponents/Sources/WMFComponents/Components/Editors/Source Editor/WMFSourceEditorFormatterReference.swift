// This Swift file was auto-generated from Objective-C.

import UIKit

// MARK: - Custom Attributed String Keys

extension NSAttributedString.Key {
    static let wmfSourceEditorContentReference = NSAttributedString.Key("WMFSourceEditorCustomKeyContentReference")
}

class WMFSourceEditorFormatterReference: WMFSourceEditorFormatter {

    private var refAttributes: [NSAttributedString.Key: Any]
    private let refContentAttributes: [NSAttributedString.Key: Any]
    private let refHorizontalRegex: NSRegularExpression
    private let refOpenRegex: NSRegularExpression
    private let refCloseRegex: NSRegularExpression
    private let refEmptyRegex: NSRegularExpression

    init(colors: WMFSourceEditorColors, fonts: WMFSourceEditorFonts) {
        refAttributes = [
            .foregroundColor: colors.greenForegroundColor,
            .wmfSourceEditorColorGreen: true
        ]
        refContentAttributes = [.wmfSourceEditorContentReference: true]

        refHorizontalRegex = Self.regex(pattern: "(<ref(?:[^\\/\\>]+?)?>)(.*?)(<\\/ref>)")
        refOpenRegex = Self.regex(pattern: "<ref(?:[^\\/\\>]+?)?>")
        refCloseRegex = Self.regex(pattern: "<\\/ref>")
        refEmptyRegex = Self.regex(pattern: "<ref[^>]+?\\/>")
    }

    func addSyntaxHighlighting(to attributedString: NSMutableAttributedString, in range: NSRange) {
        guard canEvaluateAttributedString(attributedString, againstRange: range) else { return }

        // Reset
        attributedString.removeAttribute(.wmfSourceEditorContentReference, range: range)

        refHorizontalRegex.enumerateMatches(in: attributedString.string, range: range) { result, _, _ in
            guard let result else { return }
            let openingRange = result.range(at: 1)
            let contentRange = result.range(at: 2)
            let closingRange = result.range(at: 3)

            if openingRange.location != NSNotFound { attributedString.addAttributes(self.refAttributes, range: openingRange) }
            if contentRange.location != NSNotFound { attributedString.addAttributes(self.refContentAttributes, range: contentRange) }
            if closingRange.location != NSNotFound { attributedString.addAttributes(self.refAttributes, range: closingRange) }
        }

        // refOpenAndClose regex doesn't match everything. This scoops up extra open and closing ref tags that do not have a matching tag on the same line
        for regex in [refEmptyRegex, refOpenRegex, refCloseRegex] {
            regex.enumerateMatches(in: attributedString.string, range: range) { result, _, _ in
                guard let result else { return }
                let fullMatch = result.range(at: 0)
                if fullMatch.location != NSNotFound { attributedString.addAttributes(self.refAttributes, range: fullMatch) }
            }
        }
    }

    func update(_ colors: WMFSourceEditorColors, in attributedString: NSMutableAttributedString, in range: NSRange) {
        refAttributes[.foregroundColor] = colors.greenForegroundColor

        guard canEvaluateAttributedString(attributedString, againstRange: range) else { return }

        attributedString.enumerateAttribute(.wmfSourceEditorColorGreen, in: range) { value, localRange, _ in
            if (value as? Bool) == true {
                attributedString.addAttributes(self.refAttributes, range: localRange)
            }
        }
    }

    func update(_ fonts: WMFSourceEditorFonts, in attributedString: NSMutableAttributedString, in range: NSRange) {
        // No special font handling needed for references
    }

    // MARK: - Public

    func attributedString(_ attributedString: NSMutableAttributedString, isHorizontalReferenceIn range: NSRange) -> Bool {
        guard canEvaluateAttributedString(attributedString, againstRange: range) else { return false }

        if range.length == 0 {
            let attrs = attributedString.attributes(at: range.location, effectiveRange: nil)
            if attrs[.wmfSourceEditorContentReference] != nil { return true }

            // Edge case, check previous character if we are up against closing string
            if range.location > 0, attrs[.wmfSourceEditorColorGreen] != nil {
                let newRange = NSRange(location: range.location - 1, length: 0)
                if canEvaluateAttributedString(attributedString, againstRange: newRange) {
                    let prevAttrs = attributedString.attributes(at: newRange.location, effectiveRange: nil)
                    if prevAttrs[.wmfSourceEditorContentReference] != nil { return true }
                }
            }
            return false
        } else {
            var unionRange = NSRange(location: NSNotFound, length: 0)
            attributedString.enumerateAttributes(in: range) { attrs, loopRange, _ in
                if attrs[.wmfSourceEditorContentReference] != nil {
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
