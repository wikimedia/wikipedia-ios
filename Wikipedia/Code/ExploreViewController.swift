import UIKit
import WMF

class ExploreCardViewController: ColumnarCollectionViewController, CardContent {
    override func viewDidLoad() {
        super.viewDidLoad()
        register(AnnouncementCollectionViewCell.self, forCellWithReuseIdentifier: "AnnouncementCollectionViewCell", addPlaceholder: true)
        register(ArticleRightAlignedImageCollectionViewCell.self, forCellWithReuseIdentifier: "ArticleRightAlignedImageCollectionViewCell", addPlaceholder: true)
        register(RankedArticleCollectionViewCell.self, forCellWithReuseIdentifier: "RankedArticleCollectionViewCell", addPlaceholder: true)
        register(ArticleFullWidthImageCollectionViewCell.self, forCellWithReuseIdentifier: "ArticleFullWidthImageCollectionViewCell", addPlaceholder: true)
        register(NewsCollectionViewCell.self, forCellWithReuseIdentifier: "NewsCollectionViewCell", addPlaceholder: true)
        register(OnThisDayExploreCollectionViewCell.self, forCellWithReuseIdentifier: "OnThisDayExploreCollectionViewCell", addPlaceholder: true)
        register(WMFNearbyArticleCollectionViewCell.wmf_classNib(), forCellWithReuseIdentifier: WMFNearbyArticleCollectionViewCell.wmf_nibName())
        register(WMFPicOfTheDayCollectionViewCell.wmf_classNib(), forCellWithReuseIdentifier: WMFPicOfTheDayCollectionViewCell.wmf_nibName())
    }
    
    var dataStore: MWKDataStore!
    
    public var contentGroup: WMFContentGroup! {
        didSet {
            collectionView.reloadData()
        }
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let preview = contentGroup.contentPreview as? [Any] else {
            return 1
        }
        let countOfFeedContent = preview.count
        switch contentGroup.contentGroupKind {
        case .news:
            return 1
        case .onThisDay:
            return 1
        case .relatedPages:
            return min(countOfFeedContent, Int(contentGroup.maxNumberOfCells()) + 1)
        default:
            return min(countOfFeedContent, Int(contentGroup.maxNumberOfCells()))
        }
    }
    
    private func resuseIdentifierAt(_ indexPath: IndexPath) -> String {
        return "ArticleRightAlignedImageCollectionViewCell"
    }
    
    private func articleURL(forItemAt indexPath: IndexPath) -> URL? {
        let displayType = contentGroup.displayTypeForItem(at: indexPath.row)
        var index = indexPath.row
        switch displayType {
        case .relatedPagesSourceArticle:
            return contentGroup.articleURL
        case .relatedPages:
            index = indexPath.row - 1
        case .ranked:
            guard let content = contentGroup.contentPreview as? [WMFFeedTopReadArticlePreview], content.count > indexPath.row else {
                return nil
            }
            return content[indexPath.row].articleURL
        default:
            break
        }
        
        if let contentURL = contentGroup.contentPreview as? URL {
            return contentURL
        }
        
        guard let content = contentGroup.contentPreview as? [URL], content.count > index else {
            return nil
        }
        
        return content[index]
    }
    
    private func configure(cell: UICollectionViewCell, forItemAt indexPath: IndexPath, layoutOnly: Bool) {
        guard let cell = cell as? ArticleCollectionViewCell else {
            return
        }
        guard let articleURL = articleURL(forItemAt: indexPath), let article = dataStore.fetchArticle(with: articleURL) else {
            return
        }
        cell.configure(article: article, displayType: WMFFeedDisplayType.page, index: 0, count: 0, theme: theme, layoutOnly: layoutOnly)
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: resuseIdentifierAt(indexPath), for: indexPath)
        configure(cell: cell, forItemAt: indexPath, layoutOnly: false)
        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, estimatedHeightForItemAt indexPath: IndexPath, forColumnWidth columnWidth: CGFloat) -> WMFLayoutEstimate {
        var estimate = WMFLayoutEstimate(precalculated: false, height: 100)
        guard let placeholderCell = placeholder(forCellWithReuseIdentifier: resuseIdentifierAt(indexPath)) as? CollectionViewCell else {
            return estimate
        }
        configure(cell: placeholderCell, forItemAt: indexPath, layoutOnly: true)
        estimate.height = placeholderCell.sizeThatFits(CGSize(width: columnWidth, height: UIViewNoIntrinsicMetric), apply: false).height
        estimate.precalculated = true
        return estimate
    }

    override func metrics(withBoundsSize size: CGSize, readableWidth: CGFloat) -> WMFCVLMetrics {
        return WMFCVLMetrics.singleColumnMetrics(withBoundsSize: size, readableWidth: readableWidth, interItemSpacing: 0, interSectionSpacing: 0)
    }

    func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        self.layout.invalidateLayout()
        self.layout.prepare()
        return self.layout.collectionViewContentSize
    }
    
}

class ExploreViewController: ColumnarCollectionViewController {
    fileprivate let cellReuseIdentifier = "org.wikimedia.explore.card.cell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        register(ExploreCardCollectionViewCell.self, forCellWithReuseIdentifier: cellReuseIdentifier, addPlaceholder: true)
    }
    
    private var cardViewControllers: [IndexPath: ExploreCardViewController] = [:]
    private var reusableCardViewControllers: Set<ExploreCardViewController> = []
    
    
    
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
        var cardVC = cardViewControllers[indexPath]
        if cardVC == nil {
            cardVC = reusableCardViewControllers.first
            if cardVC == nil {
                let newCardVC = ExploreCardViewController()
                newCardVC.dataStore = dataStore
                addChildViewController(newCardVC)
                didMove(toParentViewController: self)
                cardVC = newCardVC
            }
            cardVC?.contentGroup = group
            if let cardVC = cardVC, !layoutOnly {
                cardViewControllers[indexPath] = cardVC
                reusableCardViewControllers.remove(cardVC)
            }
        }
        cell.cardContent = cardVC
        cell.titleLabel.text = group.headerTitle()
        cell.subtitleLabel.text = group.headerSubTitle()
        cell.footerButton.setTitle(group.moreTitle(), for: .normal)
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let vc = cardViewControllers.removeValue(forKey: indexPath) else {
            return
        }
        reusableCardViewControllers.insert(vc)
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
