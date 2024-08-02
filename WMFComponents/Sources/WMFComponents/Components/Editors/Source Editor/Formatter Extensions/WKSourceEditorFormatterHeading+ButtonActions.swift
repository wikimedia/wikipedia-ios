import Foundation
import WMFComponentsObjC

extension WMFSourceEditorFormatterHeading {
    func toggleHeadingFormatting(selectedHeading: WMFEditorInputView.HeadingButtonType, currentSelectionState: WMFSourceEditorSelectionState, textView: UITextView) {
        
        var currentStateIsParagraph = false
        if currentSelectionState.isHeading {
            expandSelectedRangeUpToNearestFormattingStrings(startingFormattingString: "==", endingFormattingString: "==", in: textView)
            removeSurroundingFormattingStringsFromSelectedRange(startingFormattingString: "==", endingFormattingString: "==", in: textView)
        } else if currentSelectionState.isSubheading1 {
            expandSelectedRangeUpToNearestFormattingStrings(startingFormattingString: "===", endingFormattingString: "===", in: textView)
            removeSurroundingFormattingStringsFromSelectedRange(startingFormattingString: "===", endingFormattingString: "===", in: textView)
        } else if currentSelectionState.isSubheading2 {
            expandSelectedRangeUpToNearestFormattingStrings(startingFormattingString: "====", endingFormattingString: "====", in: textView)
            removeSurroundingFormattingStringsFromSelectedRange(startingFormattingString: "====", endingFormattingString: "====", in: textView)
        } else if currentSelectionState.isSubheading3 {
            expandSelectedRangeUpToNearestFormattingStrings(startingFormattingString: "=====", endingFormattingString: "=====", in: textView)
            removeSurroundingFormattingStringsFromSelectedRange(startingFormattingString: "=====", endingFormattingString: "=====", in: textView)
        } else if currentSelectionState.isSubheading4 {
            expandSelectedRangeUpToNearestFormattingStrings(startingFormattingString: "======", endingFormattingString: "======", in: textView)
            removeSurroundingFormattingStringsFromSelectedRange(startingFormattingString: "======", endingFormattingString: "======", in: textView)
        } else {
            currentStateIsParagraph = true
        }
        
        let currentlySurroundedByLineBreaks = selectedRangeIsSurroundedByFormattingString(formattingString: "\n", in: textView) || textView.selectedRange.location == 0 && rangeIsFollowedByFormattingString(range: textView.selectedTextRange, formattingString: "\n", in: textView)

        let surroundingLineBreak = currentStateIsParagraph && !currentlySurroundedByLineBreaks ? "\n" : ""
        let startingFormattingString: String
        let endingFormattingString: String
        switch selectedHeading {
        case .paragraph:
            return
        case .heading:
            startingFormattingString = surroundingLineBreak + "=="
            endingFormattingString = "==" + surroundingLineBreak
        case .subheading1:
            startingFormattingString = surroundingLineBreak + "==="
            endingFormattingString = "===" + surroundingLineBreak
        case .subheading2:
            startingFormattingString = surroundingLineBreak + "===="
            endingFormattingString = "====" + surroundingLineBreak
        case .subheading3:
            startingFormattingString = surroundingLineBreak + "====="
            endingFormattingString = "=====" + surroundingLineBreak
        case .subheading4:
            startingFormattingString = surroundingLineBreak + "======"
            endingFormattingString = "======" + surroundingLineBreak
        }
        
        addStringFormattingCharacters(startingFormattingString: startingFormattingString, endingFormattingString: endingFormattingString, in: textView)
    }
}
