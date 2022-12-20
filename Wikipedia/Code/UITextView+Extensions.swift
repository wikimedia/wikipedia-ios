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
    func addStringFormattingCharacters(formattingString: String) {
        let cursorOffset = formattingString.count
        if let selectedRange = selectedTextRange {
            let cursorPosition = offset(from: endOfDocument, to: selectedRange.end)
            if selectedRange.isEmpty {
                replace(selectedTextRange ?? UITextRange(), withText: formattingString + formattingString)

                let newPosition = position(from: endOfDocument, offset: cursorPosition - cursorOffset)
                selectedTextRange = textRange(from: newPosition ?? endOfDocument, to: newPosition ?? endOfDocument)
            } else {
                if let selectedSubstring = text(in: selectedRange) {
                    replace(selectedTextRange ?? UITextRange(), withText: formattingString + selectedSubstring + formattingString)

                    let newStartPosition = position(from: selectedRange.start, offset: cursorOffset)
                    let newEndPosition = position(from: selectedRange.end, offset: cursorOffset)
                    selectedTextRange = textRange(from: newStartPosition ?? endOfDocument, to: newEndPosition ?? endOfDocument)
                } else {
                    replace(selectedTextRange ?? UITextRange(), withText: formattingString + formattingString)
                }
            }
        }
    }

    /// Decides if should add or remove formatting characters around selected text or around cursor, based on pre-existing formatting strings
    /// - Parameters:
    ///   - formattingString: string used for formatting, will surround selected text or cursor
    func addOrRemoveStringFormattingCharacters(formattingString: String) {
        
        // here: select up to tick marks?
        
        if selectedRangeIsSurroundedByFormattingString(formattingString: formattingString) {
            removeSurroundingFormattingStringFromSelectedRange(formattingString: formattingString)
        } else {
            addStringFormattingCharacters(formattingString: formattingString)
        }
    }
    
    func selectedRangeisPrecededByFormattingString(formattingString: String) -> Bool {
        guard let selectedTextRange = selectedTextRange,
              let newStart = position(from: selectedTextRange.start, offset: -formattingString.count) else {
            return false
        }
        
        guard let startingRange = textRange(from: newStart, to: selectedTextRange.start),
              let startingString = text(in: startingRange) else {
            return false
        }
        
        return startingString == formattingString
    }
    
    func selectedRangeIsFollowedByFormattingString(formattingString: String) -> Bool {
        guard let selectedTextRange = selectedTextRange,
              let newEnd = position(from: selectedTextRange.end, offset: formattingString.count) else {
            return false
        }
        
        guard let endingRange = textRange(from: selectedTextRange.end, to: newEnd),
              let endingString = text(in: endingRange) else {
            return false
        }
        
        return endingString == formattingString
    }
    
    func selectedRangeIsSurroundedByFormattingString(formattingString: String) -> Bool {
        return selectedRangeisPrecededByFormattingString(formattingString: formattingString) && selectedRangeIsFollowedByFormattingString(formattingString: formattingString) 
    }
    
    // Check selectedRangeIsSurroundedByFormattingString first before running this
    func removeSurroundingFormattingStringFromSelectedRange(formattingString: String) {
        
        guard selectedRangeIsSurroundedByFormattingString(formattingString: formattingString) else {
            assertionFailure("Selected text is not surrounded by formatting string. Do nothing")
            return
        }
        
        guard let originalSelectedTextRange = selectedTextRange,
              let formattingTextStart = position(from: originalSelectedTextRange.start, offset: -formattingString.count),
              let formattingTextEnd = position(from: originalSelectedTextRange.end, offset: formattingString.count) else {
            return
        }
        
        guard let formattingTextStartRange = textRange(from: formattingTextStart, to: originalSelectedTextRange.start),
              let formattingTextEndRange = textRange(from: originalSelectedTextRange.end, to: formattingTextEnd) else {
            return
        }
        
        // Note: replacing end first ordering is important here, otherwise range gets thrown off if you begin with start. Check with RTL
        replace(formattingTextEndRange, withText: "")
        replace(formattingTextStartRange, withText: "")

        // Reset selection
        guard
            let newSelectionStartPosition = position(from: originalSelectedTextRange.start, offset: -formattingString.count),
            let newSelectionEndPosition = position(from: originalSelectedTextRange.end, offset: -formattingString.count) else {
            return
        }

        selectedTextRange = textRange(from: newSelectionStartPosition, to: newSelectionEndPosition)
    }
    
    func expandSelectedRangeUpToNearestFormattingString(formattingString: String) {
        
    }
}
