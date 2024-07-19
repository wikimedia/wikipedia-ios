import Foundation
import CocoaLumberjackSwift

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
        
        replyComposeController.contentView?.replyTextView.expandSelectedRangeUpToNearestFormattingStrings(startingFormattingString: "[[", endingFormattingString: "]]")
        
        if let linkInfo = replyComposeController.contentView?.replyTextView.prepareLinkInsertion(preselectedTextRange: &preselectedTextRange) {

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

extension TalkPageViewController: InsertLinkViewControllerDelegate {
    func insertLinkViewController(_ insertLinkViewController: InsertLinkViewController, didTapCloseButton button: UIBarButtonItem) {
        dismiss(animated: true)
    }

    func insertLinkViewController(_ insertLinkViewController: InsertLinkViewController, didInsertLinkFor page: String, withLabel label: String?) {
        if let textView = replyComposeController.contentView?.replyTextView {
            textView.insertLink(page: page, customTextRange: preselectedTextRange)
        }
        dismiss(animated: true)
    }

}

extension TalkPageViewController: EditLinkViewControllerDelegate {
    func editLinkViewController(_ editLinkViewController: EditLinkViewController, didTapCloseButton button: UIBarButtonItem) {
        dismiss(animated: true)
    }

    func editLinkViewController(_ editLinkViewController: EditLinkViewController, didFinishEditingLink displayText: String?, linkTarget: String) {
        if let textView = replyComposeController.contentView?.replyTextView {
            textView.editLink(page: linkTarget, label: displayText, customTextRange: preselectedTextRange)
        }
        dismiss(animated: true)
    }

    func editLinkViewController(_ editLinkViewController: EditLinkViewController, didFailToExtractArticleTitleFromArticleURL articleURL: URL) {
        DDLogWarn("Failed to extract article title from \(articleURL)")
        dismiss(animated: true)
    }

    func editLinkViewControllerDidRemoveLink(_ editLinkViewController: EditLinkViewController) {
        if let textView = replyComposeController.contentView?.replyTextView, let range =  textView.selectedTextRange {
            preselectedTextRange = range

            if let start = textView.position(from: range.start, offset: -2),
               let end = textView.position(from: range.end, offset: 2),
               let newSelectedRange = textView.textRange(from: start, to: end) {
                textView.replace(newSelectedRange, withText: textView.text(in: preselectedTextRange) ?? String())
                let newStartPosition = textView.position(from: range.start, offset: -2)
                let newEndPosition = textView.position(from: range.end, offset: -2)
                textView.selectedTextRange = textView.textRange(from: newStartPosition ?? textView.endOfDocument, to: newEndPosition ?? textView.endOfDocument)
            }
        }
        dismiss(animated: true)
    }

}
