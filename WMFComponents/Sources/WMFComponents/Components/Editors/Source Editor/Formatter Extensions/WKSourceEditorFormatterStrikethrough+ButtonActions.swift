import Foundation
import WMFComponentsObjC

extension WMFSourceEditorFormatterStrikethrough {
    func toggleStrikethroughFormatting(action: WMFSourceEditorFormatterButtonAction, in textView: UITextView) {
        toggleFormatting(startingFormattingString: "<s>", endingFormattingString: "</s>", action: action, in: textView)
    }
}
