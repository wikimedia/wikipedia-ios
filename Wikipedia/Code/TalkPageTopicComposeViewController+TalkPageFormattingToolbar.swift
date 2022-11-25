import Foundation

extension TalkPageTopicComposeViewController: TalkPageFormattingToolbarViewDelegate {
    fileprivate func formatText(formattingString: String, cursorOffset: Int) {
        if let selectedRange = bodyTextView.selectedTextRange {
            if bodyTextView.selectedRange.length == 0 {
                bodyTextView.replace(bodyTextView.selectedTextRange ?? UITextRange(), withText: formattingString)

                let cursorPosition = bodyTextView.offset(from: bodyTextView.endOfDocument, to: selectedRange.end)

                let newPosition = bodyTextView.position(from: bodyTextView.endOfDocument, offset: cursorPosition+cursorOffset)
                bodyTextView.selectedTextRange = bodyTextView.textRange(from: newPosition ?? bodyTextView.endOfDocument, to: newPosition ?? bodyTextView.endOfDocument)
            } else {
                if let selectedSubstring = bodyTextView.text(in: selectedRange) {
                    bodyTextView.replace(bodyTextView.selectedTextRange ?? UITextRange(), withText: "'''\(selectedSubstring)'''")
                } else {
                    bodyTextView.replace(bodyTextView.selectedTextRange ?? UITextRange(), withText: "''''''")
                }
            }

        }
    }

    func didSelectBold() {
        formatText(formattingString: "''''''", cursorOffset: 3)
    }

    func didSelectItalics() {
        formatText(formattingString: "''''", cursorOffset: 2)
    }

    func didSelectInsertImage() {
        print("IMAGE")
    }

    func didSelectInsertLink() {
        print("LINK")
    }
}
