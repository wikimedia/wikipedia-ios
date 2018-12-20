class ReadingListArticlesCollectionViewController: ArticlesCollectionViewController<ReadingListEntry> {
    
    override func article(at indexPath: IndexPath) -> WMFArticle {
        guard let fetchedResultsController = fetchedResultsController else {
            fatalError("Could not find fetched result controller")
        }
        
        let entry = fetchedResultsController.object(at: indexPath)
        
        guard let article = entry.articleKey.flatMap(dataStore.fetchArticle(withKey:)) else {
            fatalError("Could not fetch corresponding article for entry")
        }
        return article
    }
    
    override var basePredicate: NSPredicate {
        return NSPredicate(format: "list == %@ && isDeletedLocally != YES", readingList)
    }
    
    override var searchPredicate: NSPredicate? {
        guard let searchString = searchString else {
            return nil
        }
        return NSPredicate(format: "(displayTitle CONTAINS[cd] '\(searchString)')")
    }
    
    override var availableBatchEditToolbarActions: [BatchEditToolbarAction] {
        return [
            BatchEditToolbarActionType.addTo.action(with: nil),
            BatchEditToolbarActionType.moveTo.action(with: nil),
            BatchEditToolbarActionType.remove.action(with: nil)
        ]
    }
    
    //work around since we can't override with lazy properties
    lazy var lazySortActions: [SortActionType : SortAction] = {
        let moc = dataStore.viewContext
        let updateSortOrder: (Int) -> Void = { (rawValue: Int) in
            self.readingList.sortOrder = NSNumber(value: rawValue)
            if moc.hasChanges {
                do {
                    try moc.save()
                } catch let error {
                    DDLogError("Error updating sort order: \(error)")
                }
            }
        }
        
        let handler: ([NSSortDescriptor], UIAlertAction, Int) -> Void = { (sortDescriptors: [NSSortDescriptor], alertAction: UIAlertAction, rawValue: Int) in
            updateSortOrder(rawValue)
            self.reset()
        }
        
        let titleSortAction = SortActionType.byTitle.action(with: [NSSortDescriptor(keyPath: \ReadingListEntry.displayTitle, ascending: true)], handler: handler)
        let recentlyAddedSortAction = SortActionType.byRecentlyAdded.action(with: [NSSortDescriptor(keyPath: \ReadingListEntry.createdDate, ascending: false)], handler: handler)
        
        return [titleSortAction.type: titleSortAction, recentlyAddedSortAction.type: recentlyAddedSortAction]
    }()
    
    override var sortActions: [SortActionType : SortAction] {
        return lazySortActions
    }
    
    override func shouldDelete(_ articles: [WMFArticle], completion: @escaping (Bool) -> Void) {
        completion(true)
    }
    
    override func delete(_ articles: [WMFArticle]) {
        let url: URL? = articles.first?.url
        let articlesCount = articles.count
        do {
            try dataStore.readingListsController.remove(articles: articles, readingList: readingList)
            UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: CommonStrings.articleDeletedNotification(articleCount: articlesCount))
        } catch let error {
            DDLogError("Error removing entries from a reading list: \(error)")
        }
        guard let articleURL = url, dataStore.savedPageList.entry(for: articleURL) == nil else {
            return
        }
        ReadingListsFunnel.shared.logUnsaveInReadingList(articlesCount: articlesCount, language: articleURL.wmf_language)
    }
    
    override func configure(cell: SavedArticlesCollectionViewCell, for article: WMFArticle, at indexPath: IndexPath, layoutOnly: Bool) {
        cell.isBatchEditing = editController.isBatchEditing
        
        guard let entry = readingList.entry(for: article) else {
            return
        }
        
        cell.configureAlert(for: entry, with: article, in: readingList, listLimit: dataStore.viewContext.wmf_readingListsConfigMaxListsPerUser, entryLimit: dataStore.viewContext.wmf_readingListsConfigMaxEntriesPerList.intValue)
        cell.configure(article: article, index: indexPath.item, shouldShowSeparators: true, theme: theme, layoutOnly: layoutOnly)
        
        cell.isBatchEditable = true
        cell.layoutMargins = layout.itemLayoutMargins
        editController.configureSwipeableCell(cell, forItemAt: indexPath, layoutOnly: layoutOnly)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        emptyViewType = .noSavedPagesInReadingList
    }
    
    override func viewWillHaveFirstAppearance(_ animated: Bool) {
        super.viewWillHaveFirstAppearance(animated)
        navigationBar.isExtendedViewHidingEnabled = true
    }
}
