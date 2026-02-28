// This Swift file was auto-generated from Objective-C.

import UIKit

// MARK: - Custom Attributed String Keys

extension NSAttributedString.Key {
    static let wmfSourceEditorCommentMarkup = NSAttributedString.Key("WMFSourceEditorCustomKeyCommentMarkup")
    static let wmfSourceEditorCommentContent = NSAttributedString.Key("WMFSourceEditorCustomKeyCommentContent")
}

class WMFSourceEditorFormatterComment: WMFSourceEditorFormatter {

    private var commentMarkupAttributes: [NSAttributedString.Key: Any]
    private var commentContentAttributes: [NSAttributedString.Key: Any]
    private let commentRegex: NSRegularExpression

    init(colors: WMFSourceEditorColors, fonts: WMFSourceEditorFonts) {
        commentMarkupAttributes = [
            .foregroundColor: colors.grayForegroundColor,
            .wmfSourceEditorCommentMarkup: true
        ]
        commentContentAttributes = [
            .foregroundColor: colors.grayForegroundColor,
            .wmfSourceEditorCommentContent: true
        ]
        commentRegex = Self.regex(pattern: "(<!--)(.*?)(-->)")
    }

    func addSyntaxHighlighting(to attributedString: NSMutableAttributedString, in range: NSRange) {
        guard canEvaluateAttributedString(attributedString, againstRange: range) else { return }

        attributedString.removeAttribute(.wmfSourceEditorCommentMarkup, range: range)
        attributedString.removeAttribute(.wmfSourceEditorCommentContent, range: range)

        commentRegex.enumerateMatches(in: attributedString.string, range: range) { result, _, _ in
            guard let result else { return }
            let openingRange = result.range(at: 1)
            let contentRange = result.range(at: 2)
            let closingRange = result.range(at: 3)

            if openingRange.location != NSNotFound { attributedString.addAttributes(self.commentMarkupAttributes, range: openingRange) }
            if contentRange.location != NSNotFound { attributedString.addAttributes(self.commentContentAttributes, range: contentRange) }
            if closingRange.location != NSNotFound { attributedString.addAttributes(self.commentMarkupAttributes, range: closingRange) }
        }
    }

    func update(_ colors: WMFSourceEditorColors, in attributedString: NSMutableAttributedString, in range: NSRange) {
        commentMarkupAttributes[.foregroundColor] = colors.grayForegroundColor
        commentContentAttributes[.foregroundColor] = colors.grayForegroundColor

        guard canEvaluateAttributedString(attributedString, againstRange: range) else { return }

        attributedString.enumerateAttribute(.wmfSourceEditorCommentMarkup, in: range) { value, localRange, _ in
            if (value as? Bool) == true {
                attributedString.addAttributes(self.commentMarkupAttributes, range: localRange)
            }
        }
        attributedString.enumerateAttribute(.wmfSourceEditorCommentContent, in: range) { value, localRange, _ in
            if (value as? Bool) == true {
                attributedString.addAttributes(self.commentContentAttributes, range: localRange)
            }
        }
    }

    func update(_ fonts: WMFSourceEditorFonts, in attributedString: NSMutableAttributedString, in range: NSRange) {
        // No special font handling needed
    }

    // MARK: - Public

    func attributedString(_ attributedString: NSMutableAttributedString, isCommentIn range: NSRange) -> Bool {
        guard canEvaluateAttributedString(attributedString, againstRange: range) else { return false }

        if range.length == 0 {
            guard attributedString.length > range.location else { return false }
            let attrs = attributedString.attributes(at: range.location, effectiveRange: nil)
            if attrs[.wmfSourceEditorCommentContent] != nil { return true }

            // Edge case, check previous character if we are up against closing string
            if range.location > 0, attrs[.wmfSourceEditorCommentMarkup] != nil {
                let newRange = NSRange(location: range.location - 1, length: 0)
                if canEvaluateAttributedString(attributedString, againstRange: newRange) {
                    let prevAttrs = attributedString.attributes(at: newRange.location, effectiveRange: nil)
                    if prevAttrs[.wmfSourceEditorCommentContent] != nil { return true }
                }
            }
            return false
        } else {
            var unionRange = NSRange(location: NSNotFound, length: 0)
            attributedString.enumerateAttributes(in: range) { attrs, loopRange, _ in
                if attrs[.wmfSourceEditorCommentContent] != nil {
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
