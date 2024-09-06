import Foundation
import WMFComponentsObjC

enum WMFSourceEditorFormatterButtonAction {
    case add
    case remove
}

extension WMFSourceEditorFormatter {
    
    // MARK: - Entry points to adding/removing formatting strings
    
    func toggleFormatting(formattingString: String, action: WMFSourceEditorFormatterButtonAction, in textView: UITextView) {
        toggleFormatting(startingFormattingString: formattingString, endingFormattingString: formattingString, action: action, in: textView)
    }
    
    func toggleFormatting(startingFormattingString: String, wildcardStartingFormattingString: String? = nil, endingFormattingString: String, action: WMFSourceEditorFormatterButtonAction, in textView: UITextView) {
                
        var resolvedStartingFormattingString = startingFormattingString
        if let wildcardStartingFormattingString {
            resolvedStartingFormattingString = getModifiedStartingFormattingStringForSingleWildcard(startingFormattingString: wildcardStartingFormattingString, textView: textView)
        }
                
        if textView.selectedRange.length == 0 {
            
            switch action {
            case .remove:

                expandSelectedRangeUpToNearestFormattingStrings(startingFormattingString: resolvedStartingFormattingString, endingFormattingString: endingFormattingString, in: textView)
                
                if selectedRangeIsSurroundedByFormattingStrings(startingFormattingString: resolvedStartingFormattingString, endingFormattingString: endingFormattingString, in: textView) {
                    removeSurroundingFormattingStringsFromSelectedRange(startingFormattingString: resolvedStartingFormattingString, endingFormattingString: endingFormattingString, in: textView)
                }
            case .add:
                if selectedRangeIsSurroundedByFormattingStrings(startingFormattingString: resolvedStartingFormattingString, endingFormattingString: endingFormattingString, in: textView) {
                    removeSurroundingFormattingStringsFromSelectedRange(startingFormattingString: resolvedStartingFormattingString, endingFormattingString: endingFormattingString, in: textView)
                } else {
                    addStringFormattingCharacters(startingFormattingString: startingFormattingString, endingFormattingString: endingFormattingString, in: textView)
                }
            }
        } else {
            
            switch action {
            case .remove:
                
                if selectedRangeIsSurroundedByFormattingStrings(startingFormattingString: resolvedStartingFormattingString, endingFormattingString: endingFormattingString, in: textView) {
                    removeSurroundingFormattingStringsFromSelectedRange(startingFormattingString: resolvedStartingFormattingString, endingFormattingString: endingFormattingString, in: textView)
                } else {
                    
                    // Note the flipped formatting string params.
                    // For example, this takes selected 'text' from:
                    // Testing <s>Strikethrough text here</s>
                    // To:
                    // Testing <s>Strikethrough </s>text<s> here</s>
                    // We have to add formatters in reverse order to remove formatting from 'text'
                    
                    addStringFormattingCharacters(startingFormattingString: endingFormattingString, endingFormattingString: startingFormattingString, in: textView)
                }
                
            case .add:
                
                // Note: gross workaround to prevent italics misfire from continuing below
                if startingFormattingString == "''" && endingFormattingString == "''" {
                    if selectedRangeIsSurroundedByFormattingString(formattingString: "''", in: textView) &&
                        selectedRangeIsSurroundedByFormattingString(formattingString: "'''", in: textView) {
                        addStringFormattingCharacters(startingFormattingString: startingFormattingString, endingFormattingString: endingFormattingString, in: textView)
                        return
                    }
                }
                
                // Note the flipped formatting string params.
                // For example, this takes selected 'text' from:
                // Testing <s>Strikethrough </s>text<s> here</s>
                // To:
                // Testing <s>Strikethrough text here</s>
                // We have to check and remove formatters in reverse order to add formatting to 'text'
                
                if selectedRangeIsSurroundedByFormattingStrings(startingFormattingString: endingFormattingString, endingFormattingString: startingFormattingString, in: textView) {
                    removeSurroundingFormattingStringsFromSelectedRange(startingFormattingString: endingFormattingString, endingFormattingString: startingFormattingString, in: textView)
                } else {
                    addStringFormattingCharacters(startingFormattingString: startingFormattingString, endingFormattingString: endingFormattingString, in: textView)
                }
            }
        }
    }
    
    
    /// Takes a starting formatting string with a wildcard. Searches backwards from the selection point and seeks out a match (up until the first line break) and sends back a resolved starting formatting string
    /// For example:
    /// If you send in "<ref*>", it can match and send back "<ref name="test">"
    /// - Parameters:
    ///   - originalStartingFormattingString: Starting formatting string with a single wildcard character (*)
    ///   - textView: UITextView to search
    /// - Returns: A new resolved starting formatting string with no wildcard.
    func getModifiedStartingFormattingStringForSingleWildcard(startingFormattingString originalStartingFormattingString: String, textView: UITextView) -> String {
        guard originalStartingFormattingString.contains("*") else {
            return originalStartingFormattingString
        }
        
        let splitStrings = originalStartingFormattingString.split(separator: "*").map { String($0) }
        guard splitStrings.count == 2 else {
            return originalStartingFormattingString
        }
        
        guard let originalSelectedRange = textView.selectedTextRange else {
            return originalStartingFormattingString
        }
        
        // Loop backwards and find
        var i = 0
        var closingPosition: UITextPosition?
        var startingPosition: UITextPosition?
        while let loopPosition = textView.position(from: originalSelectedRange.start, offset: i) {
            let newRange = textView.textRange(from: loopPosition, to: originalSelectedRange.start)

            if closingPosition == nil && rangeIsPrecededByFormattingString(range: newRange, formattingString: splitStrings[1], in: textView) {

                closingPosition = loopPosition
                continue
            }
            
            if closingPosition != nil && rangeIsPrecededByFormattingString(range: newRange, formattingString: splitStrings[0], in: textView) {
                startingPosition = textView.position(from: loopPosition, offset: -splitStrings[0].count)
                break
            }
            
            // Stop searching if you encounter a line break
            if rangeIsPrecededByFormattingString(range: newRange, formattingString: "\n", in: textView) {
                break
            }
            
            i = i - 1
        }
        
        guard let startingPosition,
           let closingPosition,
           let newTextRange = textView.textRange(from: startingPosition, to: closingPosition),
            let modifiedStartingFormattingString = textView.text(in: newTextRange) else {
            return originalStartingFormattingString
        }
        
        return modifiedStartingFormattingString
    }
    
