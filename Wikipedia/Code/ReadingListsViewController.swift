import Foundation

enum ReadingListsDisplayType {
    case readingListsTab, addArticlesToReadingList
}

protocol ReadingListsViewControllerDelegate: NSObjectProtocol {
    func readingListsViewController(_ readingListsViewController: ReadingListsViewController, didAddArticles articles: [WMFArticle], to readingList: ReadingList)
}

@objc(WMFReadingListsViewController)
class ReadingListsViewController: ColumnarCollectionViewController, EditableCollection, UpdatableCollection {
    private let reuseIdentifier = "ReadingListsViewControllerCell"
    
    typealias T = ReadingList
    let dataStore: MWKDataStore
    let readingListsController: ReadingListsController
    var fetchedResultsController: NSFetchedResultsController<ReadingList>?
    var collectionViewUpdater: CollectionViewUpdater<ReadingList>?
    var editController: CollectionViewEditController!
    private var articles: [WMFArticle] = [] // the articles that will be added to a reading list
    private var readingLists: [ReadingList]? // the displayed reading lists
    private var displayType: ReadingListsDisplayType = .readingListsTab
    public weak var delegate: ReadingListsViewControllerDelegate?
    private var createReadingListViewController: CreateReadingListViewController?
    
    func setupFetchedResultsController() {
        let request: NSFetchRequest<ReadingList> = ReadingList.fetchRequest()
        request.relationshipKeyPathsForPrefetching = ["previewArticles"]
        let isDefaultListEnabled = readingListsController.isDefaultListEnabled
        
        if let readingLists = readingLists, readingLists.count > 0 {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [basePredicate, NSPredicate(format:"self IN %@", readingLists)])
        } else if displayType == .addArticlesToReadingList {
            let commonReadingLists = articles.reduce(articles.first?.readingLists ?? []) { $0.intersection($1.readingLists ?? []) }
            var subpredicates: [NSPredicate] = []
            if commonReadingLists.count > 0 {
                subpredicates.append(NSPredicate(format:"NOT (self IN %@)", commonReadingLists))
            }
            if !isDefaultListEnabled {
                subpredicates.append(NSPredicate(format: "isDefault != YES"))
            }
            subpredicates.append(basePredicate)
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: subpredicates)
        } else {
            var predicate = basePredicate
            if !isDefaultListEnabled {
                predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [NSPredicate(format: "isDefault != YES"), basePredicate])
            }
            request.predicate = predicate
        }
        
        var sortDescriptors = baseSortDescriptors
        sortDescriptors.append(NSSortDescriptor(key: "canonicalName", ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare)))
        request.sortDescriptors = sortDescriptors
        fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: dataStore.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        
        fetch()
    }
    
    func setupCollectionViewUpdater() {
        guard let fetchedResultsController = fetchedResultsController else {
            return
        }
        collectionViewUpdater = CollectionViewUpdater(fetchedResultsController: fetchedResultsController, collectionView: collectionView)
        collectionViewUpdater?.delegate = self
    }
    
    var isShowingDefaultReadingListOnly: Bool {
        guard readingListsController.isDefaultListEnabled else {
            return false
        }
        guard let readingList = readingList(at: IndexPath(item: 0, section: 0)), readingList.isDefault else {
            return false
        }
        return collectionView.numberOfSections == 1 && collectionView(collectionView, numberOfItemsInSection: 0) == 1
    }
    
    var basePredicate: NSPredicate {
        return NSPredicate(format: "isDeletedLocally == NO")
    }
    
    var baseSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \ReadingList.isDefault, ascending: false)]
    }
    
    init(with dataStore: MWKDataStore) {
        self.dataStore = dataStore
        self.readingListsController = dataStore.readingListsController
        super.init()
    }
    
    convenience init(with dataStore: MWKDataStore, articles: [WMFArticle]) {
        self.init(with: dataStore)
        self.articles = articles
        self.displayType = .addArticlesToReadingList
    }
    
    convenience init(with dataStore: MWKDataStore, readingLists: [ReadingList]?) {
        self.init(with: dataStore)
        self.readingLists = readingLists
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not supported")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        register(ReadingListsCollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier, addPlaceholder: true)
        
        emptyViewType = .noReadingLists
        
        setupEditController()
        
        // Remove peek & pop for now
        unregisterForPreviewing()

        isRefreshControlEnabled = true
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
        editController.isShowingDefaultCellOnly = isShowingDefaultReadingListOnly
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        editController.close()
        collectionViewUpdater = nil
        fetchedResultsController = nil
    }
    
    func readingList(at indexPath: IndexPath) -> ReadingList? {
        guard let fetchedResultsController = fetchedResultsController, let sections = fetchedResultsController.sections,
            indexPath.section < sections.count,
            indexPath.item < sections[indexPath.section].numberOfObjects else {
                return nil
        }
        return fetchedResultsController.object(at: indexPath)
    }
    
    // MARK: - Reading list creation
    
    @objc func createReadingList(with articles: [WMFArticle] = [], moveFromReadingList: ReadingList? = nil) {
        createReadingListViewController = CreateReadingListViewController(theme: self.theme, articles: articles, moveFromReadingList: moveFromReadingList)
        guard let createReadingListViewController = createReadingListViewController else {
            assertionFailure("createReadingListViewController is nil")
            return
        }
        createReadingListViewController.delegate = self
        let navigationController = WMFThemeableNavigationController(rootViewController: createReadingListViewController, theme: theme)
        createReadingListViewController.navigationItem.rightBarButtonItem = UIBarButtonItem.wmf_buttonType(WMFButtonType.X, target: self, action: #selector(dismissCreateReadingListViewController))
        present(navigationController, animated: true, completion: nil)
    }
    
    @objc func presentCreateReadingListViewController() {
        createReadingList(with: [])
    }
    
    @objc func dismissCreateReadingListViewController() {
        dismiss(animated: true, completion: nil)
    }
    
    private func handleReadingListError(_ error: Error) {
        if let readingListsError = error as? ReadingListError {
            WMFAlertManager.sharedInstance.showErrorAlertWithMessage(readingListsError.localizedDescription, sticky: true, dismissPreviousAlerts: true, tapCallBack: nil)
        } else {
            WMFAlertManager.sharedInstance.showErrorAlertWithMessage(
                CommonStrings.unknownError, sticky: false, dismissPreviousAlerts: true, tapCallBack: nil)
        }
    }
    
    // MARK: - Cell configuration
    
    open func configure(cell: ReadingListsCollectionViewCell, forItemAt indexPath: IndexPath, layoutOnly: Bool) {
        guard let readingList = readingList(at: indexPath) else {
            return
        }
        let numberOfItems = self.collectionView(collectionView, numberOfItemsInSection: indexPath.section)
        let articleCount = readingList.countOfEntries
        let lastFourArticlesWithLeadImages = Array(readingList.previewArticles ?? []) as? Array<WMFArticle> ?? []
        
        cell.layoutMargins = layout.readableMargins
        
        cell.configureAlert(for: readingList, listLimit: dataStore.viewContext.wmf_readingListsConfigMaxListsPerUser, entryLimit: dataStore.viewContext.wmf_readingListsConfigMaxEntriesPerList.intValue)

        if readingList.isDefault {
            cell.configure(with: CommonStrings.readingListsDefaultListTitle, description: CommonStrings.readingListsDefaultListDescription, isDefault: true, index: indexPath.item, count: numberOfItems, shouldAdjustMargins: false, shouldShowSeparators: true, theme: theme, for: displayType, articleCount: articleCount, lastFourArticlesWithLeadImages: lastFourArticlesWithLeadImages, layoutOnly: layoutOnly)
            cell.isBatchEditing = false
            cell.swipeTranslation = 0
            cell.isBatchEditable = false
        } else {
            cell.isBatchEditable = true
            cell.actions = availableActions(at: indexPath)
            if editController.isBatchEditing {
                cell.isBatchEditing = editController.isBatchEditing
            } else {
                cell.isBatchEditing = false
                let translation = editController.swipeTranslationForItem(at: indexPath) ?? 0
                cell.swipeTranslation = translation
            }
            cell.configure(readingList: readingList, index: indexPath.item, count: numberOfItems, shouldAdjustMargins: false, shouldShowSeparators: true, theme: theme, for: displayType, articleCount: articleCount, lastFourArticlesWithLeadImages: lastFourArticlesWithLeadImages, layoutOnly: layoutOnly)
        }
    }
    
    // MARK: - Empty state
    
    override func isEmptyDidChange() {
        editController.isCollectionViewEmpty = isEmpty
        if isEmpty {
            collectionView.isHidden = true
        } else {
            collectionView.isHidden = false
        }
        super.isEmptyDidChange()
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        guard displayType != .addArticlesToReadingList else {
            return true
        }
        
        guard !editController.isClosed else {
            return true
        }
        
        guard let readingList = readingList(at: indexPath), !readingList.isDefault else {
            return false
        }
        return true
    }
    
    // MARK: - Batch editing
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard editController.isClosed else {
            return
        }
        
        guard let readingList = readingList(at: indexPath) else {
            return
        }
        
        guard displayType == .readingListsTab else {
            do {
                try readingListsController.add(articles: articles, to: readingList)
                delegate?.readingListsViewController(self, didAddArticles: articles, to: readingList)
            } catch let error {
                handleReadingListError(error)
            }
            return
        }
        
        let readingListDetailViewController = ReadingListDetailViewController(for: readingList, with: dataStore)
        readingListDetailViewController.apply(theme: theme)
        wmf_push(readingListDetailViewController, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let _ = editController.isClosed
    }
    
    lazy var availableBatchEditToolbarActions: [BatchEditToolbarAction] = {
        //let updateItem = BatchEditToolbarActionType.update.action(with: self)
        let deleteItem = BatchEditToolbarActionType.delete.action(with: self)
        return [deleteItem]
    }()
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        editController.transformBatchEditPaneOnScroll()
    }
}

