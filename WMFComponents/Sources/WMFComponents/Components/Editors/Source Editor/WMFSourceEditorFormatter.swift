// This Swift file was auto-generated from Objective-C.

import UIKit

// MARK: - Common Custom Attributed String Keys

// Font and Color custom attributes allow us to easily target already-formatted ranges. This is handy for speedy updates upon theme and text size change, as well as determining keyboard button selection states.
extension NSAttributedString.Key {
    static let wmfSourceEditorColorOrange = NSAttributedString.Key("WMFSourceEditorKeyColorOrange")
    static let wmfSourceEditorColorGreen = NSAttributedString.Key("WMFSourceEditorKeyColorGreen")
}

protocol WMFSourceEditorFormatter {
    func addSyntaxHighlighting(to attributedString: NSMutableAttributedString, in range: NSRange)
    func update(_ colors: WMFSourceEditorColors, in attributedString: NSMutableAttributedString, in range: NSRange)
    func update(_ fonts: WMFSourceEditorFonts, in attributedString: NSMutableAttributedString, in range: NSRange)
}

extension WMFSourceEditorFormatter {
    func canEvaluateAttributedString(_ attributedString: NSAttributedString, againstRange range: NSRange) -> Bool {
        range.location != NSNotFound &&
        attributedString.length > 0 &&
        range.location < attributedString.length &&
        NSMaxRange(range) <= attributedString.length
    }
    
    /// Helper method to safely create NSRegularExpression with compile-time validation
    static func regex(pattern: String, options: NSRegularExpression.Options = []) -> NSRegularExpression {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else {
            preconditionFailure("Invalid regex pattern: \(pattern)")
        }
        return regex
    }
}