    // MARK: - Expanding selected range methods
    
    func expandSelectedRangeUpToNearestFormattingStrings(startingFormattingString: String, endingFormattingString: String, in textView: UITextView) {
        if let textPositions = textPositionsCloserToNearestFormattingStrings(startingFormattingString: startingFormattingString, endingFormattingString: endingFormattingString, in: textView) {
            textView.selectedTextRange = textView.textRange(from: textPositions.startPosition, to: textPositions.endPosition)
        }
    }
    
    private func textPositionsCloserToNearestFormattingStrings(startingFormattingString: String, endingFormattingString: String, in textView: UITextView) -> (startPosition: UITextPosition, endPosition: UITextPosition)? {
        
        guard let originalSelectedRange = textView.selectedTextRange else {
            return nil
        }
        
        let breakOnOppositeTag = startingFormattingString != endingFormattingString
        
        // loop backwards to find start
        var i = 0
        var finalStart: UITextPosition?
        while let newStart = textView.position(from: originalSelectedRange.start, offset: i) {
            let newRange = textView.textRange(from: newStart, to: originalSelectedRange.end)

            if rangeIsPrecededByFormattingString(range: newRange, formattingString: startingFormattingString, in: textView) {

                finalStart = newStart
                break
            }
            
            // Stop searching if you encounter a line break or another closing formatting string
            if rangeIsPrecededByFormattingString(range: newRange, formattingString: "\n", in: textView) {
                break
            }
            
            if breakOnOppositeTag && rangeIsPrecededByFormattingString(range: newRange, formattingString: endingFormattingString, in: textView) {
                break
            }
            
            i = i - 1
        }
        
        // loop forwards to find end
        i = 0
        var finalEnd: UITextPosition?
        while let newEnd = textView.position(from: originalSelectedRange.end, offset: i) {
            let newRange = textView.textRange(from: originalSelectedRange.start, to: newEnd)
            
            if rangeIsFollowedByFormattingString(range: newRange, formattingString: endingFormattingString, in: textView) {

                finalEnd = newEnd
                break
            }
            
            // Stop searching if you encounter a line break or another opening formatting string
            if rangeIsFollowedByFormattingString(range: newRange, formattingString: "\n", in: textView) {
                break
            }
            
            if breakOnOppositeTag && rangeIsFollowedByFormattingString(range: newRange, formattingString: startingFormattingString, in: textView) {
                break
            }
            
            i = i + 1
        }
        
        // Select new range
        guard let finalStart = finalStart,
                  let finalEnd = finalEnd else {
                      return nil
                  }
        
        return (finalStart, finalEnd)
    }
    
    // MARK: - Nearby formatting string determination
    
    func selectedRangeIsSurroundedByFormattingString(formattingString: String, in textView: UITextView) -> Bool {
        selectedRangeIsSurroundedByFormattingStrings(startingFormattingString: formattingString, endingFormattingString: formattingString, in: textView)
    }
    
