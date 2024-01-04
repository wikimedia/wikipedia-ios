import Foundation
import ComponentsObjC

extension WKSourceEditorFormatterUnderline {
    func toggleUnderlineFormatting(action: WKSourceEditorFormatterButtonAction, in textView: UITextView) {
        toggleFormatting(startingFormattingString: "<u>", endingFormattingString: "</u>", action: action, in: textView)
    }
}
