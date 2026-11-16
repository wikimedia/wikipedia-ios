import Foundation
import WMFComponents
import WMFData
import WMFNativeLocalizations

protocol ReadingListsViewControllerDelegate: NSObjectProtocol {
    func readingListsViewController(_ readingListsViewController: ReadingListsViewController, didAddArticles articles: [WMFArticle], to readingList: ReadingList)
    func readingListsViewControllerDidChangeEmptyState(_ readingListsViewController: ReadingListsViewController, isEmpty: Bool)
}

/// The list of reading lists inside the "Add to reading list" sheet. The Saved tab shows its
/// own SwiftUI list (`WMFReadingListsView`).
class ReadingListsViewController: ColumnarCollectionViewController, EditableCollection, UpdatableCollection {

    typealias T = ReadingList
    let dataStore: MWKDataStore
    let readingListsController: ReadingListsController
    var fetchedResultsController: NSFetchedResultsController<ReadingList>?
    var collectionViewUpdater: CollectionViewUpdater<ReadingList>?
    var editController: CollectionViewEditController!
    private let articles: [WMFArticle] // the articles that will be added to a reading list
    public weak var delegate: ReadingListsViewControllerDelegate?
    private var createReadingListCoordinator: CreateReadingListCoordinator?
    private var emptyViewController: WMFEmptyViewController?

    // MARK: - Fetching

    var basePredicate: NSPredicate {
        return NSPredicate(format: "isDeletedLocally == NO")
    }

    /// The order the reader chose on the Saved tab's Reading lists segment.
    var baseSortDescriptors: [NSSortDescriptor] {
        switch WMFLegacyReadingListsDataController().readingListsSortOrder {
        case .byTitle:
            return [NSSortDescriptor(key: "canonicalName", ascending: true, selector: #selector(NSString.localizedStandardCompare(_:)))]
        case .byRecentlyAdded:
            return [NSSortDescriptor(keyPath: \ReadingList.createdDate, ascending: false)]
        }
    }

    /// Lists that do not already hold every article, plus the default list when it is shown.
    func setupFetchedResultsController() {
        let request: NSFetchRequest<ReadingList> = ReadingList.fetchRequest()
        request.relationshipKeyPathsForPrefetching = ["previewArticles"]

        let commonReadingLists = articles.reduce(articles.first?.readingLists ?? []) { $0.intersection($1.readingLists ?? []) }
        var subpredicates: [NSPredicate] = []
        if !commonReadingLists.isEmpty {
            subpredicates.append(NSPredicate(format: "NOT (self IN %@)", commonReadingLists))
        }
        if !readingListsController.isDefaultListEnabled {
            subpredicates.append(NSPredicate(format: "isDefault != YES"))
        }
        subpredicates.append(basePredicate)
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: subpredicates)
        request.sortDescriptors = baseSortDescriptors
        fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: dataStore.viewContext, sectionNameKeyPath: nil, cacheName: nil)
    }

    init(with dataStore: MWKDataStore, articles: [WMFArticle]) {
        self.dataStore = dataStore
        self.readingListsController = dataStore.readingListsController
        self.articles = articles
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not supported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        layoutManager.register(ReadingListsCollectionViewCell.self, forCellWithReuseIdentifier: ReadingListsCollectionViewCell.identifier, addPlaceholder: true)
        setupEditController()
        isRefreshControlEnabled = true
        collectionView.accessibilityIdentifier = AccessibilityIdentifiers.Saved.readingListsView
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
        super.viewWillAppear(animated)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        collectionViewUpdater = nil
        fetchedResultsController = nil
        editController.close()
    }

    func readingList(at indexPath: IndexPath) -> ReadingList? {
        guard let fetchedResultsController = fetchedResultsController, fetchedResultsController.isValidIndexPath(indexPath) else {
            return nil
        }
        return fetchedResultsController.object(at: indexPath)
    }

    // MARK: - Reading list creation

