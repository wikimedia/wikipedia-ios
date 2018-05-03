
@objc(WMFSavedArticlesViewController)
class SavedArticlesViewController: ColumnarCollectionViewController, EditableCollection, SearchableCollection, SortableCollection {
    
    private let reuseIdentifier = "SavedArticlesCollectionViewCell"
    private var cellLayoutEstimate: WMFLayoutEstimate?

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
        register(SavedArticlesCollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier, addPlaceholder: true)
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
        fetch()
        setupCollectionViewUpdater()
        super.viewWillAppear(animated)
    }
    
    override func viewWillHaveFirstAppearance(_ animated: Bool) {
        super.viewWillHaveFirstAppearance(animated)
        navigationBarHider.isBarHidingEnabled = false
        navigationBarHider.isUnderBarViewHidingEnabled = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        PiwikTracker.sharedInstance()?.wmf_logView(self)
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
        guard let fetchedResultsController = fetchedResultsController,
            let sections = fetchedResultsController.sections,
            indexPath.section < sections.count,
            indexPath.item < sections[indexPath.section].numberOfObjects else {
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
        let addToListItem = BatchEditToolbarActionType.addTo.action(with: self)
        let unsaveItem = BatchEditToolbarActionType.unsave.action(with: self)
        return [addToListItem, unsaveItem]
    }()
    
    // MARK: - Hiding extended view
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        navigationBarHider.scrollViewDidScroll(scrollView)
        editController.transformBatchEditPaneOnScroll()
    }
    
    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        navigationBarHider.scrollViewWillBeginDragging(scrollView) // this & following UIScrollViewDelegate calls could be in a default implementation
        super.scrollViewWillBeginDragging(scrollView)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        navigationBarHider.scrollViewDidEndDecelerating(scrollView)
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        navigationBarHider.scrollViewDidEndScrollingAnimation(scrollView)
    }
    
    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        navigationBarHider.scrollViewWillScrollToTop(scrollView)
        return true
    }
    
    func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        navigationBarHider.scrollViewDidScrollToTop(scrollView)
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
}

// MARK: - WMFColumnarCollectionViewLayoutDelegate

extension SavedArticlesViewController {
    override func collectionView(_ collectionView: UICollectionView, estimatedHeightForItemAt indexPath: IndexPath, forColumnWidth columnWidth: CGFloat) -> WMFLayoutEstimate {
        // The layout estimate can be re-used in this case becuause both labels are one line, meaning the cell
        // size only varies with font size. The layout estimate is nil'd when the font size changes on trait collection change
        if let estimate = cellLayoutEstimate {
            return estimate
        }
        var estimate = WMFLayoutEstimate(precalculated: false, height: 60)
        guard let placeholderCell = placeholder(forCellWithReuseIdentifier: reuseIdentifier) as? SavedArticlesCollectionViewCell else {
            return estimate
        }
        placeholderCell.prepareForReuse()
        configure(cell: placeholderCell, forItemAt: indexPath, layoutOnly: true)
        estimate.height = placeholderCell.sizeThatFits(CGSize(width: columnWidth, height: UIViewNoIntrinsicMetric), apply: false).height
        estimate.precalculated = true
        cellLayoutEstimate = estimate
        return estimate
    }
    
    override func metrics(withBoundsSize size: CGSize, readableWidth: CGFloat) -> WMFCVLMetrics {
        return WMFCVLMetrics.singleColumnMetrics(withBoundsSize: size, readableWidth: readableWidth)
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
            cell.configureAlert(for: entry, in: nil, listLimit: dataStore.viewContext.wmf_readingListsConfigMaxListsPerUser, entryLimit: dataStore.viewContext.wmf_readingListsConfigMaxEntriesPerList.intValue, isInDefaultReadingList: true)
        }
        
        cell.tags = (readingLists: readingListsForArticle(at: indexPath), indexPath: indexPath)
        
        let numberOfItems = self.collectionView(collectionView, numberOfItemsInSection: indexPath.section)
        cell.configure(article: article, index: indexPath.item, count: numberOfItems, shouldAdjustMargins: false, shouldShowSeparators: true, theme: theme, layoutOnly: layoutOnly)
        
        cell.actions = availableActions(at: indexPath)
        cell.isBatchEditable = true
        cell.delegate = self
        cell.layoutMargins = layout.readableMargins
        
        editController.configureSwipeableCell(cell, forItemAt: indexPath, layoutOnly: layoutOnly)
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
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let _ = editController.isClosed
    }
    
    internal func didPerformBatchEditToolbarAction(_ action: BatchEditToolbarAction) -> Bool {
        guard let selectedIndexPaths = collectionView.indexPathsForSelectedItems else {
            return false
        }
        
        let articles = selectedIndexPaths.flatMap({ article(at: $0) })
        
        switch action.type {
        case .update:
            return false
        case .addTo:
            let addArticlesToReadingListViewController = AddArticlesToReadingListViewController(with: dataStore, articles: articles, theme: theme)
            addArticlesToReadingListViewController.delegate = self
            present(addArticlesToReadingListViewController, animated: true, completion: nil)
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
        UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, CommonStrings.articleDeletedNotification(articleCount: articles.count))
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
        defer {
            if let cell = collectionView.cellForItem(at: indexPath) as? SavedArticlesCollectionViewCell {
                cell.actions = availableActions(at: indexPath)
            }
        }
        switch action.type {
        case .delete:
            if let article = article(at: indexPath) {
                delete(articles: [article])
            }
            return true
        case .save:
            if let articleURL = articleURL(at: indexPath) {
                dataStore.savedPageList.addSavedPage(with: articleURL)
                UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, CommonStrings.accessibilitySavedNotification)
                return true
            }
        case .unsave:
            if let articleURL = articleURL(at: indexPath) {
                dataStore.savedPageList.removeEntry(with: articleURL)
                UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, CommonStrings.accessibilityUnsavedNotification)
                return true
            }
        case .share:
            return share(article: article(at: indexPath), articleURL: articleURL(at: indexPath), at: indexPath, dataStore: dataStore, theme: theme)
        }
        return false
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
        navigationBarHider.isHidingEnabled = false
    }
    
    func saved(_ saved: SavedViewController, searchBarTextDidEndEditing searchBar: UISearchBar) {
        makeSearchBarResignFirstResponder(searchBar)
    }
    
    private func makeSearchBarResignFirstResponder(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        navigationBarHider.isHidingEnabled = true
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
        guard let indexPath = collectionView.indexPathForItem(at: location),
            let cell = collectionView.cellForItem(at: indexPath) as? SavedArticlesCollectionViewCell,
            let url = articleURL(at: indexPath)
            else {
                return nil
        }
        previewingContext.sourceRect = cell.convert(cell.bounds, to: collectionView)
        
        let articleViewController = WMFArticleViewController(articleURL: url, dataStore: dataStore, theme: self.theme)
        articleViewController.articlePreviewingActionsDelegate = self
        articleViewController.wmf_addPeekableChildViewController(for: url, dataStore: dataStore, theme: theme)
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

// MARK: - Analytics

extension SavedArticlesViewController: AnalyticsContextProviding, AnalyticsViewNameProviding {
    var analyticsName: String {
        return "SavedArticles"
    }
    
    var analyticsContext: String {
        return analyticsName
    }
}

