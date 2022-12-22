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
        expandSelectedRangeUpToNearestFormattingStrings(startingFormattingString: formattingString, endingFormattingString: formattingString)
        
        if selectedRangeIsSurroundedByFormattingString(formattingString: formattingString) {
            removeSurroundingFormattingStringFromSelectedRange(formattingString: formattingString)
        } else {
            addStringFormattingCharacters(formattingString: formattingString)
        }
    }
    
    func rangeIsPrecededByFormattingString(range: UITextRange?, formattingString: String) -> Bool {
        guard let range = range,
              let newStart = position(from: range.start, offset: -formattingString.count) else {
            return false
        }
        
        guard let startingRange = textRange(from: newStart, to: range.start),
              let startingString = text(in: startingRange) else {
            return false
        }
        
        return startingString == formattingString
    }
    
    func rangeIsFollowedByFormattingString(range: UITextRange?, formattingString: String) -> Bool {
        guard let range = range,
              let newEnd = position(from: range.end, offset: formattingString.count) else {
            return false
        }
        
        guard let endingRange = textRange(from: range.end, to: newEnd),
              let endingString = text(in: endingRange) else {
            return false
        }
        
        return endingString == formattingString
    }
    
    func selectedRangeIsSurroundedByFormattingString(formattingString: String) -> Bool {
        return rangeIsPrecededByFormattingString(range: selectedTextRange, formattingString: formattingString) && rangeIsFollowedByFormattingString(range: selectedTextRange, formattingString: formattingString)
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

    func expandSelectedRangeUpToNearestFormattingStrings(startingFormattingString: String, endingFormattingString: String) {

        guard let originalSelectedRange = selectedTextRange else {
            return
        }
        
        // loop backwards to find start
        var i = 0
        var finalStart: UITextPosition?
        while let newStart = position(from: originalSelectedRange.start, offset: i) {
            let newRange = textRange(from: newStart, to: originalSelectedRange.end)

            if rangeIsPrecededByFormattingString(range: newRange, formattingString: startingFormattingString) {

                finalStart = newStart
                break
            }
            
            i = i - 1
        }
        
        // loop forwards to find end
        i = 0
        var finalEnd: UITextPosition?
        while let newEnd = position(from: originalSelectedRange.end, offset: i) {
            let newRange = textRange(from: originalSelectedRange.start, to: newEnd)
            
            if rangeIsFollowedByFormattingString(range: newRange, formattingString: endingFormattingString) {

                finalEnd = newEnd
                break
            }
            
            i = i + 1
        }
        
        // Select new range
        guard let finalStart = finalStart,
                  let finalEnd = finalEnd else {
                      return
                  }
        
        selectedTextRange = textRange(from: finalStart, to: finalEnd)
    }
}
