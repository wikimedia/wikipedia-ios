import Foundation
import CocoaLumberjackSwift
import WMF

extension TalkPageTopicComposeViewController: TalkPageFormattingToolbarViewDelegate {

    func didSelectBold() {
        bodyTextView.addOrRemoveStringFormattingCharacters(formattingString: "'''")
    }

    func didSelectItalics() {
        bodyTextView.addOrRemoveStringFormattingCharacters(formattingString: "''")
    }

    func didSelectInsertLink() {
        
        bodyTextView.expandSelectedRangeUpToNearestFormattingStrings(startingFormattingString: "[[", endingFormattingString: "]]")

        if let linkInfo = bodyTextView.prepareLinkInsertion(preselectedTextRange: &preselectedTextRange) {

            guard let link = Link(page: linkInfo.linkText, label: linkInfo.labelText, exists: linkInfo.doesLinkExist) else {
                return
            }

            if link.exists {
                guard let editLinkViewController = EditLinkViewController(link: link, siteURL: viewModel.siteURL, dataStore: MWKDataStore.shared()) else {
                    return
                }
                editLinkViewController.delegate = self
                let navigationController = WMFThemeableNavigationController(rootViewController: editLinkViewController, theme: self.theme)
                navigationController.isNavigationBarHidden = true
                present(navigationController, animated: true)
            } else {
                let insertLinkViewController = InsertLinkViewController(link: link, siteURL: viewModel.siteURL, dataStore: MWKDataStore.shared())
                insertLinkViewController.delegate = self
                let navigationController = WMFThemeableNavigationController(rootViewController: insertLinkViewController, theme: self.theme)
                present(navigationController, animated: true)
            }

        }
    }

}

extension TalkPageTopicComposeViewController: InsertLinkViewControllerDelegate {
    func insertLinkViewController(_ insertLinkViewController: InsertLinkViewController, didTapCloseButton button: UIBarButtonItem) {
        dismiss(animated: true)
    }

    func insertLinkViewController(_ insertLinkViewController: InsertLinkViewController, didInsertLinkFor page: String, withLabel label: String?) {
        bodyTextView.insertLink(page: page, customTextRange: preselectedTextRange)
        dismiss(animated: true)
    }
}

extension TalkPageTopicComposeViewController: EditLinkViewControllerDelegate {
    func editLinkViewController(_ editLinkViewController: EditLinkViewController, didTapCloseButton button: UIBarButtonItem) {
        dismiss(animated: true)
    }

    func editLinkViewController(_ editLinkViewController: EditLinkViewController, didFinishEditingLink displayText: String?, linkTarget: String) {
        bodyTextView.editLink(page: linkTarget, label: displayText, customTextRange: preselectedTextRange)
        dismiss(animated: true)
    }

    func editLinkViewController(_ editLinkViewController: EditLinkViewController, didFailToExtractArticleTitleFromArticleURL articleURL: URL) {
        DDLogWarn("Failed to extract article title from \(articleURL)")
        dismiss(animated: true)
    }

    func editLinkViewControllerDidRemoveLink(_ editLinkViewController: EditLinkViewController) {
        if let range =  bodyTextView.selectedTextRange {
            preselectedTextRange = range

            if let start = bodyTextView.position(from: range.start, offset: -2),
               let end = bodyTextView.position(from: range.end, offset: 2),
               let newSelectedRange = bodyTextView.textRange(from: start, to: end) {
                bodyTextView.replace(newSelectedRange, withText: bodyTextView.text(in: preselectedTextRange) ?? String())

                let newStartPosition = bodyTextView.position(from: range.start, offset: -2)
                let newEndPosition = bodyTextView.position(from: range.end, offset: -2)
                bodyTextView.selectedTextRange = bodyTextView.textRange(from: newStartPosition ?? bodyTextView.endOfDocument, to: newEndPosition ?? bodyTextView.endOfDocument)
            }
        }
        dismiss(animated: true)
    }


}
