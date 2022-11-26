import Foundation

extension TalkPageViewController: TalkPageFormattingToolbarViewDelegate {

    func didSelectBold() {
        if let textView = replyComposeController.contentView?.replyTextView {
            textView.addStringFormattingCharacters(formattingString: "'''", cursorOffset: 3)
        }
    }

    func didSelectItalics() {
        if let textView = replyComposeController.contentView?.replyTextView {
            textView.addStringFormattingCharacters(formattingString: "''", cursorOffset: 2)
        }
    }

    func didSelectInsertImage() {
        print("IMAGE")
    }

    func didSelectInsertLink() {
        print("LINK")
    }
    
}
