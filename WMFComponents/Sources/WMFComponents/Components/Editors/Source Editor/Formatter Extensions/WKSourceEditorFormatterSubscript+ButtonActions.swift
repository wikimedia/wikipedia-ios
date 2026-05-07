import UIKit
extension WMFSourceEditorFormatterSubscript {
    func toggleSubscriptFormatting(action: WMFSourceEditorFormatterButtonAction, in textView: UITextView) {
        toggleFormatting(startingFormattingString: "<sub>", endingFormattingString: "</sub>", action: action, in: textView)
    }
}
