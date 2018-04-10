import UIKit

enum ReadingListDetailDisplayType {
    case modal, pushed
}

class ReadingListDetailViewController: ColumnarCollectionViewController, EditableCollection, SearchableCollection, SortableCollection {
    let dataStore: MWKDataStore
    let readingList: ReadingList
    
    typealias T = ReadingListEntry
    var fetchedResultsController: NSFetchedResultsController<ReadingListEntry>?
    var collectionViewUpdater: CollectionViewUpdater<ReadingListEntry>?
    
    var basePredicate: NSPredicate {
        return NSPredicate(format: "list == %@ && isDeletedLocally != YES", readingList)
    }
    
    var searchPredicate: NSPredicate? {
        guard let searchString = searchString else {
            return nil
        }
        return NSPredicate(format: "(displayTitle CONTAINS[cd] '\(searchString)')") // ReadingListEntry has no snippet
    }
    
    private var cellLayoutEstimate: WMFLayoutEstimate?
    private let reuseIdentifier = "ReadingListDetailCollectionViewCell"
    var editController: CollectionViewEditController!
    private let readingListDetailExtendedViewController: ReadingListDetailExtendedViewController
    private var displayType: ReadingListDetailDisplayType = .pushed

    init(for readingList: ReadingList, with dataStore: MWKDataStore, displayType: ReadingListDetailDisplayType = .pushed) {
        self.readingList = readingList
        self.dataStore = dataStore
        self.readingListDetailExtendedViewController = ReadingListDetailExtendedViewController()
        self.displayType = displayType
        super.init()
        self.readingListDetailExtendedViewController.delegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not supported")
    }
    
    var shouldShowEditButtonsForEmptyState: Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        emptyViewType = .noSavedPagesInReadingList

        navigationBar.title = readingList.name
        navigationBar.addExtendedNavigationBarView(readingListDetailExtendedViewController.view)
        navigationBar.extendedViewPercentHiddenForShowingTitle = 0.4
        
        setupFetchedResultsController()
        setupCollectionViewUpdater()
        setupEditController()
        fetch()
        
        register(SavedArticlesCollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier, addPlaceholder: true)

        if displayType == .modal {
            navigationItem.leftBarButtonItem = UIBarButtonItem.wmf_buttonType(WMFButtonType.X, target: self, action: #selector(dismissController))
        }
        
        isRefreshControlEnabled = true
    }
    
    override func refresh() {
        dataStore.readingListsController.fullSync {
            self.endRefreshing()
        }
    }
    
