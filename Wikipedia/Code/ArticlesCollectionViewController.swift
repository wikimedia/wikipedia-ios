import UIKit

protocol ArticlesCollectionViewControllerDelegate: NSObjectProtocol {
    func articlesCollectionViewController(_ viewController: ArticlesCollectionViewController, didUpdate collectionView: UICollectionView)
    func articlesCollectionViewControllerDidChangeEmptyState(_ viewController: ArticlesCollectionViewController)
}

class ArticlesCollectionViewController: ColumnarCollectionViewController, EditableCollection, UpdatableCollection, SearchableCollection, ArticleURLProvider, ActionDelegate, EventLoggingEventValuesProviding {
    let dataStore: MWKDataStore
    var fetchedResultsController: NSFetchedResultsController<ReadingListEntry>?
    var collectionViewUpdater: CollectionViewUpdater<ReadingListEntry>?
    let readingList: ReadingList
    
    var searchString: String?
    
    var basePredicate: NSPredicate {
        return NSPredicate(format: "list == %@ && isDeletedLocally != YES", readingList)
    }
    
    var shouldShowEditButtonsForEmptyState: Bool {
        return !readingList.isDefault
    }
    
    var searchPredicate: NSPredicate? {
        guard let searchString = searchString else {
            return nil
        }
        return NSPredicate(format: "(displayTitle CONTAINS[cd] '\(searchString)')")
    }
    
    var availableBatchEditToolbarActions: [BatchEditToolbarAction] {
        return [
            BatchEditToolbarActionType.addTo.action(with: nil),
            BatchEditToolbarActionType.moveTo.action(with: nil),
            BatchEditToolbarActionType.remove.action(with: nil)
        ]
    }
    
    var editController: CollectionViewEditController!
    
    private var cellLayoutEstimate: ColumnarCollectionViewLayoutHeightEstimate?
    private let reuseIdentifier = "ArticlesCollectionViewCell"
    
    weak var delegate: ArticlesCollectionViewControllerDelegate?
    
    init(for readingList: ReadingList, with dataStore: MWKDataStore) {
        self.readingList = readingList
        self.dataStore = dataStore
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        layoutManager.register(SavedArticlesCollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier, addPlaceholder: true)
        setupEditController()
        isRefreshControlEnabled = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setupFetchedResultsController()
        setupCollectionViewUpdater()
        fetch()
        super.viewWillAppear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        collectionViewUpdater = nil
        fetchedResultsController = nil
        editController.close()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        cellLayoutEstimate = nil
    }
    
    func configure(cell: SavedArticlesCollectionViewCell, for entry: ReadingListEntry, at indexPath: IndexPath, layoutOnly: Bool) {
        cell.isBatchEditing = editController.isBatchEditing
        
        guard let article = article(for: entry) else {
            return
        }
        
        cell.configureAlert(for: entry, with: article, in: readingList, listLimit: dataStore.viewContext.wmf_readingListsConfigMaxListsPerUser, entryLimit: dataStore.viewContext.wmf_readingListsConfigMaxEntriesPerList.intValue)
        cell.configure(article: article, index: indexPath.item, shouldShowSeparators: true, theme: theme, layoutOnly: layoutOnly)
        
        cell.isBatchEditable = true
        cell.layoutMargins = layout.itemLayoutMargins
        editController.configureSwipeableCell(cell, forItemAt: indexPath, layoutOnly: layoutOnly)
    }
    
    func shouldDelete(_ articles: [WMFArticle], completion: @escaping (Bool) -> Void) {
        completion(true)
    }
    
