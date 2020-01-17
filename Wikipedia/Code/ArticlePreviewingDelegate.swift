import Foundation

protocol ArticlePreviewingDelegate {
    func readMoreArticlePreviewActionSelected(with articleController: ArticleViewController)
    func saveArticlePreviewActionSelected(with articleController: ArticleViewController, didSave: Bool, articleURL: URL)
    func shareArticlePreviewActionSelected(with articleController: ArticleViewController, shareActivityController: UIActivityViewController)
    func viewOnMapArticlePreviewActionSelected(with articleController: ArticleViewController)
}
