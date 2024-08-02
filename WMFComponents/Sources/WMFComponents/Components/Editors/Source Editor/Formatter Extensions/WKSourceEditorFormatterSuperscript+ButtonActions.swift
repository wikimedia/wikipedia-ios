import Foundation
import WMFComponentsObjC

extension WMFSourceEditorFormatterSuperscript {
    func toggleSuperscriptFormatting(action: WMFSourceEditorFormatterButtonAction, in textView: UITextView) {
        toggleFormatting(startingFormattingString: "<sup>", endingFormattingString: "</sup>", action: action, in: textView)
    }
}