    @objc private func dismissController() {
        dismiss(animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        readingListDetailExtendedViewController.setup(for: readingList, listLimit: dataStore.viewContext.wmf_readingListsConfigMaxListsPerUser, entryLimit: dataStore.viewContext.wmf_readingListsConfigMaxEntriesPerList.intValue)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        editController.close()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        cellLayoutEstimate = nil
    }
    
    private func entry(at indexPath: IndexPath) -> ReadingListEntry? {
        guard let fetchedResultsController = fetchedResultsController,
            let sections = fetchedResultsController.sections,
            indexPath.section < sections.count,
            indexPath.item < sections[indexPath.section].numberOfObjects else {
                return nil
        }
        return fetchedResultsController.object(at: indexPath)
    }
    
    private func articleURL(at indexPath: IndexPath) -> URL? {
        guard let entry = entry(at: indexPath), let key = entry.articleKey else {
            assertionFailure("Can't get articleURL")
            return nil
        }
        return URL(string: key)
    }
    
    private func article(at indexPath: IndexPath) -> WMFArticle? {
        guard let entry = entry(at: indexPath), let key = entry.articleKey, let article = dataStore.fetchArticle(withKey: key) else {
            return nil
        }
        return article
    }
    
    // MARK: - Empty state
    
    override func isEmptyDidChange() {
        editController.isCollectionViewEmpty = isEmpty
        if isEmpty {
            title = readingList.name
        } else {
            title = nil
        }
        readingListDetailExtendedViewController.isSearchBarHidden = isEmpty
        updateScrollViewInsets()
        super.isEmptyDidChange()
    }
    
    // MARK: - Theme
    
    override func apply(theme: Theme) {
        super.apply(theme: theme)
        readingListDetailExtendedViewController.apply(theme: theme)
    }
    
    // MARK: - Batch editing (parts that cannot be in an extension)
    
    lazy var availableBatchEditToolbarActions: [BatchEditToolbarAction] = {
        let addToListItem = BatchEditToolbarActionType.addTo.action(with: self)
        let moveToListItem = BatchEditToolbarActionType.moveTo.action(with: self)
        let removeItem = BatchEditToolbarActionType.remove.action(with: self)
        return [addToListItem, moveToListItem, removeItem]
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
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        navigationBarHider.scrollViewWillEndDragging(scrollView, withVelocity: velocity, targetContentOffset: targetContentOffset)
    }
    
    // MARK: - Filtering
    
    var searchString: String?
    
    // MARK: - Sorting
    
    var sort: (descriptors: [NSSortDescriptor], action: UIAlertAction?) = (descriptors: [NSSortDescriptor(keyPath: \ReadingListEntry.createdDate, ascending: false)], action: nil)
    
    var defaultSortAction: UIAlertAction? { return sortActions[.byRecentlyAdded] }
    
    lazy var sortActions: [SortActionType: UIAlertAction] = {
        let title = SortActionType.byTitle.action(with: [NSSortDescriptor(keyPath: \ReadingListEntry.displayTitle, ascending: true)], handler: { (sortDescriptors, action) in
            self.updateSort(with: sortDescriptors, newAction: action)
        })
       let recentlyAdded = SortActionType.byRecentlyAdded.action(with: [NSSortDescriptor(keyPath: \ReadingListEntry.createdDate, ascending: false)], handler: { (sortDescriptors, action) in
            self.updateSort(with: sortDescriptors, newAction: action)
        })
        return [title.type: title.action, recentlyAdded.type: recentlyAdded.action]
    }()
    
    lazy var sortAlert: UIAlertController = {
        return alert(title: "Sort saved articles", message: nil)
    }()
}

// MARK: - ActionDelegate

extension ReadingListDetailViewController: ActionDelegate {
    
    func willPerformAction(_ action: Action) -> Bool {
        return self.editController.didPerformAction(action)
    }
    
    
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
        
        let entries = selectedIndexPaths.flatMap({ entry(at: $0) })
        let articles = selectedIndexPaths.flatMap({ article(at: $0) })
        
