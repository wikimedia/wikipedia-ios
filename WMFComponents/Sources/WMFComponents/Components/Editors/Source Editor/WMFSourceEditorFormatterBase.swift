// This Swift file was auto-generated from Objective-C.

import UIKit

class WMFSourceEditorFormatterBase: WMFSourceEditorFormatter {

    private var attributes: [NSAttributedString.Key: Any]

    init(colors: WMFSourceEditorColors, fonts: WMFSourceEditorFonts, textAlignment: NSTextAlignment) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 5
        paragraphStyle.lineHeightMultiple = 1.1
        paragraphStyle.alignment = textAlignment

        self.attributes = [
            .font: fonts.baseFont,
            .paragraphStyle: paragraphStyle,
            .foregroundColor: colors.baseForegroundColor
        ]
    }

    func addSyntaxHighlighting(to attributedString: NSMutableAttributedString, in range: NSRange) {
        guard canEvaluateAttributedString(attributedString, againstRange: range) else { return }

        // reset base attributes
        attributedString.removeAttribute(.font, range: range)
        attributedString.removeAttribute(.foregroundColor, range: range)
        attributedString.removeAttribute(.backgroundColor, range: range)
        
        // reset shared custom attributes
        attributedString.removeAttribute(.wmfSourceEditorColorOrange, range: range)
        attributedString.removeAttribute(.wmfSourceEditorColorGreen, range: range)

        attributedString.addAttributes(attributes, range: range)
    }

    func update(_ colors: WMFSourceEditorColors, in attributedString: NSMutableAttributedString, in range: NSRange) {
        guard canEvaluateAttributedString(attributedString, againstRange: range) else { return }

        attributes[.foregroundColor] = colors.baseForegroundColor
        attributedString.addAttributes(attributes, range: range)
    }

    func update(_ fonts: WMFSourceEditorFonts, in attributedString: NSMutableAttributedString, in range: NSRange) {
        guard canEvaluateAttributedString(attributedString, againstRange: range) else { return }

        attributes[.font] = fonts.baseFont
        attributedString.addAttributes(attributes, range: range)
    }
}
