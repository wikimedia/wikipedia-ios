import Foundation

extension TalkPageViewController: TalkPageFormattingToolbarViewDelegate {

    func didSelectBold() {
        if let textView = replyComposeController.contentView?.replyTextView {
            textView.addOrRemoveStringFormattingCharacters(formattingString: "'''")
        }
    }

    func didSelectItalics() {
        if let textView = replyComposeController.contentView?.replyTextView {
            textView.addOrRemoveStringFormattingCharacters(formattingString: "''")
        }
    }

    func didSelectInsertLink() {
        if let textView = replyComposeController.contentView?.replyTextView {
            let text = textView.text(in: textView.selectedTextRange ?? UITextRange())
            guard let link = Link(page: text, label: text, exists: true) else {
                return
            }
            let insertLinkViewController = InsertLinkViewController(link: link, siteURL: viewModel.siteURL, dataStore: MWKDataStore.shared())
            insertLinkViewController.delegate = self
            let navigationController = WMFThemeableNavigationController(rootViewController: insertLinkViewController, theme: self.theme)
            present(navigationController, animated: true)
        }
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
                textView.replace(textView.selectedTextRange ?? UITextRange(), withText: "[[\(page)|\(label)]]")
            } else {
                textView.replace(textView.selectedTextRange ?? UITextRange(), withText: "[[\(page)]]")
            }
        }
    }
}