    func delete(_ articles: [WMFArticle]) {
        let url: URL? = articles.first?.url
        let articlesCount = articles.count
        do {
            try dataStore.readingListsController.remove(articles: articles, readingList: readingList)
            UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: CommonStrings.articleDeletedNotification(articleCount: articlesCount))
        } catch {
            DDLogError("Error removing entries from a reading list: \(error)")
        }
        guard let articleURL = url, dataStore.savedPageList.entry(for: articleURL) == nil else {
            return
        }
        ReadingListsFunnel.shared.logUnsaveInReadingList(articlesCount: articlesCount, language: articleURL.wmf_language)
    }
    
    // MARK: - Empty state
    
    override func isEmptyDidChange() {
        editController.isCollectionViewEmpty = isEmpty
        delegate?.articlesCollectionViewControllerDidChangeEmptyState(self)
        super.isEmptyDidChange()
    }
    
    // MARK: - Refresh
    
    override func refresh() {
        dataStore.readingListsController.fullSync {
            self.endRefreshing()
        }
    }
    
    lazy var sortActions: [SortActionType: SortAction] = {
        let moc = dataStore.viewContext
        let updateSortOrder: (Int) -> Void = { (rawValue: Int) in
            self.readingList.sortOrder = NSNumber(value: rawValue)
            if moc.hasChanges {
                do {
                    try moc.save()
                } catch {
                    DDLogError("Error updating sort order: \(error)")
                }
            }
        }
        
        let handler: ([NSSortDescriptor], UIAlertAction, Int) -> Void = { (_: [NSSortDescriptor], _: UIAlertAction, rawValue: Int) in
            updateSortOrder(rawValue)
            self.reset()
        }
        
        let titleSortAction = SortActionType.byTitle.action(with: [NSSortDescriptor(keyPath: \ReadingListEntry.displayTitle, ascending: true)], handler: handler)
        let recentlyAddedSortAction = SortActionType.byRecentlyAdded.action(with: [NSSortDescriptor(keyPath: \ReadingListEntry.createdDate, ascending: false)], handler: handler)
        
        return [titleSortAction.type: titleSortAction, recentlyAddedSortAction.type: recentlyAddedSortAction]
    }()
    
    lazy var sortAlert: UIAlertController = {
        alert(title: CommonStrings.sortAlertTitle, message: nil)
    }()
    
    func article(at indexPath: IndexPath) -> WMFArticle? {
        guard let fetchedResultsController = fetchedResultsController, fetchedResultsController.isValidIndexPath(indexPath) else {
            return nil
        }
        let entry = fetchedResultsController.object(at: indexPath)
        
        guard let article = entry.articleKey.flatMap(dataStore.fetchArticle(withKey:)) else {
            return nil
        }
        return article
    }
    
    func article(for entry: ReadingListEntry) -> WMFArticle? {
        return entry.articleKey.flatMap(dataStore.fetchArticle(withKey: ))
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        super.scrollViewDidScroll(scrollView)
        editController.transformBatchEditPaneOnScroll()
    }
    
    func articleURL(at indexPath: IndexPath) -> URL? {
        return article(at: indexPath)?.url
    }
    
    func entry(at indexPath: IndexPath) -> ReadingListEntry? {
        guard fetchedResultsController?.isValidIndexPath(indexPath) == true else {
            return nil
        }
        return fetchedResultsController?.object(at: indexPath)
    }
    
    func readingLists(for article: WMFArticle) -> [ReadingList] {
        guard let moc = article.managedObjectContext else {
            return []
        }
        
        let request: NSFetchRequest<ReadingList> = ReadingList.fetchRequest()
        request.predicate = NSPredicate(format: "ANY articles == %@ && isDefault == NO", article)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ReadingList.canonicalName, ascending: true)]
        
        do {
            return try moc.fetch(request)
        } catch {
            DDLogError("Error fetching lists: \(error)")
            return []
        }
    }
    
    // MARK: - ColumnarCollectionViewLayoutDelegate
    
    override func collectionView(_ collectionView: UICollectionView, estimatedHeightForItemAt indexPath: IndexPath, forColumnWidth columnWidth: CGFloat) -> ColumnarCollectionViewLayoutHeightEstimate {
        // The layout estimate can be re-used in this case becuause both labels are one line, meaning the cell
        // size only varies with font size. The layout estimate is nil'd when the font size changes on trait collection change
        if let estimate = cellLayoutEstimate {
            return estimate
        }
        var estimate = ColumnarCollectionViewLayoutHeightEstimate(precalculated: false, height: 60)
        guard let placeholderCell = layoutManager.placeholder(forCellWithReuseIdentifier: reuseIdentifier) as? SavedArticlesCollectionViewCell, let entry = entry(at: indexPath) else {
            return estimate
        }
        configure(cell: placeholderCell, for: entry, at: indexPath, layoutOnly: true)
        estimate.height = placeholderCell.sizeThatFits(CGSize(width: columnWidth, height: UIView.noIntrinsicMetric), apply: false).height
        estimate.precalculated = true
        cellLayoutEstimate = estimate
        return estimate
    }
    
    override func metrics(with size: CGSize, readableWidth: CGFloat, layoutMargins: UIEdgeInsets) -> ColumnarCollectionViewLayoutMetrics {
        return ColumnarCollectionViewLayoutMetrics.tableViewMetrics(with: size, readableWidth: readableWidth, layoutMargins: layoutMargins)
    }
    
    // MARK: - EventLoggingEventValuesProviding
    
    var eventLoggingLabel: EventLoggingLabel? {
        return nil
    }
    
    var eventLoggingCategory: EventLoggingCategory {
        return EventLoggingCategory.saved
    }
}

