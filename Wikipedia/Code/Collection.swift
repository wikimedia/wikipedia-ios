protocol Collection: AnyObject {
    var collectionView: UICollectionView { get set }
}

protocol UpdatableCollection: Collection, CollectionViewUpdaterDelegate {
    associatedtype T: NSManagedObject
    var dataStore: MWKDataStore { get }
    var collectionViewUpdater: CollectionViewUpdater<T>? { get set }
    var fetchedResultsController: NSFetchedResultsController<T>? { get set }
    var basePredicate: NSPredicate { get }
    var baseSortDescriptors: [NSSortDescriptor] { get }
    func setupFetchedResultsController()
}

extension UpdatableCollection {
    func setupCollectionViewUpdater() {
        guard let fetchedResultsController = fetchedResultsController else {
            return
        }
        collectionViewUpdater = CollectionViewUpdater(fetchedResultsController: fetchedResultsController, collectionView: collectionView)
        collectionViewUpdater?.delegate = self
    }
    
    func fetch() {
        collectionViewUpdater?.performFetch()
    }

    func reset() {
        setupFetchedResultsController()
        setupCollectionViewUpdater()
        fetch()
    }
}

extension UpdatableCollection where Self: SearchableCollection {
    func setupFetchedResultsController() {
        guard let request = T.fetchRequest() as? NSFetchRequest<T> else {
            assertionFailure("Can't set up NSFetchRequest")
            return
        }
        request.predicate = basePredicate
        if let searchPredicate = searchPredicate {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [basePredicate, searchPredicate])
        }
        
        request.sortDescriptors = baseSortDescriptors
        fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: dataStore.viewContext, sectionNameKeyPath: nil, cacheName: nil)
    }
}

protocol SearchableCollection: UpdatableCollection {
    var searchString: String? { get set }
    func updateSearchString(_ newSearchString: String)
    var searchPredicate: NSPredicate? { get }
}

extension SearchableCollection where Self: EditableCollection {
    func updateSearchString(_ newSearchString: String) {
        guard newSearchString != searchString else {
            return
        }
        searchString = newSearchString.isEmpty ? nil : newSearchString
        editController.close()
        reset()
    }
}

enum SortActionType: Int {
    case byTitle, byRecentlyAdded
    
    func action(with sortDescriptors: [NSSortDescriptor], handler: @escaping ([NSSortDescriptor], UIAlertAction, Int) -> Void) -> SortAction {
        let title: String
        switch self {
        case .byTitle:
            title = WMFLocalizedString("sort-by-title-action", value: "Title", comment: "Title of the sort action that allows sorting items by title.")
        case .byRecentlyAdded:
            title = WMFLocalizedString("sort-by-recently-added-action", value: "Recently added", comment: "Title of the sort action that allows sorting items by date added.")
        }
        
        let alertAction = UIAlertAction(title: title, style: .default) { (alertAction) in
            handler(sortDescriptors, alertAction, self.rawValue)
        }
        return SortAction(alertAction: alertAction, type: self, sortDescriptors: sortDescriptors)
    }
}

struct SortAction {
    let alertAction: UIAlertAction
    let type: SortActionType
    let sortDescriptors: [NSSortDescriptor]
}

protocol SortableCollection: UpdatableCollection {
    var sort: (descriptors: [NSSortDescriptor], alertAction: UIAlertAction?) { get }
    var defaultSortAction: SortAction? { get }
    var defaultSortDescriptors: [NSSortDescriptor] { get }
    var sortActions: [SortActionType: SortAction] { get }
    var sortAlert: UIAlertController { get }
    func presentSortAlert(from button: UIButton)
    func updateSortActionCheckmark()
}

extension SortableCollection where Self: UIViewController {
    
    func alert(title: String, message: String?) -> UIAlertController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        sortActions.values.forEach { alert.addAction($0.alertAction) }
        let cancel = UIAlertAction(title: CommonStrings.cancelActionTitle, style: .cancel)
        alert.addAction(cancel)
        return alert
    }
    
    func updateSortActionCheckmark() {
        // hax https://stackoverflow.com/questions/40647039/how-to-add-uiactionsheet-button-check-mark
        let checkedKey = "checked"
        sortActions.values.forEach { $0.alertAction.setValue(false, forKey: checkedKey) }
        let checkedAction = sort.alertAction ?? defaultSortAction?.alertAction
        checkedAction?.setValue(true, forKey: checkedKey)
    }
    
    func presentSortAlert(from button: UIButton) {
        if let popoverController = sortAlert.popoverPresentationController {
            popoverController.sourceView = button
            popoverController.sourceRect = button.bounds
        }
        present(sortAlert, animated: true)
        updateSortActionCheckmark()
    }
    
    var baseSortDescriptors: [NSSortDescriptor] {
        return sort.descriptors.isEmpty ? defaultSortDescriptors : sort.descriptors
    }
    
    var defaultSortDescriptors: [NSSortDescriptor] {
        guard let defaultSortAction = defaultSortAction else {
            assertionFailure("Sort action not found")
            return []
        }
        return defaultSortAction.sortDescriptors
    }
}

protocol EditableCollection: Collection {
    var editController: CollectionViewEditController! { get set }
    var shouldShowEditButtonsForEmptyState: Bool { get }
    func setupEditController()
}

extension EditableCollection where Self: ActionDelegate {
    func setupEditController() {
        editController = CollectionViewEditController(collectionView: collectionView)
        editController.delegate = self
        editController.shouldShowEditButtonsForEmptyState = shouldShowEditButtonsForEmptyState
        if let navigationDelegate = self as? CollectionViewEditControllerNavigationDelegate {
            editController.navigationDelegate = navigationDelegate
        }
    }
    
    var shouldShowEditButtonsForEmptyState: Bool {
        return false
    }
}
