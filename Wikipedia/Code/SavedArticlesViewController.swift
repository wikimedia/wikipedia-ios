class SavedArticlesViewController: ColumnarCollectionViewController, EditableCollection, SearchableCollection, SortableCollection {
    
    private let reuseIdentifier = "SavedArticlesCollectionViewCell"
    private var cellLayoutEstimate: ColumnarCollectionViewLayoutHeightEstimate?

    typealias T = WMFArticle
    let dataStore: MWKDataStore
    var fetchedResultsController: NSFetchedResultsController<WMFArticle>?
    var collectionViewUpdater: CollectionViewUpdater<WMFArticle>?
    var editController: CollectionViewEditController!
    
    var basePredicate: NSPredicate {
        return NSPredicate(format: "savedDate != NULL")
    }
    
    var searchPredicate: NSPredicate? {
        guard let searchString = searchString else {
            return nil
        }
        return NSPredicate(format: "(displayTitle CONTAINS[cd] '\(searchString)') OR (snippet CONTAINS[cd] '\(searchString)')")
    }
    
    init(with dataStore: MWKDataStore) {
        self.dataStore = dataStore
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not supported")
    }
    
    // MARK - View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        layoutManager.register(SavedArticlesCollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier, addPlaceholder: true)
        setupEditController()
        isRefreshControlEnabled = true
        emptyViewType = .noSavedPages
    }
    
    override func refresh() {
        dataStore.readingListsController.fullSync {
            self.endRefreshing()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // setup FRC before calling super so that the data is available before the superclass checks for the empty state
        setupFetchedResultsController()
        setupCollectionViewUpdater()
        fetch()
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NSUserActivity.wmf_makeActive(NSUserActivity.wmf_savedPagesView())
        if !isEmpty {
            self.wmf_showLoginToSyncSavedArticlesToReadingListPanelOncePerDevice(theme: theme)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        editController.close()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        collectionViewUpdater = nil
        fetchedResultsController = nil
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        cellLayoutEstimate = nil
    }
    
    // MARK: - Empty state
    
    override func isEmptyDidChange() {
        editController.isCollectionViewEmpty = isEmpty
        super.isEmptyDidChange()
    }
    
    // MARK: - Sorting
    
    var sort: (descriptors: [NSSortDescriptor], alertAction: UIAlertAction?) = (descriptors: [NSSortDescriptor(keyPath: \WMFArticle.savedDate, ascending: false)], alertAction: nil)
    
    var defaultSortAction: SortAction? {
        return sortActions[.byRecentlyAdded]
    }

    lazy var sortActions: [SortActionType: SortAction] = {
        let title = SortActionType.byTitle.action(with: [NSSortDescriptor(keyPath: \WMFArticle.displayTitle, ascending: true)], handler: { (sortDescriptors, alertAction, _) in
            self.updateSort(with: sortDescriptors, alertAction: alertAction)
        })
        let recentlyAdded = SortActionType.byRecentlyAdded.action(with: [NSSortDescriptor(keyPath: \WMFArticle.savedDate, ascending: false)], handler: { (sortDescriptors, alertAction, _) in
            self.updateSort(with: sortDescriptors, alertAction: alertAction)
        })
        return [title.type: title, recentlyAdded.type: recentlyAdded]
    }()
    
    lazy var sortAlert: UIAlertController = {
        return alert(title: "Sort saved articles", message: nil)
    }()
    
    // MARK: - Filtering
    
    var searchString: String?
    
    private func articleURL(at indexPath: IndexPath) -> URL? {
        return article(at: indexPath)?.url
    }
    
    private func article(at indexPath: IndexPath) -> WMFArticle? {
        guard let fetchedResultsController = fetchedResultsController, fetchedResultsController.isValidIndexPath(indexPath) else {
                return nil
        }
        return fetchedResultsController.object(at: indexPath)
    }
    
    private func readingListsForArticle(at indexPath: IndexPath) -> [ReadingList] {
        guard let article = article(at: indexPath), let moc = article.managedObjectContext else {
            return []
        }
        
        let request: NSFetchRequest<ReadingList> = ReadingList.fetchRequest()
        request.predicate = NSPredicate(format:"ANY articles == %@ && isDefault == NO", article)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ReadingList.canonicalName, ascending: true)]
        request.fetchLimit = 4
        
        do {
            return try moc.fetch(request)
        } catch let error {
            DDLogError("Error fetching lists: \(error)")
            return []
        }
    }
    
    // MARK: - Editing
    
    lazy var availableBatchEditToolbarActions: [BatchEditToolbarAction] = {
        let addToListItem = BatchEditToolbarActionType.addToList.action(with: self)
        let unsaveItem = BatchEditToolbarActionType.unsave.action(with: self)
        return [addToListItem, unsaveItem]
    }()
    
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        super.scrollViewDidScroll(scrollView)
        editController.transformBatchEditPaneOnScroll()
    }
    
    // MARK: - ColumnarCollectionViewLayoutDelegate
    
    override func collectionView(_ collectionView: UICollectionView, estimatedHeightForItemAt indexPath: IndexPath, forColumnWidth columnWidth: CGFloat) -> ColumnarCollectionViewLayoutHeightEstimate {
        // The layout estimate can be re-used in this case becuause both labels are one line, meaning the cell
        // size only varies with font size. The layout estimate is nil'd when the font size changes on trait collection change
        if let estimate = cellLayoutEstimate {
            return estimate
        }
        var estimate = ColumnarCollectionViewLayoutHeightEstimate(precalculated: false, height: 60)
        guard let placeholderCell = layoutManager.placeholder(forCellWithReuseIdentifier: reuseIdentifier) as? SavedArticlesCollectionViewCell else {
            return estimate
        }
        configure(cell: placeholderCell, forItemAt: indexPath, layoutOnly: true)
        estimate.height = placeholderCell.sizeThatFits(CGSize(width: columnWidth, height: UIView.noIntrinsicMetric), apply: false).height
        estimate.precalculated = true
        cellLayoutEstimate = estimate
        return estimate
    }
    
    override func metrics(with size: CGSize, readableWidth: CGFloat, layoutMargins: UIEdgeInsets) -> ColumnarCollectionViewLayoutMetrics {
        return ColumnarCollectionViewLayoutMetrics.tableViewMetrics(with: size, readableWidth: readableWidth, layoutMargins: layoutMargins)
    }
    
}

