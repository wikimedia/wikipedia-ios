import UIKit
import Foundation

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

    func prepareLinkInsertion(preselectedTextRange: inout UITextRange) -> (linkText: String, labelText: String, doesLinkExist: Bool)? {
        guard let range =  selectedTextRange else { return nil }
            let text = text(in: range)
            preselectedTextRange = range

        guard let text else { return nil }

        var doesLinkExist = false

        if let start = position(from: range.start, offset: -2),
           let end = position(from: range.end, offset: 2),
           let newSelectedRange = textRange(from: start, to: end) {

            if let newText = self.text(in: newSelectedRange) {
                if newText.contains("[") || newText.contains("]") {
                    doesLinkExist = true
                } else {
                    doesLinkExist = false
                }
            }
        }

        let index = text.firstIndex(of: "|") ?? text.endIndex
        let beggining = text[..<index]

        let ending = text[index...]

        let newSearchTerm = String(beggining)
        let newLabel = String(ending.dropFirst())

        let linkText = doesLinkExist ? newSearchTerm : text
        let labelText = doesLinkExist ? newLabel : text

        return (linkText, labelText, doesLinkExist)
    }

}
