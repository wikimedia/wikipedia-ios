import Foundation
import ComponentsObjC

extension WKSourceEditorFormatterComment {
    func toggleCommentFormatting(action: WKSourceEditorFormatterButtonAction, in textView: UITextView) {
        toggleFormatting(startingFormattingString: "<!--", endingFormattingString: "-->", action: action, in: textView)
    }
}
