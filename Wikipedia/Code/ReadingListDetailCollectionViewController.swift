import UIKit

class ReadingListDetailExtendedNavBarView: UIView {
    
}

class ReadingListDetailCollectionViewController: ColumnarCollectionViewController {
    
    fileprivate let dataStore: MWKDataStore
    var fetchedResultsController: NSFetchedResultsController<ReadingListEntry>!
    fileprivate let readingList: ReadingList

    init(for readingList: ReadingList, with dataStore: MWKDataStore) {
        self.readingList = readingList
        self.dataStore = dataStore
        super.init()
    }
    
    func setupFetchedResultsControllerOrdered() {
        let request: NSFetchRequest<ReadingListEntry> = ReadingListEntry.fetchRequest()
        request.predicate = NSPredicate(format: "list == %@", readingList)
        request.sortDescriptors = [NSSortDescriptor(key: "displayTitle", ascending: true)]
        fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: dataStore.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        
        do {
            try fetchedResultsController.performFetch()
        } catch let error {
            DDLogError("Error fetching reading list entries: \(error)")
        }
        collectionView?.reloadData()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not supported")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        defer {
            apply(theme: theme)
        }
        
        navigationController?.navigationBar.topItem?.title = "Back"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: nil)
    }

}