// MARK: - CollectionViewUpdaterDelegate

extension SavedArticlesViewController: CollectionViewUpdaterDelegate {
    func collectionViewUpdater<T>(_ updater: CollectionViewUpdater<T>, didUpdate collectionView: UICollectionView) {
        for indexPath in collectionView.indexPathsForVisibleItems {
            guard let cell = collectionView.cellForItem(at: indexPath) as? SavedArticlesCollectionViewCell else {
                continue
            }
            configure(cell: cell, forItemAt: indexPath, layoutOnly: false)
        }
        updateEmptyState()
        collectionView.setNeedsLayout()
    }
    
    func collectionViewUpdater<T>(_ updater: CollectionViewUpdater<T>, updateItemAtIndexPath indexPath: IndexPath, in collectionView: UICollectionView) where T : NSFetchRequestResult {
        
    }
}


// MARK: - UICollectionViewDataSource

extension SavedArticlesViewController {
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
        guard let savedArticleCell = cell as? SavedArticlesCollectionViewCell else {
            return cell
        }
        configure(cell: savedArticleCell, forItemAt: indexPath, layoutOnly: false)
        return cell
    }
    
    private func configure(cell: SavedArticlesCollectionViewCell, forItemAt indexPath: IndexPath, layoutOnly: Bool) {
        cell.isBatchEditing = editController.isBatchEditing
        
        guard let article = article(at: indexPath) else {
            return
        }
        
        if let defaultListEntry = try? article.fetchDefaultListEntry(), let entry = defaultListEntry {
            cell.configureAlert(for: entry, with: article, in: nil, listLimit: dataStore.viewContext.wmf_readingListsConfigMaxListsPerUser, entryLimit: dataStore.viewContext.wmf_readingListsConfigMaxEntriesPerList.intValue, isInDefaultReadingList: true)
        }
        
        cell.tags = (readingLists: readingListsForArticle(at: indexPath), indexPath: indexPath)
        
        cell.configure(article: article, index: indexPath.item, shouldShowSeparators: true, theme: theme, layoutOnly: layoutOnly)

        cell.isBatchEditable = true
        cell.delegate = self
        cell.layoutMargins = layout.itemLayoutMargins
        
        editController.configureSwipeableCell(cell, forItemAt: indexPath, layoutOnly: layoutOnly)
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        editController.deconfigureSwipeableCell(cell, forItemAt: indexPath)
    }
}

// MARK: - ActionDelegate