        switch action.type {
        case .addTo:
            let addArticlesToReadingListViewController = AddArticlesToReadingListViewController(with: dataStore, articles: articles, theme: theme)
            addArticlesToReadingListViewController.delegate = self
            present(addArticlesToReadingListViewController, animated: true, completion: nil)
            return true
        case .remove:
            delete(entries)
            UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, CommonStrings.accessibilityUnsavedNotification)
            return true
        case .moveTo:
            let addArticlesToReadingListViewController = AddArticlesToReadingListViewController(with: dataStore, articles: articles, moveFromReadingList: readingList, theme: theme)
            addArticlesToReadingListViewController.delegate = self
            present(addArticlesToReadingListViewController, animated: true, completion: nil)
            return true
        default:
            assert(false, "Unhandled action type")
            break
        }
        return false
    }
    
    private func delete(at indexPath: IndexPath) {
        guard let entry = entry(at: indexPath) else {
            return
        }
        do {
            try dataStore.readingListsController.remove(entries: [entry])
        } catch let err {
            DDLogError("Error removing entry from a reading list: \(err)")
        }
    }
    
    private func delete(_ entries: [ReadingListEntry]) {
        do {
            try dataStore.readingListsController.remove(entries: entries)
        } catch let err {
            DDLogError("Error removing entries from a reading list: \(err)")
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
            delete(at: indexPath)
            UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, CommonStrings.articleDeletedNotification(articleCount: 1))
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
    
    private func canSave(at indexPath: IndexPath) -> Bool {
        guard let articleURL = articleURL(at: indexPath) else {
            return false
        }
        return !dataStore.savedPageList.isSaved(articleURL)
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

extension ReadingListDetailViewController: ShareableArticlesProvider {}

// MARK: - NavigationDelegate

extension ReadingListDetailViewController: CollectionViewEditControllerNavigationDelegate {
    var currentTheme: Theme {
        return self.theme
    }
    
    func didChangeEditingState(from oldEditingState: EditingState, to newEditingState: EditingState, rightBarButton: UIBarButtonItem?, leftBarButton: UIBarButtonItem?) {
        navigationItem.rightBarButtonItem = rightBarButton
        navigationItem.rightBarButtonItem?.tintColor = theme.colors.link // no need to do a whole apply(theme:) pass
        
        if displayType == .pushed {
            navigationItem.leftBarButtonItem = leftBarButton
            navigationItem.leftBarButtonItem?.tintColor = theme.colors.link
        }
        
        switch newEditingState {
        case .open where isEmpty:
            readingListDetailExtendedViewController.beginEditing()
        case .done:
            readingListDetailExtendedViewController.finishEditing()
        case .closed where isEmpty:
            fallthrough
        case .cancelled:
            readingListDetailExtendedViewController.cancelEditing()
        default:
            break
        }
    }
}

// MARK: - AddArticlesToReadingListViewControllerDelegate
// default implementation for types conforming to EditableCollection defined in AddArticlesToReadingListViewController
extension ReadingListDetailViewController: AddArticlesToReadingListDelegate {}

// MARK: - CollectionViewUpdaterDelegate

extension ReadingListDetailViewController: CollectionViewUpdaterDelegate {
    func collectionViewUpdater<T>(_ updater: CollectionViewUpdater<T>, didUpdate collectionView: UICollectionView) {
        readingListDetailExtendedViewController.reconfigureAlert(for: readingList)
        for indexPath in collectionView.indexPathsForVisibleItems {
            guard let cell = collectionView.cellForItem(at: indexPath) as? SavedArticlesCollectionViewCell else {
                continue
            }
            configure(cell: cell, forItemAt: indexPath, layoutOnly: false)
        }
        updateEmptyState()
        readingListDetailExtendedViewController.updateArticleCount(readingList.countOfEntries)
        collectionView.setNeedsLayout()
    }
}

// MARK: - WMFColumnarCollectionViewLayoutDelegate

extension ReadingListDetailViewController {
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

extension ReadingListDetailViewController {
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
        
        guard let entry = entry(at: indexPath), let articleKey = entry.articleKey else {
            assertionFailure("Coudn't get a reading list entry or an article key to configure the cell")
            return
        }
        
        guard let article = dataStore.fetchArticle(withKey: articleKey) else {
            assertionFailure("Coudn't fetch an article with \(articleKey) articleKey")
            return
        }
        let numberOfItems = self.collectionView(collectionView, numberOfItemsInSection: indexPath.section)
        
        cell.configureAlert(for: entry, in: readingList, listLimit: dataStore.viewContext.wmf_readingListsConfigMaxListsPerUser, entryLimit: dataStore.viewContext.wmf_readingListsConfigMaxEntriesPerList.intValue)
        cell.configure(article: article, index: indexPath.item, count: numberOfItems, shouldAdjustMargins: false, shouldShowSeparators: true, theme: theme, layoutOnly: layoutOnly)
        
        cell.actions = availableActions(at: indexPath)
        cell.isBatchEditable = true
        cell.layoutMargins = layout.readableMargins
        
        guard !layoutOnly, let translation = editController.swipeTranslationForItem(at: indexPath) else {
            return
        }
        cell.swipeTranslation = translation
    }
}

// MARK: - UIViewControllerPreviewingDelegate

extension ReadingListDetailViewController {
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

// MARK: - ReadingListDetailExtendedViewControllerDelegate

extension ReadingListDetailViewController: ReadingListDetailExtendedViewControllerDelegate {
    func extendedViewController(_ extendedViewController: ReadingListDetailExtendedViewController, didEdit name: String?, description: String?) {
        dataStore.readingListsController.updateReadingList(readingList, with: name, newDescription: description)
        title = name
    }
    
    func extendedViewController(_ extendedViewController: ReadingListDetailExtendedViewController, searchTextDidChange searchText: String) {
        updateSearchString(searchText)
    }
    
    func extendedViewControllerDidPressSortButton(_ extendedViewController: ReadingListDetailExtendedViewController, sortButton: UIButton) {
        presentSortAlert(from: sortButton)
    }
    
    func extendedViewController(_ extendedViewController: ReadingListDetailExtendedViewController, didBeginEditing textField: UITextField) {
        editController.isTextEditing = true
    }

}

// MARK: - Analytics

extension ReadingListDetailViewController: AnalyticsContextProviding, AnalyticsViewNameProviding {
    var analyticsName: String {
        return "ReadingListDetailView"
    }
    
    var analyticsContext: String {
        return analyticsName
    }
}
