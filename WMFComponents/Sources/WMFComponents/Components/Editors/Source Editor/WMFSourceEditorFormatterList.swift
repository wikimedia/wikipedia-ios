// This Swift file was auto-generated from Objective-C.

import UIKit

// MARK: - Custom Attributed String Keys

extension NSAttributedString.Key {
    static let wmfSourceEditorContentBulletSingle = NSAttributedString.Key("WMFSourceEditorCustomKeyContentBulletSingle")
    static let wmfSourceEditorContentBulletMultiple = NSAttributedString.Key("WMFSourceEditorCustomKeyContentBulletMultiple")
    static let wmfSourceEditorContentNumberSingle = NSAttributedString.Key("WMFSourceEditorCustomKeyContentNumberSingle")
    static let wmfSourceEditorContentNumberMultiple = NSAttributedString.Key("WMFSourceEditorCustomKeyContentNumberMultiple")
}

class WMFSourceEditorFormatterList: WMFSourceEditorFormatter {

    private var orangeAttributes: [NSAttributedString.Key: Any]
    private let bulletSingleContentAttributes: [NSAttributedString.Key: Any]
    private let bulletMultipleContentAttributes: [NSAttributedString.Key: Any]
    private let numberSingleContentAttributes: [NSAttributedString.Key: Any]
    private let numberMultipleContentAttributes: [NSAttributedString.Key: Any]

    private let bulletSingleRegex: NSRegularExpression
    private let bulletMultipleRegex: NSRegularExpression
    private let numberSingleRegex: NSRegularExpression
    private let numberMultipleRegex: NSRegularExpression

    init(colors: WMFSourceEditorColors, fonts: WMFSourceEditorFonts) {
        orangeAttributes = [
            .foregroundColor: colors.orangeForegroundColor,
            .wmfSourceEditorColorOrange: true
        ]
        bulletSingleContentAttributes = [.wmfSourceEditorContentBulletSingle: true]
        bulletMultipleContentAttributes = [.wmfSourceEditorContentBulletMultiple: true]
        numberSingleContentAttributes = [.wmfSourceEditorContentNumberSingle: true]
        numberMultipleContentAttributes = [.wmfSourceEditorContentNumberMultiple: true]

        bulletSingleRegex = Self.regex(pattern: "^(\\*{1})(.*)$", options: .anchorsMatchLines)
        bulletMultipleRegex = Self.regex(pattern: "^(\\*{2,})(.*)$", options: .anchorsMatchLines)
        numberSingleRegex = Self.regex(pattern: "^(#{1})(.*)$", options: .anchorsMatchLines)
        numberMultipleRegex = Self.regex(pattern: "^(#{2,})(.*)$", options: .anchorsMatchLines)
    }

    func addSyntaxHighlighting(to attributedString: NSMutableAttributedString, in range: NSRange) {
        guard canEvaluateAttributedString(attributedString, againstRange: range) else { return }

        attributedString.removeAttribute(.wmfSourceEditorContentBulletSingle, range: range)
        attributedString.removeAttribute(.wmfSourceEditorContentBulletMultiple, range: range)
        attributedString.removeAttribute(.wmfSourceEditorContentNumberSingle, range: range)
        attributedString.removeAttribute(.wmfSourceEditorContentNumberMultiple, range: range)

        enumerateAndHighlight(attributedString, range: range, singleRegex: bulletSingleRegex, multipleRegex: bulletMultipleRegex, singleContentAttributes: bulletSingleContentAttributes, multipleContentAttributes: bulletMultipleContentAttributes)
        enumerateAndHighlight(attributedString, range: range, singleRegex: numberSingleRegex, multipleRegex: numberMultipleRegex, singleContentAttributes: numberSingleContentAttributes, multipleContentAttributes: numberMultipleContentAttributes)
    }

    func update(_ colors: WMFSourceEditorColors, in attributedString: NSMutableAttributedString, in range: NSRange) {
        // First update orangeAttributes property so that addSyntaxHighlighting has the correct color the next time it is called
        orangeAttributes[.foregroundColor] = colors.orangeForegroundColor

        guard canEvaluateAttributedString(attributedString, againstRange: range) else { return }

        // Then update entire attributed string orange color
        attributedString.enumerateAttribute(.wmfSourceEditorColorOrange, in: range) { value, localRange, _ in
            if (value as? Bool) == true {
                attributedString.addAttributes(self.orangeAttributes, range: localRange)
            }
        }
    }

