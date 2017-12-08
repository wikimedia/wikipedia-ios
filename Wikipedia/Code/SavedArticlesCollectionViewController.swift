import UIKit
import WMF

class SavedArticleCollectionViewCell: SavedCollectionViewCell {
}

class ReadingListTag: SizeThatFitsView {
    fileprivate let label: UILabel = UILabel()
    let padding = UIEdgeInsetsMake(3, 3, 3, 3)
    
    override func setup() {
        super.setup()
        layer.borderWidth = 1
        label.isOpaque = true
        addSubview(label)
    }
    
    var readingListName: String = "" {
        didSet {
            label.text = String.localizedStringWithFormat("%d", readingListName)
            setNeedsLayout()
        }
    }
    
    var labelBackgroundColor: UIColor? {
        didSet {
            label.backgroundColor = labelBackgroundColor
        }
    }
    
    override func tintColorDidChange() {
        label.textColor = tintColor
        layer.borderColor = tintColor.cgColor
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        label.font = UIFont.wmf_preferredFontForFontFamily(.system, withTextStyle: .footnote, compatibleWithTraitCollection: traitCollection)
    }
    
    override func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        let insetSize = UIEdgeInsetsInsetRect(CGRect(origin: .zero, size: size), padding)
        let labelSize = label.sizeThatFits(insetSize.size)
        if (apply) {
            layer.cornerRadius = 3
            label.frame = CGRect(origin: CGPoint(x: 0.5*size.width - 0.5*labelSize.width, y: 0.5*size.height - 0.5*labelSize.height), size: labelSize)
        }
        let width = labelSize.width + padding.left + padding.right
        let height = labelSize.height + padding.top + padding.bottom
        let dimension = max(width, height)
        return CGSize(width: dimension, height: dimension)
    }
}

@objc(WMFSavedArticlesCollectionViewController)
class SavedArticlesCollectionViewController: ArticleFetchedResultsViewController {
    
    fileprivate let reuseIdentifier = "SavedArticleCollectionViewCell"
    
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
        register(SavedArticleCollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier, addPlaceholder: true)
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
        guard let savedArticleCell = cell as? SavedArticleCollectionViewCell else {
            return cell
        }
        configure(cell: savedArticleCell, forItemAt: indexPath, layoutOnly: false)
        return cell
    }
    
    override func configure(cell: ArticleRightAlignedImageCollectionViewCell, forItemAt indexPath: IndexPath, layoutOnly: Bool) {
        super.configure(cell: cell, forItemAt: indexPath, layoutOnly: layoutOnly)
        cell.batchEditAction = batchEditAction(at: indexPath)
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

    override func didBatchSelect(_ action: BatchEditAction) -> Bool {
        let indexPath = action.indexPath
        
        switch action.type {
        case .select:
            select(at: indexPath)
            UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, WMFLocalizedString("item-selected-accessibility-notification", value: "Item selected", comment: "Notification spoken after user batch selects an item from the list."))
            return true
        }
        
    }
    
    fileprivate func select(at indexPath: IndexPath) {
        guard let collectionView = collectionView, let isSelected = collectionView.cellForItem(at: indexPath)?.isSelected else {
            return
        }
        
        if isSelected {
            collectionView.deselectItem(at: indexPath, animated: true)
        } else {
            collectionView.selectItem(at: indexPath, animated: true, scrollPosition: .bottom)
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? BatchEditableCell,  cell.batchEditingState != .open  else {
            return
        }
        super.collectionView(collectionView, didSelectItemAt: indexPath)
    }
    
    func batchEditAction(at indexPath: IndexPath) -> BatchEditAction {
        return BatchEditActionType.select.action(with: self, indexPath: indexPath)
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
            return true
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

extension SavedArticlesCollectionViewController: AddArticlesToReadingListViewControllerDelegate {
    func viewControllerWillBeDismissed() {
        editController.close()
    }
}

// MARK: - UISearchBarDelegate

extension SavedArticlesCollectionViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            searchString = nil
        } else {
           searchString = searchText
        }
    }
}
