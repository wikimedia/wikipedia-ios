import Foundation

extension TalkPageTopicComposeViewController: TalkPageFormattingToolbarViewDelegate {

    func didSelectBold() {
        bodyTextView.addStringFormattingCharacters(formattingString: "'''", cursorOffset: 3)
    }

    func didSelectItalics() {
        bodyTextView.addStringFormattingCharacters(formattingString: "''", cursorOffset: 2)
    }

    func didSelectInsertImage() {
        let insertMediaViewController = InsertMediaViewController(articleTitle: viewModel.pageTitle, siteURL: viewModel.siteUrl)
        insertMediaViewController.delegate = self
        insertMediaViewController.apply(theme: theme)
        let navigationController = WMFThemeableNavigationController(rootViewController: insertMediaViewController, theme: theme)
        navigationController.isNavigationBarHidden = true
        present(navigationController, animated: true)
    }

    func didSelectInsertLink() {
        let link = Link(page: "", label: "", exists: false)
        let insertLinkViewController = InsertLinkViewController(link: link!, siteURL: viewModel.siteUrl, dataStore: MWKDataStore.shared())
        insertLinkViewController.delegate = self
        let navigationController = WMFThemeableNavigationController(rootViewController: insertLinkViewController, theme: self.theme)
        self.present(navigationController, animated: true)
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
        let text = String()
        if let label {
            bodyTextView.insertText("[[\(page)|\(label)]]")
        } else {
            bodyTextView.insertText("[[\(page)]]")
        }
    }

}

extension TalkPageTopicComposeViewController: InsertMediaViewControllerDelegate {
    func insertMediaViewController(_ insertMediaViewController: InsertMediaViewController, didTapCloseButton button: UIBarButtonItem) {
        dismiss(animated: true)
    }

    func insertMediaViewController(_ insertMediaViewController: InsertMediaViewController, didPrepareWikitextToInsert wikitext: String) {
        bodyTextView.insertText(wikitext)
        dismiss(animated: true)
    }


}
