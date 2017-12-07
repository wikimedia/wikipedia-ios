import UIKit

class ReadingListDetailExtendedNavBarView: UIView {
    
}

class ReadingListDetailCollectionViewController: ColumnarCollectionViewController {
    
    fileprivate let dataStore: MWKDataStore
    fileprivate var fetchedResultsController: NSFetchedResultsController<ReadingListEntry>!
    fileprivate let readingList: ReadingList
    fileprivate var collectionViewUpdater: CollectionViewUpdater<ReadingListEntry>!
    fileprivate var cellLayoutEstimate: WMFLayoutEstimate?
    fileprivate let reuseIdentifier = "ReadingListDetailCollectionViewCell"
    
    var editController: CollectionViewEditController!

    init(for readingList: ReadingList, with dataStore: MWKDataStore) {
        self.readingList = readingList
        self.dataStore = dataStore
        super.init()
    }
    
    func setupFetchedResultsControllerOrdered(by key: String, ascending: Bool) {
        let request: NSFetchRequest<ReadingListEntry> = ReadingListEntry.fetchRequest()
        request.predicate = NSPredicate(format: "list == %@", readingList)
        request.sortDescriptors = [NSSortDescriptor(key: key, ascending: ascending)]
        fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: dataStore.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        do {
            try fetchedResultsController.performFetch()
        } catch let error {
            DDLogError("Error fetching reading list entries: \(error)")
        }
        collectionView?.reloadData()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not supported")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupFetchedResultsControllerOrdered(by: "displayTitle", ascending: true)
        collectionViewUpdater = CollectionViewUpdater(fetchedResultsController: fetchedResultsController, collectionView: collectionView!)
        collectionViewUpdater?.delegate = self
        
        register(SavedArticleCollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier, addPlaceholder: true)
        
        guard let collectionView = collectionView else {
            return
        }
        editController = CollectionViewEditController(collectionView: collectionView)
        editController.delegate = self
        editController.navigationDelegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateEmptyState()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        editController.close()
    }
    
    fileprivate func entry(at indexPath: IndexPath) -> ReadingListEntry? {
        guard let sections = fetchedResultsController.sections,
            indexPath.section < sections.count,
            indexPath.item < sections[indexPath.section].numberOfObjects else {
                return nil
        }
        return fetchedResultsController.object(at: indexPath)
    }
    
    fileprivate func articleURL(at indexPath: IndexPath) -> URL? {
        guard let entry = entry(at: indexPath), let key = entry.articleKey else {
            assertionFailure("Can't get articleURL")
            return nil
        }
        return URL(string: key)
    }
    
    fileprivate func article(at indexPath: IndexPath) -> WMFArticle? {
        guard let entry = entry(at: indexPath), let key = entry.articleKey, let article = dataStore.fetchArticle(withKey: key) else {
            return nil
        }
        return article
    }
    
    // MARK: - Empty state
    
    fileprivate var isEmpty = true {
        didSet {
            editController.isCollectionViewEmpty = isEmpty
        }
    }
    
    fileprivate final func updateEmptyState() {
        guard let collectionView = self.collectionView else {
            return
        }
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
    
    // MARK: - Theme
    
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
        let toolbarHeight: CGFloat = 50
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: view.bounds.height - toolbarHeight, width: view.bounds.width, height: toolbarHeight))
        toolbar.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return toolbar
    }()

}

// MARK: - ActionDelegate

extension ReadingListDetailCollectionViewController: ActionDelegate {
    
    fileprivate func batchEditAction(at indexPath: IndexPath) -> BatchEditAction {
        return BatchEditActionType.select.action(with: self, indexPath: indexPath)
    }
    
