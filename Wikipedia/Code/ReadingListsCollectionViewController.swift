import Foundation

@objc(WMFReadingListsCollectionViewController)
class ReadingListsCollectionViewController: ColumnarCollectionViewController {
    
    let dataStore: MWKDataStore
    let managedObjectContext: NSManagedObjectContext
    let readingListsController: ReadingListsController
    var fetchedResultsController: NSFetchedResultsController<ReadingList>!
    var collectionViewUpdater: CollectionViewUpdater<ReadingList>!
    
    var cellLayoutEstimate: WMFLayoutEstimate?
    
    var editController: CollectionViewEditController!

    fileprivate let reuseIdentifier = "ReadingListsCollectionViewCell"

    func setupFetchedResultsControllerOrdered(by key: String, ascending: Bool) {
        let request: NSFetchRequest<ReadingList> = ReadingList.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: key, ascending: ascending)]
        fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        do {
            try fetchedResultsController.performFetch()
        } catch let error {
            DDLogError("Error fetching reading lists: \(error)")
        }
        collectionView?.reloadData()
    }
    
    init(with dataStore: MWKDataStore) {
        self.dataStore = dataStore
        self.managedObjectContext = dataStore.viewContext
        self.readingListsController = dataStore.readingListsController
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not supported")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupFetchedResultsControllerOrdered(by: "name", ascending: true)
        collectionViewUpdater = CollectionViewUpdater(fetchedResultsController: fetchedResultsController, collectionView: collectionView!)
        collectionViewUpdater?.delegate = self

        register(SavedCollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier, addPlaceholder: true)
        
        guard let collectionView = collectionView else {
            return
        }
        editController = CollectionViewEditController(collectionView: collectionView)
        editController.delegate = self
        // Remove peek & pop for now
        unregisterForPreviewing()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateEmptyState()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        editController.close()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        cellLayoutEstimate = nil
    }
    
    func readingList(at indexPath: IndexPath) -> ReadingList? {
        guard let sections = fetchedResultsController.sections,
            indexPath.section < sections.count,
            indexPath.item < sections[indexPath.section].numberOfObjects else {
                return nil
        }
        return fetchedResultsController.object(at: indexPath)
    }
    
    @objc func presentCreateReadingListViewController() {
        let createReadingListViewController = CreateReadingListViewController(theme: self.theme)
        createReadingListViewController.delegate = self
        present(createReadingListViewController, animated: true, completion: nil)
    }
    
    open func configure(cell: SavedCollectionViewCell, forItemAt indexPath: IndexPath, layoutOnly: Bool) {
        guard let collectionView = self.collectionView else {
            return
        }
        guard let readingList = readingList(at: indexPath) else {
            return
        }
        
        cell.actions = availableActions(at: indexPath)
        cell.isBatchEditable = true
        let numberOfItems = self.collectionView(collectionView, numberOfItemsInSection: indexPath.section)
        cell.configure(readingList: readingList, index: indexPath.item, count: numberOfItems, shouldAdjustMargins: false, shouldShowSeparators: true, theme: theme)
        cell.layoutMargins = layout.readableMargins
        
        guard let translation = editController.swipeTranslationForItem(at: indexPath) else {
            return
        }
        cell.swipeTranslation = translation
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
            wmf_showEmptyView(of: WMFEmptyViewType.noReadingLists, theme: theme)
        } else {
            wmf_hideEmptyView()
        }
    }
    
    // MARK: - Batch editing
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard editController.batchEditingState != .open else {
            editController.didTapCellWhileBatchEditing()
            return
        }
        guard let readingList = readingList(at: indexPath) else {
            return
        }
        let readingListDetailCollectionViewController = ReadingListDetailCollectionViewController(for: readingList, with: dataStore)
        readingListDetailCollectionViewController.apply(theme: theme)
        wmf_push(readingListDetailCollectionViewController, animated: true)
    }
    
    override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if editController.batchEditingState == .open {
            editController.didTapCellWhileBatchEditing()
        }
    }
    
    lazy var availableBatchEditToolbarActions: [BatchEditToolbarAction] = {
        let updateItem = BatchEditToolbarActionType.update.action(with: self)
        let deleteItem = BatchEditToolbarActionType.delete.action(with: self)
        return [updateItem, deleteItem]
    }()
    
}

