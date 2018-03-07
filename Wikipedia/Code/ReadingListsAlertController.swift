@objc public protocol WMFReadingListAlertControllerDelegate: NSObjectProtocol {
    func readingListsAlertController(_ readingListsAlertController: ReadingListsAlertController, didSelectUnsaveForArticle: WMFArticle)
}

@objc(WMFReadingListsAlertPresenter)
public protocol ReadingListsAlertPresenter: NSObjectProtocol {
    @objc var readingListsAlertController: ReadingListsAlertController { get }
    @objc func entriesLimitReached(notification: Notification)
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
    public var isPresenting: Bool = false
    
    // MARK: UIAlertController presentation
    
    /// Presents a UIAlertController for a single article. If the user attemps to unsave an article added to multiple lists, they will be 1) warned that unsaving the article will remove it from all associated reading lists, 2) given options to cancel or unsave
    ///
    /// - Parameters:
    ///   - presenter: UIViewController that presents the alert
    ///   - article: article being unsaved
    @objc func showAlert(presenter: UIViewController & WMFReadingListAlertControllerDelegate, article: WMFArticle) {
        delegate = presenter
        let unsave = ReadingListsAlertActionType.unsave.action {
            self.delegate?.readingListsAlertController(self, didSelectUnsaveForArticle: article)
        }
        let title = CommonStrings.unsaveArticleAndRemoveFromListsTitle(articleCount: 1)
        let message = CommonStrings.unsaveArticleAndRemoveFromListsMessage(articleCount: 1)
        presenter.present(alert(with: title, message: message, actions: [ReadingListsAlertActionType.cancel.action(), unsave]), animated: true)
    }
    
    
    /// Presents a UIAlertController for multiple articles. If the user attemps to unsave articles added to multiple lists, they will be 1) warned that unsaving selected articles will remove them from all associated reading lists, 2) given action options
    ///
    /// - Parameters:
    ///   - presenter: UIViewController that presents the alert
    ///   - articles: articles being unsaved
    ///   - actions: actions that will be attached to the alert
    ///   - completion: closure that will be performed on presentation completion
    ///   - failure: closure that will be performed if the alert is not supposed to be presented to the user
    /// - Returns: bool to indicate whether the alert was presented
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
    
    
    /// Presents a UIAlertController for multiple reading lists. If the user attemps to unsave reading lists, they will be 1) warned that deleting selected reading lists will unsave articles saved to those lists, 2) given action options
    ///
    /// - Parameters:
    ///   - presenter: UIViewController that presents the alert
    ///   - articles: reading lists being deleted
    ///   - actions: actions that will be attached to the alert
    ///   - completion: closure that will be performed on presentation completion
    ///   - failure: closure that will be performed if the alert is not supposed to be presented to the user
    /// - Returns: bool to indicate whether the alert was presented
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
    
    
    /// Creates a UIAlertController with provided parameters
    ///
    /// - Parameters:
    ///   - title: title of the alert
    ///   - message: message in the alert
    ///   - actions: actions that will be attached to the alert
    /// - Returns: UIAlertController
    private func alert(with title: String, message: String?, actions: [UIAlertAction]) -> UIAlertController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        actions.forEach { alert.addAction($0) }
        return alert
    }
    
    // MARK: - ScrollableEducationPanelViewController presentation
    
    @objc func showLimitHitForDefaultListPanelIfNecessary(presenter: UIViewController, dataStore: MWKDataStore, readingList: ReadingList, theme: Theme) {
        guard Thread.isMainThread, dataStore.readingListsController.isSyncEnabled else {
            return
        }
        guard readingList.isDefault else {
            return
        }
        guard !isPresenting else {
            assertionFailure("Attempted to present LimitHitForDefaultListPanel while presenting other view")
            return
        }
        isPresenting = true
        let primaryButtonHandler: ScrollableEducationPanelButtonTapHandler = { _ in
            presenter.presentedViewController?.dismiss(animated: true)
            let readingListDetailViewController = ReadingListDetailViewController(for: readingList, with: dataStore, displayType: .modal)
            readingListDetailViewController.apply(theme: theme)
            let navigationController = WMFThemeableNavigationController(rootViewController: readingListDetailViewController, theme: theme)
            presenter.present(navigationController, animated: true)
        }
        presenter.wmf_showLimitHitForUnsortedArticlesPanelViewController(theme: theme, primaryButtonTapHandler: primaryButtonHandler) {
            UserDefaults.wmf_userDefaults().wmf_setDidShowLimitHitForUnsortedArticlesPanel(true)
            self.isPresenting = false
        }
    }
}
