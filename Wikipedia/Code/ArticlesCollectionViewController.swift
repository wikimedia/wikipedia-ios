import UIKit


protocol ArticlesCollectionViewControllerDelegate: NSObjectProtocol {
    func articlesCollectionViewController(_ viewController: ArticlesCollectionViewController, shouldDelete articles: [WMFArticle], completion:@escaping (Bool) -> Void)
    func articlesCollectionViewController(_ viewController: ArticlesCollectionViewController, delete articles: [WMFArticle])
    func articlesCollectionViewController(_ viewController: ArticlesCollectionViewController, configure cell: SavedArticlesCollectionViewCell, for article: WMFArticle, at indexPath: IndexPath, layoutOnly: Bool)
    func articlesCollectionViewController(_ viewController: ArticlesCollectionViewController, didUpdate collectionView: UICollectionView)
    func articlesCollectionViewControllerDidChangeEmptyState(_ viewController: ArticlesCollectionViewController)
}

extension ArticlesCollectionViewControllerDelegate {
    func articlesCollectionViewController(_ viewController: ArticlesCollectionViewController, didUpdate collectionView: UICollectionView) {
        
    }
    
    func articlesCollectionViewControllerDidChangeEmptyState(_ viewController: ArticlesCollectionViewController) {
        
    }
}

func makeArticlesCollectionViewControllerForDefaultReadingList( dataStore: MWKDataStore) -> ArticlesCollectionViewController {
    
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
    
    let predicate = NSPredicate(format: "savedDate != NULL")
    let readingList = fetchDefaultReadingListWithSortOrder()
    let actions = [
        BatchEditToolbarActionType.addToList.action(with: nil),
        BatchEditToolbarActionType.unsave.action(with: nil)
    ]
    let viewController = ArticlesCollectionViewController(for: readingList, with: dataStore, basePredicate: predicate, sortDescriptors: [], batchEditActions: actions)
    viewController.emptyViewType = .noSavedPages
    return viewController
}

class ArticlesCollectionViewController: ColumnarCollectionViewController, EditableCollection, UpdatableCollection, SearchableCollection, ArticleURLProvider {
    
    typealias T = WMFArticle
    
    let dataStore: MWKDataStore
    var fetchedResultsController: NSFetchedResultsController<WMFArticle>?
    var collectionViewUpdater: CollectionViewUpdater<WMFArticle>?
    let readingList: ReadingList
    
    var searchString: String?
    
    let basePredicate: NSPredicate
    var searchPredicate: NSPredicate? {
        guard let searchString = searchString else {
            return nil
        }
        return NSPredicate(format: "(displayTitle CONTAINS[cd] '\(searchString)') OR (snippet CONTAINS[cd] '\(searchString)')")
    }
    
    let baseSortDescriptors: [NSSortDescriptor]
    let availableBatchEditToolbarActions: [BatchEditToolbarAction]
    
    var editController: CollectionViewEditController!
    
    private var cellLayoutEstimate: ColumnarCollectionViewLayoutHeightEstimate?
    private let reuseIdentifier = "ArticlesCollectionViewCell"
    
    weak var delegate: ArticlesCollectionViewControllerDelegate?
    
    init(for readingList: ReadingList, with dataStore: MWKDataStore, basePredicate: NSPredicate, searchPredicate: NSPredicate? = nil , sortDescriptors: [NSSortDescriptor], batchEditActions: [BatchEditToolbarAction]) {
        self.readingList = readingList
        self.dataStore = dataStore
        self.basePredicate = basePredicate
        self.baseSortDescriptors = sortDescriptors
        self.availableBatchEditToolbarActions = batchEditActions
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
        #warning("Check this after implementation to see what other classes were doing here")
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
    
    private func article(at indexPath: IndexPath) -> WMFArticle? {
        guard let fetchedResultsController = fetchedResultsController, fetchedResultsController.isValidIndexPath(indexPath) else {
            return nil
        }
        return fetchedResultsController.object(at: indexPath)
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        super.scrollViewDidScroll(scrollView)
        editController.transformBatchEditPaneOnScroll()
    }
    
    func articleURL(at indexPath: IndexPath) -> URL? {
        return article(at: indexPath)?.url
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

// MARK: - SortableCollection

extension ArticlesCollectionViewController: SortableCollection {
    var sort: (descriptors: [NSSortDescriptor], alertAction: UIAlertAction?) {
        fatalError()
    }
    
    var defaultSortAction: SortAction? {
        fatalError()
    }
    
    var sortActions: [SortActionType : SortAction] {
        fatalError()
    }
    
    var sortAlert: UIAlertController {
        fatalError()
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
    
    private func configure(cell: SavedArticlesCollectionViewCell, forItemAt indexPath: IndexPath, layoutOnly: Bool) {
        guard let article = article(at: indexPath)  else { return }
        delegate?.articlesCollectionViewController(self, configure: cell, for: article, at: indexPath, layoutOnly: false)
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
        let _ = editController.isClosed
    }
}


// MARK: - ActionDelegate

extension ArticlesCollectionViewController: ActionDelegate {
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
        
        delegate?.articlesCollectionViewController(self, delete: [article])
    }
    
    func willPerformAction(_ action: Action) -> Bool {
        guard let article = article(at: action.indexPath) else {
            return false
        }
        guard action.type == .delete, let delegate = delegate else {
            return self.editController.didPerformAction(action)
        }
        
        delegate.articlesCollectionViewController(self, shouldDelete: [article]) { shouldDelete in
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
            delegate?.articlesCollectionViewController(self, shouldDelete: articles, completion: { shouldDelete in
                if shouldDelete {
                    self.delegate?.articlesCollectionViewController(self, delete: articles)
                    completion(true)
                } else {
                    completion(false)
                }
            })
        case .remove:
            delegate?.articlesCollectionViewController(self, delete: articles)
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


// MARK: - AddArticlesToReadingListViewControllerDelegate
// default implementation for types conforming to EditableCollection defined in AddArticlesToReadingListViewController
extension ArticlesCollectionViewController: AddArticlesToReadingListDelegate {}

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
        
        let articleViewController = WMFArticleViewController(articleURL: articleURL, dataStore: dataStore, theme: self.theme)
        articleViewController.articlePreviewingActionsDelegate = self
        articleViewController.wmf_addPeekableChildViewController(for: articleURL, dataStore: dataStore, theme: theme)
        return articleViewController
    }
    
    override func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        viewControllerToCommit.wmf_removePeekableChildViewControllers()
        wmf_push(viewControllerToCommit, animated: true)
    }
}

extension ArticlesCollectionViewController: ShareableArticlesProvider {}

// MARK: - EventLoggingEventValuesProviding

extension ArticlesCollectionViewController: EventLoggingEventValuesProviding {
    var eventLoggingLabel: EventLoggingLabel? {
        return nil
    }
    
    var eventLoggingCategory: EventLoggingCategory {
        return EventLoggingCategory.saved
    }
}

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
        guard let article = article(at: tag.indexPath) else {
            return
        }
        let viewController = tag.isLast ? ReadingListsViewController(with: dataStore, readingLists: readingLists(for: article)) : ReadingListDetailViewController(for: tag.readingList, with: dataStore)
        viewController.apply(theme: theme)
        wmf_push(viewController, animated: true)
    }
}
