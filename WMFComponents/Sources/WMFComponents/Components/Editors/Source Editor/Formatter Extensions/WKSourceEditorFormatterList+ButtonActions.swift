import Foundation
import WMFComponentsObjC

extension WMFSourceEditorFormatterList {
    func toggleListBullet(action: WMFSourceEditorFormatterButtonAction, in textView: UITextView) {
        toggleListItem(action: action, formattingCharacter: "*", in: textView)
    }
    
    func toggleListNumber(action: WMFSourceEditorFormatterButtonAction, in textView: UITextView) {
        toggleListItem(action: action, formattingCharacter: "#", in: textView)
    }
    
    func tappedIncreaseIndent(currentSelectionState: WMFSourceEditorSelectionState, textView: UITextView) {

        guard currentSelectionState.isBulletSingleList ||
                currentSelectionState.isBulletMultipleList ||
                currentSelectionState.isNumberSingleList ||
                currentSelectionState.isNumberMultipleList else {
            assertionFailure("Increase / Decrease indent buttons should have been disabled.")
            return
        }
        
        let formattingCharacter = (currentSelectionState.isBulletSingleList ||
                                   currentSelectionState.isBulletMultipleList) ? "*" : "#"
        
        let nsString = textView.attributedText.string as NSString
        let lineRange = nsString.lineRange(for: textView.selectedRange)
        
        textView.textStorage.insert(NSAttributedString(string: String(formattingCharacter)), at: lineRange.location)
        
        // reset cursor so it doesn't move
        if let selectedRange = textView.selectedTextRange {
            if let newStart = textView.position(from: selectedRange.start, offset: 1),
            let newEnd = textView.position(from: selectedRange.end, offset: 1) {
                textView.selectedTextRange = textView.textRange(from: newStart, to: newEnd)
            }
        }
    }
    
    func tappedDecreaseIndent(currentSelectionState: WMFSourceEditorSelectionState, textView: UITextView) {
        
        guard currentSelectionState.isBulletSingleList ||
                currentSelectionState.isBulletMultipleList ||
                currentSelectionState.isNumberSingleList ||
                currentSelectionState.isNumberMultipleList else {
            assertionFailure("Increase / Decrease indent buttons should have been disabled.")
            return
        }
        
        let nsString = textView.attributedText.string as NSString
        let lineRange = nsString.lineRange(for: textView.selectedRange)
        
        guard textView.textStorage.length > lineRange.location else {
            return
        }
        
        textView.textStorage.replaceCharacters(in: NSRange(location: lineRange.location, length: 1), with: "")
        
        // reset cursor so it doesn't move
        if let selectedRange = textView.selectedTextRange {
            if let newStart = textView.position(from: selectedRange.start, offset: -1),
            let newEnd = textView.position(from: selectedRange.end, offset: -1) {
                textView.selectedTextRange = textView.textRange(from: newStart, to: newEnd)
            }
        }
    }
    
    private func toggleListItem(action: WMFSourceEditorFormatterButtonAction, formattingCharacter: Character, in textView: UITextView) {
        let nsString = textView.attributedText.string as NSString
        let lineRange = nsString.lineRange(for: textView.selectedRange)
        switch action {
        case .add:
            
            var numBullets = 0
            for char in textView.textStorage.attributedSubstring(from: lineRange).string {
                if char == formattingCharacter {
                    numBullets += 1
                }
            }
            
            let insertString = numBullets == 0 ? "\(String(formattingCharacter)) " : String(formattingCharacter)
            textView.textStorage.insert(NSAttributedString(string: insertString), at: lineRange.location)
            
            // reset cursor so it doesn't move
            if let selectedRange = textView.selectedTextRange {
                if let newStart = textView.position(from: selectedRange.start, offset: insertString.count),
                   let newEnd = textView.position(from: selectedRange.end, offset: insertString.count) {
                    textView.selectedTextRange = textView.textRange(from: newStart, to: newEnd)
                }
            }
        case .remove:
            
            var numBullets = 0
            var hasSpace = false
            for char in textView.textStorage.attributedSubstring(from: lineRange).string {
                if char != formattingCharacter {
                    if char == " " {
                        hasSpace = true
                    }
                    break
                }
                
                if char == formattingCharacter {
                    numBullets += 1
                }
            }
            
            let replacementLength = numBullets + (hasSpace ? 1 : 0)
            textView.textStorage.replaceCharacters(in: NSRange(location: lineRange.location, length: replacementLength), with: "")
            
            // reset cursor so it doesn't move
            if let selectedRange = textView.selectedTextRange {
                if let newStart = textView.position(from: selectedRange.start, offset: -1 * replacementLength),
                let newEnd = textView.position(from: selectedRange.end, offset: -1 * replacementLength) {
                    textView.selectedTextRange = textView.textRange(from: newStart, to: newEnd)
                }
            }
        }
    }
}
