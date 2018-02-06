import Foundation

enum ReadingListsDisplayType {
    case readingListsTab, addArticlesToReadingList
}

protocol ReadingListsViewControllerDelegate: NSObjectProtocol {
    func readingListsViewController(_ readingListsViewController: ReadingListsViewController, didAddArticles articles: [WMFArticle], to readingList: ReadingList)
}

@objc(WMFReadingListsViewController)
class ReadingListsViewController: ColumnarCollectionViewController {
    
    private let reuseIdentifier = "ReadingListsViewControllerCell"
    
    let dataStore: MWKDataStore
    let readingListsController: ReadingListsController
    var fetchedResultsController: NSFetchedResultsController<ReadingList>!
    var collectionViewUpdater: CollectionViewUpdater<ReadingList>!
    var cellLayoutEstimate: WMFLayoutEstimate?
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
            subpredicates.append(basePredicate)
            isShowingDefaultList = false
            subpredicates.append(NSPredicate(format:"isDefault == NO"))
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
        
        editController = CollectionViewEditController(collectionView: collectionView)
        editController.delegate = self
        editController.navigationDelegate = self
        
        // Remove peek & pop for now
        unregisterForPreviewing()
        
        areScrollViewInsetsDeterminedByVisibleHeight = false
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
    
    @objc func createReadingList(with articles: [WMFArticle] = []) {
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
            let defaultListTitle = WMFLocalizedString("reading-lists-default-list-title", value: "Bookmarks", comment: "The title of the default saved pages list")
            cell.configure(with: defaultListTitle, description: WMFLocalizedString("reading-lists-default-list-description", value: "Default list for saved articles", comment: "The description of the default saved pages list"), isDefault: true, index: indexPath.item, count: numberOfItems, shouldAdjustMargins: false, shouldShowSeparators: true, theme: theme, for: displayType, articleCount: articleCount, lastFourArticlesWithLeadImages: lastFourArticlesWithLeadImages ?? [], layoutOnly: layoutOnly)
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
            var emptyViewFrame = CGRect.zero
            if displayType == .readingListsTab {
                let cellHeight = cellLayoutEstimate?.height ?? 100
                let emptyViewYPosition = navigationBar.visibleHeight - navigationBar.extendedView.frame.height + cellHeight
                emptyViewFrame = CGRect(x: view.bounds.origin.x, y: emptyViewYPosition, width: view.bounds.width, height: view.bounds.height - emptyViewYPosition)
            } else {
                let cellHeight = cellLayoutEstimate?.height ?? 70
                let emptyViewYPosition = navigationBar.visibleHeight - navigationBar.frame.height + cellHeight
                emptyViewFrame = CGRect(x: view.bounds.origin.x, y: emptyViewYPosition, width: view.bounds.width, height: view.bounds.height - emptyViewYPosition)
            }
            wmf_showEmptyView(of: WMFEmptyViewType.noReadingLists, theme: theme, frame: emptyViewFrame)
        } else {
            wmf_hideEmptyView()
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
        let updateItem = BatchEditToolbarActionType.update.action(with: self)
        let deleteItem = BatchEditToolbarActionType.delete.action(with: self)
        return [updateItem, deleteItem]
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
    
    func shouldPerformAction(_ action: Action) -> Bool {
        guard let readingList = readingList(at: action.indexPath) else {
            return false
        }
        guard action.type == .delete, shouldPresentDeletionAlert(for: [readingList]) else {
            return self.editController.didPerformAction(action)
        }
        let alert = createDeletionAlert(for: [readingList])
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: { (cancel) in
            self.editController.close()
            alert.dismiss(animated: true, completion: nil)
        })
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive, handler: { (delete) in
            let _ = self.editController.didPerformAction(action)
        })
        alert.addAction(cancelAction)
        alert.addAction(deleteAction)
        present(alert, animated: true)
        return true
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
        let articlesCount = entriesCount(for: readingLists)
        
        let readingListFormat = WMFLocalizedString("reading-lists-format", value:"{{PLURAL:%1$d|reading list|reading lists}}", comment: "Describes the number of reading lists")
        let listCountFormat = WMFLocalizedString("lists-count", value:"{{PLURAL:%1$d|%1$d list|%1$d lists}}", comment: "Describes the number of lists - %1$d is replaced with the number of reading lists")
        let possesiveDeterminerFormat = WMFLocalizedString("possesive-determiner", value:"{{PLURAL:%1$d|its|their}}", comment: "Expresses possession or belonging, e.g., 'reading list and its articles'")
        
        let readingListString = String.localizedStringWithFormat(readingListFormat, readingListsCount)
        let listCountString = String.localizedStringWithFormat(listCountFormat, readingListsCount)
        let articleCountString = String.localizedStringWithFormat(CommonStrings.articleCountFormat, articlesCount)
        let possesiveDeterminer = String.localizedStringWithFormat(possesiveDeterminerFormat, readingListsCount)
        
        let title = String.localizedStringWithFormat(WMFLocalizedString("delete-reading-list-alert-title", value: "Delete %1$@ and all of %2$@ saved articles?", comment: "Title of the altert shown before deleting selected reading lists."), "\(readingListString)", "\(possesiveDeterminer)")
        let message = String.localizedStringWithFormat(WMFLocalizedString("delete-reading-list-alert-message", value: "Your %1$@ and %2$@ will be deleted", comment: "Title of the altert shown before deleting selected reading lists."), "\(listCountString)", "\(articleCountString)")
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
            print("Update")
            return true
        case .delete:
            if shouldPresentDeletionAlert(for: readingLists) {
                let alert = createDeletionAlert(for: readingLists)
                let cancelAction = UIAlertAction(title: CommonStrings.cancelActionTitle, style: .cancel, handler: { (action) in
                    alert.dismiss(animated: true, completion: nil)
                })
                let deleteAction = UIAlertAction(title: CommonStrings.deleteActionTitle, style: .destructive, handler: { (action) in
                    self.deleteReadingLists(readingLists)
                })
                alert.addAction(cancelAction)
                alert.addAction(deleteAction)
                var didPerform = false
                present(alert, animated: true, completion: {
                    didPerform = true
                })
                return didPerform
            } else {
                self.deleteReadingLists(readingLists)
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

extension ReadingListsViewController: BatchEditNavigationDelegate {
    func didChange(editingState: BatchEditingState, rightBarButton: UIBarButtonItem) {
        //
    }
    
    var currentTheme: Theme {
        return self.theme
    }
}

// MARK: - WMFColumnarCollectionViewLayoutDelegate
extension ReadingListsViewController {
    override func collectionView(_ collectionView: UICollectionView, estimatedHeightForItemAt indexPath: IndexPath, forColumnWidth columnWidth: CGFloat) -> WMFLayoutEstimate {
        // The layout estimate can be re-used in this case becuause both labels are one line, meaning the cell
        // size only varies with font size. The layout estimate is nil'd when the font size changes on trait collection change
        if let estimate = cellLayoutEstimate {
            return estimate
        }
        var estimate = WMFLayoutEstimate(precalculated: false, height: 80)
        guard let placeholderCell = placeholder(forCellWithReuseIdentifier: reuseIdentifier) as? ReadingListsCollectionViewCell else {
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
