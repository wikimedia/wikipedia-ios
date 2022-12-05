import Foundation

extension TalkPageTopicComposeViewController: TalkPageFormattingToolbarViewDelegate {

    func didSelectBold() {
        bodyTextView.addOrRemoveStringFormattingCharacters(formattingString: "'''")
    }

    func didSelectItalics() {
        bodyTextView.addOrRemoveStringFormattingCharacters(formattingString: "''")
    }

    func didSelectInsertLink() {
        if let range =  bodyTextView.selectedTextRange {
            let text = bodyTextView.text(in: range)
            preselectedTextRange = range
            guard let link = Link(page: text, label: text, exists: true) else {
                return
            }
            let insertLinkViewController = InsertLinkViewController(link: link, siteURL: viewModel.siteUrl, dataStore: MWKDataStore.shared())
            insertLinkViewController.delegate = self
            let navigationController = WMFThemeableNavigationController(rootViewController: insertLinkViewController, theme: self.theme)
            present(navigationController, animated: true)
        }
    }

}

extension TalkPageTopicComposeViewController: InsertLinkViewControllerDelegate {
    func insertLinkViewController(_ insertLinkViewController: InsertLinkViewController, didTapCloseButton button: UIBarButtonItem) {
        dismiss(animated: true)
    }

    func insertLinkViewController(_ insertLinkViewController: InsertLinkViewController, didInsertLinkFor page: String, withLabel label: String?) {
        insertOrEditLink(page: page, label: label)
        dismiss(animated: true)
    }

    func insertOrEditLink(page: String, label: String?) {
        if let label {
            bodyTextView.replace(preselectedTextRange, withText: "[[\(page)|\(label)]]")
        } else {
            bodyTextView.replace(preselectedTextRange, withText: "[[\(page)]]")
        }
    }
}
