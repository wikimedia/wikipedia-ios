import Foundation
import WMFComponentsObjC

extension WMFSourceEditorFormatterReference {
    func toggleReferenceFormatting(action: WMFSourceEditorFormatterButtonAction, in textView: UITextView) {
        toggleFormatting(startingFormattingString: "<ref>", wildcardStartingFormattingString: "<ref*>", endingFormattingString: "</ref>", action: action, in: textView)
    }
}
