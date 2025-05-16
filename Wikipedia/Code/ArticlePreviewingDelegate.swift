import Foundation

@objc protocol ArticlePreviewingDelegate: AnyObject {
    func readMoreArticlePreviewActionSelected(with peekController: ArticlePeekPreviewViewController)
    func saveArticlePreviewActionSelected(with peekController: ArticlePeekPreviewViewController, didSave: Bool, articleURL: URL)
    func shareArticlePreviewActionSelected(with peekController: ArticlePeekPreviewViewController, shareActivityController: UIActivityViewController)
    func viewOnMapArticlePreviewActionSelected(with peekController: ArticlePeekPreviewViewController)
    func openInNewTabArticlePreviewActionSelected(with peekController: ArticlePeekPreviewViewController)
}