// MARK: - CreateReadingListViewControllerDelegate

extension ReadingListsCollectionViewController: CreateReadingListDelegate {
    func createdNewReadingList(in controller: CreateReadingListViewController, with name: String, description: String?) {
        do {
            let _ = try readingListsController.createReadingList(named: name, description: description)
            controller.dismiss(animated: true, completion: nil)
        } catch let err {
            print(err)
            // show error
        }
    }
}

// MARK: - UICollectionViewDataSource
extension ReadingListsCollectionViewController {
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
        guard let readingListCell = cell as? SavedCollectionViewCell else {
            return cell
        }
        configure(cell: readingListCell, forItemAt: indexPath, layoutOnly: false)
        return cell
    }
}

// MARK: - CollectionViewUpdaterDelegate
extension ReadingListsCollectionViewController: CollectionViewUpdaterDelegate {
    func collectionViewUpdater<T>(_ updater: CollectionViewUpdater<T>, didUpdate collectionView: UICollectionView) {
        for indexPath in collectionView.indexPathsForVisibleItems {
            guard let cell = collectionView.cellForItem(at: indexPath) as? SavedCollectionViewCell else {
                continue
            }
            cell.configureSeparators(for: indexPath.item)
            cell.actions = availableActions(at: indexPath)
        }
        updateEmptyState()
        collectionView.setNeedsLayout()
    }
    
}

// MARK: - ActionDelegate
extension ReadingListsCollectionViewController: ActionDelegate {
    
    func didPerformBatchEditToolbarAction(_ action: BatchEditToolbarAction) -> Bool {
        guard let collectionView = collectionView, let selectedIndexPaths = collectionView.indexPathsForSelectedItems else {
            return false
        }
        
        let readingLists: [ReadingList] = selectedIndexPaths.flatMap({ readingList(at: $0) })
        let articlesCount = readingLists.flatMap({ $0.entries?.count }).reduce( 0, + )
        
        switch action.type {
        case .update:
            print("Update")
            return true
        case .delete:
            let title = "Delete reading lists and all of their saved articles?"
            let message = "Your \(readingLists.count) lists and \(articlesCount) articles will be deleted"
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
                alert.dismiss(animated: true, completion: nil)
            })
            let deleteAction = UIAlertAction(title: "Delete", style: .destructive, handler: { (action) in
                do {
                    try self.readingListsController.delete(readingLists: readingLists)
                } catch let err {
                    print(err)
                    // do something
                }
            })
            alert.addAction(cancelAction)
            alert.addAction(deleteAction)
            present(alert, animated: true, completion: nil)
            return true
        default:
            break
        }
        return false
    }
    
    func didPerformAction(_ action: Action) -> Bool {
        let indexPath = action.indexPath
        guard let readingList = readingList(at: indexPath) else {
            return false
        }
        switch action.type {
        case .delete:
            do {
            try readingListsController.delete(readingLists: [readingList])
            } catch let err {
                print(err)
                // do something
            }
            UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, WMFLocalizedString("reading-list-deleted-accessibility-notification", value: "Reading list deleted", comment: "Notification spoken after user deletes a reading list from the list."))
            return true
        default:
            return false
        }
    }
    
    func availableActions(at indexPath: IndexPath) -> [Action] {
        return [ActionType.delete.action(with: self, indexPath: indexPath)]
    }

}

// MARK: - WMFColumnarCollectionViewLayoutDelegate
extension ReadingListsCollectionViewController {
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
