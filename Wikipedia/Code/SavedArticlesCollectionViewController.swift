import UIKit
import WMF

@objc(WMFSavedArticlesCollectionViewController)
class SavedArticlesCollectionViewController: ArticleFetchedResultsViewController {
    
    fileprivate let reuseIdentifier = "SavedCollectionViewCell"
    
    override func setupFetchedResultsController(with dataStore: MWKDataStore) {
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
        collectionViewUpdater = CollectionViewUpdater(fetchedResultsController: fetchedResultsController, collectionView: collectionView!)
        do {
            try fetchedResultsController.performFetch()
        } catch let err {
            assertionFailure("Couldn't sort by \(sortDescriptor.key ?? "unknown key"): \(err)")
        }
        collectionView?.reloadData()
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
    
    // MARK: - Swipe actions
    
    override func canSave(at indexPath: IndexPath) -> Bool {
        return false
    }
    
    override func canUnsave(at indexPath: IndexPath) -> Bool {
        return false
    }
    
    override func delete(at indexPath: IndexPath) {
        guard let articleURL = self.articleURL(at: indexPath) else {
            return
        }
        dataStore.savedPageList.removeEntry(with: articleURL)
    }
    
    // MARK: - View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        register(SavedCollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier, addPlaceholder: true)
        deleteAllButtonText = WMFLocalizedString("saved-clear-all", value: "Clear", comment: "Text of the button shown at the top of saved pages which deletes all the saved pages\n{{Identical|Clear}}")
        deleteAllConfirmationText = WMFLocalizedString("saved-pages-clear-confirmation-heading", value: "Are you sure you want to delete all your saved pages?", comment: "Heading text of delete all confirmation dialog")
        deleteAllCancelText = WMFLocalizedString("saved-pages-clear-cancel", value: "Cancel", comment: "Button text for cancelling delete all action\n{{Identical|Cancel}}")
        deleteAllText = WMFLocalizedString("saved-pages-clear-delete-all", value: "Yes, delete all", comment: "Button text for confirming delete all action\n{{Identical|Delete all}}")
        isDeleteAllVisible = false
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        PiwikTracker.sharedInstance()?.wmf_logView(self)
        NSUserActivity.wmf_makeActive(NSUserActivity.wmf_savedPagesView())
    }
    
    // MARK: - Analytics
    
    override var analyticsName: String {
        return "Saved Articles"
    }
    
    override func deleteAll() {
        dataStore.savedPageList.removeAllEntries()
    }
    
    // MARK: - Cell configuartion
    
    override open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
        guard let savedArticleCell = cell as? SavedCollectionViewCell else {
            return cell
        }
        configure(cell: savedArticleCell, forItemAt: indexPath, layoutOnly: false)
        return cell
    }
    
    override func configure(cell: ArticleRightAlignedImageCollectionViewCell, forItemAt indexPath: IndexPath, layoutOnly: Bool) {
        super.configure(cell: cell, forItemAt: indexPath, layoutOnly: layoutOnly)
        if let savedArticleCell = cell as? SavedCollectionViewCell {
            savedArticleCell.readingLists = readingListsForArticle(at: indexPath)
            let readingLists = readingListsForArticle(at: indexPath)
            
            let readingListNames = readingLists.flatMap({ $0.name })
            readingListNames.forEach({ print("name: \($0)") })
        }
        cell.isBatchEditable = true
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
    
    // MARK: - Layout
    
    override func collectionView(_ collectionView: UICollectionView, estimatedHeightForItemAt indexPath: IndexPath, forColumnWidth columnWidth: CGFloat) -> WMFLayoutEstimate {
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
    
    // MARK: - Empty state
    
    override var emptyViewType: WMFEmptyViewType {
        return .noSavedPages
    }
    
    override var isEmpty: Bool {
        didSet {
            editController.isCollectionViewEmpty = isEmpty
        }
    }
    
    // MARK: - Batch editing
    
    lazy var availableBatchEditToolbarActions: [BatchEditToolbarAction] = {
        let updateItem = BatchEditToolbarActionType.update.action(with: self)
        let addToListItem = BatchEditToolbarActionType.addToList.action(with: self)
        let unsaveItem = BatchEditToolbarActionType.unsave.action(with: self)
        return [updateItem, addToListItem, unsaveItem]
    }()
    
    override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if editController.batchEditingState == .open {
            editController.didTapCellWhileBatchEditing()
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard editController.batchEditingState != .open  else {
            editController.didTapCellWhileBatchEditing()
            return
        }
        super.collectionView(collectionView, didSelectItemAt: indexPath)
    }
    
    override func didPerformBatchEditToolbarAction(_ action: BatchEditToolbarAction) -> Bool {
        guard let collectionView = collectionView, let selectedIndexPaths = collectionView.indexPathsForSelectedItems else {
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
    
}

// MARK: - SavedViewControllerDelegate

extension SavedArticlesCollectionViewController: SavedViewControllerDelegate {
    
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
        if let popoverController = alert.popoverPresentationController, let collectionView = collectionView, let first = collectionView.visibleCells.first {
            popoverController.sourceView = first
            popoverController.sourceRect = first.bounds
        }
        present(alert, animated: true, completion: nil)
    }
}

// MARK: - AddArticlesToReadingListViewControllerDelegate

extension SavedArticlesCollectionViewController: AddArticlesToReadingListDelegate {
    func viewControllerWillBeDismissed() {
        editController.close()
    }
    func addedArticleToReadingList(named name: String) {
        editController.close()
    }
}

// MARK: - UISearchBarDelegate

extension SavedArticlesCollectionViewController: UISearchBarDelegate {
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
