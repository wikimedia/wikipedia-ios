import Foundation

enum ReadingListsDisplayType {
    case readingListsTab, addArticlesToReadingList
}

protocol ReadingListsViewControllerDelegate: NSObjectProtocol {
    func readingListsViewController(_ readingListsViewController: ReadingListsViewController, didAddArticles articles: [WMFArticle], to readingList: ReadingList)
}

@objc(WMFReadingListsViewController)
class ReadingListsViewController: ColumnarCollectionViewController, EditableCollection {
    
    private let reuseIdentifier = "ReadingListsViewControllerCell"
    
    let dataStore: MWKDataStore
    let readingListsController: ReadingListsController
    var fetchedResultsController: NSFetchedResultsController<ReadingList>!
    var collectionViewUpdater: CollectionViewUpdater<ReadingList>!
    var editController: CollectionViewEditController!
    private var articles: [WMFArticle] = [] // the articles that will be added to a reading list
    private var readingLists: [ReadingList]? // the displayed reading lists
    private var displayType: ReadingListsDisplayType = .readingListsTab
    var isShowingDefaultList = false
    public weak var delegate: ReadingListsViewControllerDelegate?
    
    func setupFetchedResultsController() {
        let request: NSFetchRequest<ReadingList> = ReadingList.fetchRequest()
        let basePredicate = NSPredicate(format: "isDeletedLocally == NO")
        if let readingLists = readingLists, readingLists.count > 0 {
            isShowingDefaultList = readingLists.filter { $0.isDefaultList }.count > 0
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [basePredicate, NSPredicate(format:"self IN %@", readingLists)])
        } else if displayType == .addArticlesToReadingList {
            let commonReadingLists = articles.reduce(articles.first?.readingLists ?? []) { $0.intersection($1.readingLists ?? []) }
            var subpredicates: [NSPredicate] = []
            if commonReadingLists.count > 0 {
                subpredicates.append(NSPredicate(format:"NOT (self IN %@)", commonReadingLists))
            }
            isShowingDefaultList = commonReadingLists.filter { $0.isDefaultList }.count == 0
            subpredicates.append(basePredicate)
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: subpredicates)
        } else {
            isShowingDefaultList = true
            request.predicate = basePredicate
        }
        
        request.sortDescriptors = [NSSortDescriptor(key: "isDefault", ascending: false), NSSortDescriptor(key: "canonicalName", ascending: true)]
        fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: dataStore.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        
        do {
            try fetchedResultsController.performFetch()
        } catch let error {
            DDLogError("Error fetching reading lists: \(error)")
        }
        
        collectionView.reloadData()
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
        
        setupFetchedResultsController()
        collectionViewUpdater = CollectionViewUpdater(fetchedResultsController: fetchedResultsController, collectionView: collectionView)
        collectionViewUpdater?.delegate = self

        register(ReadingListsCollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier, addPlaceholder: true)
        
        setupEditController()
        
        // Remove peek & pop for now
        unregisterForPreviewing()
        
        areScrollViewInsetsDeterminedByVisibleHeight = false
        
        isRefreshControlEnabled = true
    }
    
    override func refresh() {
        dataStore.readingListsController.backgroundUpdate {
            self.endRefreshing()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateEmptyState()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        editController.close()
    }
    
    func readingList(at indexPath: IndexPath) -> ReadingList? {
        guard let sections = fetchedResultsController.sections,
            indexPath.section < sections.count,
            indexPath.item < sections[indexPath.section].numberOfObjects else {
                return nil
        }
        return fetchedResultsController.object(at: indexPath)
    }
    
    @objc func createReadingList(with articles: [WMFArticle] = [], moveFromReadingList: ReadingList? = nil) {
        let createReadingListViewController = CreateReadingListViewController(theme: self.theme, articles: articles)
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
    
    open func configure(cell: ReadingListsCollectionViewCell, forItemAt indexPath: IndexPath, layoutOnly: Bool) {
        guard let readingList = readingList(at: indexPath) else {
            return
        }
        let numberOfItems = self.collectionView(collectionView, numberOfItemsInSection: indexPath.section)
        let articleCount = readingList.countOfEntries
        let lastFourArticlesWithLeadImages = try? readingListsController.articlesWithLeadImages(for: readingList, limit: 4)
        
        guard !readingList.isDefaultList else {
            cell.configure(with: CommonStrings.readingListsDefaultListTitle, description: CommonStrings.readingListsDefaultListDescription, isDefault: true, index: indexPath.item, count: numberOfItems, shouldAdjustMargins: false, shouldShowSeparators: true, theme: theme, for: displayType, articleCount: articleCount, lastFourArticlesWithLeadImages: lastFourArticlesWithLeadImages ?? [], layoutOnly: layoutOnly)
            cell.layoutMargins = layout.readableMargins
            return
        }
        cell.actions = availableActions(at: indexPath)
        cell.isBatchEditable = true
        cell.configure(readingList: readingList, index: indexPath.item, count: numberOfItems, shouldAdjustMargins: false, shouldShowSeparators: true, theme: theme, for: displayType, articleCount: articleCount, lastFourArticlesWithLeadImages: lastFourArticlesWithLeadImages ?? [], layoutOnly: layoutOnly)
        cell.layoutMargins = layout.readableMargins
        
        guard let translation = editController.swipeTranslationForItem(at: indexPath) else {
            return
        }
        cell.swipeTranslation = translation
    }
    
    // MARK: - Empty state
    
    private var isEmpty = true {
        didSet {
            editController.isCollectionViewEmpty = isEmpty
        }
    }
    
    private final func updateEmptyState() {
        let sectionCount = numberOfSections(in: collectionView)
        
        isEmpty = true
        for sectionIndex in 0..<sectionCount {
            let numberOfItems = self.collectionView(collectionView, numberOfItemsInSection: sectionIndex)
            if numberOfItems > (isShowingDefaultList ? 1 : 0) {
                editController.hasDefaultCell = numberOfItems == 1
                isEmpty = false
                break
            }
        }
        if isEmpty {
            if isShowingDefaultList {
                collectionView.isHidden = true
            }
            let yPosition: CGFloat
            if let navigationController = navigationController {
                yPosition = navigationController.navigationBar.frame.size.height + navigationBar.statusBarHeight
            } else {
                yPosition = view.bounds.origin.y
            }
            let emptyViewFrame = CGRect(origin: CGPoint(x: view.bounds.origin.x, y: yPosition), size: view.bounds.size)
            wmf_showEmptyView(of: WMFEmptyViewType.noReadingLists, theme: theme, frame: emptyViewFrame)
        } else {
            wmf_hideEmptyView()
            collectionView.isHidden = false
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        guard displayType != .addArticlesToReadingList else {
            return true
        }
        
        guard !editController.isClosed else {
            return true
        }
        
        guard let readingList = readingList(at: indexPath), !readingList.isDefaultList else {
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
                readingListsController.handle(error)
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
    func createReadingList(_ createReadingList: CreateReadingListViewController, shouldCreateReadingList: Bool, with name: String, description: String?, articles: [WMFArticle]) {
        guard shouldCreateReadingList else {
            return
        }
        do {
            let readingList = try readingListsController.createReadingList(named: name, description: description, with: articles)
            if let moveFromReadingList = createReadingList.moveFromReadingList {
                try readingListsController.remove(articles: articles, readingList: moveFromReadingList)
            }
            delegate?.readingListsViewController(self, didAddArticles: articles, to: readingList)
            createReadingList.dismiss(animated: true, completion: nil)
        } catch let error {
            readingListsController.handle(error)
        }
    }
}

// MARK: - UICollectionViewDataSource
extension ReadingListsViewController {
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
        collectionView.setNeedsLayout()
    }
    
}

// MARK: - ActionDelegate
extension ReadingListsViewController: ActionDelegate {
    
    func willPerformAction(_ action: Action) {
        guard let readingList = readingList(at: action.indexPath) else {
            return
        }
        guard action.type == .delete, shouldPresentDeletionAlert(for: [readingList]) else {
            let _ = self.editController.didPerformAction(action)
            return
        }
        let alertController = ReadingListAlertController()
        let cancel = ReadingListAlertActionType.cancel.action {
            self.editController.close()
        }
        let delete = ReadingListAlertActionType.delete.action {
            let _ = self.editController.didPerformAction(action)
        }
        alertController.showAlert(presenter: self, readingLists: [readingList], actions: [cancel, delete])
    }
    
    private func deleteReadingLists(_ readingLists: [ReadingList]) {
        do {
            try self.readingListsController.delete(readingLists: readingLists)
            self.editController.close()
        } catch let error {
            self.readingListsController.handle(error)
        }
    }
    
    func shouldPresentDeletionAlert(for readingLists: [ReadingList]) -> Bool {
        return entriesCount(for: readingLists) > 0
    }
    
    private func entriesCount(for readingLists: [ReadingList]) -> Int {
        return Int(readingLists.flatMap({ $0.countOfEntries }).reduce(0, +))
    }
    
    func createDeletionAlert(for readingLists: [ReadingList]) -> UIAlertController {
        let readingListsCount = readingLists.count
        let title = String.localizedStringWithFormat(WMFLocalizedString("delete-reading-list-alert-title", value: "Delete {{PLURAL:%1$d|list|lists}}?", comment: "Title of the alert shown before deleting selected reading lists."), readingListsCount)
        let message = String.localizedStringWithFormat(WMFLocalizedString("delete-reading-list-alert-message", value: "Any articles saved only to {{PLURAL:%1$d|this list will be unsaved when this list is deleted|these lists will be unsaved when these lists are deleted}}.", comment: "Title of the altert shown before deleting selected reading lists."), readingListsCount)
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        return alert
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
            if shouldPresentDeletionAlert(for: readingLists) {
                let alertController = ReadingListAlertController()
                let delete = ReadingListAlertActionType.delete.action {
                    self.deleteReadingLists(readingLists)
                }
                var didPerform = false
                alertController.showAlert(presenter: self, readingLists: readingLists, actions: [ReadingListAlertActionType.cancel.action(), delete]) {
                    didPerform = true
                }
                return didPerform
            } else {
                deleteReadingLists(readingLists)
                return true
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

extension ReadingListsViewController: CollectionViewEditControllerNavigationDelegate {
    func didChangeEditingState(from oldEditingState: BatchEditingState, to newEditingState: BatchEditingState, rightBarButton: UIBarButtonItem, leftBarButton: UIBarButtonItem?) {
        //
    }
    
    var currentTheme: Theme {
        return self.theme
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
