import UIKit
import WMF

class SavedArticlesCollectionViewController: ReadingListEntryCollectionViewController {
    
    // This is not a convenience initalizer because this allows us to not inherit
    // the super class initializer, so clients can't pass any arbitrary reading list to this
    // class
    
    init?(with dataStore: MWKDataStore) {
        guard let readingList = dataStore.viewContext.defaultReadingList else {
            return nil
        }
        
        super.init(for: readingList, with: dataStore)
        emptyViewType = .noSavedPages
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var availableBatchEditToolbarActions: [BatchEditToolbarAction] {
        return [
            BatchEditToolbarActionType.addToList.action(with: nil),
            BatchEditToolbarActionType.unsave.action(with: nil)
        ]
    }
    
    override var shouldShowEditButtonsForEmptyState: Bool {
        return false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NSUserActivity.wmf_makeActive(NSUserActivity.wmf_savedPagesView())
        if !isEmpty {
            self.wmf_showLoginToSyncSavedArticlesToReadingListPanelOncePerDevice(theme: theme)
        }
    }
    
    override func shouldDelete(_ articles: [WMFArticle], completion: @escaping (Bool) -> Void) {
        let alertController = ReadingListsAlertController()
        let unsave = ReadingListsAlertActionType.unsave.action {
            completion(true)
        }
        let cancel = ReadingListsAlertActionType.cancel.action {
            completion(false)
        }
        alertController.showAlertIfNeeded(presenter: self, for: articles, with: [cancel, unsave]) { showed in
            if !showed {
                completion(true)
            }
        }
    }
    
    override func delete(_ articles: [WMFArticle]) {
        dataStore.readingListsController.unsave(articles, in: dataStore.viewContext)
        let articlesCount = articles.count
        UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: CommonStrings.articleDeletedNotification(articleCount: articlesCount))
        let language = articles.count == 1 ? articles.first?.url?.wmf_languageCode : nil
        ReadingListsFunnel.shared.logUnsaveInReadingList(articlesCount: articlesCount, language: language)
    }
    
    override func configure(cell: SavedArticlesCollectionViewCell, for entry: ReadingListEntry, at indexPath: IndexPath, layoutOnly: Bool) {
        super.configure(cell: cell, for: entry, at: indexPath, layoutOnly: layoutOnly)
        cell.delegate = self
    }
}

// MARK: - SavedArticlesCollectionViewCellDelegate

extension SavedArticlesCollectionViewController: SavedArticlesCollectionViewCellDelegate {
    func didSelect(_ tag: Tag) {
        guard let article = article(at: tag.indexPath) else {
            return
        }
        let viewController = tag.isLast ? ReadingListsViewController(with: dataStore, readingLists: article.sortedNonDefaultReadingLists) : ReadingListDetailViewController(for: tag.readingList, with: dataStore)
        viewController.apply(theme: theme)
        push(viewController, animated: true)
    }
}
