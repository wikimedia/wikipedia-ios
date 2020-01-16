import Foundation

protocol ArticlePreviewingDelegate {
    func readMoreArticlePreviewActionSelected(with articleController: ArticleContainerViewController)
    func saveArticlePreviewActionSelected(with articleController: ArticleContainerViewController, didSave: Bool, articleURL: URL)
    func shareArticlePreviewActionSelected(with articleController: ArticleContainerViewController, shareActivityController: UIActivityViewController)
    func viewOnMapArticlePreviewActionSelected(with articleController: ArticleContainerViewController)
}
