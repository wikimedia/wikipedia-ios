import Foundation

extension TalkPageTopicComposeViewController: TalkPageFormattingToolbarViewDelegate {
    func didSelectBold() {
        print("BOLD")
    }

    func didSelectItalics() {
        print("ITALICS")
    }

    func didSelectInsertImage() {
        print("IMAGE")
    }

    func didSelectInsertLink() {
        print("LINK")
    }
}
