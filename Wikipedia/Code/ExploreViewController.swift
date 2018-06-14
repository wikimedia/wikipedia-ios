import UIKit
import WMF


class ExploreViewController: ColumnarCollectionViewController {
    fileprivate let cellReuseIdentifier = "org.wikimedia.explore.card.cell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        layoutManager.register(ExploreCardCollectionViewCell.self, forCellWithReuseIdentifier: cellReuseIdentifier, addPlaceholder: true)
    }
    
    private var cardViewControllers: [IndexPath: ExploreCardViewController] = [:]
    private var reusableCardViewControllers: [ExploreCardViewController] = []

    
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
        cell.apply(theme: theme)
        let width = self.layout.layoutAttributesForItem(at: indexPath)?.bounds.size.width ?? 1
        configure(cell: cell, forItemAt: indexPath, width: width, layoutOnly: false)
        return cell
    }
    
    func dequeueReusableCardViewController() -> ExploreCardViewController {
        if let cardVC = reusableCardViewControllers.last {
            reusableCardViewControllers.removeLast()
            return cardVC
        }
        
        let cardVC = ExploreCardViewController()
        cardVC.dataStore = dataStore
        cardVC.view.isHidden = true
        cardVC.view.autoresizingMask = []
        addChildViewController(cardVC)
        view.addSubview(cardVC.view)
        cardVC.didMove(toParentViewController: self)
        return cardVC
    }
    
    func enqueueReusableCardViewController(_ cardVC: ExploreCardViewController) {
        cardVC.view.removeFromSuperview()
        cardVC.view.isHidden = true
        view.addSubview(cardVC.view)
        reusableCardViewControllers.append(cardVC)
    }
    
    func configure(cell: ExploreCardCollectionViewCell, forItemAt indexPath: IndexPath, width: CGFloat, layoutOnly: Bool) {
        let group = fetchedResultsController.object(at: indexPath)
        let cardVC = dequeueReusableCardViewController()
        assert(cardVC.view.superview === view)
        cardVC.view.frame = CGRect(origin: .zero, size: CGSize(width: cell.contentWidth(for: width), height: 100))
        cardVC.contentGroup = group
        cell.cardContentSize = cardVC.precalculatedLayoutSize
        if layoutOnly {
            enqueueReusableCardViewController(cardVC)
        } else {
            cell.cardContent = cardVC
        }
        cell.titleLabel.text = group.headerTitle()
        cell.subtitleLabel.text = group.headerSubTitle()
        cell.footerButton.setTitle(group.moreTitle(), for: .normal)
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? ExploreCardCollectionViewCell, let vc = cell.cardContent as? ExploreCardViewController else {
            return
        }
        cell.cardContent = nil
        enqueueReusableCardViewController(vc)
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
        guard let placeholderCell = layoutManager.placeholder(forCellWithReuseIdentifier: cellReuseIdentifier) as? ExploreCardCollectionViewCell else {
            return estimate
        }
        placeholderCell.prepareForReuse()
        configure(cell: placeholderCell, forItemAt: indexPath, width: columnWidth, layoutOnly: true)
        estimate.height = placeholderCell.sizeThatFits(CGSize(width: columnWidth, height: UIViewNoIntrinsicMetric), apply: false).height
        estimate.precalculated = true
        return estimate
    }
    
    override func metrics(withBoundsSize size: CGSize, readableWidth: CGFloat) -> WMFCVLMetrics {
        return WMFCVLMetrics(boundsSize: size, readableWidth: readableWidth, layoutDirection: UIApplication.shared.userInterfaceLayoutDirection)
    }
}