    private func selectedRangeIsSurroundedByFormattingStrings(startingFormattingString: String, endingFormattingString: String, in textView: UITextView) -> Bool {
        return rangeIsPrecededByFormattingString(range: textView.selectedTextRange, formattingString: startingFormattingString, in: textView) && rangeIsFollowedByFormattingString(range: textView.selectedTextRange, formattingString: endingFormattingString, in: textView)
    }
    
    private func rangeIsPrecededByFormattingString(range: UITextRange?, formattingString: String, in textView: UITextView) -> Bool {
        guard let range = range,
              let newStart = textView.position(from: range.start, offset: -formattingString.count) else {
            return false
        }
        
        guard let startingRange = textView.textRange(from: newStart, to: range.start),
              let startingString = textView.text(in: startingRange) else {
            return false
        }
        
        return startingString == formattingString
    }
    
    func rangeIsFollowedByFormattingString(range: UITextRange?, formattingString: String, in textView: UITextView) -> Bool {
        guard let range = range,
              let newEnd = textView.position(from: range.end, offset: formattingString.count) else {
            return false
        }
        
        guard let endingRange = textView.textRange(from: range.end, to: newEnd),
              let endingString = textView.text(in: endingRange) else {
            return false
        }
        
        return endingString == formattingString
    }
    
    // MARK: Adding and removing text
    
    func addStringFormattingCharacters(startingFormattingString: String, endingFormattingString: String, in textView: UITextView) {
        
        let startingCursorOffset = startingFormattingString.count
        let endingCursorOffset = endingFormattingString.count
        if let selectedRange = textView.selectedTextRange {
            let cursorPosition = textView.offset(from: textView.endOfDocument, to: selectedRange.end)
            if selectedRange.isEmpty {
                textView.replace(textView.selectedTextRange ?? UITextRange(), withText: startingFormattingString + " " + endingFormattingString)

                let newStartPosition = textView.position(from: textView.endOfDocument, offset: cursorPosition - endingCursorOffset - 1)
                let newEndPosition = textView.position(from: newStartPosition ?? textView.endOfDocument, offset: 1)
                textView.selectedTextRange = textView.textRange(from: newStartPosition ?? textView.endOfDocument, to: newEndPosition ?? textView.endOfDocument)
            } else {
                if let selectedSubstring = textView.text(in: selectedRange) {
                    textView.replace(textView.selectedTextRange ?? UITextRange(), withText: startingFormattingString + selectedSubstring + endingFormattingString)

                    let delta = endingFormattingString.count - startingFormattingString.count
                    let newStartPosition = textView.position(from: selectedRange.start, offset: startingCursorOffset)
                    let newEndPosition = textView.position(from: selectedRange.end, offset: endingCursorOffset - delta)
                    textView.selectedTextRange = textView.textRange(from: newStartPosition ?? textView.endOfDocument, to: newEndPosition ?? textView.endOfDocument)
                } else {
                    textView.replace(textView.selectedTextRange ?? UITextRange(), withText: startingFormattingString + endingFormattingString)
                }
            }
        }
    }
    
    func removeSurroundingFormattingStringsFromSelectedRange(startingFormattingString: String, endingFormattingString: String, in textView: UITextView) {

        guard let originalSelectedTextRange = textView.selectedTextRange,
              let formattingTextStart = textView.position(from: originalSelectedTextRange.start, offset: -startingFormattingString.count),
              let formattingTextEnd = textView.position(from: originalSelectedTextRange.end, offset: endingFormattingString.count) else {
            return
        }
        
        guard let formattingTextStartRange = textView.textRange(from: formattingTextStart, to: originalSelectedTextRange.start),
              let formattingTextEndRange = textView.textRange(from: originalSelectedTextRange.end, to: formattingTextEnd) else {
            return
        }
        
        var removedSingleSpace = false
        if let selectedText = textView.text(in: originalSelectedTextRange),
           selectedText == " ",
           let replaceRange = textView.textRange(from: formattingTextStartRange.start, to: formattingTextEndRange.end) {
            
            // If there's just a space in the middle, remove the whole thing
            textView.replace(replaceRange, withText: "")
            removedSingleSpace = true
        } else {
            
            // Otherwise remove only formatting strings
            // Note: replacing end first ordering is important here, otherwise range gets thrown off if you begin with start.
            textView.replace(formattingTextEndRange, withText: "")
            textView.replace(formattingTextStartRange, withText: "")
        }

        // Reset selection
        let delta = endingFormattingString.count - startingFormattingString.count
        guard
            let newSelectionStartPosition = textView.position(from: originalSelectedTextRange.start, offset: -startingFormattingString.count),
            let newSelectionEndPosition = removedSingleSpace ? newSelectionStartPosition : textView.position(from: originalSelectedTextRange.end, offset: -endingFormattingString.count + delta) else {
            return
        }

        textView.selectedTextRange = textView.textRange(from: newSelectionStartPosition, to: newSelectionEndPosition)
    }
}
