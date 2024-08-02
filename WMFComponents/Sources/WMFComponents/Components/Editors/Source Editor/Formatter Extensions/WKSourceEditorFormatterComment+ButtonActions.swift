import Foundation
import WMFComponentsObjC

extension WMFSourceEditorFormatterComment {
    func toggleCommentFormatting(action: WMFSourceEditorFormatterButtonAction, in textView: UITextView) {
        toggleFormatting(startingFormattingString: "<!--", endingFormattingString: "-->", action: action, in: textView)
    }
}
