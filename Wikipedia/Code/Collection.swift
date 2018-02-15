protocol Collection: class {
    var collectionView: UICollectionView { get set }
}

protocol UpdatableCollection: Collection, CollectionViewUpdaterDelegate {
    associatedtype T: NSManagedObject
    var dataStore: MWKDataStore { get }
    var collectionViewUpdater: CollectionViewUpdater<T>! { get set }
    var fetchedResultsController: NSFetchedResultsController<T>! { get set }
    var basePredicate: NSPredicate { get }
    var baseSortDescriptor: NSSortDescriptor { get }
    func setupFetchedResultsController()
    func setupCollectionViewUpdater()
    func fetch()
}

extension UpdatableCollection {
    func setupCollectionViewUpdater() {
        collectionViewUpdater = CollectionViewUpdater(fetchedResultsController: fetchedResultsController, collectionView: collectionView)
        collectionViewUpdater.delegate = self
    }
    
    func fetch() {
        do {
            try fetchedResultsController.performFetch()
        } catch let error {
            DDLogError("Error performing fetch: \(error)")
        }
        collectionView.reloadData()
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
        
        request.sortDescriptors = [baseSortDescriptor]
        fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: dataStore.viewContext, sectionNameKeyPath: nil, cacheName: nil)
    }
}

extension UpdatableCollection where Self: SearchableCollection & SortableCollection {
    func setupFetchedResultsController() {
        // hax https://stackoverflow.com/questions/40647039/how-to-add-uiactionsheet-button-check-mark
        let checkedKey = "checked"
        sortActions.forEach { $0.setValue(false, forKey: checkedKey) }
        if let checkedAction = sort.action {
            checkedAction.setValue(true, forKey: checkedKey)
        }

        guard let request = T.fetchRequest() as? NSFetchRequest<T> else {
            assertionFailure("Can't set up NSFetchRequest")
            return
        }
        request.predicate = basePredicate
        if let searchPredicate = searchPredicate {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [basePredicate, searchPredicate])
        }
        
        request.sortDescriptors = [baseSortDescriptor]
        
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
        setupFetchedResultsController()
        setupCollectionViewUpdater()
        fetch()
    }
}

protocol SortableCollection: UpdatableCollection {
    var sort: (descriptor: NSSortDescriptor, action: UIAlertAction?) { get set }
    var sortActions: [UIAlertAction] { get }
    var sortAlert: UIAlertController { get }
}

extension SortableCollection {
    // Return in a lazy implementation of sortAlert.
    var alert: UIAlertController {
        let alert = UIAlertController(title: "Sort saved articles", message: nil, preferredStyle: .actionSheet)
        sortActions.forEach { alert.addAction($0) }
        let cancel = UIAlertAction(title: CommonStrings.cancelActionTitle, style: .cancel)
        alert.addAction(cancel)
        if let popoverController = alert.popoverPresentationController, let first = collectionView.visibleCells.first {
            popoverController.sourceView = first
            popoverController.sourceRect = first.bounds
        }
        return alert
    }
    
    func updateSort(with newDescriptor: NSSortDescriptor, newAction: UIAlertAction) {
        guard sort.descriptor != newDescriptor else {
            return
        }
        sort = (descriptor: newDescriptor, action: newAction)
        setupFetchedResultsController()
        setupCollectionViewUpdater()
        fetch()
    }
    
    var baseSortDescriptor: NSSortDescriptor { return sort.descriptor }
}

protocol EditableCollection: Collection {
    var editController: CollectionViewEditController! { get set }
    func setupEditController()
}

extension EditableCollection where Self: ActionDelegate {
    func setupEditController() {
        editController = CollectionViewEditController(collectionView: collectionView)
        editController.delegate = self
        if let navigationDelegate = self as? BatchEditNavigationDelegate {
            editController.navigationDelegate = navigationDelegate
        }
    }
}
