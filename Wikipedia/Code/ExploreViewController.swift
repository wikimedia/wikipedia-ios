import UIKit
import WMF

class ExploreViewController: ColumnarCollectionViewController {
    fileprivate let cellReuseIdentifier = "org.wikimedia.explore.card.cell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        register(ExploreCardCollectionViewCell.self, forCellWithReuseIdentifier: cellReuseIdentifier, addPlaceholder: true)
    }
    
    private var contentGroupViewControllers: [IndexPath: UIViewController] = [:]
    
    private var fetchedResultsController: NSFetchedResultsController<WMFContentGroup>!
    private var collectionViewUpdater: CollectionViewUpdater<WMFContentGroup>!

    @objc var dataStore: MWKDataStore! {
        didSet {
            let fetchRequest: NSFetchRequest<WMFContentGroup> = WMFContentGroup.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "isVisible == YES")
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "midnightUTCDate", ascending: false), NSSortDescriptor(key: "dailySortPriority", ascending: true), NSSortDescriptor(key: "date", ascending: false)]
            fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataStore.viewContext, sectionNameKeyPath: "midnightUTCDate", cacheName: nil)
            do {
                try fetchedResultsController.performFetch()
            } catch let error {
                DDLogError("Error fetching explore feed: \(error)")
            }
            collectionView.reloadData()
            collectionViewUpdater = CollectionViewUpdater(fetchedResultsController: fetchedResultsController, collectionView: collectionView)
            collectionViewUpdater.delegate = self
        }
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        guard let sections = fetchedResultsController.sections else {
            return 0
        }
        return sections.count
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let sections = fetchedResultsController.sections, sections.count > section else {
            return 0
        }
        return sections[section].numberOfObjects
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let maybeCell = collectionView.dequeueReusableCell(withReuseIdentifier: cellReuseIdentifier, for: indexPath)
        guard let cell = maybeCell as? ExploreCardCollectionViewCell else {
            return maybeCell
        }
        configure(cell: cell, forItemAt: indexPath, layoutOnly: false)
        return cell
    }
    
    func configure(cell: ExploreCardCollectionViewCell, forItemAt indexPath: IndexPath, layoutOnly: Bool) {
        let group = fetchedResultsController.object(at: indexPath)
        cell.titleLabel.text = group.headerTitle()
        cell.subtitleLabel.text = group.headerSubTitle()
        cell.footerButton.setTitle(group.moreTitle(), for: .normal)
    }
    
}


extension ExploreViewController: CollectionViewUpdaterDelegate {
    func collectionViewUpdater<T>(_ updater: CollectionViewUpdater<T>, didUpdate collectionView: UICollectionView) where T : NSFetchRequestResult {
        
    }
}

// MARK: - WMFColumnarCollectionViewLayoutDelegate
extension ExploreViewController {
    override func collectionView(_ collectionView: UICollectionView, estimatedHeightForItemAt indexPath: IndexPath, forColumnWidth columnWidth: CGFloat) -> WMFLayoutEstimate {
        var estimate = WMFLayoutEstimate(precalculated: false, height: 100)
        guard let placeholderCell = placeholder(forCellWithReuseIdentifier: cellReuseIdentifier) as? ExploreCardCollectionViewCell else {
            return estimate
        }
        placeholderCell.prepareForReuse()
        configure(cell: placeholderCell, forItemAt: indexPath, layoutOnly: true)
        estimate.height = placeholderCell.sizeThatFits(CGSize(width: columnWidth, height: UIViewNoIntrinsicMetric), apply: false).height
        estimate.precalculated = true
        return estimate
    }
    
    override func metrics(withBoundsSize size: CGSize, readableWidth: CGFloat) -> WMFCVLMetrics {
        return WMFCVLMetrics(boundsSize: size, readableWidth: readableWidth, layoutDirection: UIApplication.shared.userInterfaceLayoutDirection)
    }
}
