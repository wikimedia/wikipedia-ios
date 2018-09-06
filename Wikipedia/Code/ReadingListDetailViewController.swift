import UIKit

enum ReadingListDetailDisplayType {
    case modal, pushed
}

class ReadingListDetailViewController: ColumnarCollectionViewController, EditableCollection, SearchableCollection, SortableCollection, ArticleURLProvider {
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
    
    private var cellLayoutEstimate: ColumnarCollectionViewLayoutHeightEstimate?
    private let reuseIdentifier = "ReadingListDetailCollectionViewCell"
    var editController: CollectionViewEditController!
    var updater: ArticleURLProviderEditControllerUpdater?
    private let readingListDetailUnderBarViewController: ReadingListDetailUnderBarViewController
    private var searchBarExtendedViewController: SearchBarExtendedViewController?
    private var displayType: ReadingListDetailDisplayType = .pushed

    init(for readingList: ReadingList, with dataStore: MWKDataStore, displayType: ReadingListDetailDisplayType = .pushed) {
        self.readingList = readingList
        self.dataStore = dataStore
        self.displayType = displayType
        readingListDetailUnderBarViewController = ReadingListDetailUnderBarViewController()
        super.init()
        searchBarExtendedViewController = SearchBarExtendedViewController()
        searchBarExtendedViewController?.dataSource = self
        searchBarExtendedViewController?.delegate = self
        readingListDetailUnderBarViewController.delegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not supported")
    }
    
    var shouldShowEditButtonsForEmptyState: Bool {
        return !readingList.isDefault
    }
    
    private lazy var savedProgressViewController: SavedProgressViewController? = SavedProgressViewController.wmf_initialViewControllerFromClassStoryboard()
    
