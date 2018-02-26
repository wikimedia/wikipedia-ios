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
    
    func showAlert(presenter: UIViewController, items: [Any], actions: [UIAlertAction], completion: (() -> Void)? = nil, failure: (() -> Void)? = nil) {
        let itemsCount = items.count
        var title: String?
        var message: String?
        if let articles = items as? [WMFArticle], articles.filter ({ $0.isOnlyInDefaultList }).count != articles.count {
            title = CommonStrings.unsaveArticleAndRemoveFromListsTitle(articleCount: itemsCount)
            message = CommonStrings.unsaveArticleAndRemoveFromListsMessage(articleCount: itemsCount)
        } else if let readingLists = items as? [ReadingList], Int(readingLists.flatMap({ $0.countOfEntries }).reduce(0, +)) > 0 {
            title = String.localizedStringWithFormat(WMFLocalizedString("reading-lists-delete-reading-list-alert-title", value: "Delete {{PLURAL:%1$d|list|lists}}?", comment: "Title of the alert shown before deleting selected reading lists."), itemsCount)
            message =  String.localizedStringWithFormat(WMFLocalizedString("reading-lists-delete-reading-list-alert-message", value: "This action cannot be undone. Any articles saved only to {{PLURAL:%1$d|this list|these lists}} will be unsaved.", comment: "Title of the altert shown before deleting selected reading lists."), itemsCount)
        } else {
            failure?()
            return
        }
        if let title = title {
            presenter.present(alert(with: title, message: message, actions: actions), animated: true, completion: completion)
        }
    }
    
    private func alert(with title: String, message: String?, actions: [UIAlertAction]) -> UIAlertController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        actions.forEach { alert.addAction($0) }
        return alert
    }
}
