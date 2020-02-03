import Foundation

enum ReadingListsDisplayType {
    case readingListsTab, addArticlesToReadingList
}

protocol ReadingListsViewControllerDelegate: NSObjectProtocol {
    func readingListsViewController(_ readingListsViewController: ReadingListsViewController, didAddArticles articles: [WMFArticle], to readingList: ReadingList)
    func readingListsViewControllerDidChangeEmptyState(_ readingListsViewController: ReadingListsViewController, isEmpty: Bool)
}

@objc(WMFReadingListsViewController)
class ReadingListsViewController: ColumnarCollectionViewController, EditableCollection, UpdatableCollection {

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
        
        if let readingLists = readingLists, !readingLists.isEmpty {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [basePredicate, NSPredicate(format:"self IN %@", readingLists)])
        } else if displayType == .addArticlesToReadingList {
            let commonReadingLists = articles.reduce(articles.first?.readingLists ?? []) { $0.intersection($1.readingLists ?? []) }
            var subpredicates: [NSPredicate] = []
            if !commonReadingLists.isEmpty {
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
        layoutManager.register(ReadingListsCollectionViewCell.self, forCellWithReuseIdentifier: ReadingListsCollectionViewCell.identifier, addPlaceholder: true)
        emptyViewType = .noReadingLists
        emptyViewTarget = self
        emptyViewAction = #selector(presentCreateReadingListViewController)
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
        fetch()
        editController.isShowingDefaultCellOnly = isShowingDefaultReadingListOnly
        super.viewWillAppear(animated)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        collectionViewUpdater = nil
        fetchedResultsController = nil
        editController.close()
    }
    
    func readingList(at indexPath: IndexPath) -> ReadingList? {
        guard let fetchedResultsController = fetchedResultsController,fetchedResultsController.isValidIndexPath(indexPath) else {
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
        let navigationController = WMFThemeableNavigationController(rootViewController: createReadingListViewController, theme: theme, style: .sheet)
        createReadingListViewController.navigationItem.rightBarButtonItem = UIBarButtonItem.wmf_buttonType(WMFButtonType.X, target: self, action: #selector(dismissCreateReadingListViewController))
        present(navigationController, animated: true, completion: nil)
    }
    
    @objc func presentCreateReadingListViewController() {
        createReadingList(with: articles)
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

    public lazy var createNewReadingListButtonView: CreateNewReadingListButtonView = {
        let createNewReadingListButtonView = CreateNewReadingListButtonView.wmf_viewFromClassNib()
        createNewReadingListButtonView?.title = CommonStrings.createNewListTitle
        createNewReadingListButtonView?.button.addTarget(self, action: #selector(presentCreateReadingListViewController), for: .touchUpInside)
        createNewReadingListButtonView?.apply(theme: theme)
        return createNewReadingListButtonView!
    }()
    
    // MARK: - Cell configuration
    
    open func configure(cell: ReadingListsCollectionViewCell, forItemAt indexPath: IndexPath, layoutOnly: Bool) {
        guard let readingList = readingList(at: indexPath) else {
            return
        }
        let articleCount = readingList.countOfEntries
        let lastFourArticlesWithLeadImages = Array(readingList.previewArticles ?? []) as? Array<WMFArticle> ?? []
        
        cell.layoutMargins = layout.itemLayoutMargins
        
        cell.configureAlert(for: readingList, listLimit: dataStore.viewContext.wmf_readingListsConfigMaxListsPerUser, entryLimit: dataStore.viewContext.wmf_readingListsConfigMaxEntriesPerList.intValue)

        if readingList.isDefault {
            cell.configure(with: CommonStrings.readingListsDefaultListTitle, description: CommonStrings.readingListsDefaultListDescription, isDefault: true, index: indexPath.item, shouldShowSeparators: true, theme: theme, for: displayType, articleCount: articleCount, lastFourArticlesWithLeadImages: lastFourArticlesWithLeadImages, layoutOnly: layoutOnly)
            cell.isBatchEditing = false
            cell.isBatchEditable = false
        } else {
            cell.isBatchEditable = true
            cell.isBatchEditing = editController.isBatchEditing
            editController.configureSwipeableCell(cell, forItemAt: indexPath, layoutOnly: layoutOnly)
            cell.configure(readingList: readingList, index: indexPath.item, shouldShowSeparators: true, theme: theme, for: displayType, articleCount: articleCount, lastFourArticlesWithLeadImages: lastFourArticlesWithLeadImages, layoutOnly: layoutOnly)
        }
    }
    
    // MARK: - ColumnarCollectionViewLayoutDelegate
    
    override func collectionView(_ collectionView: UICollectionView, estimatedHeightForItemAt indexPath: IndexPath, forColumnWidth columnWidth: CGFloat) -> ColumnarCollectionViewLayoutHeightEstimate {
        var estimate = ColumnarCollectionViewLayoutHeightEstimate(precalculated: false, height: 100)
        guard let placeholderCell = layoutManager.placeholder(forCellWithReuseIdentifier: ReadingListsCollectionViewCell.identifier) as? ReadingListsCollectionViewCell else {
            return estimate
        }
        configure(cell: placeholderCell, forItemAt: indexPath, layoutOnly: true)
        estimate.height = placeholderCell.sizeThatFits(CGSize(width: columnWidth, height: UIView.noIntrinsicMetric), apply: false).height
        estimate.precalculated = true
        return estimate
    }
    
    override func metrics(with size: CGSize, readableWidth: CGFloat, layoutMargins: UIEdgeInsets) -> ColumnarCollectionViewLayoutMetrics {
        return ColumnarCollectionViewLayoutMetrics.tableViewMetrics(with: size, readableWidth: readableWidth, layoutMargins: layoutMargins)
    }
    
    // MARK: - Empty state
    
    override func isEmptyDidChange() {
        editController.isCollectionViewEmpty = isEmpty
        collectionView.isHidden = isEmpty
        super.isEmptyDidChange()
        delegate?.readingListsViewControllerDidChangeEmptyState(self, isEmpty: isEmpty)
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
        push(readingListDetailViewController, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let _ = editController.isClosed
    }
    
    lazy var availableBatchEditToolbarActions: [BatchEditToolbarAction] = {
        //let updateItem = BatchEditToolbarActionType.update.action(with: self)
        let deleteItem = BatchEditToolbarActionType.delete.action(with: self)
        return [deleteItem]
    }()
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        super.scrollViewDidScroll(scrollView)
        editController.transformBatchEditPaneOnScroll()
    }

    // MARK: Themeable

    override func apply(theme: Theme) {
        super.apply(theme: theme)
        view.backgroundColor = theme.colors.paperBackground
        createNewReadingListButtonView.apply(theme: theme)
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
            if displayType == .addArticlesToReadingList {
                ReadingListsFunnel.shared.logCreateInAddToReadingList()
            } else {
                ReadingListsFunnel.shared.logCreateInReadingLists()
            }
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
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ReadingListsCollectionViewCell.identifier, for: indexPath)
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
    
    func collectionViewUpdater<T: NSFetchRequestResult>(_ updater: CollectionViewUpdater<T>, updateItemAtIndexPath indexPath: IndexPath, in collectionView: UICollectionView) {
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
        let cancel = ReadingListsAlertActionType.cancel.action()
        let delete = ReadingListsAlertActionType.delete.action { let _ = self.editController.didPerformAction(action) }
        alertController.showAlertIfNeeded(presenter: self, for: [readingList], with: [cancel, delete]) { showed in
            if !showed {
                let _ = self.editController.didPerformAction(action)
            }
        }
        return true
    }
    
    private func deleteReadingLists(_ readingLists: [ReadingList]) {
        do {
            try self.readingListsController.delete(readingLists: readingLists)
            self.editController.close()
            let readingListsCount = readingLists.count
            if displayType == .addArticlesToReadingList {
                ReadingListsFunnel.shared.logDeleteInAddToReadingList(readingListsCount: readingListsCount)
            } else {
                ReadingListsFunnel.shared.logDeleteInReadingLists(readingListsCount: readingListsCount)
            }
        } catch let error {
            handleReadingListError(error)
        }
    }
    
    func didPerformBatchEditToolbarAction(_ action: BatchEditToolbarAction, completion: @escaping (Bool) -> Void) {
        guard let selectedIndexPaths = collectionView.indexPathsForSelectedItems else {
            completion(false)
            return
        }
        
        let readingLists: [ReadingList] = selectedIndexPaths.compactMap({ readingList(at: $0) })
        
        switch action.type {
        case .delete:
            let alertController = ReadingListsAlertController()
            let deleteReadingLists = {
                self.deleteReadingLists(readingLists)
                completion(true)
            }
            let delete = ReadingListsAlertActionType.delete.action {
                self.deleteReadingLists(readingLists)
                completion(true)
            }
            let cancel = ReadingListsAlertActionType.cancel.action {
                completion(false)
            }
            let actions = [cancel, delete]
            alertController.showAlertIfNeeded(presenter: self, for: readingLists, with: actions) { showed in
                if !showed {
                    deleteReadingLists()
                }
            }
        default:
            completion(false)
            break
        }
    }
    
    func didPerformAction(_ action: Action) -> Bool {
        let indexPath = action.indexPath
        guard let readingList = readingList(at: indexPath) else {
            return false
        }
        switch action.type {
        case .delete:
            self.deleteReadingLists([readingList])
            UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: WMFLocalizedString("reading-list-deleted-accessibility-notification", value: "Reading list deleted", comment: "Notification spoken after user deletes a reading list from the list."))
            return true
        default:
            return false
        }
    }
    
    func availableActions(at indexPath: IndexPath) -> [Action] {
        return [ActionType.delete.action(with: self, indexPath: indexPath)]
    }

}
