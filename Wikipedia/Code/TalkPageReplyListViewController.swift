
import UIKit

protocol TalkPageReplyListViewControllerDelegate: class {
    func tappedLink(_ url: URL, viewController: TalkPageReplyListViewController)
}

class TalkPageReplyListViewController: ColumnarCollectionViewController {
    
    private let discussion: TalkPageDiscussion
    private let dataStore: MWKDataStore
    
    private var fetchedResultsController: NSFetchedResultsController<TalkPageDiscussionItem>!
    private var collectionViewUpdater: CollectionViewUpdater<TalkPageDiscussionItem>!
    
    private let reuseIdentifier = "ReplyListItemCollectionViewCell"
    
    weak var delegate: TalkPageReplyListViewControllerDelegate?
    
    required init(dataStore: MWKDataStore, discussion: TalkPageDiscussion) {
        self.dataStore = dataStore
        self.discussion = discussion
        
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        layoutManager.register(ReplyListItemCollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier, addPlaceholder: true)
        layoutManager.register(TalkPageHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: TalkPageHeaderView.identifier, addPlaceholder: true)
        layoutManager.register(ReplyButtonFooterView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: ReplyButtonFooterView.identifier, addPlaceholder: true)
        
        setupFetchedResultsController(with: dataStore)
        collectionViewUpdater = CollectionViewUpdater(fetchedResultsController: fetchedResultsController, collectionView: collectionView)
        collectionViewUpdater?.delegate = self
        collectionViewUpdater?.performFetch()
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
        
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as? ReplyListItemCollectionViewCell else {
                return UICollectionViewCell()
        }
        
        configure(cell: cell, at: indexPath)
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, estimatedHeightForItemAt indexPath: IndexPath, forColumnWidth columnWidth: CGFloat) -> ColumnarCollectionViewLayoutHeightEstimate {
        var estimate = ColumnarCollectionViewLayoutHeightEstimate(precalculated: false, height: 54)
        guard let placeholderCell = layoutManager.placeholder(forCellWithReuseIdentifier: reuseIdentifier) as? ReplyListItemCollectionViewCell else {
            return estimate
        }
        configure(cell: placeholderCell, at: indexPath)
        estimate.height = placeholderCell.sizeThatFits(CGSize(width: columnWidth, height: UIView.noIntrinsicMetric), apply: false).height
        estimate.precalculated = true
        return estimate
    }
    
    override func metrics(with size: CGSize, readableWidth: CGFloat, layoutMargins: UIEdgeInsets) -> ColumnarCollectionViewLayoutMetrics {
        return ColumnarCollectionViewLayoutMetrics.tableViewMetrics(with: size, readableWidth: readableWidth, layoutMargins: layoutMargins)
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader,
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: TalkPageHeaderView.identifier, for: indexPath) as? TalkPageHeaderView {
                configure(header: header)
                return header
        }
        
        if kind == UICollectionView.elementKindSectionFooter,
            let footer = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: ReplyButtonFooterView.identifier, for: indexPath) as? ReplyButtonFooterView {
            configure(footer: footer)
            return footer
        }
        
        return UICollectionReusableView()
    }
    
    override func collectionView(_ collectionView: UICollectionView, estimatedHeightForHeaderInSection section: Int, forColumnWidth columnWidth: CGFloat) -> ColumnarCollectionViewLayoutHeightEstimate {
        
        var estimate = ColumnarCollectionViewLayoutHeightEstimate(precalculated: false, height: 100)
        guard let header = layoutManager.placeholder(forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: TalkPageHeaderView.identifier) as? TalkPageHeaderView else {
            return estimate
        }
        
        configure(header: header)
        estimate.height = header.sizeThatFits(CGSize(width: columnWidth, height: UIView.noIntrinsicMetric), apply: false).height
        estimate.precalculated = true
        return estimate
    }
    
    override func collectionView(_ collectionView: UICollectionView, estimatedHeightForFooterInSection section: Int, forColumnWidth columnWidth: CGFloat) -> ColumnarCollectionViewLayoutHeightEstimate {
        var estimate = ColumnarCollectionViewLayoutHeightEstimate(precalculated: false, height: 100)
        guard let footer = layoutManager.placeholder(forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: ReplyButtonFooterView.identifier) as? ReplyButtonFooterView else {
            return estimate
        }
        configure(footer: footer)
        estimate.height = footer.sizeThatFits(CGSize(width: columnWidth, height: UIView.noIntrinsicMetric), apply: false).height
        estimate.precalculated = true
        return estimate
    }

    override func apply(theme: Theme) {
        super.apply(theme: theme)
        view.backgroundColor = theme.colors.paperBackground
    }
}

extension TalkPageReplyListViewController: CollectionViewUpdaterDelegate {
    func collectionViewUpdater<T>(_ updater: CollectionViewUpdater<T>, didUpdate collectionView: UICollectionView) where T : NSFetchRequestResult {
        for indexPath in collectionView.indexPathsForVisibleItems {
            guard let cell = collectionView.cellForItem(at: indexPath) as? DiscussionListItemCollectionViewCell,
                let title = fetchedResultsController.object(at: indexPath).text else {
                    continue
            }
            
            cell.configure(title: title)
        }
    }
    
    func collectionViewUpdater<T>(_ updater: CollectionViewUpdater<T>, updateItemAtIndexPath indexPath: IndexPath, in collectionView: UICollectionView) where T : NSFetchRequestResult {
        //no-op
    }
}

private extension TalkPageReplyListViewController {
    
    func setupFetchedResultsController(with dataStore: MWKDataStore) {
        
        let request: NSFetchRequest<TalkPageDiscussionItem> = TalkPageDiscussionItem.fetchRequest()
        request.predicate = NSPredicate(format: "discussion == %@",  discussion)
        request.sortDescriptors = [NSSortDescriptor(key: "discussion", ascending: true)] //todo: I am forced to use this, does this keep original ordering?
        fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: dataStore.viewContext, sectionNameKeyPath: nil, cacheName: nil)
    }
    
    func configure(header: TalkPageHeaderView) {
        
        guard let title = discussion.title else {
                return
        }
        
        let headerText = WMFLocalizedString("talk-page-discussion-title", value: "Discussion", comment: "This header label is displayed at the top of a talk page discussion thread.").localizedUppercase
        
        let viewModel = TalkPageHeaderView.ViewModel(header: headerText, title: title, info: nil)
        
        header.configure(viewModel: viewModel)
        header.layoutMargins = layout.itemLayoutMargins
        header.apply(theme: theme)
    }
    
    func configure(footer: ReplyButtonFooterView) {
        footer.layoutMargins = layout.itemLayoutMargins
        footer.apply(theme: theme)
    }
    
    func configure(cell: ReplyListItemCollectionViewCell, at indexPath: IndexPath) {
        let item = fetchedResultsController.object(at: indexPath)
        guard let title = item.text,
        item.depth >= 0 else {
            return
        }
        
        cell.delegate = self
        cell.configure(title: title, depth: UInt(item.depth))
        cell.layoutMargins = layout.itemLayoutMargins
        cell.apply(theme: theme)
    }
}

extension TalkPageReplyListViewController: ReplyListItemCollectionViewCellDelegate {
    func tappedLink(_ url: URL, cell: ReplyListItemCollectionViewCell) {
        
        delegate?.tappedLink(url, viewController: self)
    }
}
