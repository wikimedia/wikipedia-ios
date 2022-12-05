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
        if let range =  bodyTextView.selectedTextRange {
            let text = bodyTextView.text(in: range)
            preselectedTextRange = range

            var existes = false

            if let start = bodyTextView.position(from: range.start, offset: -2),
               let end = bodyTextView.position(from: range.end, offset: 2),
               let newSelectedRange = bodyTextView.textRange(from: start, to: end) {

                if let newText = bodyTextView.text(in: newSelectedRange) {
                    if newText.contains("[") || newText.contains("]") {
                        existes = true
                    } else {
                        existes = false
                    }
                }
            }

            guard let link = Link(page: text, label: text, exists: existes) else {
                return
            }

            if link.exists {
                guard let editLinkViewController = EditLinkViewController(link: link, siteURL: viewModel.siteUrl, dataStore: MWKDataStore.shared()) else {
                    return
                }
                editLinkViewController.delegate = self
                let navigationController = WMFThemeableNavigationController(rootViewController: editLinkViewController, theme: self.theme)
                navigationController.isNavigationBarHidden = true
                present(navigationController, animated: true)
            } else {
                let insertLinkViewController = InsertLinkViewController(link: link, siteURL: viewModel.siteUrl, dataStore: MWKDataStore.shared())
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
        insertLink(page: page, label: label)
        dismiss(animated: true)
    }

    func insertLink(page: String, label: String?) {
        if let label {
            bodyTextView.replace(preselectedTextRange, withText: "[[\(page)|\(label)]]")
        } else {
            bodyTextView.replace(preselectedTextRange, withText: "[[\(page)]]")
        }
    }
}

extension TalkPageTopicComposeViewController: EditLinkViewControllerDelegate {
    func editLinkViewController(_ editLinkViewController: EditLinkViewController, didTapCloseButton button: UIBarButtonItem) {
        dismiss(animated: true)
    }

    func editLinkViewController(_ editLinkViewController: EditLinkViewController, didFinishEditingLink displayText: String?, linkTarget: String) {
        editLink(page: linkTarget, label: displayText)
        dismiss(animated: true)
    }

    func editLinkViewController(_ editLinkViewController: EditLinkViewController, didFailToExtractArticleTitleFromArticleURL articleURL: URL) {
        DDLogError("Failed to extract article title from \(articleURL)")
        dismiss(animated: true)
    }

    func editLinkViewControllerDidRemoveLink(_ editLinkViewController: EditLinkViewController) {
        if let range =  bodyTextView.selectedTextRange {
            let text = bodyTextView.text(in: range)
            preselectedTextRange = range

            if let start = bodyTextView.position(from: range.start, offset: -2),
               let end = bodyTextView.position(from: range.end, offset: 2),
               let newSelectedRange = bodyTextView.textRange(from: start, to: end) {
                bodyTextView.replace(newSelectedRange, withText: bodyTextView.text(in: preselectedTextRange) ?? String())
            }
        }
        dismiss(animated: true)
    }

    func editLink(page: String, label: String?) {
        if let label {
            bodyTextView.replace(preselectedTextRange, withText: "\(page)|\(label)")
        } else {
            bodyTextView.replace(preselectedTextRange, withText: "\(page)")
        }
    }

}