// MARK: - CreateReadingListViewControllerDelegate

extension ReadingListsViewController: CreateReadingListDelegate {
    func createReadingListViewController(_ createReadingListViewController: CreateReadingListViewController, didCreateReadingListWith name: String, description: String?, articles: [WMFArticle]) {
        do {
            let readingList = try readingListsController.createReadingList(named: name, description: description, with: articles)
            if let moveFromReadingList = createReadingListViewController.moveFromReadingList {
                try readingListsController.remove(articles: articles, readingList: moveFromReadingList)
            }
            delegate?.readingListsViewController(self, didAddArticles: articles, to: readingList)
            createReadingListViewController.dismiss(animated: true, completion: nil)
        } catch let error {
            
            switch error {
            case let readingListError as ReadingListError where readingListError == .listExistsWithTheSameName:
                createReadingListViewController.handleReadingListNameError(readingListError)
            default:
                createReadingListViewController.dismiss(animated: true) {
                    self.handleReadingListError(error)
                }
            }
            
        }
    }
}

// MARK: - UICollectionViewDataSource
extension ReadingListsViewController {
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        guard let sectionsCount = self.fetchedResultsController?.sections?.count else {
            return 0
        }
        return sectionsCount
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let sections = self.fetchedResultsController?.sections, section < sections.count else {
            return 0
        }
        return sections[section].numberOfObjects
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
        guard let readingListCell = cell as? ReadingListsCollectionViewCell else {
            return cell
        }
        configure(cell: readingListCell, forItemAt: indexPath, layoutOnly: false)
        return cell
    }
}

