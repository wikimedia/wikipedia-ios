import UIKit


protocol ArticlesCollectionViewControllerDelegate: NSObjectProtocol {
    func articlesCollectionViewController<T>(_ viewController: ArticlesCollectionViewController<T>, didUpdate collectionView: UICollectionView)
    func articlesCollectionViewControllerDidChangeEmptyState<T>(_ viewController: ArticlesCollectionViewController<T>)
}

extension ArticlesCollectionViewControllerDelegate {
    func articlesCollectionViewController<T>(_ viewController: ArticlesCollectionViewController<T>, didUpdate collectionView: UICollectionView) {
        
    }
    
    func articlesCollectionViewControllerDidChangeEmptyState<T>(_ viewController: ArticlesCollectionViewController<T>) {
        
    }
}

class ArticlesCollectionViewController<ElementType: NSManagedObject>: ColumnarCollectionViewController, EditableCollection, UpdatableCollection, SearchableCollection, ArticleURLProvider, ActionDelegate, EventLoggingEventValuesProviding  {
    
    typealias T = ElementType
    
    let dataStore: MWKDataStore
    var fetchedResultsController: NSFetchedResultsController<T>?
    var collectionViewUpdater: CollectionViewUpdater<T>?
    let readingList: ReadingList
    
    var searchString: String?
    
    var basePredicate: NSPredicate {
        fatalError()
    }
    
    var searchPredicate: NSPredicate? {
        guard let searchString = searchString else {
            return nil
        }
        return NSPredicate(format: "(displayTitle CONTAINS[cd] '\(searchString)') OR (snippet CONTAINS[cd] '\(searchString)')")
    }
    
    func shouldDelete(_ articles: [WMFArticle], completion:@escaping (Bool) -> Void) {
        completion(true)
    }
    
    func delete(_ articles: [WMFArticle]) {
        
    }
    
    func configure(cell: SavedArticlesCollectionViewCell, for article: WMFArticle, at indexPath: IndexPath, layoutOnly: Bool) {
        
    }
    
    var availableBatchEditToolbarActions: [BatchEditToolbarAction] {
        return []
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
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
    
    // MARK: - Empty state
    
    override func isEmptyDidChange() {
        editController.isCollectionViewEmpty = isEmpty
        delegate?.articlesCollectionViewControllerDidChangeEmptyState(self)
        super.isEmptyDidChange()
    }
    
    //MARK: - Refresh
    
    override func refresh() {
        dataStore.readingListsController.fullSync {
            self.endRefreshing()
        }
    }
    
    open override func endRefreshing() {
        let now = Date()
        let timeInterval = 0.5 - now.timeIntervalSince(refreshStart)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + timeInterval, execute: {
            self.collectionView.refreshControl?.endRefreshing()
        })
    }
    
    var sortActions: [SortActionType : SortAction] {
        return [:]
    }
    
    lazy var sortAlert: UIAlertController = {
        return alert(title: CommonStrings.sortAlertTitle, message: nil)
    }()
    
    private func getArticle(at indexPath: IndexPath) -> WMFArticle? {
        guard let fetchedResultsController = fetchedResultsController, fetchedResultsController.isValidIndexPath(indexPath) else {
            return nil
        }
        return article(at: indexPath)
    }
    
    func article(at indexPath: IndexPath) -> WMFArticle {
        fatalError("must be implemented by subclasses")
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        super.scrollViewDidScroll(scrollView)
        editController.transformBatchEditPaneOnScroll()
    }
    
    func articleURL(at indexPath: IndexPath) -> URL? {
        return getArticle(at: indexPath)?.url
    }
    
