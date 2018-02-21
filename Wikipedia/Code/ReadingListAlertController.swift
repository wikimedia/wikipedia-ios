@objc public protocol WMFReadingListAlertControllerDelegate: NSObjectProtocol {
    func readingListAlertController(_ readingListAlertController: ReadingListAlertController, didSelectUnsaveForArticle: WMFArticle)
}

public enum ReadingListAlertActionType {
    case delete, unsave, cancel
    
    public func action(with handler: (() -> Void)? = nil) -> UIAlertAction {
        let title: String
        let style: UIAlertActionStyle
        switch self {
        case .delete:
            title = CommonStrings.deleteActionTitle
            style = .destructive
        case .unsave:
            title = CommonStrings.shortUnsaveTitle
            style = .destructive
        case .cancel:
            title = CommonStrings.cancelActionTitle
            style = .cancel
        }
        return UIAlertAction(title: title, style: style) { (_) in
            handler?()
        }
    }
}

@objc (WMFReadingListAlertController)
public class ReadingListAlertController: NSObject {
    @objc public weak var delegate: WMFReadingListAlertControllerDelegate?
    
    @objc func showAlert(presenter: UIViewController & WMFReadingListAlertControllerDelegate, article: WMFArticle) {
        delegate = presenter
        let unsave = ReadingListAlertActionType.unsave.action {
            self.delegate?.readingListAlertController(self, didSelectUnsaveForArticle: article)
        }
        let title = CommonStrings.unsaveArticleAndRemoveFromListsTitle(articleCount: 1)
        let message = CommonStrings.unsaveArticleAndRemoveFromListsMessage(articleCount: 1)
        presenter.present(alert(with: title, message: message, actions: [ReadingListAlertActionType.cancel.action(), unsave]), animated: true)
    }
    
    func showAlert(presenter: UIViewController, readingLists: [ReadingList], actions: [UIAlertAction], completion: (() -> Void)? = nil) {
        let readingListsCount = readingLists.count
        let title = String.localizedStringWithFormat(WMFLocalizedString("reading-lists-delete-reading-list-alert-title", value: "Delete {{PLURAL:%1$d|list|lists}}?", comment: "Title of the alert shown before deleting selected reading lists."), readingListsCount)
        let message = WMFLocalizedString("reading-lists-delete-reading-list-alert-message", value: "This action cannot be undone. Saved articles will remain in your All articles tab", comment: "Title of the altert shown before deleting selected reading lists.")
        presenter.present(alert(with: title, message: message, actions: actions), animated: true, completion: completion)
    }
    
    func showAlert(presenter: UIViewController, articles: [WMFArticle], actions: [UIAlertAction], completion: (() -> Void)? = nil) {
        let title = CommonStrings.unsaveArticleAndRemoveFromListsTitle(articleCount: articles.count)
        let message = CommonStrings.unsaveArticleAndRemoveFromListsMessage(articleCount: articles.count)
        presenter.present(alert(with: title, message: message, actions: actions), animated: true, completion: completion)
    }
    
    private func alert(with title: String, message: String?, actions: [UIAlertAction]) -> UIAlertController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        actions.forEach { alert.addAction($0) }
        return alert
    }
}