    internal func didBatchSelect(_ action: BatchEditAction) -> Bool {
        let indexPath = action.indexPath
        
        switch action.type {
        case .select:
            select(at: indexPath)
            UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, WMFLocalizedString("item-selected-accessibility-notification", value: "Item selected", comment: "Notification spoken after user batch selects an item from the list."))
            return true
        }
    }
    
    fileprivate func select(at indexPath: IndexPath) {
        let isSelected = collectionView?.cellForItem(at: indexPath)?.isSelected ?? false
        
        if isSelected {
            collectionView?.deselectItem(at: indexPath, animated: true)
        } else {
            collectionView?.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? BatchEditableCell,  cell.batchEditingState != .open  else {
            return
        }
        guard let articleURL = articleURL(at: indexPath) else {
            collectionView.deselectItem(at: indexPath, animated: true)
            return
        }
        wmf_pushArticle(with: articleURL, dataStore: dataStore, theme: theme, animated: true)
    }
    
    internal func didPerformBatchEditToolbarAction(_ action: BatchEditToolbarAction) -> Bool {
        guard let collectionView = collectionView, let selectedIndexPaths = collectionView.indexPathsForSelectedItems else {
            return false
        }
        
        let entries = selectedIndexPaths.flatMap({ entry(at: $0) })
        let articles = selectedIndexPaths.flatMap({ article(at: $0) })
        
        switch action.type {
        case .update:
            print("Update")
            return true
        case .addToList:
            let addArticlesToReadingListViewController = AddArticlesToReadingListViewController(with: dataStore, articles: articles, theme: theme)
            addArticlesToReadingListViewController.delegate = self
            present(addArticlesToReadingListViewController, animated: true, completion: nil)
            return true
        case .unsave:
            delete(entries)
            UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, CommonStrings.accessibilityUnsavedNotification)
            return true
        default:
            break
        }
        return false
    }
    
    fileprivate func delete(at indexPath: IndexPath) {
        guard let entry = entry(at: indexPath) else {
            return
        }
        do {
            try dataStore.readingListsController.remove(entries: [entry], from: readingList)
        } catch let err {
            DDLogError("Error removing entry from a reading list: \(err)")
        }
    }
    
    fileprivate func delete(_ entries: [ReadingListEntry]) {
        do {
            try dataStore.readingListsController.remove(entries: entries, from: readingList)
        } catch let err {
            DDLogError("Error removing entries from a reading list: \(err)")
        }
    }
    
    func didPerformAction(_ action: Action) -> Bool {
        let indexPath = action.indexPath
        defer {
            if let cell = collectionView?.cellForItem(at: indexPath) as? ArticleRightAlignedImageCollectionViewCell {
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
                    let cell = collectionView?.cellForItem(at: indexPath)
                    viewController.popoverPresentationController?.sourceView = cell ?? view
                    viewController.popoverPresentationController?.sourceRect = cell?.bounds ?? view.bounds
                }
                present(viewController, animated: true, completion: nil)
                return true
            }
        }
        return false
    }
    
    fileprivate func canSave(at indexPath: IndexPath) -> Bool {
        guard let articleURL = articleURL(at: indexPath) else {
            return false
        }
        return !dataStore.savedPageList.isSaved(articleURL)
    }
    
    func availableActions(at indexPath: IndexPath) -> [Action] {
        var actions: [Action] = []
        
        if canSave(at: indexPath) {
            actions.append(ActionType.save.action(with: self, indexPath: indexPath))
        } else {
            actions.append(ActionType.unsave.action(with: self, indexPath: indexPath))
        }
        
        if articleURL(at: indexPath) != nil {
            actions.append(ActionType.share.action(with: self, indexPath: indexPath))
        }

        actions.append(ActionType.delete.action(with: self, indexPath: indexPath))
        
        return actions
    }
}

// MARK: - BatchEditNavigationDelegate

extension ReadingListDetailCollectionViewController: BatchEditNavigationDelegate {
    func changeRightNavButton(to button: UIBarButtonItem) {
        navigationItem.rightBarButtonItem = button
    }
    
    func didSetIsBatchEditToolbarVisible(_ isVisible: Bool) {
        tabBarController?.tabBar.isHidden = isVisible
    }
    
    func createBatchEditToolbar(with items: [UIBarButtonItem], add: Bool) {
        if add {
            batchEditToolbar.items = items
            view.addSubview(batchEditToolbar)
        } else {
            batchEditToolbar.removeFromSuperview()
        }
    }
}

// MARK: - AddArticlesToReadingListViewControllerDelegate

extension ReadingListDetailCollectionViewController: AddArticlesToReadingListViewControllerDelegate {
    func viewControllerWillBeDismissed() {
        editController.close()
    }
}

// MARK: - CollectionViewUpdaterDelegate

extension ReadingListDetailCollectionViewController: CollectionViewUpdaterDelegate {
    func collectionViewUpdater<T>(_ updater: CollectionViewUpdater<T>, didUpdate collectionView: UICollectionView) {
        for indexPath in collectionView.indexPathsForVisibleItems {
            guard let cell = collectionView.cellForItem(at: indexPath) as? ReadingListCollectionViewCell else {
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

extension ReadingListDetailCollectionViewController {
    override func collectionView(_ collectionView: UICollectionView, estimatedHeightForItemAt indexPath: IndexPath, forColumnWidth columnWidth: CGFloat) -> WMFLayoutEstimate {
        // The layout estimate can be re-used in this case becuause both labels are one line, meaning the cell
        // size only varies with font size. The layout estimate is nil'd when the font size changes on trait collection change
        if let estimate = cellLayoutEstimate {
            return estimate
        }
        var estimate = WMFLayoutEstimate(precalculated: false, height: 60)
        guard let placeholderCell = placeholder(forCellWithReuseIdentifier: reuseIdentifier) as? SavedArticleCollectionViewCell else {
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

extension ReadingListDetailCollectionViewController {
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
        guard let savedArticleCell = cell as? SavedArticleCollectionViewCell else {
            return cell
        }
        configure(cell: savedArticleCell, forItemAt: indexPath, layoutOnly: false)
        return cell
    }
    
    fileprivate func configure(cell: SavedArticleCollectionViewCell, forItemAt indexPath: IndexPath, layoutOnly: Bool) {
        cell.batchEditAction = batchEditAction(at: indexPath)
    
        guard let collectionView = self.collectionView else {
            return
        }
        
        guard let entry = entry(at: indexPath), let articleKey = entry.articleKey else {
            assertionFailure("Coudn't get a reading list entry or an article key to configure the cell")
            return
        }
        
        guard let article = dataStore.fetchArticle(withKey: articleKey) else {
            assertionFailure("Coudn't fetch an article with \(articleKey) articleKey")
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

// MARK: - UIViewControllerPreviewingDelegate

extension ReadingListDetailCollectionViewController {
    override func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard !editController.isActive else {
            return nil // don't allow 3d touch when swipe actions are active
        }
        guard let collectionView = collectionView,
            let indexPath = collectionView.indexPathForItem(at: location),
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

// MARK: - Analytics

extension ReadingListDetailCollectionViewController: AnalyticsContextProviding, AnalyticsViewNameProviding {
    var analyticsName: String {
        return "ReadingListDetailView"
    }
    
    var analyticsContext: String {
        return analyticsName
    }
}
