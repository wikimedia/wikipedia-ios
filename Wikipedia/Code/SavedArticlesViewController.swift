
@objc(WMFSavedArticlesViewController)
class SavedArticlesViewController: ColumnarCollectionViewController {
    fileprivate let reuseIdentifier = "SavedArticlesCollectionViewCell"
    
    fileprivate var fetchedResultsController: NSFetchedResultsController<WMFArticle>!
    fileprivate var collectionViewUpdater: CollectionViewUpdater<WMFArticle>!
    fileprivate var cellLayoutEstimate: WMFLayoutEstimate?
    var editController: CollectionViewEditController!
    
    var dataStore: MWKDataStore!
    
    fileprivate func setupFetchedResultsController(with dataStore: MWKDataStore) {
        let articleRequest = WMFArticle.fetchRequest()
        let basePredicate = NSPredicate(format: "savedDate != NULL")
        articleRequest.predicate = basePredicate
        if let searchString = searchString {
            let searchPredicate = NSPredicate(format: "(displayTitle CONTAINS[cd] '\(searchString)') OR (snippet CONTAINS[cd] '\(searchString)')")
            articleRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [basePredicate, searchPredicate])
        }
        articleRequest.sortDescriptors = [sortDescriptor]
        fetchedResultsController = NSFetchedResultsController(fetchRequest: articleRequest, managedObjectContext: dataStore.viewContext, sectionNameKeyPath: nil, cacheName: nil)
    }
    
    // MARK - View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        register(SavedCollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier, addPlaceholder: true)
        
        setupFetchedResultsController(with: dataStore)
        collectionViewUpdater = CollectionViewUpdater(fetchedResultsController: fetchedResultsController, collectionView: collectionView)
        collectionViewUpdater?.delegate = self
        
        editController = CollectionViewEditController(collectionView: collectionView)
        editController.delegate = self
    }
    
    fileprivate var isFirstAppearance = true
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard isFirstAppearance else {
            return
        }
        isFirstAppearance = false
        do {
            try fetchedResultsController.performFetch()
        } catch let error {
            DDLogError("Error fetching articles for \(self): \(error)")
        }
        collectionView.reloadData()
        updateEmptyState()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        PiwikTracker.sharedInstance()?.wmf_logView(self)
        NSUserActivity.wmf_makeActive(NSUserActivity.wmf_savedPagesView())
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        editController.close()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        cellLayoutEstimate = nil
    }
    
    // MARK: - Empty state
    
    var isEmpty = true {
        didSet {
            editController.isCollectionViewEmpty = isEmpty
        }
    }
    
    fileprivate final func updateEmptyState() {
        let sectionCount = numberOfSections(in: collectionView)
        
        isEmpty = true
        for sectionIndex in 0..<sectionCount {
            if self.collectionView(collectionView, numberOfItemsInSection: sectionIndex) > 0 {
                isEmpty = false
                break
            }
        }
        if isEmpty {
            wmf_showEmptyView(of: WMFEmptyViewType.noSavedPages, theme: theme)
        } else {
            wmf_hideEmptyView()
        }
    }
    
    // MARK: - Sorting
    
    fileprivate var sortDescriptor: NSSortDescriptor = NSSortDescriptor(key: "savedDate", ascending: false) {
        didSet {
            guard sortDescriptor != oldValue else {
                return
            }
            setupCollectionViewUpdaterAndFetch()
        }
    }
    
    fileprivate func setupCollectionViewUpdaterAndFetch() {
        setupFetchedResultsController(with: dataStore)
        collectionViewUpdater = CollectionViewUpdater(fetchedResultsController: fetchedResultsController, collectionView: collectionView)
        collectionViewUpdater.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch let err {
            assertionFailure("Couldn't sort by \(sortDescriptor.key ?? "unknown key"): \(err)")
        }
        collectionView.reloadData()
    }
    
    fileprivate func sort(by key: String, ascending: Bool) {
        sortDescriptor = NSSortDescriptor(key: key, ascending: ascending)
    }
    
    // MARK: - Filtering
    
    fileprivate var searchString: String? {
        didSet {
            guard searchString != oldValue else {
                return
            }
            setupCollectionViewUpdaterAndFetch()
        }
    }
    
    fileprivate func articleURL(at indexPath: IndexPath) -> URL? {
        return article(at: indexPath)?.url
    }
    
    fileprivate func article(at indexPath: IndexPath) -> WMFArticle? {
        guard let sections = fetchedResultsController.sections,
            indexPath.section < sections.count,
            indexPath.item < sections[indexPath.section].numberOfObjects else {
                return nil
        }
        return fetchedResultsController.object(at: indexPath)
    }
    
    fileprivate func readingListsForArticle(at indexPath: IndexPath) -> [ReadingList] {
        let request: NSFetchRequest<ReadingListEntry> = ReadingListEntry.fetchRequest()
        let moc = dataStore.viewContext
        do {
            let entries = try moc.fetch(request)
            let articleKey = article(at: indexPath)?.key
            let readingLists = entries.filter { $0.articleKey == articleKey }.flatMap { $0.list }
            return readingLists
        } catch let err {
            print(err)
        }
        return []
    }
    
    fileprivate func delete(at indexPath: IndexPath) {
        guard let articleURL = self.articleURL(at: indexPath) else {
            return
        }
        dataStore.savedPageList.removeEntry(with: articleURL)
    }
    
    // MARK: - Themeable
    
    override func apply(theme: Theme) {
        super.apply(theme: theme)
        if wmf_isShowingEmptyView() {
            updateEmptyState()
        }
        batchEditToolbar.barTintColor = theme.colors.paperBackground
        batchEditToolbar.tintColor = theme.colors.link
    }
    
    // MARK: - Batch editing (parts that cannot be in an extension)
    
    lazy var availableBatchEditToolbarActions: [BatchEditToolbarAction] = {
        let updateItem = BatchEditToolbarActionType.update.action(with: self)
        let addToListItem = BatchEditToolbarActionType.addToList.action(with: self)
        let unsaveItem = BatchEditToolbarActionType.unsave.action(with: self)
        return [updateItem, addToListItem, unsaveItem]
    }()
    
    internal lazy var batchEditToolbar: UIToolbar = {
        let toolbar = UIToolbar()
        let height: CGFloat = 50
        toolbar.frame = CGRect(x: 0, y: view.bounds.height - height, width: view.bounds.width, height: height)
        toolbar.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        return toolbar
    }()
    
    
}

