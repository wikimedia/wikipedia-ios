import Foundation
import ComponentsObjC

extension WKSourceEditorFormatterTemplate {
    func toggleTemplateFormatting(action: WKSourceEditorFormatterButtonAction, in textView: UITextView) {
        toggleFormatting(startingFormattingString: "{{", endingFormattingString: "}}", action: action, in: textView)
    }
}