    @objc func createReadingList(with articles: [WMFArticle] = [], moveFromReadingList: ReadingList? = nil) {
        let coordinator = CreateReadingListCoordinator(presentingViewController: self, articles: articles, moveFromReadingList: moveFromReadingList)
        coordinator.delegate = self
        coordinator.didDismiss = { [weak self] in
            self?.createReadingListCoordinator = nil
        }
        createReadingListCoordinator = coordinator
        coordinator.start()
    }

    @objc func presentCreateReadingListViewController() {
        createReadingList(with: articles)
    }

    @objc func dismissCreateReadingListViewController() {
        dismiss(animated: true, completion: nil)
    }

    private func handleReadingListError(_ error: Error) {
        if let readingListsError = error as? ReadingListError {
            WMFToastManager.sharedInstance.showToast(readingListsError.localizedDescription, sticky: true, dismissPreviousToasts: true, tapCallBack: nil)
        } else {
            WMFToastManager.sharedInstance.showToast(
                CommonStrings.unknownError, sticky: false, dismissPreviousToasts: true, tapCallBack: nil)
        }
    }

    // MARK: - Cell configuration

    open func configure(cell: ReadingListsCollectionViewCell, forItemAt indexPath: IndexPath, layoutOnly: Bool) {
        guard let readingList = readingList(at: indexPath) else {
            return
        }
        let lastFourArticlesWithLeadImages = Array(readingList.previewArticles ?? []) as? [WMFArticle] ?? []

        cell.layoutMargins = layout.itemLayoutMargins
        cell.accessibilityIdentifier = AccessibilityIdentifiers.Saved.readingListCell(readingList.name ?? "")

        if readingList.isDefault {
            cell.configure(with: CommonStrings.readingListsDefaultListTitle, description: CommonStrings.readingListsDefaultListDescription, isDefault: true, index: indexPath.item, shouldShowSeparators: true, theme: theme, lastFourArticlesWithLeadImages: lastFourArticlesWithLeadImages, layoutOnly: layoutOnly)
            cell.isBatchEditing = false
            cell.isBatchEditable = false
        } else {
            cell.isBatchEditable = true
            cell.isBatchEditing = editController.isBatchEditing
            editController.configureSwipeableCell(cell, forItemAt: indexPath, layoutOnly: layoutOnly)
            cell.configure(readingList: readingList, index: indexPath.item, shouldShowSeparators: true, theme: theme, lastFourArticlesWithLeadImages: lastFourArticlesWithLeadImages, layoutOnly: layoutOnly)
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

    override func collectionView(_ collectionView: UICollectionView, estimatedHeightForHeaderInSection section: Int, forColumnWidth columnWidth: CGFloat) -> ColumnarCollectionViewLayoutHeightEstimate {
        return ColumnarCollectionViewLayoutHeightEstimate(precalculated: false, height: 0)
    }

    override func metrics(with size: CGSize, readableWidth: CGFloat, layoutMargins: UIEdgeInsets) -> ColumnarCollectionViewLayoutMetrics {
        return ColumnarCollectionViewLayoutMetrics.tableViewMetrics(with: size, readableWidth: readableWidth, layoutMargins: layoutMargins)
    }

    // MARK: - Empty state

    override func isEmptyDidChange() {
        editController.isCollectionViewEmpty = isEmpty
        collectionView.isHidden = isEmpty

        if isEmpty {
            showEmptyView()
        } else {
            hideEmptyView()
        }

        delegate?.readingListsViewControllerDidChangeEmptyState(self, isEmpty: isEmpty)
    }

    private func showEmptyView() {
        guard emptyViewController == nil else { return }

        let localizedStrings = WMFEmptyViewModel.LocalizedStrings(
            title: CommonStrings.readingListsEmptyTitle,
            subtitle: CommonStrings.readingListsEmptyMessage,
            titleFilter: nil,
            buttonTitle: CommonStrings.createNewListTitle,
            attributedFilterString: nil
        )

        let viewModel = WMFEmptyViewModel(
            localizedStrings: localizedStrings,
            image: UIImage(named: "reading-lists-empty-state"),
            imageColor: nil,
            numberOfFilters: nil
        )

        let emptyVC = WMFEmptyViewController(viewModel: viewModel, type: .noItems, delegate: self)
        emptyVC.view.accessibilityIdentifier = AccessibilityIdentifiers.Saved.readingListsEmptyView
        addChild(emptyVC)
        view.insertSubview(emptyVC.view, belowSubview: collectionView)
        emptyVC.view.frame = view.bounds
        emptyVC.view.autoresizingMask = [UIView.AutoresizingMask.flexibleWidth, UIView.AutoresizingMask.flexibleHeight]
        emptyVC.didMove(toParent: self)

        emptyViewController = emptyVC
    }

    private func hideEmptyView() {
        guard let emptyVC = emptyViewController else { return }

        emptyVC.willMove(toParent: nil)
        emptyVC.view.removeFromSuperview()
        emptyVC.removeFromParent()
        emptyViewController = nil
    }

    // MARK: - Adding the articles

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard editController.isClosed else {
            return
        }

        guard let readingList = readingList(at: indexPath) else {
            return
        }

        do {
            try readingListsController.add(articles: articles, to: readingList)
            delegate?.readingListsViewController(self, didAddArticles: articles, to: readingList)
        } catch let error {
            handleReadingListError(error)
        }
    }

    // MARK: Themeable

    override func apply(theme: Theme) {
        super.apply(theme: theme)
        view.backgroundColor = theme.colors.paperBackground
    }
}

// MARK: - CreateReadingListCoordinatorDelegate

extension ReadingListsViewController: CreateReadingListCoordinatorDelegate {
    func createReadingListCoordinator(_ coordinator: CreateReadingListCoordinator, didCreateReadingListWith name: String, description: String, articles: [WMFArticle]) {
        do {
            let readingList = try readingListsController.createReadingList(named: name, description: description, with: articles)
            if let moveFromReadingList = coordinator.moveFromReadingList {
                try readingListsController.remove(articles: articles, readingList: moveFromReadingList)
            }
            delegate?.readingListsViewController(self, didAddArticles: articles, to: readingList)
            coordinator.dismiss(animated: true)
            ReadingListsFunnel.shared.logCreateInAddToReadingList()
        } catch let error {
            switch error {
            case let readingListError as ReadingListError where readingListError == .listExistsWithTheSameName:
                coordinator.handleReadingListNameError(readingListError)
            default:
                coordinator.dismiss(animated: true) { [weak self] in
                    self?.handleReadingListError(error)
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
        collectionView.setNeedsLayout()
    }

    func collectionViewUpdater<T: NSFetchRequestResult>(_ updater: CollectionViewUpdater<T>, updateItemAtIndexPath indexPath: IndexPath, in collectionView: UICollectionView) {
    }
}

// MARK: - ActionDelegate (swipe to delete)
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
        let delete = ReadingListsAlertActionType.delete.action { _ = self.editController.didPerformAction(action) }
        alertController.showAlertIfNeeded(presenter: self, for: [readingList], with: [cancel, delete]) { showed in
            if !showed {
                _ = self.editController.didPerformAction(action)
            }
        }
        return true
    }

    private func deleteReadingLists(_ readingLists: [ReadingList]) {
        do {
            try self.readingListsController.delete(readingLists: readingLists)
            self.editController.close()
            ReadingListsFunnel.shared.logDeleteInAddToReadingList(readingListsCount: readingLists.count)
        } catch let error {
            handleReadingListError(error)
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
            UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: CommonStrings.readingListDeletedAccessibilityNotification)
            return true
        default:
            return false
        }
    }

    func availableActions(at indexPath: IndexPath) -> [Action] {
        return [ActionType.delete.action(with: self, indexPath: indexPath)]
    }

}

// MARK: - WMFEmptyViewDelegate

extension ReadingListsViewController: WMFComponents.WMFEmptyViewDelegate {
    func emptyViewDidTapMainAction() {
        presentCreateReadingListViewController()
    }

    func emptyViewDidTapFilters() {
        // Not used for reading lists
    }

    func emptyViewDidShow(type: WMFEmptyViewStateType) {}
}