// MARK: - CollectionViewUpdaterDelegate
extension ReadingListsViewController: CollectionViewUpdaterDelegate {
    func collectionViewUpdater<T>(_ updater: CollectionViewUpdater<T>, didUpdate collectionView: UICollectionView) {
        for indexPath in collectionView.indexPathsForVisibleItems {
            guard let cell = collectionView.cellForItem(at: indexPath) as? ReadingListsCollectionViewCell else {
                continue
            }
            configure(cell: cell, forItemAt: indexPath, layoutOnly: false)
        }
        updateEmptyState()
        editController.isShowingDefaultCellOnly = isShowingDefaultReadingListOnly
        collectionView.setNeedsLayout()
    }

}

// MARK: - ActionDelegate
extension ReadingListsViewController: ActionDelegate {

    func willPerformAction(_ action: Action) -> Bool {
        guard let readingList = readingList(at: action.indexPath) else {
            return false
        }
        guard action.type == .delete else {
            return self.editController.didPerformAction(action)
        }
        let alertController = ReadingListsAlertController()
        let cancel = ReadingListsAlertActionType.cancel.action { self.editController.close() }
        let delete = ReadingListsAlertActionType.delete.action { let _ = self.editController.didPerformAction(action) }
        return alertController.showAlert(presenter: self, for: [readingList], with: [cancel, delete], completion: nil) {
            return self.editController.didPerformAction(action)
        }
    }
    
    private func deleteReadingLists(_ readingLists: [ReadingList]) {
        do {
            try self.readingListsController.delete(readingLists: readingLists)
            self.editController.close()
        } catch let error {
            handleReadingListError(error)
        }
    }
    
    func didPerformBatchEditToolbarAction(_ action: BatchEditToolbarAction) -> Bool {
        guard let selectedIndexPaths = collectionView.indexPathsForSelectedItems else {
            return false
        }
        
        let readingLists: [ReadingList] = selectedIndexPaths.flatMap({ readingList(at: $0) })
        
        switch action.type {
        case .update:
            return true
        case .delete:
            let alertController = ReadingListsAlertController()
            let delete = ReadingListsAlertActionType.delete.action {
                self.deleteReadingLists(readingLists)
            }
            var didPerform = false
            return alertController.showAlert(presenter: self, for: readingLists, with: [ReadingListsAlertActionType.cancel.action(), delete], completion: { didPerform = true }) {
                self.deleteReadingLists(readingLists)
                didPerform = true
                return didPerform
            }
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
            self.deleteReadingLists([readingList])
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
extension ReadingListsViewController {
    override func collectionView(_ collectionView: UICollectionView, estimatedHeightForItemAt indexPath: IndexPath, forColumnWidth columnWidth: CGFloat) -> WMFLayoutEstimate {
        var estimate = WMFLayoutEstimate(precalculated: false, height: 100)
        guard let placeholderCell = placeholder(forCellWithReuseIdentifier: reuseIdentifier) as? ReadingListsCollectionViewCell else {
            return estimate
        }
        placeholderCell.prepareForReuse()
        configure(cell: placeholderCell, forItemAt: indexPath, layoutOnly: true)
        estimate.height = placeholderCell.sizeThatFits(CGSize(width: columnWidth, height: UIViewNoIntrinsicMetric), apply: false).height
        estimate.precalculated = true
        return estimate
    }
    
    override func metrics(withBoundsSize size: CGSize, readableWidth: CGFloat) -> WMFCVLMetrics {
        return WMFCVLMetrics.singleColumnMetrics(withBoundsSize: size, readableWidth: readableWidth)
    }
}
