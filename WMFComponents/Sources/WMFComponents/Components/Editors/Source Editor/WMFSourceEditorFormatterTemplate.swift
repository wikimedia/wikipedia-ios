// This Swift file was auto-generated from Objective-C.

import UIKit

// MARK: - Custom Attributed String Keys

extension NSAttributedString.Key {
    static let wmfSourceEditorHorizontalTemplate = NSAttributedString.Key("WMFSourceEditorCustomKeyHorizontalTemplate")
    static let wmfSourceEditorVerticalTemplate = NSAttributedString.Key("WMFSourceEditorCustomKeyVerticalTemplate")
}

class WMFSourceEditorFormatterTemplate: WMFSourceEditorFormatter {

    private var horizontalTemplateAttributes: [NSAttributedString.Key: Any]
    private var verticalTemplateAttributes: [NSAttributedString.Key: Any]
    private let horizontalTemplateRegex: NSRegularExpression
    private let verticalStartTemplateRegex: NSRegularExpression
    private let verticalParameterTemplateRegex: NSRegularExpression
    private let verticalEndTemplateRegex: NSRegularExpression

    init(colors: WMFSourceEditorColors, fonts: WMFSourceEditorFonts) {
        horizontalTemplateAttributes = [
            .foregroundColor: colors.purpleForegroundColor,
            .wmfSourceEditorHorizontalTemplate: true
        ]
        verticalTemplateAttributes = [
            .foregroundColor: colors.purpleForegroundColor,
            .wmfSourceEditorVerticalTemplate: true
        ]

        horizontalTemplateRegex = Self.regex(pattern: "\\{{2}[^\\{\\}\\n]*(?:\\{{2}[^\\{\\}\\n]*\\}{2})*[^\\{\\}\\n]*\\}{2}")
        verticalStartTemplateRegex = Self.regex(pattern: "^(?:.*)(\\{{2}[^\\{\\}\\n]*)$", options: .anchorsMatchLines)
        verticalParameterTemplateRegex = Self.regex(pattern: "^\\s*\\|.*$", options: .anchorsMatchLines)
        verticalEndTemplateRegex = Self.regex(pattern: "^([^\\{\\}\\n]*\\}{2})(?:.)*$", options: .anchorsMatchLines)
    }

    func addSyntaxHighlighting(to attributedString: NSMutableAttributedString, in range: NSRange) {
        guard canEvaluateAttributedString(attributedString, againstRange: range) else { return }

        // Reset
        attributedString.removeAttribute(.wmfSourceEditorHorizontalTemplate, range: range)
        attributedString.removeAttribute(.wmfSourceEditorVerticalTemplate, range: range)

        horizontalTemplateRegex.enumerateMatches(in: attributedString.string, range: range) { result, _, _ in
            guard let result else { return }
            let matchRange = result.range(at: 0)
            if matchRange.location != NSNotFound {
                attributedString.addAttributes(self.horizontalTemplateAttributes, range: matchRange)
            }
        }

        verticalStartTemplateRegex.enumerateMatches(in: attributedString.string, range: range) { result, _, _ in
            guard let result else { return }
            let fullMatch = result.range(at: 0)
            let openingTemplateRange = result.range(at: 1)
            if fullMatch.location != NSNotFound && openingTemplateRange.location != NSNotFound {
                attributedString.addAttributes(self.verticalTemplateAttributes, range: openingTemplateRange)
            }
        }

        verticalParameterTemplateRegex.enumerateMatches(in: attributedString.string, range: range) { result, _, _ in
            guard let result else { return }
            let matchRange = result.range(at: 0)
            if matchRange.location != NSNotFound {
                attributedString.addAttributes(self.verticalTemplateAttributes, range: matchRange)
            }
        }

        verticalEndTemplateRegex.enumerateMatches(in: attributedString.string, range: range) { result, _, _ in
            guard let result else { return }
            let fullMatch = result.range(at: 0)
            let closingTemplateRange = result.range(at: 1)
            if fullMatch.location != NSNotFound && closingTemplateRange.location != NSNotFound {
                attributedString.addAttributes(self.verticalTemplateAttributes, range: closingTemplateRange)
            }
        }
    }

    func update(_ colors: WMFSourceEditorColors, in attributedString: NSMutableAttributedString, in range: NSRange) {
        horizontalTemplateAttributes[.foregroundColor] = colors.purpleForegroundColor
        verticalTemplateAttributes[.foregroundColor] = colors.purpleForegroundColor

        guard canEvaluateAttributedString(attributedString, againstRange: range) else { return }

        attributedString.enumerateAttribute(.wmfSourceEditorHorizontalTemplate, in: range) { value, localRange, _ in
            if (value as? Bool) == true {
                attributedString.addAttributes(self.horizontalTemplateAttributes, range: localRange)
            }
        }
        attributedString.enumerateAttribute(.wmfSourceEditorVerticalTemplate, in: range) { value, localRange, _ in
            if (value as? Bool) == true {
                attributedString.addAttributes(self.verticalTemplateAttributes, range: localRange)
            }
        }
    }

    func update(_ fonts: WMFSourceEditorFonts, in attributedString: NSMutableAttributedString, in range: NSRange) {
        // No special font handling needed for templates
    }

    // MARK: - Public

    func attributedString(_ attributedString: NSMutableAttributedString, isHorizontalTemplateIn range: NSRange) -> Bool {
        guard canEvaluateAttributedString(attributedString, againstRange: range) else { return false }

        if range.length == 0 {
            let attrs = attributedString.attributes(at: range.location, effectiveRange: nil)
            return attrs[.wmfSourceEditorHorizontalTemplate] != nil
        } else {
            var unionRange = NSRange(location: NSNotFound, length: 0)
            attributedString.enumerateAttributes(in: range) { attrs, loopRange, _ in
                if attrs[.wmfSourceEditorHorizontalTemplate] != nil {
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
