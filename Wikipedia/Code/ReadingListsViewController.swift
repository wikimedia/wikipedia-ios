import Foundation

@objc(WMFReadingListsViewController)
class ReadingListsViewController: ColumnarCollectionViewController {
    
    let dataStore: MWKDataStore
    let managedObjectContext: NSManagedObjectContext
    let readingListsController: ReadingListsController
    var fetchedResultsController: NSFetchedResultsController<ArticleList>!
    
    
    func setupFetchedResultsControllerOrdered(by key: String, ascending: Bool) {
        let request: NSFetchRequest<ArticleList> = ArticleList.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        do {
            try fetchedResultsController.performFetch()
        } catch let error {
            DDLogError("Error fetching reading lists: \(error)")
        }
        collectionView?.reloadData()
    }
    
    init(with dataStore: MWKDataStore) {
        self.dataStore = dataStore
        self.managedObjectContext = dataStore.viewContext
        self.readingListsController = dataStore.readingListsController
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not supported")
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupFetchedResultsControllerOrdered(by: "name", ascending: true)
    }
    
}