    private lazy var progressContainerView: UIView = {
        let containerView = UIView()
        containerView.isUserInteractionEnabled = false
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        
        // reminder: this height constraint gets deactivated by "wmf_add:andConstrainToEdgesOfContainerView:"
        containerView.addConstraint(containerView.heightAnchor.constraint(equalToConstant: 1))
        
        view.addConstraints([
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        return containerView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        emptyViewType = .noSavedPagesInReadingList

        navigationBar.title = readingList.name
        navigationBar.addUnderNavigationBarView(readingListDetailUnderBarViewController.view)
        navigationBar.underBarViewPercentHiddenForShowingTitle = 0.6
        navigationBar.isBarHidingEnabled = false
        navigationBar.isUnderBarViewHidingEnabled = true
        addExtendedView()
        
        setupFetchedResultsController()
        setupCollectionViewUpdater()
        setupEditController()
        fetch()
        
        layoutManager.register(SavedArticlesCollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier, addPlaceholder: true)

        if displayType == .modal {
            navigationItem.leftBarButtonItem = UIBarButtonItem.wmf_buttonType(WMFButtonType.X, target: self, action: #selector(dismissController))
            title = readingList.name
        }
        
        isRefreshControlEnabled = true

        wmf_add(childController:savedProgressViewController, andConstrainToEdgesOfContainerView: progressContainerView)
        
        updater = ArticleURLProviderEditControllerUpdater(articleURLProvider: self, collectionView: collectionView, editController: editController)
    }
    
    private func addExtendedView() {
        guard let extendedView = searchBarExtendedViewController?.view else {
            return
        }
        navigationBar.addExtendedNavigationBarView(extendedView)
    }
    
    override func viewWillHaveFirstAppearance(_ animated: Bool) {
        super.viewWillHaveFirstAppearance(animated)
        setNavigationBarHidingEnabled(true)
    }
    
    private func setNavigationBarHidingEnabled(_ enabled: Bool) {
        navigationBar.isExtendedViewHidingEnabled = enabled
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
        readingListDetailUnderBarViewController.setup(for: readingList, listLimit: dataStore.viewContext.wmf_readingListsConfigMaxListsPerUser, entryLimit: dataStore.viewContext.wmf_readingListsConfigMaxEntriesPerList.intValue)
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
        guard let fetchedResultsController = fetchedResultsController, fetchedResultsController.isValidIndexPath(indexPath) else {
                return nil
        }
        return fetchedResultsController.object(at: indexPath)
    }
    
    func articleURL(at indexPath: IndexPath) -> URL? {
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
        // for cases when empty state changes while user is viewing search results, we need to make sure that new empty state matches reading list's empty state
        let isReadingListEmpty = readingList.countOfEntries == 0
        let isEmptyStateMatchingReadingListEmptyState = isEmpty == isReadingListEmpty
        if !isEmptyStateMatchingReadingListEmptyState {
            isEmpty = isReadingListEmpty
        }
        editController.isCollectionViewEmpty = isEmpty
        if isEmpty {
            title = readingList.name
            navigationBar.removeExtendedNavigationBarView()
        } else {
            addExtendedView()
        }
        updateScrollViewInsets()
        super.isEmptyDidChange()
    }
    
    // MARK: - Theme
    
    override func apply(theme: Theme) {
        super.apply(theme: theme)
        readingListDetailUnderBarViewController.apply(theme: theme)
        searchBarExtendedViewController?.apply(theme: theme)
        savedProgressViewController?.apply(theme: theme)
    }
    
    // MARK: - Batch editing (parts that cannot be in an extension)
    
    lazy var availableBatchEditToolbarActions: [BatchEditToolbarAction] = {
        let addToListItem = BatchEditToolbarActionType.addTo.action(with: self)
        let moveToListItem = BatchEditToolbarActionType.moveTo.action(with: self)
        let removeItem = BatchEditToolbarActionType.remove.action(with: self)
        return [addToListItem, moveToListItem, removeItem]
    }()
    
    // MARK: - UIScrollViewDelegate
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        super.scrollViewDidScroll(scrollView)
        editController.transformBatchEditPaneOnScroll()
    }
    
    // MARK: - Filtering
    
    var searchString: String?
    
    // MARK: - Sorting
    
    var sort: (descriptors: [NSSortDescriptor], alertAction: UIAlertAction?) {
        get {
            guard let sortOrder = readingList.sortOrder, let sortActionType = SortActionType(rawValue: sortOrder.intValue), let sortAction = sortActions[sortActionType] else {
                return ([], nil)
            }
            return (sortAction.sortDescriptors, sortAction.alertAction)
        }
        set {
            
        }
    }
    
    var defaultSortAction: SortAction? {
        return sortActions[.byRecentlyAdded]
    }
    
    lazy var sortActions: [SortActionType: SortAction] = {
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
            self.updateSort(with: sortDescriptors, alertAction: alertAction)
        }
        
        let titleSortAction = SortActionType.byTitle.action(with: [NSSortDescriptor(keyPath: \ReadingListEntry.displayTitle, ascending: true)], handler: handler)
        let recentlyAddedSortAction = SortActionType.byRecentlyAdded.action(with: [NSSortDescriptor(keyPath: \ReadingListEntry.createdDate, ascending: false)], handler: handler)
        
        return [titleSortAction.type: titleSortAction, recentlyAddedSortAction.type: recentlyAddedSortAction]
    }()
    
    lazy var sortAlert: UIAlertController = {
        return alert(title: WMFLocalizedString("reading-lists-sort-saved-articles", value: "Sort saved articles", comment: "Title of the alert that allows sorting saved articles."), message: nil)
    }()
    
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
        ReadingListsFunnel.shared.logReadStartIReadingList(articleURL)
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let _ = editController.isClosed
    }
    
