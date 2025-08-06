import Foundation

extension ArticleViewController: ArticlePreviewingDelegate {
    @objc func readMoreArticlePreviewActionSelected(with peekController: ArticlePeekPreviewViewController) {
        guard let navVC = navigationController else { return }
        let articleCoordinator = ArticleCoordinator(navigationController: navVC, articleURL: peekController.articleURL, dataStore: dataStore, theme: theme, source: .undefined, previousPageViewObjectID: pageViewObjectID)
        articleCoordinator.start()
    }
    
    @objc func saveArticlePreviewActionSelected(with peekController: ArticlePeekPreviewViewController, didSave: Bool, articleURL: URL) {
        
        if didSave {
            ReadingListsFunnel.shared.logSave(category: eventLoggingCategory, label: eventLoggingLabel, articleURL: articleURL)
        } else {
            ReadingListsFunnel.shared.logUnsave(category: eventLoggingCategory, label: eventLoggingLabel, articleURL: articleURL)
        }
    }
    
    @objc func shareArticlePreviewActionSelected(with peekController: ArticlePeekPreviewViewController, shareActivityController: UIActivityViewController) {
        if let popover = shareActivityController.popoverPresentationController {
            popover.sourceView = peekController.view
            popover.sourceRect = peekController.view.bounds
        }
        present(shareActivityController, animated: true, completion: nil)
    }

    @objc func viewOnMapArticlePreviewActionSelected(with peekController: ArticlePeekPreviewViewController) {
        let placesURL = NSUserActivity.wmf_URLForActivity(of: .places, withArticleURL: peekController.articleURL)
        UIApplication.shared.open(placesURL, options: [:], completionHandler: nil)
    }
    
    func openInNewTabArticlePreviewActionSelected(with peekController: ArticlePeekPreviewViewController) {        
        guard let navVC = navigationController else { return }
        let articleCoordinator = ArticleCoordinator(navigationController: navVC, articleURL: peekController.articleURL, dataStore: dataStore, theme: theme, source: .undefined, previousPageViewObjectID: pageViewObjectID, tabConfig: .appendArticleAndAssignNewTabAndSetToCurrent)
        articleCoordinator.start()
    }
}
