import UIKit

internal extension UITextView {
    func insertLink(page: String, customTextRange: UITextRange) {
        var content = "[[\(page)]]"

        if let selectedText = text(in: customTextRange) {
            if selectedText.isEmpty || page == selectedText {
                content = "[[\(page)]]"
            } else if page != selectedText {
                content = "[[\(page)|\(selectedText)]]"
            }
        }
        replace(customTextRange, withText: content)

        let newStartPosition = position(from: customTextRange.start, offset: 2)
        let newEndPosition = position(from: customTextRange.start, offset: content.count-2)
        selectedTextRange = textRange(from: newStartPosition ?? endOfDocument, to: newEndPosition ?? endOfDocument)
    }

    func editLink(page: String, label: String?, customTextRange: UITextRange) {
        if let label, !label.isEmpty {
            replace(customTextRange, withText: "\(page)|\(label)")
        } else {
            replace(customTextRange, withText: "\(page)")
        }
    }

}
