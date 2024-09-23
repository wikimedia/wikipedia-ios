import Foundation
import WMFComponentsObjC

extension WMFSourceEditorFormatterTemplate {
    func toggleTemplateFormatting(action: WMFSourceEditorFormatterButtonAction, in textView: UITextView) {
        toggleFormatting(startingFormattingString: "{{", endingFormattingString: "}}", action: action, in: textView)
    }
}
