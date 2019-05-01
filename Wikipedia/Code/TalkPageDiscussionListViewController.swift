
import UIKit

protocol TalkPageDiscussionListDelegate: class {
    func tappedDiscussion(_ discussion: TalkPageDiscussion, viewController: TalkPageDiscussionListViewController)
}

class TalkPageDiscussionListViewController: ColumnarCollectionViewController {
    
    weak var delegate: TalkPageDiscussionListDelegate?
    
    private var dataStore: MWKDataStore
    private var talkPage: TalkPage
    
    private var fetchedResultsController: NSFetchedResultsController<TalkPageDiscussion>!
    private var collectionViewUpdater: CollectionViewUpdater<TalkPageDiscussion>!
    
    private var cellLayoutEstimate: ColumnarCollectionViewLayoutHeightEstimate?
    private let reuseIdentifier = "DiscussionListItemCollectionViewCell"
    
    required init(dataStore: MWKDataStore, talkPage: TalkPage) {
        self.dataStore = dataStore
        self.talkPage = talkPage
        
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        layoutManager.register(DiscussionListItemCollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier, addPlaceholder: true)
        
        setupFetchedResultsController(with: dataStore)
        collectionViewUpdater = CollectionViewUpdater(fetchedResultsController: fetchedResultsController, collectionView: collectionView)
        collectionViewUpdater?.delegate = self
        collectionViewUpdater?.performFetch()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        cellLayoutEstimate = nil
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        guard let sectionsCount = fetchedResultsController.sections?.count else {
            return 0
        }
        return sectionsCount
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let sections = fetchedResultsController.sections,
            section < sections.count else {
            return 0
        }
        return sections[section].numberOfObjects
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as? DiscussionListItemCollectionViewCell else {
                return UICollectionViewCell()
        }
        
        configure(cell: cell, at: indexPath)
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, estimatedHeightForItemAt indexPath: IndexPath, forColumnWidth columnWidth: CGFloat) -> ColumnarCollectionViewLayoutHeightEstimate {
        
        // The layout estimate can be re-used in this case because label is one line, meaning the cell
        // size only varies with font size. The layout estimate is nil'd when the font size changes on trait collection change
        if let estimate = cellLayoutEstimate {
            return estimate
        }
        var estimate = ColumnarCollectionViewLayoutHeightEstimate(precalculated: false, height: 54)
        guard let placeholderCell = layoutManager.placeholder(forCellWithReuseIdentifier: reuseIdentifier) as? DiscussionListItemCollectionViewCell else {
            return estimate
        }
        configure(cell: placeholderCell, at: indexPath)
        estimate.height = placeholderCell.sizeThatFits(CGSize(width: columnWidth, height: UIView.noIntrinsicMetric), apply: false).height
        estimate.precalculated = true
        cellLayoutEstimate = estimate
        return estimate
    }
    
    override func metrics(with size: CGSize, readableWidth: CGFloat, layoutMargins: UIEdgeInsets) -> ColumnarCollectionViewLayoutMetrics {
        return ColumnarCollectionViewLayoutMetrics.tableViewMetrics(with: size, readableWidth: readableWidth, layoutMargins: layoutMargins)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let discussion = fetchedResultsController.object(at: indexPath)
        delegate?.tappedDiscussion(discussion, viewController: self)
    }
}

private extension TalkPageDiscussionListViewController {
    func setupFetchedResultsController(with dataStore: MWKDataStore) {
        
        let request: NSFetchRequest<TalkPageDiscussion> = TalkPageDiscussion.fetchRequest()
        request.predicate = NSPredicate(format: "talkPage == %@",  talkPage)
        request.sortDescriptors = [NSSortDescriptor(key: "talkPage", ascending: true)] //todo: I am forced to use this, does this keep original ordering?
        fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: dataStore.viewContext, sectionNameKeyPath: nil, cacheName: nil)
    }
    
    func configure(cell: DiscussionListItemCollectionViewCell, at indexPath: IndexPath) {
        guard let title = fetchedResultsController.object(at: indexPath).title else {
            return
        }
        
        cell.configure(title: title)
        cell.layoutMargins = layout.itemLayoutMargins
        cell.apply(theme: theme)
    }
}

extension TalkPageDiscussionListViewController: CollectionViewUpdaterDelegate {
    func collectionViewUpdater<T>(_ updater: CollectionViewUpdater<T>, didUpdate collectionView: UICollectionView) where T : NSFetchRequestResult {
        for indexPath in collectionView.indexPathsForVisibleItems {
            guard let cell = collectionView.cellForItem(at: indexPath) as? DiscussionListItemCollectionViewCell else {
                continue
            }
            
            configure(cell: cell, at: indexPath)
        }
    }
    
    func collectionViewUpdater<T>(_ updater: CollectionViewUpdater<T>, updateItemAtIndexPath indexPath: IndexPath, in collectionView: UICollectionView) where T : NSFetchRequestResult {
        //no-op
    }
}
