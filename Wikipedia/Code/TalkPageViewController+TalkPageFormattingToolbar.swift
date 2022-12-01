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

    func didSelectInsertLink() {
        guard let link = Link(page: "", label: "", exists: false) else {
            return
        }
        let insertLinkViewController = InsertLinkViewController(link: link, siteURL: viewModel.siteURL, dataStore: MWKDataStore.shared())
        insertLinkViewController.delegate = self
        let navigationController = WMFThemeableNavigationController(rootViewController: insertLinkViewController, theme: self.theme)
        self.present(navigationController, animated: true)
    }
}

extension TalkPageViewController: InsertLinkViewControllerDelegate {
    func insertLinkViewController(_ insertLinkViewController: InsertLinkViewController, didTapCloseButton button: UIBarButtonItem) {
        dismiss(animated: true)
    }

    func insertLinkViewController(_ insertLinkViewController: InsertLinkViewController, didInsertLinkFor page: String, withLabel label: String?) {
        insertOrEditLink(page: page, label: label)
        dismiss(animated: true)
    }

    func insertOrEditLink(page: String, label: String?) {
        if let textView = replyComposeController.contentView?.replyTextView {
            if let label {
                textView.insertText("[[\(page)|\(label)]]")
            } else {
                textView.insertText("[[\(page)]]")
            }
        }
    }
}
