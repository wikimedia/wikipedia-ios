import Foundation

extension TalkPageTopicComposeViewController: TalkPageFormattingToolbarViewDelegate {

    func didSelectBold() {
        bodyTextView.addStringFormattingCharacters(formattingString: "'''", cursorOffset: 3)
    }

    func didSelectItalics() {
        bodyTextView.addStringFormattingCharacters(formattingString: "''", cursorOffset: 2)
    }

    func didSelectInsertImage() {
        print("IMAGE")
    }

    func didSelectInsertLink() {
        print("LINK")
    }
}