// MARK: - CollectionViewUpdaterDelegate

extension SavedArticlesViewController: CollectionViewUpdaterDelegate {
    func collectionViewUpdater<T>(_ updater: CollectionViewUpdater<T>, didUpdate collectionView: UICollectionView) {
        for indexPath in collectionView.indexPathsForVisibleItems {
            guard let cell = collectionView.cellForItem(at: indexPath) as? ArticleRightAlignedImageCollectionViewCell else {
                continue
            }
            cell.configureSeparators(for: indexPath.item)
            cell.actions = availableActions(at: indexPath)
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
        guard let placeholderCell = placeholder(forCellWithReuseIdentifier: reuseIdentifier) as? SavedCollectionViewCell else {
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
        return WMFCVLMetrics.singleColumnMetrics(withBoundsSize: size, readableWidth: readableWidth,  collapseSectionSpacing:true)
    }
}

// MARK: - UICollectionViewDataSource

extension SavedArticlesViewController {
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        guard let sectionsCount = self.fetchedResultsController.sections?.count else {
            return 0
        }
        return sectionsCount
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let sections = self.fetchedResultsController.sections, section < sections.count else {
            return 0
        }
        return sections[section].numberOfObjects
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
        guard let savedArticleCell = cell as? SavedCollectionViewCell else {
            return cell
        }
        configure(cell: savedArticleCell, forItemAt: indexPath, layoutOnly: false)
        return cell
    }
    
    fileprivate func configure(cell: SavedCollectionViewCell, forItemAt indexPath: IndexPath, layoutOnly: Bool) {
        cell.isBatchEditable = true
        
        guard let article = article(at: indexPath) else {
            return
        }
        
        let numberOfItems = self.collectionView(collectionView, numberOfItemsInSection: indexPath.section)
        
        cell.configure(article: article, index: indexPath.item, count: numberOfItems, shouldAdjustMargins: false, shouldShowSeparators: true, theme: theme, layoutOnly: layoutOnly)
        cell.actions = availableActions(at: indexPath)
        cell.layoutMargins = layout.readableMargins
        
        guard !layoutOnly, let translation = editController.swipeTranslationForItem(at: indexPath) else {
            return
        }
        cell.swipeTranslation = translation
    }
}

// MARK: - ActionDelegate

extension SavedArticlesViewController: ActionDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard !editController.isOpen else {
            return
        }
        guard let articleURL = articleURL(at: indexPath) else {
            return
        }
        wmf_pushArticle(with: articleURL, dataStore: dataStore, theme: theme, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let _ = editController.isOpen
    }
    
