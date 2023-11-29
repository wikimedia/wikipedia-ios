import Foundation
import ComponentsObjC

extension WKSourceEditorFormatterBoldItalics {
    func toggleBoldFormatting(action: WKSourceEditorFormatterButtonAction, in textView: UITextView) {
        let formattingString = "'''"
        toggleFormatting(formattingString: formattingString, action: action, in: textView)
    }
    
    func toggleItalicsFormatting(action: WKSourceEditorFormatterButtonAction, in textView: UITextView) {
        let formattingString = "''"
        toggleFormatting(formattingString: formattingString, action: action, in: textView)
    }
}