// MARK: - UICollectionViewDataSource

extension ArticlesCollectionViewController {
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        guard let sectionsCount = fetchedResultsController?.sections?.count else {
            return 0
        }
        return sectionsCount
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let sections = fetchedResultsController?.sections, section < sections.count else {
            return 0
        }
        return sections[section].numberOfObjects
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
        guard let savedArticleCell = cell as? SavedArticlesCollectionViewCell,
            let entry = entry(at: indexPath)
            else {
                return cell
        }
        
        configure(cell: savedArticleCell, for: entry, at: indexPath, layoutOnly: false)
        return cell
    }
}

// MARK: - ActionDelegate

extension ArticlesCollectionViewController {
    func availableActions(at indexPath: IndexPath) -> [Action] {
        var actions: [Action] = []
        
        if articleURL(at: indexPath) != nil {
            actions.append(ActionType.share.action(with: self, indexPath: indexPath))
        }
        
        actions.append(ActionType.delete.action(with: self, indexPath: indexPath))
        
        return actions
    }
    
    private func delete(at indexPath: IndexPath) {
        guard let article = article(at: indexPath) else {
            return
        }
        delete([article])
    }
    
    func willPerformAction(_ action: Action) -> Bool {
        guard let article = article(at: action.indexPath) else {
            return false
        }
        guard action.type == .delete else {
            return editController.didPerformAction(action)
        }
        shouldDelete([article]) { shouldDelete in
            if shouldDelete {
                _ = self.editController.didPerformAction(action)
            }
        }
        return true
    }
    
    func didPerformAction(_ action: Action) -> Bool {
        let indexPath = action.indexPath
        let sourceView = collectionView.cellForItem(at: indexPath)
        switch action.type {
        case .delete:
            delete(at: indexPath)
            return true
        case .share:
            return share(article: article(at: indexPath), articleURL: articleURL(at: indexPath), at: indexPath, dataStore: dataStore, theme: theme, sourceView: sourceView)
        default:
            assertionFailure("Unsupported action type")
            return false
        }
    }
    
    func didPerformBatchEditToolbarAction(_ action: BatchEditToolbarAction, completion: @escaping (Bool) -> Void) {
        guard let selectedIndexPaths = collectionView.indexPathsForSelectedItems else {
            completion(false)
            return
        }
        
        let articles = selectedIndexPaths.compactMap { article(at: $0) }
        
        switch action.type {
        case .addTo:
            let addArticlesToReadingListViewController = AddArticlesToReadingListViewController(with: dataStore, articles: articles, theme: theme)
            let navigationController = WMFThemeableNavigationController(rootViewController: addArticlesToReadingListViewController, theme: theme)
            navigationController.isNavigationBarHidden = true
            addArticlesToReadingListViewController.delegate = self
            present(navigationController, animated: true) {
                completion(true)
            }
        case .unsave:
            shouldDelete(articles) { shouldDelete in
                if shouldDelete {
                    self.delete(articles)
                    completion(true)
                } else {
                    completion(false)
                }
            }
        case .remove:
            delete(articles)
            completion(true)
        case .moveTo:
            let addArticlesToReadingListViewController = AddArticlesToReadingListViewController(with: dataStore, articles: articles, moveFromReadingList: readingList, theme: theme)
            let navigationController = WMFThemeableNavigationController(rootViewController: addArticlesToReadingListViewController, theme: theme)
            navigationController.isNavigationBarHidden = true
            addArticlesToReadingListViewController.delegate = self
            present(navigationController, animated: true) {
                completion(true)
            }
        default:
            completion(false)
        }
    }
}

// MARK: - UIViewControllerPreviewingDelegate