    func update(_ fonts: WMFSourceEditorFonts, in attributedString: NSMutableAttributedString, in range: NSRange) {
        // No special font handling needed for lists
    }

    // MARK: - Public

    func attributedString(_ attributedString: NSMutableAttributedString, isBulletSingleIn range: NSRange) -> Bool {
        isContentKey(.wmfSourceEditorContentBulletSingle, in: attributedString, range: range)
    }

    func attributedString(_ attributedString: NSMutableAttributedString, isBulletMultipleIn range: NSRange) -> Bool {
        isContentKey(.wmfSourceEditorContentBulletMultiple, in: attributedString, range: range)
    }

    func attributedString(_ attributedString: NSMutableAttributedString, isNumberSingleIn range: NSRange) -> Bool {
        isContentKey(.wmfSourceEditorContentNumberSingle, in: attributedString, range: range)
    }

    func attributedString(_ attributedString: NSMutableAttributedString, isNumberMultipleIn range: NSRange) -> Bool {
        isContentKey(.wmfSourceEditorContentNumberMultiple, in: attributedString, range: range)
    }

    // MARK: - Private

    private func enumerateAndHighlight(_ attributedString: NSMutableAttributedString, range: NSRange, singleRegex: NSRegularExpression, multipleRegex: NSRegularExpression, singleContentAttributes: [NSAttributedString.Key: Any], multipleContentAttributes: [NSAttributedString.Key: Any]) {
        guard canEvaluateAttributedString(attributedString, againstRange: range) else { return }

        var multipleRanges: [NSRange] = []

        multipleRegex.enumerateMatches(in: attributedString.string, range: range) { result, _, _ in
            guard let result else { return }
            let fullMatch = result.range(at: 0)
            let orangeRange = result.range(at: 1)
            let contentRange = result.range(at: 2)

            if fullMatch.location != NSNotFound { multipleRanges.append(fullMatch) }
            if orangeRange.location != NSNotFound { attributedString.addAttributes(self.orangeAttributes, range: orangeRange) }
            if contentRange.location != NSNotFound { attributedString.addAttributes(multipleContentAttributes, range: contentRange) }
        }

        singleRegex.enumerateMatches(in: attributedString.string, range: range) { result, _, _ in
            guard let result else { return }
            let fullMatch = result.range(at: 0)
            let orangeRange = result.range(at: 1)
            let contentRange = result.range(at: 2)

            if multipleRanges.contains(where: { NSIntersectionRange($0, fullMatch).length != 0 }) { return }

            if orangeRange.location != NSNotFound { attributedString.addAttributes(self.orangeAttributes, range: orangeRange) }
            if contentRange.location != NSNotFound { attributedString.addAttributes(singleContentAttributes, range: contentRange) }
        }
    }

    private func isContentKey(_ contentKey: NSAttributedString.Key, in attributedString: NSMutableAttributedString, range: NSRange) -> Bool {
        guard canEvaluateAttributedString(attributedString, againstRange: range) else { return false }

        if range.length == 0 {
            let attrs = attributedString.attributes(at: range.location, effectiveRange: nil)
            if attrs[contentKey] != nil { return true }

            // Edge case, check previous character in case we're at the end of the line and list isn't detected
            if range.location > 0 {
                let newRange = NSRange(location: range.location - 1, length: 0)
                if canEvaluateAttributedString(attributedString, againstRange: newRange) {
                    let prevAttrs = attributedString.attributes(at: newRange.location, effectiveRange: nil)
                    if prevAttrs[contentKey] != nil { return true }
                }
            }
            return false
        } else {
            var found = false
            attributedString.enumerateAttributes(in: range) { attrs, loopRange, stop in
                if attrs[contentKey] != nil && loopRange.location == range.location && loopRange.length == range.length {
                    found = true
                    stop.pointee = true
                }
            }
            return found
        }
    }
}
