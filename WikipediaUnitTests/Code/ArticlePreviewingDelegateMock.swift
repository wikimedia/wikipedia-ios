import UIKit
import WMFData
@testable import Wikipedia

class ArticlePreviewingDelegateMock: UIViewController, ArticlePreviewingDelegate {
    var didReadMore = false
    var didOpenInNewTab = false
    var saveResult: Bool?
    var savedArticleURL: URL?
    var didShare = false
    var shareActivityController: UIActivityViewController?
    var didViewOnMap = false

    func readMoreArticlePreviewActionSelected(with peekController: ArticlePeekPreviewViewController) {
        didReadMore = true
    }

    func saveArticlePreviewActionSelected(with peekController: ArticlePeekPreviewViewController, didSave: Bool, articleURL: URL) {
        saveResult = didSave
        savedArticleURL = articleURL
    }

    func shareArticlePreviewActionSelected(with peekController: ArticlePeekPreviewViewController, shareActivityController: UIActivityViewController) {
        didShare = true
        self.shareActivityController = shareActivityController
    }

    func viewOnMapArticlePreviewActionSelected(with peekController: ArticlePeekPreviewViewController) {
        didViewOnMap = true
    }

    func openInNewTabArticlePreviewActionSelected(with peekController: ArticlePeekPreviewViewController) {
        didOpenInNewTab = true
    }
}
