import Foundation
import WMFComponentsObjC

extension WMFSourceEditorFormatterBoldItalics {
    func toggleBoldFormatting(action: WMFSourceEditorFormatterButtonAction, in textView: UITextView) {
        let formattingString = "'''"
        toggleFormatting(formattingString: formattingString, action: action, in: textView)
    }
    
    func toggleItalicsFormatting(action: WMFSourceEditorFormatterButtonAction, in textView: UITextView) {
        let formattingString = "''"
        toggleFormatting(formattingString: formattingString, action: action, in: textView)
    }
}