    func readingLists(for article: WMFArticle) -> [ReadingList] {
        guard let moc = article.managedObjectContext else {
            return []
        }
        
        let request : NSFetchRequest<ReadingList> = ReadingList.fetchRequest()
        request.predicate = NSPredicate(format: "ANY articles == %@ && isDefault == NO", article)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ReadingList.canonicalName, ascending: true)]
        
        do {
            return try moc.fetch(request)
        } catch let error {
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
    
    // MARK: - UICollectionViewDataSource
    
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
    
    private func configure(cell: SavedArticlesCollectionViewCell, forItemAt indexPath: IndexPath, layoutOnly: Bool) {
        guard let article = getArticle(at: indexPath)  else { return }
        configure(cell: cell, for: article, at: indexPath, layoutOnly: layoutOnly)
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
        guard let savedArticleCell = cell as? SavedArticlesCollectionViewCell else {
            return cell
        }
        savedArticleCell.delegate = self
        configure(cell: savedArticleCell, forItemAt: indexPath, layoutOnly: false)
        return cell
    }
    
    //MARK: - UICollectionViewDelegate
    
    override func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        editController.deconfigureSwipeableCell(cell, forItemAt: indexPath)
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard editController.isClosed else {
            return
        }
        guard let articleURL = articleURL(at: indexPath) else {
            return
        }
        wmf_pushArticle(with: articleURL, dataStore: dataStore, theme: theme, animated: true)
        ReadingListsFunnel.shared.logReadStartIReadingList(articleURL)
    }
    
    override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let _ = editController.isClosed
    }
    
    //MARK: - ActionDelegate
    func availableActions(at indexPath: IndexPath) -> [Action] {
        var actions: [Action] = []
        
        if articleURL(at: indexPath) != nil {
            actions.append(ActionType.share.action(with: self, indexPath: indexPath))
        }
        
        actions.append(ActionType.delete.action(with: self, indexPath: indexPath))
        
        return actions
    }
    
    private func delete(at indexPath: IndexPath) {
        guard let article = getArticle(at: indexPath) else {
            return
        }
        delete([article])
    }
    
    func willPerformAction(_ action: Action) -> Bool {
        guard let article = getArticle(at: action.indexPath) else {
            return false
        }
        guard action.type == .delete else {
            return self.editController.didPerformAction(action)
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
        
        let articles = selectedIndexPaths.compactMap{ article(at: $0) }
        
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
    
    //MARK: - UIViewControllerPreviewingDelegate
    
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
        
        let articleViewController = WMFArticleViewController(articleURL: articleURL, dataStore: dataStore, theme: self.theme)
        articleViewController.articlePreviewingActionsDelegate = self
        articleViewController.wmf_addPeekableChildViewController(for: articleURL, dataStore: dataStore, theme: theme)
        return articleViewController
    }
    
    override func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        viewControllerToCommit.wmf_removePeekableChildViewControllers()
        wmf_push(viewControllerToCommit, animated: true)
    }
    
    //MARK: - EventLoggingEventValuesProviding
    
    var eventLoggingLabel: EventLoggingLabel? {
        return nil
    }
    
    var eventLoggingCategory: EventLoggingCategory {
        return EventLoggingCategory.saved
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
            guard let cell = collectionView.cellForItem(at: indexPath) as? SavedArticlesCollectionViewCell else {
                continue
            }
            configure(cell: cell, forItemAt: indexPath, layoutOnly: false)
        }
        updateEmptyState()
        collectionView.setNeedsLayout()
        delegate?.articlesCollectionViewController(self, didUpdate: collectionView)
    }
    
    func collectionViewUpdater<T>(_ updater: CollectionViewUpdater<T>, updateItemAtIndexPath indexPath: IndexPath, in collectionView: UICollectionView) where T : NSFetchRequestResult {
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

// MARK: - SavedArticlesCollectionViewCellDelegate

extension ArticlesCollectionViewController: SavedArticlesCollectionViewCellDelegate {
    func didSelect(_ tag: Tag) {
        guard let article = getArticle(at: tag.indexPath) else {
            return
        }
        let viewController = tag.isLast ? ReadingListsViewController(with: dataStore, readingLists: readingLists(for: article)) : ReadingListDetailViewController(for: tag.readingList, with: dataStore)
        viewController.apply(theme: theme)
        wmf_push(viewController, animated: true)
    }
}
