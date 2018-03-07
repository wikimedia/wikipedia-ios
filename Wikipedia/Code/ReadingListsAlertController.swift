@objc public protocol WMFReadingListAlertControllerDelegate: NSObjectProtocol {
    func readingListsAlertController(_ readingListsAlertController: ReadingListsAlertController, didSelectUnsaveForArticle: WMFArticle)
}

public enum ReadingListsAlertActionType {
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

@objc (WMFReadingListsAlertController)
public class ReadingListsAlertController: NSObject {
    @objc public weak var delegate: WMFReadingListAlertControllerDelegate?
    
    // MARK: UIAlertController presentation
    
    @objc func showAlert(presenter: UIViewController & WMFReadingListAlertControllerDelegate, article: WMFArticle) {
        delegate = presenter
        let unsave = ReadingListsAlertActionType.unsave.action {
            self.delegate?.readingListsAlertController(self, didSelectUnsaveForArticle: article)
        }
        let title = CommonStrings.unsaveArticleAndRemoveFromListsTitle(articleCount: 1)
        let message = CommonStrings.unsaveArticleAndRemoveFromListsMessage(articleCount: 1)
        presenter.present(alert(with: title, message: message, actions: [ReadingListsAlertActionType.cancel.action(), unsave]), animated: true)
    }
    
    func showAlert(presenter: UIViewController, for articles: [WMFArticle], with actions: [UIAlertAction], completion: (() -> Void)? = nil, failure: () -> Bool) -> Bool {
        let articlesCount = articles.count
        guard articles.filter ({ $0.isOnlyInDefaultList }).count != articlesCount else {
            return failure()
        }
        let title = CommonStrings.unsaveArticleAndRemoveFromListsTitle(articleCount: articlesCount)
        let message = CommonStrings.unsaveArticleAndRemoveFromListsMessage(articleCount: articlesCount)
        presenter.present(alert(with: title, message: message, actions: actions), animated: true, completion: completion)
        return true
    }
    
    func showAlert(presenter: UIViewController, for readingLists: [ReadingList], with actions: [UIAlertAction], completion: (() -> Void)? = nil, failure: () -> Bool) -> Bool {
        let readingListsCount = readingLists.count
        guard Int(readingLists.flatMap({ $0.countOfEntries }).reduce(0, +)) > 0 else {
            return failure()
        }
        let title = String.localizedStringWithFormat(WMFLocalizedString("reading-lists-delete-reading-list-alert-title", value: "Delete {{PLURAL:%1$d|list|lists}}?", comment: "Title of the alert shown before deleting selected reading lists."), readingListsCount)
        let message =  String.localizedStringWithFormat(WMFLocalizedString("reading-lists-delete-reading-list-alert-message", value: "This action cannot be undone. Any articles saved only to {{PLURAL:%1$d|this list|these lists}} will be unsaved.", comment: "Title of the altert shown before deleting selected reading lists."), readingListsCount)
        presenter.present(alert(with: title, message: message, actions: actions), animated: true, completion: completion)
        return true
    }
    
    private func alert(with title: String, message: String?, actions: [UIAlertAction]) -> UIAlertController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        actions.forEach { alert.addAction($0) }
        return alert
    }
}
