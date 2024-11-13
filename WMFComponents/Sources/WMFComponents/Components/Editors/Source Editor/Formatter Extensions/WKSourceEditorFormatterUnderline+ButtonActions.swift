import Foundation
import WMFComponentsObjC

extension WMFSourceEditorFormatterUnderline {
    func toggleUnderlineFormatting(action: WMFSourceEditorFormatterButtonAction, in textView: UITextView) {
        toggleFormatting(startingFormattingString: "<u>", endingFormattingString: "</u>", action: action, in: textView)
    }
}
