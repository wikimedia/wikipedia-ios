
import UIKit

protocol TalkPageDiscussionListDelegate: class {
    func tappedDiscussion(_ discussion: TalkPageDiscussion, viewController: TalkPageDiscussionListViewController)
}

class TalkPageDiscussionListViewController: ColumnarCollectionViewController {
    
    weak var delegate: TalkPageDiscussionListDelegate?
    var dataStore: MWKDataStore!
    var talkPage: TalkPage! {
        didSet {
            setupFetchedResultsController(with: dataStore)
            if let fetchedResultsController = fetchedResultsController {
                collectionViewUpdater = CollectionViewUpdater(fetchedResultsController: fetchedResultsController, collectionView: collectionView)
                collectionViewUpdater?.delegate = self
                collectionViewUpdater?.performFetch()
            }
        }
    }
    
    private var fetchedResultsController: NSFetchedResultsController<TalkPageDiscussion>?
    private var collectionViewUpdater: CollectionViewUpdater<TalkPageDiscussion>?
    
    private let reuseIdentifier = "DiscussionListItemCollectionViewCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        layoutManager.register(DiscussionListItemCollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier, addPlaceholder: true)
    }
    
    private func setupFetchedResultsController(with dataStore: MWKDataStore) {

        let request: NSFetchRequest<TalkPageDiscussion> = TalkPageDiscussion.fetchRequest()
        request.predicate = NSPredicate(format: "talkPage == %@",  talkPage)
        request.sortDescriptors = [NSSortDescriptor(key: "talkPage", ascending: true)] //todo: I am forced to use this, does this keep original ordering?
        fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: dataStore.viewContext, sectionNameKeyPath: nil, cacheName: nil)
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        guard let fetchedResultsController = fetchedResultsController,
            let sectionsCount = fetchedResultsController.sections?.count else {
            return 0
        }
        return sectionsCount
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let fetchedResultsController = fetchedResultsController,
            let sections = fetchedResultsController.sections,
            section < sections.count else {
            return 0
        }
        return sections[section].numberOfObjects
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let fetchedResultsController = fetchedResultsController,
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as? DiscussionListItemCollectionViewCell,
            let title = fetchedResultsController.object(at: indexPath).title else {
                return UICollectionViewCell()
        }
        
        cell.configure(title: title)
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, estimatedHeightForItemAt indexPath: IndexPath, forColumnWidth columnWidth: CGFloat) -> ColumnarCollectionViewLayoutHeightEstimate {
        let estimate = ColumnarCollectionViewLayoutHeightEstimate(precalculated: false, height: 100)
        return estimate
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let discussion = fetchedResultsController?.object(at: indexPath) else {
            return
        }
        
        delegate?.tappedDiscussion(discussion, viewController: self)
    }
}

extension TalkPageDiscussionListViewController: CollectionViewUpdaterDelegate {
    func collectionViewUpdater<T>(_ updater: CollectionViewUpdater<T>, didUpdate collectionView: UICollectionView) where T : NSFetchRequestResult {
        for indexPath in collectionView.indexPathsForVisibleItems {
            guard let fetchedResultsController = fetchedResultsController,
                let cell = collectionView.cellForItem(at: indexPath) as? DiscussionListItemCollectionViewCell,
                let title = fetchedResultsController.object(at: indexPath).title else {
                continue
            }
            
            cell.configure(title: title)
        }
    }
    
    func collectionViewUpdater<T>(_ updater: CollectionViewUpdater<T>, updateItemAtIndexPath indexPath: IndexPath, in collectionView: UICollectionView) where T : NSFetchRequestResult {
        //no-op
    }
}