    internal func didPerformBatchEditToolbarAction(_ action: BatchEditToolbarAction) -> Bool {
        guard let selectedIndexPaths = collectionView.indexPathsForSelectedItems else {
            return false
        }
        
        let articleURLs = selectedIndexPaths.flatMap({ articleURL(at: $0) })
        let articles = selectedIndexPaths.flatMap({ article(at: $0) })
        
        switch action.type {
        case .update:
            print("Update")
            return false
        case .addToList:
            let addArticlesToReadingListViewController = AddArticlesToReadingListViewController(with: dataStore, articles: articles, theme: theme)
            addArticlesToReadingListViewController.delegate = self
            present(addArticlesToReadingListViewController, animated: true, completion: nil)
            return true
        case .unsave:
            dataStore.savedPageList.removeEntries(with: articleURLs)
            UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, CommonStrings.accessibilityUnsavedNotification)
            return true
        default:
            break
        }
        return false
    }
    
    func didPerformAction(_ action: Action) -> Bool {
        let indexPath = action.indexPath
        defer {
            if let cell = collectionView.cellForItem(at: indexPath) as? ArticleRightAlignedImageCollectionViewCell {
                cell.actions = availableActions(at: indexPath)
            }
        }
        switch action.type {
        case .delete:
            delete(at: indexPath)
            UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, WMFLocalizedString("article-deleted-accessibility-notification", value: "Article deleted", comment: "Notification spoken after user deletes an article from the list."))
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
            let shareActivityController: ShareActivityController?
            if let article = article(at: indexPath) {
                shareActivityController = ShareActivityController(article: article, context: self)
            } else if let articleURL =  self.articleURL(at: indexPath) {
                shareActivityController = ShareActivityController(articleURL: articleURL, userDataStore: dataStore, context: self)
            } else {
                shareActivityController = nil
            }
            if let viewController = shareActivityController {
                if UIDevice.current.userInterfaceIdiom == .pad {
                    let cell = collectionView.cellForItem(at: indexPath)
                    viewController.popoverPresentationController?.sourceView = cell ?? view
                    viewController.popoverPresentationController?.sourceRect = cell?.bounds ?? view.bounds
                }
                present(viewController, animated: true, completion: nil)
                return true
            }
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

// MARK: - SavedViewControllerDelegate

extension SavedArticlesViewController: SavedViewControllerDelegate {
    
    @objc func didPressSortButton() {
        // TODO: Add an option to sort by "recently updated" once we have the key hooked up.
        let alert = UIAlertController(title: "Sort saved articles", message: nil, preferredStyle: .actionSheet)
        let titleAction = UIAlertAction(title: "Title", style: .default) { (actions) in
            self.sort(by: "displayTitle", ascending: true)
        }
        let recentlyAddedAction = UIAlertAction(title: "Recently added", style: .default) { (actions) in
            self.sort(by: "savedDate", ascending: false)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (actions) in
            self.dismiss(animated: true, completion: nil)
        }
        alert.addAction(titleAction)
        alert.addAction(recentlyAddedAction)
        alert.addAction(cancelAction)
        if let popoverController = alert.popoverPresentationController, let first = collectionView.visibleCells.first {
            popoverController.sourceView = first
            popoverController.sourceRect = first.bounds
        }
        present(alert, animated: true, completion: nil)
    }
}

// MARK: - AddArticlesToReadingListDelegate

extension SavedArticlesViewController: AddArticlesToReadingListDelegate {
    func viewControllerWillBeDismissed() {
        editController.close()
    }
    func addedArticleToReadingList(named name: String) {
        editController.close()
    }
}

// MARK: - UIViewControllerPreviewingDelegate

extension SavedArticlesViewController {
    override func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard !editController.isActive else {
            return nil // don't allow 3d touch when swipe actions are active
        }
        guard let indexPath = collectionView.indexPathForItem(at: location),
            let cell = collectionView.cellForItem(at: indexPath) as? ArticleRightAlignedImageCollectionViewCell,
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

// MARK: - UISearchBarDelegate

extension SavedArticlesViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            searchString = nil
            // Calling .resignFirstResponder() directly is not enough. https://stackoverflow.com/a/2823182/4574147
            perform(#selector(dismisKeyboard(for:)), with: searchBar, afterDelay: 0)
        } else {
            searchString = searchText
        }
    }
    
    @objc fileprivate func dismisKeyboard(for searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
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

