import Foundation

extension ArticleViewController: ArticlePreviewingDelegate {
    @objc func readMoreArticlePreviewActionSelected(with articleController: ArticleViewController) {
        articleController.wmf_removePeekableChildViewControllers()
        push(articleController, animated: true)
    }
    
    @objc func saveArticlePreviewActionSelected(with articleController: ArticleViewController, didSave: Bool, articleURL: URL) {
        
        if didSave {
            ReadingListsFunnel.shared.logSave(category: eventLoggingCategory, label: eventLoggingLabel, articleURL: articleURL)
        } else {
            ReadingListsFunnel.shared.logUnsave(category: eventLoggingCategory, label: eventLoggingLabel, articleURL: articleURL)
        }
    }
    
    @objc func shareArticlePreviewActionSelected(with articleController: ArticleViewController, shareActivityController: UIActivityViewController) {
        articleController.wmf_removePeekableChildViewControllers()
        present(shareActivityController, animated: true, completion: nil)
    }
    
    @objc func viewOnMapArticlePreviewActionSelected(with articleController: ArticleViewController) {
        articleController.wmf_removePeekableChildViewControllers()
        let placesURL = NSUserActivity.wmf_URLForActivity(of: .places, withArticleURL: articleController.articleURL)
        UIApplication.shared.open(placesURL, options: [:], completionHandler: nil)
    }
}
