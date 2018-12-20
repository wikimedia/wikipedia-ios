import UIKit

class SavedArticlesCollectionViewController: ArticlesCollectionViewController<WMFArticle> {
    convenience init(with dataStore: MWKDataStore) {
        func fetchDefaultReadingListWithSortOrder() -> ReadingList {
            let fetchRequest: NSFetchRequest<ReadingList> = ReadingList.fetchRequest()
            fetchRequest.fetchLimit = 1
            fetchRequest.propertiesToFetch = ["sortOrder"]
            fetchRequest.predicate = NSPredicate(format: "isDefault == YES")
            
            guard let readingLists = try? dataStore.viewContext.fetch(fetchRequest),
                let defaultReadingList = readingLists.first else {
                    assertionFailure("Failed to fetch default reading list with sort order")
                    fatalError()
            }
            return defaultReadingList
        }
        let readingList = fetchDefaultReadingListWithSortOrder()
        self.init(for: readingList, with: dataStore)
    }
    
    override func article(at indexPath: IndexPath) -> WMFArticle {
        guard let fetchedResultsController = fetchedResultsController else {
            fatalError("Could not find fetched result controller")
        }
        return fetchedResultsController.object(at: indexPath)
    }
    
    override var basePredicate: NSPredicate {
        return NSPredicate(format: "savedDate != NULL")
    }
    
    override var availableBatchEditToolbarActions: [BatchEditToolbarAction] {
        return [
            BatchEditToolbarActionType.addToList.action(with: nil),
            BatchEditToolbarActionType.unsave.action(with: nil)
        ]
    }
    
    // workaround since we can't override with lazy properties
    lazy var lazySortActions: [SortActionType : SortAction] = {
        let moc = dataStore.viewContext
        
        let handler: ([NSSortDescriptor], UIAlertAction, Int) -> Void = { (sortDescriptors: [NSSortDescriptor], alertAction: UIAlertAction, rawValue: Int) in
            self.readingList.sortOrder = NSNumber(value: rawValue)
            if moc.hasChanges {
                do {
                    try moc.save()
                } catch let error {
                    DDLogError("Error updating sort order: \(error)")
                }
            }
            self.reset()
        }
        
        let title = SortActionType.byTitle.action(with: [NSSortDescriptor(keyPath: \WMFArticle.displayTitle, ascending: true)], handler: handler)
        let recentlyAdded = SortActionType.byRecentlyAdded.action(with: [NSSortDescriptor(keyPath: \WMFArticle.savedDate, ascending: false)], handler: handler)
        return [title.type: title, recentlyAdded.type: recentlyAdded]
    }()
    
    override var sortActions: [SortActionType : SortAction] {
        return lazySortActions
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
        let language = articles.count == 1 ? articles.first?.url?.wmf_language : nil
        ReadingListsFunnel.shared.logUnsaveInReadingList(articlesCount: articlesCount, language: language)
    }
    
    override func configure(cell: SavedArticlesCollectionViewCell, for article: WMFArticle, at indexPath: IndexPath, layoutOnly: Bool) {
        cell.isBatchEditing = editController.isBatchEditing
        
        cell.tags = (readingLists: readingLists(for: article), indexPath: indexPath)
        cell.configure(article: article, index: indexPath.item, shouldShowSeparators: true, theme: theme, layoutOnly: layoutOnly)
        cell.isBatchEditable = true
        cell.layoutMargins = layout.itemLayoutMargins
        editController.configureSwipeableCell(cell, forItemAt: indexPath, layoutOnly: layoutOnly)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        emptyViewType = .noSavedPages
    }
}
