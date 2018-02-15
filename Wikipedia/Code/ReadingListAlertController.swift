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
        let title = WMFLocalizedString("unsave-article-and-remove-from-reading-lists-title", value: "Unsave article?", comment: "Title of the alert action that unsaves a selected article and removes it from all reading lists")
        let message: String
        if article.userCreatedReadingListsCount == 1, let name = article.userCreatedReadingLists.first?.name {
            message = String.localizedStringWithFormat(WMFLocalizedString("unsave-article-and-remove-from-reading-list-with-name-message", value: "Unsaving this article will also remove it from the reading list “%1$@”.", comment: "Message of the alert action that unsaves a selected article and removes it from all reading lists"), name)
        } else {
            message = WMFLocalizedString("unsave-article-and-remove-from-reading-lists-message", value: "Unsaving this article will remove it from all reading lists.", comment: "Message of the alert action that unsaves a selected article and removes it from all reading lists")
        }
        
        let unsave = ReadingListAlertActionType.unsave.action {
            self.delegate?.readingListAlertController(self, didSelectUnsaveForArticle: article)
        }
        presenter.present(alert(with: title, message: message, actions: [ReadingListAlertActionType.cancel.action(), unsave]), animated: true)
    }
    
    func showAlert(presenter: UIViewController, readingLists: [ReadingList], actions: [UIAlertAction], completion: (() -> Void)? = nil) {
        let readingListsCount = readingLists.count
        let title = String.localizedStringWithFormat(WMFLocalizedString("delete-reading-list-alert-title", value: "Delete {{PLURAL:%1$d|list|lists}}?", comment: "Title of the alert shown before deleting selected reading lists."), readingListsCount)
        let message = String.localizedStringWithFormat(WMFLocalizedString("delete-reading-list-alert-message", value: "Any articles saved only to {{PLURAL:%1$d|this list will be unsaved when this list is deleted|these lists will be unsaved when these lists are deleted}}.", comment: "Title of the altert shown before deleting selected reading lists."), readingListsCount)
        presenter.present(alert(with: title, message: message, actions: actions), animated: true, completion: completion)
    }
    
    func showAlert(presenter: UIViewController, articles: [WMFArticle], actions: [UIAlertAction], completion: (() -> Void)? = nil) {
        let title = String.localizedStringWithFormat(WMFLocalizedString("saved-confirm-unsave-article-and-remove-from-reading-lists", value: "Are you sure you want to unsave {{PLURAL:%1$d|this articles and remove it|these articles and remove them}} from all reading lists?", comment: "Confirmation prompt for action that unsaves a selected article and removes it from all reading lists"), articles.count)
        presenter.present(alert(with: title, message: nil, actions: actions), animated: true, completion: completion)
    }
    
    private func alert(with title: String, message: String?, actions: [UIAlertAction]) -> UIAlertController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        actions.forEach { alert.addAction($0) }
        return alert
    }
}
