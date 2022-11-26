import Foundation

extension UITextView {
    func frame(of textRange: NSRange) -> CGRect? {
        
        let oldSelectedRange = selectedRange
        selectedRange = textRange
        
        var rect: CGRect?
        if let uiTextRange = selectedTextRange {
            rect = firstRect(for: uiTextRange)
        }
        
        selectedRange = oldSelectedRange
        
        return rect
    }

    /// Adds formatting characters around selected text or around cursor
    /// - Parameters:
    ///   - formattingString: string used for formatting, will surround selected text or cursor
    ///   - cursorOffset: offset to adjust cursor position, should be equal to the number of characters
    func addStringFormattingCharacters(formattingString: String, cursorOffset: Int) {
        if let selectedRange = selectedTextRange {
            if selectedRange.isEmpty {
                replace(selectedTextRange ?? UITextRange(), withText: formattingString + formattingString)

                let cursorPosition = offset(from: endOfDocument, to: selectedRange.end)

                let newPosition = position(from: endOfDocument, offset: cursorPosition + cursorOffset)
                selectedTextRange = textRange(from: newPosition ?? endOfDocument, to: newPosition ?? endOfDocument)
            } else {
                if let selectedSubstring = text(in: selectedRange) {
                    replace(selectedTextRange ?? UITextRange(), withText: formattingString + selectedSubstring + formattingString)
                } else {
                    replace(selectedTextRange ?? UITextRange(), withText: formattingString + formattingString)
                }
            }
        }
    }
}