extension SavedArticlesViewController: ActionDelegate {

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
        let _ = editController.isClosed
    }
    
    internal func didPerformBatchEditToolbarAction(_ action: BatchEditToolbarAction) -> Bool {
        guard let selectedIndexPaths = collectionView.indexPathsForSelectedItems else {
            return false
        }
        
        let articles = selectedIndexPaths.compactMap({ article(at: $0) })
        
        switch action.type {
        case .update:
            return false
        case .addTo:
            let addArticlesToReadingListViewController = AddArticlesToReadingListViewController(with: dataStore, articles: articles, theme: theme)
            let navigationController = WMFThemeableNavigationController(rootViewController: addArticlesToReadingListViewController, theme: theme)
            navigationController.isNavigationBarHidden = true
            addArticlesToReadingListViewController.delegate = self
            present(navigationController, animated: true)
            return true
        case .unsave:
            let alertController = ReadingListsAlertController()
            let delete = ReadingListsAlertActionType.delete.action {
                self.delete(articles: articles)
            }
            var didPerform = false
            return alertController.showAlert(presenter: self, for: articles, with: [ReadingListsAlertActionType.cancel.action(), delete], completion: { didPerform = true }) {
                self.delete(articles: articles)
                didPerform = true
                return didPerform
            }
        default:
            break
        }
        return false
    }
    
    private func delete(articles: [WMFArticle]) {
        dataStore.readingListsController.unsave(articles, in: dataStore.viewContext)
        let articlesCount = articles.count
        UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: CommonStrings.articleDeletedNotification(articleCount: articlesCount))
        let language = articles.count == 1 ? articles.first?.url?.wmf_language : nil
        ReadingListsFunnel.shared.logUnsaveInReadingList(articlesCount: articlesCount, language: language)
    }
    
    func willPerformAction(_ action: Action) -> Bool {
        guard let article = article(at: action.indexPath) else {
            return false
        }
        guard action.type == .delete else {
            return self.editController.didPerformAction(action)
        }
        let alertController = ReadingListsAlertController()
        let unsave = ReadingListsAlertActionType.unsave.action { let _ = self.editController.didPerformAction(action) }
        let cancel = ReadingListsAlertActionType.cancel.action { self.editController.close() }
        return alertController.showAlert(presenter: self, for: [article], with: [cancel, unsave], completion: nil) {
            return self.editController.didPerformAction(action)
        }
    }
    
    func didPerformAction(_ action: Action) -> Bool {
        let indexPath = action.indexPath
        let sourceView: UIView? = UIDevice.current.userInterfaceIdiom == .pad ? collectionView(collectionView, cellForItemAt: indexPath) : nil
        switch action.type {
        case .delete:
            if let article = article(at: indexPath) {
                delete(articles: [article])
            }
            return true
        case .share:
            return share(article: article(at: indexPath), articleURL: articleURL(at: indexPath), at: indexPath, dataStore: dataStore, theme: theme, sourceView: sourceView)
        default:
            assertionFailure("Unsupported action type")
            return false
        }
    }
    
    func availableActions(at indexPath: IndexPath) -> [Action] {
        var actions: [Action] = []
        
        if articleURL(at: indexPath) != nil {
            actions.append(ActionType.share.action(with: self, indexPath: indexPath))
        }
        
        actions.append(ActionType.delete.action(with: self, indexPath: indexPath))
        
        return actions
    }
}

// MARK: - ShareableArticlesProvider

extension SavedArticlesViewController: ShareableArticlesProvider {}

// MARK: - SavedViewControllerDelegate

extension SavedArticlesViewController: SavedViewControllerDelegate {
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

// MARK: - AddArticlesToReadingListDelegate
// default implementation for types conforming to EditableCollection defined in AddArticlesToReadingListViewController
extension SavedArticlesViewController: AddArticlesToReadingListDelegate {}

// MARK: - UIViewControllerPreviewingDelegate

extension SavedArticlesViewController {
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

// MARK: - SavedArticlesCollectionViewCellDelegate

extension SavedArticlesViewController: SavedArticlesCollectionViewCellDelegate {
    func didSelect(_ tag: Tag) {
        let viewController = tag.isLast ? ReadingListsViewController(with: dataStore, readingLists: readingListsForArticle(at: tag.indexPath)) : ReadingListDetailViewController(for: tag.readingList, with: dataStore)
        viewController.apply(theme: theme)
        wmf_push(viewController, animated: true)
    }
}

extension SavedArticlesViewController: EventLoggingEventValuesProviding {
    var eventLoggingCategory: EventLoggingCategory {
        return EventLoggingCategory.saved
    }
    
    var eventLoggingLabel: EventLoggingLabel? {
        return nil
    }
}
