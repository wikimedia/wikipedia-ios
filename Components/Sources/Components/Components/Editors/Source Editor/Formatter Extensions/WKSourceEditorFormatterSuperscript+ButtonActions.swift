import Foundation
import ComponentsObjC

extension WKSourceEditorFormatterSuperscript {
    func toggleSuperscriptFormatting(action: WKSourceEditorFormatterButtonAction, in textView: UITextView) {
        toggleFormatting(startingFormattingString: "<sup>", endingFormattingString: "</sup>", action: action, in: textView)
    }
}
