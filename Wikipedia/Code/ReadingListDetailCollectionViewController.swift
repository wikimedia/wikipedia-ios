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
        
        defer {
            apply(theme: theme)
        }
        
        setupFetchedResultsControllerOrdered(by: "displayTitle", ascending: true)
        collectionViewUpdater = CollectionViewUpdater(fetchedResultsController: fetchedResultsController, collectionView: collectionView!)
        collectionViewUpdater?.delegate = self
        
        register(SavedArticleCollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier, addPlaceholder: true)
        
        guard let collectionView = collectionView else {
            return
        }
        editController = CollectionViewEditController(collectionView: collectionView)
        editController.delegate = self
        
        navigationController?.navigationBar.topItem?.title = "Back"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: nil)
    }
    
    fileprivate func entry(at indexPath: IndexPath) -> ReadingListEntry? {
        guard let sections = fetchedResultsController.sections,
            indexPath.section < sections.count,
            indexPath.item < sections[indexPath.section].numberOfObjects else {
                return nil
        }
        return fetchedResultsController.object(at: indexPath)
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
    
    // MARK: - Batch editing (parts that cannot be in an extension)
    
    lazy var availableBatchEditToolbarActions: [BatchEditToolbarAction] = {
        let updateItem = BatchEditToolbarActionType.update.action(with: self)
        let addToListItem = BatchEditToolbarActionType.addToList.action(with: self)
        let unsaveItem = BatchEditToolbarActionType.unsave.action(with: self)
        return [updateItem, addToListItem, unsaveItem]
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
        super.collectionView(collectionView, didSelectItemAt: indexPath)
    }
    
    
    func didPerformBatchEditToolbarAction(_ action: BatchEditToolbarAction) -> Bool {
        return false
    }
    
    func didPerformAction(_ action: Action) -> Bool {
        return false
    }
    
    func availableActions(at indexPath: IndexPath) -> [Action] {
        return [ActionType.unsave.action(with: self, indexPath: indexPath), ActionType.share.action(with: self, indexPath: indexPath), ActionType.delete.action(with: self, indexPath: indexPath)]
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