extension ArticlesCollectionViewController {
    override func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard !editController.isActive else {
            return nil // don't allow 3d touch when swipe actions are active
        }
        
        guard
            let indexPath = collectionViewIndexPathForPreviewingContext(previewingContext, location: location),
            let articleURL = articleURL(at: indexPath)
        else {
            return nil
        }
        
        let articleViewController = WMFArticleViewController(articleURL: articleURL, dataStore: dataStore, theme: theme)
        articleViewController.articlePreviewingActionsDelegate = self
        articleViewController.wmf_addPeekableChildViewController(for: articleURL, dataStore: dataStore, theme: theme)
        return articleViewController
    }
    
    override func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        viewControllerToCommit.wmf_removePeekableChildViewControllers()
        wmf_push(viewControllerToCommit, animated: true)
    }
}

// MARK: - UICollectionViewDelegate

extension ArticlesCollectionViewController {
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        editController.deconfigureSwipeableCell(cell, forItemAt: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard editController.isClosed else {
            return
        }
        guard let articleURL = articleURL(at: indexPath) else {
            return
        }
        wmf_pushArticle(with: articleURL, dataStore: dataStore, theme: theme, animated: true)
        ReadingListsFunnel.shared.logReadStartIReadingList(articleURL)
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        _ = editController.isClosed
    }
}

// MARK: - SortableCollection

extension ArticlesCollectionViewController: SortableCollection {
    var sort: (descriptors: [NSSortDescriptor], alertAction: UIAlertAction?) {
        guard let sortOrder = readingList.sortOrder, let sortActionType = SortActionType(rawValue: sortOrder.intValue), let sortAction = sortActions[sortActionType] else {
            return ([], nil)
        }
        return (sortAction.sortDescriptors, sortAction.alertAction)
    }
    
    var defaultSortAction: SortAction? {
        return sortActions[.byRecentlyAdded]
    }
}

// MARK: - CollectionViewUpdaterDelegate

extension ArticlesCollectionViewController: CollectionViewUpdaterDelegate {
    func collectionViewUpdater<T>(_ updater: CollectionViewUpdater<T>, didUpdate collectionView: UICollectionView) {
        for indexPath in collectionView.indexPathsForVisibleItems {
            guard let cell = collectionView.cellForItem(at: indexPath) as? SavedArticlesCollectionViewCell,
                let entry = entry(at: indexPath) else {
                continue
            }
            configure(cell: cell, for: entry, at: indexPath, layoutOnly: false)
        }
        updateEmptyState()
        collectionView.setNeedsLayout()
        delegate?.articlesCollectionViewController(self, didUpdate: collectionView)
    }
    
    func collectionViewUpdater<T: NSFetchRequestResult>(_ updater: CollectionViewUpdater<T>, updateItemAtIndexPath indexPath: IndexPath, in collectionView: UICollectionView) {
        
    }
}

// MARK: - AddArticlesToReadingListViewControllerDelegate

// default implementation for types conforming to EditableCollection defined in AddArticlesToReadingListViewController
extension ArticlesCollectionViewController: AddArticlesToReadingListDelegate {}

extension ArticlesCollectionViewController: ShareableArticlesProvider {}

// MARK: - SavedViewControllerDelegate

extension ArticlesCollectionViewController: SavedViewControllerDelegate {
    func savedWillShowSortAlert(_ saved: SavedViewController, from button: UIButton) {
        presentSortAlert(from: button)
    }
    
    func saved(_ saved: SavedViewController, searchBar: UISearchBar, textDidChange searchText: String) {
        updateSearchString(searchText)
        
        if searchText.isEmpty {
            makeSearchBarResignFirstResponder(searchBar)
        }
    }
    
    func saved(_ saved: SavedViewController, searchBarSearchButtonClicked searchBar: UISearchBar) {
        makeSearchBarResignFirstResponder(searchBar)
    }
    
    func saved(_ saved: SavedViewController, searchBarTextDidBeginEditing searchBar: UISearchBar) {
        navigationBar.isInteractiveHidingEnabled = false
    }
    
    func saved(_ saved: SavedViewController, searchBarTextDidEndEditing searchBar: UISearchBar) {
        makeSearchBarResignFirstResponder(searchBar)
    }
    
    private func makeSearchBarResignFirstResponder(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        navigationBar.isInteractiveHidingEnabled = true
    }
}



