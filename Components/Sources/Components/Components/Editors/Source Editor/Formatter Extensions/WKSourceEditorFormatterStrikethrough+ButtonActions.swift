import Foundation
import ComponentsObjC

extension WKSourceEditorFormatterStrikethrough {
    func toggleStrikethroughFormatting(action: WKSourceEditorFormatterButtonAction, in textView: UITextView) {
        toggleFormatting(startingFormattingString: "<s>", endingFormattingString: "</s>", action: action, in: textView)
    }
}
