import Foundation

protocol InternalLinkPreviewing: ViewController { }

extension InternalLinkPreviewing {
    func showInternalLink(url: URL) {
        let exists: Bool
        if let query = url.query {
            exists = !query.contains("redlink=1")
        } else {
            exists = true
        }
        if !exists {
            showRedLinkInAlert()
            return
        }
        let dataStore = MWKDataStore.shared()
        let internalLinkViewController = EditPreviewInternalLinkViewController(articleURL: url, dataStore: dataStore)
        internalLinkViewController.modalPresentationStyle = .overCurrentContext
        internalLinkViewController.modalTransitionStyle = .crossDissolve
        internalLinkViewController.apply(theme: theme)
        present(internalLinkViewController, animated: true, completion: nil)
    }

    func showRedLinkInAlert() {
        let title = WMFLocalizedString("wikitext-preview-link-not-found-preview-title", value: "No internal link found", comment: "Title for nonexistent link preview popup")
        let message = WMFLocalizedString("wikitext-preview-link-not-found-preview-description", value: "Wikipedia does not have an article with this exact name", comment: "Description for nonexistent link preview popup")
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: CommonStrings.okTitle, style: .default))
        present(alertController, animated: true)
    }
}
