
import UIKit

protocol TalkPageTopicListDelegate: class {
    func tappedTopic(_ topic: TalkPageTopic, viewController: TalkPageTopicListViewController)
    func scrollViewDidScroll(_ scrollView: UIScrollView, viewController: TalkPageTopicListViewController)
    func didTriggerRefresh(viewController: TalkPageTopicListViewController)
}

class TalkPageTopicListViewController: ColumnarCollectionViewController {
    
    weak var delegate: TalkPageTopicListDelegate?
    
    private let dataStore: MWKDataStore
    private let talkPageTitle: String
    private let talkPage: TalkPage
    private let fetchedResultsController: NSFetchedResultsController<TalkPageTopic>
    
    private let reuseIdentifier = "TalkPageTopicCell"
    
    private var collectionViewUpdater: CollectionViewUpdater<TalkPageTopic>!
    private var cellLayoutEstimate: ColumnarCollectionViewLayoutHeightEstimate?
    
    private let siteURL: URL
    private let type: TalkPageType
    private let talkPageSemanticContentAttribute: UISemanticContentAttribute
    
    var fromNavigationStateRestoration: Bool = false

    required init(dataStore: MWKDataStore, talkPageTitle: String, talkPage: TalkPage, siteURL: URL, type: TalkPageType, talkPageSemanticContentAttribute: UISemanticContentAttribute) {
        self.dataStore = dataStore
        self.talkPageTitle = talkPageTitle
        self.talkPage = talkPage
        self.siteURL = siteURL
        self.type = type
        self.talkPageSemanticContentAttribute = talkPageSemanticContentAttribute
        
        let request: NSFetchRequest<TalkPageTopic> = TalkPageTopic.fetchRequest()
        request.predicate = NSPredicate(format: "talkPage == %@ && isIntro == NO",  talkPage)
        request.relationshipKeyPathsForPrefetching = ["content"]
        request.sortDescriptors = [NSSortDescriptor(key: "sort", ascending: true)]
        self.fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: dataStore.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        isRefreshControlEnabled = true
        registerCells()
        setupCollectionViewUpdater()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        //T226732 - workaround for when navigation bar maxY doesn't include top safe area height when returning from state restoration which results in a scroll view inset bug
        if fromNavigationStateRestoration {
            navigationBar.setNeedsLayout()
            navigationBar.layoutIfNeeded()
            updateScrollViewInsets()
            fromNavigationStateRestoration = false
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func refresh() {
        delegate?.didTriggerRefresh(viewController: self)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        cellLayoutEstimate = nil
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { _ in
            //
        }) { _ in
            self.updateScrollViewInsets()
        }
        super.willTransition(to: newCollection, with: coordinator)
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        super.scrollViewDidScroll(scrollView)
        delegate?.scrollViewDidScroll(scrollView, viewController: self)
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
        
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as? TalkPageTopicCell else {
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
        guard let placeholderCell = layoutManager.placeholder(forCellWithReuseIdentifier: reuseIdentifier) as? TalkPageTopicCell else {
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
    
    @objc func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let topic = fetchedResultsController.object(at: indexPath)
        delegate?.tappedTopic(topic, viewController: self)
    }
    
    override func apply(theme: Theme) {
        super.apply(theme: theme)
        
        guard viewIfLoaded != nil else {
            return
        }
        
        collectionView.backgroundColor = theme.colors.baseBackground
    }
}

//MARK: Private

private extension TalkPageTopicListViewController {
    
    func registerCells() {
        layoutManager.register(TalkPageTopicCell.self, forCellWithReuseIdentifier: reuseIdentifier, addPlaceholder: true)
    }
    
    func setupCollectionViewUpdater() {
        collectionViewUpdater = CollectionViewUpdater(fetchedResultsController: fetchedResultsController, collectionView: collectionView)
        collectionViewUpdater?.delegate = self
        collectionViewUpdater?.performFetch()
    }
    
    
    
    func configure(cell: TalkPageTopicCell, at indexPath: IndexPath) {
        let topic = fetchedResultsController.object(at: indexPath)
        guard let title = topic.title else {
            return
        }
        
        cell.configure(title: title, isRead: topic.isRead)
        cell.layoutMargins = layout.itemLayoutMargins
        cell.semanticContentAttributeOverride = talkPageSemanticContentAttribute
        cell.accessibilityTraits = .button
        cell.apply(theme: theme)
    }
}

//MARK: CollectionViewUpdaterDelegate

extension TalkPageTopicListViewController: CollectionViewUpdaterDelegate {
    func collectionViewUpdater<T>(_ updater: CollectionViewUpdater<T>, didUpdate collectionView: UICollectionView) where T : NSFetchRequestResult {
        for indexPath in collectionView.indexPathsForVisibleItems {
            guard let cell = collectionView.cellForItem(at: indexPath) as? TalkPageTopicCell else {
                continue
            }
            
            configure(cell: cell, at: indexPath)
        }
    }
    
    func collectionViewUpdater<T>(_ updater: CollectionViewUpdater<T>, updateItemAtIndexPath indexPath: IndexPath, in collectionView: UICollectionView) where T : NSFetchRequestResult {
        //no-op
    }
}