    internal func didPerformBatchEditToolbarAction(_ action: BatchEditToolbarAction) -> Bool {
        guard let selectedIndexPaths = collectionView.indexPathsForSelectedItems else {
            return false
        }
        
        let entries = selectedIndexPaths.compactMap({ entry(at: $0) })
        let articles = selectedIndexPaths.compactMap({ article(at: $0) })
        
        switch action.type {
        case .addTo:
            let addArticlesToReadingListViewController = AddArticlesToReadingListViewController(with: dataStore, articles: articles, theme: theme)
            let navigationController = WMFThemeableNavigationController(rootViewController: addArticlesToReadingListViewController, theme: theme)
            navigationController.isNavigationBarHidden = true
            addArticlesToReadingListViewController.delegate = self
            present(navigationController, animated: true)
            return true
        case .remove:
            delete(entries)
            return true
        case .moveTo:
            let addArticlesToReadingListViewController = AddArticlesToReadingListViewController(with: dataStore, articles: articles, moveFromReadingList: readingList, theme: theme)
            let navigationController = WMFThemeableNavigationController(rootViewController: addArticlesToReadingListViewController, theme: theme)
            navigationController.isNavigationBarHidden = true
            addArticlesToReadingListViewController.delegate = self
            present(navigationController, animated: true)
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
        delete([entry], indexPath: indexPath)
    }
    
    private func delete(_ entries: [ReadingListEntry], indexPath: IndexPath? = nil) {
        var url: URL? = nil
        if let indexPath = indexPath, let articleURL = articleURL(at: indexPath) {
            url = articleURL
        }
        let entriesCount = entries.count
        do {
            try dataStore.readingListsController.remove(entries: entries)
            UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: CommonStrings.articleDeletedNotification(articleCount: entriesCount))
        } catch let err {
            DDLogError("Error removing entries from a reading list: \(err)")
        }
        guard let articleURL = url, dataStore.savedPageList.entry(for: articleURL) == nil else {
            return
        }
        ReadingListsFunnel.shared.logUnsaveInReadingList(articlesCount: entriesCount, language: url?.wmf_language)
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
    
    func newEditingState(for currentEditingState: EditingState, fromEditBarButtonWithSystemItem systemItem: UIBarButtonItem.SystemItem) -> EditingState {
        let newEditingState: EditingState
        
        switch currentEditingState {
        case .open:
            newEditingState = .closed
        case .swiping:
            newEditingState = .open
        case .editing where systemItem == .cancel:
            newEditingState = .cancelled
        case .editing where systemItem == .done:
            newEditingState = .done
        case .empty:
            newEditingState = .editing
        default:
            newEditingState = .open
        }
        
        return newEditingState
    }
    
    func didChangeEditingState(from oldEditingState: EditingState, to newEditingState: EditingState, rightBarButton: UIBarButtonItem?, leftBarButton: UIBarButtonItem?) {
        navigationItem.rightBarButtonItem = rightBarButton
        navigationItem.rightBarButtonItem?.tintColor = theme.colors.link // no need to do a whole apply(theme:) pass
        
        if displayType == .pushed {
            navigationItem.leftBarButtonItem = leftBarButton
            navigationItem.leftBarButtonItem?.tintColor = theme.colors.link
        }
        
        switch newEditingState {
        case .editing:
            fallthrough
        case .open where isEmpty:
            readingListDetailUnderBarViewController.beginEditing()
        case .done:
            readingListDetailUnderBarViewController.finishEditing()
        case .closed where isEmpty:
            fallthrough
        case .cancelled:
            readingListDetailUnderBarViewController.cancelEditing()
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
        readingListDetailUnderBarViewController.reconfigureAlert(for: readingList)
        for indexPath in collectionView.indexPathsForVisibleItems {
            guard let cell = collectionView.cellForItem(at: indexPath) as? SavedArticlesCollectionViewCell else {
                continue
            }
            configure(cell: cell, forItemAt: indexPath, layoutOnly: false)
        }
        updateEmptyState()
        readingListDetailUnderBarViewController.updateArticleCount(readingList.countOfEntries)
        collectionView.setNeedsLayout()
    }
    
    func collectionViewUpdater<T>(_ updater: CollectionViewUpdater<T>, updateItemAtIndexPath indexPath: IndexPath, in collectionView: UICollectionView) where T : NSFetchRequestResult {
        
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
        
        cell.configureAlert(for: entry, with: article, in: readingList, listLimit: dataStore.viewContext.wmf_readingListsConfigMaxListsPerUser, entryLimit: dataStore.viewContext.wmf_readingListsConfigMaxEntriesPerList.intValue)
        cell.configure(article: article, index: indexPath.item, shouldShowSeparators: true, theme: theme, layoutOnly: layoutOnly)
        
        cell.isBatchEditable = true
        cell.layoutMargins = layout.itemLayoutMargins
        editController.configureSwipeableCell(cell, forItemAt: indexPath, layoutOnly: layoutOnly)
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        editController.deconfigureSwipeableCell(cell, forItemAt: indexPath)
    }
}

// MARK: - UIViewControllerPreviewingDelegate

extension ReadingListDetailViewController {
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

// MARK: - ReadingListDetailUnderBarViewControllerDelegate

extension ReadingListDetailViewController: ReadingListDetailUnderBarViewControllerDelegate {
    func readingListDetailUnderBarViewController(_ underBarViewController: ReadingListDetailUnderBarViewController, didEdit name: String?, description: String?) {
        dataStore.readingListsController.updateReadingList(readingList, with: name, newDescription: description)
        title = name
    }
    
    func readingListDetailUnderBarViewController(_ underBarViewController: ReadingListDetailUnderBarViewController, didBeginEditing textField: UITextField) {
        editController.isTextEditing = true
    }
    
    func readingListDetailUnderBarViewController(_ underBarViewController: ReadingListDetailUnderBarViewController, titleTextFieldTextDidChange textField: UITextField) {
        navigationItem.rightBarButtonItem?.isEnabled = textField.text?.wmf_hasNonWhitespaceText ?? false
    }
    
    func readingListDetailUnderBarViewController(_ underBarViewController: ReadingListDetailUnderBarViewController, titleTextFieldWillClear textField: UITextField) {
        navigationItem.rightBarButtonItem?.isEnabled = false
    }

}

// MARK: - SearchBarExtendedViewControllerDataSource

extension ReadingListDetailViewController: SearchBarExtendedViewControllerDataSource {
    func returnKeyType(for searchBar: UISearchBar) -> UIReturnKeyType {
        return .search
    }
    
    func placeholder(for searchBar: UISearchBar) -> String? {
        return WMFLocalizedString("search-reading-list-placeholder-text", value: "Search reading list", comment: "Placeholder text for the search bar in reading list detail view.")
    }
    
    func isSeparatorViewHidden(above searchBar: UISearchBar) -> Bool {
        return true
    }
}
// MARK: - SearchBarExtendedViewControllerDelegate

extension ReadingListDetailViewController: SearchBarExtendedViewControllerDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        updateSearchString(searchText)
        
        if searchText.isEmpty {
            makeSearchBarResignFirstResponder(searchBar)
        }
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        makeSearchBarResignFirstResponder(searchBar)
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        setNavigationBarHidingEnabled(false)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        makeSearchBarResignFirstResponder(searchBar)
    }
    
    private func makeSearchBarResignFirstResponder(_ searchBar: UISearchBar) {
        searchBar.text = ""
        updateSearchString("")
        searchBar.resignFirstResponder()
        setNavigationBarHidingEnabled(true)
    }
    
    func textStyle(for button: UIButton) -> DynamicTextStyle {
        return .body
    }
    
    func buttonType(for button: UIButton, currentButtonType: SearchBarExtendedViewButtonType?) -> SearchBarExtendedViewButtonType? {
        switch currentButtonType {
        case nil:
            return .sort
        case .cancel?:
            return .sort
        case .sort?:
            return .cancel
        }
    }
    
    func buttonWasPressed(_ button: UIButton, buttonType: SearchBarExtendedViewButtonType?, searchBar: UISearchBar) {
        guard let buttonType = buttonType else {
            return
        }
        switch buttonType {
        case .sort:
            presentSortAlert(from: button)
        case .cancel:
            makeSearchBarResignFirstResponder(searchBar)
        }
    }
}

extension ReadingListDetailViewController: EventLoggingEventValuesProviding {
    var eventLoggingLabel: EventLoggingLabel? {
        return nil
    }
    
    var eventLoggingCategory: EventLoggingCategory {
        return EventLoggingCategory.saved
    }
}
