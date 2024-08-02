import Foundation
import WMFComponentsObjC

extension WKSourceEditorFormatterTemplate {
    func toggleTemplateFormatting(action: WKSourceEditorFormatterButtonAction, in textView: UITextView) {
        toggleFormatting(startingFormattingString: "{{", endingFormattingString: "}}", action: action, in: textView)
    }
}
