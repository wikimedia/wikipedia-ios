import Foundation

class ReadingListCollectionViewCell: ArticleRightAlignedImageCollectionViewCell {
    func configure(readingList: ReadingList, index: Int, count: Int, shouldAdjustMargins: Bool = true, shouldShowSeparators: Bool = false, theme: Theme) {
        if shouldShowSeparators {
            topSeparator.isHidden = index != 0
            bottomSeparator.isHidden = false
        } else {
            bottomSeparator.isHidden = true
        }
        apply(theme: theme)
        
        isImageViewHidden = true
        titleLabel.text = readingList.name
        
        imageViewDimension = 40
        isSaveButtonHidden = true
        descriptionLabel.text = readingList.description
        extractLabel?.text = nil
        if (shouldAdjustMargins) {
            adjustMargins(for: index, count: count)
        }
        
        setNeedsLayout()
    }
}

@objc(WMFReadingListsCollectionViewController)
class ReadingListsCollectionViewController: ColumnarCollectionViewController {
    
    let dataStore: MWKDataStore
    let managedObjectContext: NSManagedObjectContext
    let readingListsController: ReadingListsController
    var fetchedResultsController: NSFetchedResultsController<ReadingList>!
    
    fileprivate let reuseIdentifier = "ReadingListCollectionViewCell"

    func setupFetchedResultsControllerOrdered(by key: String, ascending: Bool) {
        let request: NSFetchRequest<ReadingList> = ReadingList.fetchRequest()
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
        register(ArticleRightAlignedImageCollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier, addPlaceholder: true)
    }
    
    func readingList(at indexPath: IndexPath) -> ReadingList? {
        guard let sections = fetchedResultsController.sections,
            indexPath.section < sections.count,
            indexPath.item < sections[indexPath.section].numberOfObjects else {
                return nil
        }
        return fetchedResultsController.object(at: indexPath)
    }
    
    @objc func presentCreateReadingListViewController() {
        let createReadingListViewController = CreateReadingListViewController(theme: self.theme)
        createReadingListViewController.delegate = self
        present(createReadingListViewController, animated: true, completion: nil)
    }
    
}

extension ReadingListsCollectionViewController: CreateReadingListViewControllerDelegate {
    func createdNewReadingList(with name: String, description: String) {
        //
    }
}

// MARK: - UICollectionViewDataSource
extension ReadingListsCollectionViewController {
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
        
        guard let readingListCell = cell as? ReadingListCollectionViewCell, let readingList = readingList(at: indexPath) else {
            return cell
        }
        
        let numberOfItems = self.collectionView(collectionView, numberOfItemsInSection: indexPath.section)
        
        readingListCell.configure(readingList: readingList, index: indexPath.item, count: numberOfItems, shouldAdjustMargins: false, shouldShowSeparators: true, theme: theme)
        readingListCell.layoutMargins = layout.readableMargins
        
        return cell
    }

}
