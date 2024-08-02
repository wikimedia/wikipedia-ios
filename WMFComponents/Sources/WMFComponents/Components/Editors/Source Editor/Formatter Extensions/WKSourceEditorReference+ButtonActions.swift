import Foundation
import WMFComponentsObjC

extension WKSourceEditorFormatterReference {
    func toggleReferenceFormatting(action: WKSourceEditorFormatterButtonAction, in textView: UITextView) {
        toggleFormatting(startingFormattingString: "<ref>", wildcardStartingFormattingString: "<ref*>", endingFormattingString: "</ref>", action: action, in: textView)
    }
}
