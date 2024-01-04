import Foundation
import ComponentsObjC

extension WKSourceEditorFormatterSubscript {
    func toggleSubscriptFormatting(action: WKSourceEditorFormatterButtonAction, in textView: UITextView) {
        toggleFormatting(startingFormattingString: "<sub>", endingFormattingString: "</sub>", action: action, in: textView)
    }
}
