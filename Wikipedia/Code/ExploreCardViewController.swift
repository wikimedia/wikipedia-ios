import UIKit

class ExploreCardViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, CardContent, WMFColumnarCollectionViewLayoutDelegate {
    lazy var layoutManager: ColumnarCollectionViewLayoutManager = {
        return ColumnarCollectionViewLayoutManager(view: view, collectionView: collectionView)
    }()
    
    lazy var layout: UICollectionViewLayout = {
        return WMFColumnarCollectionViewLayout()
    }()
    
    var collectionView: UICollectionView {
        return view as! UICollectionView
    }
    
    override func loadView() {
        super.loadView()
        self.view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
    }
    
    var theme: Theme = Theme.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.isScrollEnabled = false
        layoutManager.register(AnnouncementCollectionViewCell.self, forCellWithReuseIdentifier: "AnnouncementCollectionViewCell", addPlaceholder: true)
        layoutManager.register(ArticleRightAlignedImageCollectionViewCell.self, forCellWithReuseIdentifier: "ArticleRightAlignedImageCollectionViewCell", addPlaceholder: true)
        layoutManager.register(RankedArticleCollectionViewCell.self, forCellWithReuseIdentifier: "RankedArticleCollectionViewCell", addPlaceholder: true)
        layoutManager.register(ArticleFullWidthImageCollectionViewCell.self, forCellWithReuseIdentifier: "ArticleFullWidthImageCollectionViewCell", addPlaceholder: true)
        layoutManager.register(NewsCollectionViewCell.self, forCellWithReuseIdentifier: "NewsCollectionViewCell", addPlaceholder: true)
        layoutManager.register(OnThisDayExploreCollectionViewCell.self, forCellWithReuseIdentifier: "OnThisDayExploreCollectionViewCell", addPlaceholder: true)
        layoutManager.register(WMFNearbyArticleCollectionViewCell.wmf_classNib(), forCellWithReuseIdentifier: WMFNearbyArticleCollectionViewCell.wmf_nibName())
        layoutManager.register(WMFPicOfTheDayCollectionViewCell.wmf_classNib(), forCellWithReuseIdentifier: WMFPicOfTheDayCollectionViewCell.wmf_nibName())
    }
    
    var dataStore: MWKDataStore!
    
    public var contentGroup: WMFContentGroup? {
        didSet {
            collectionView.reloadData()
        }
    }
    
    public var precalculatedLayoutSize: CGSize {
        layout.invalidateLayout()
        layout.prepare()
        return layout.collectionViewContentSize
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        guard contentGroup != nil else {
            return 0
        }
        return 1
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return numberOfItems
    }
    
    var numberOfItems: Int {
        guard let contentGroup = contentGroup else {
            return 0
        }
        
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
    
    private func displayTypeAt(_ indexPath: IndexPath) -> WMFFeedDisplayType {
        return contentGroup?.displayTypeForItem(at: indexPath.row) ?? .page
    }
    
    private func resuseIdentifierAt(_ indexPath: IndexPath) -> String {
        switch displayTypeAt(indexPath) {
        case .ranked:
            return "RankedArticleCollectionViewCell"
        case .story:
            return "NewsCollectionViewCell"
        case .event:
            return "OnThisDayExploreCollectionViewCell"
        case .continueReading:
            fallthrough
        case .relatedPagesSourceArticle:
            fallthrough
        case .random:
            fallthrough
        case .pageWithPreview:
            return "ArticleFullWidthImageCollectionViewCell"
        case .photo:
            return WMFPicOfTheDayCollectionViewCell.wmf_nibName()
        case .pageWithLocation:
            return WMFNearbyArticleCollectionViewCell.wmf_nibName()
        case .page, .relatedPages, .mainPage, .compactList:
            return "ArticleRightAlignedImageCollectionViewCell"
        case .announcement, .notification, .theme, .readingList:
            return "AnnouncementCollectionViewCell"
        }
    }
    
    private func articleURL(forItemAt indexPath: IndexPath) -> URL? {
        guard let contentGroup = contentGroup else {
            return nil
        }
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
    
    var eventLoggingLabel: EventLoggingLabel? {
        return contentGroup?.eventLoggingLabel
    }
    
    private func configureArticleCell(_ cell: UICollectionViewCell, forItemAt indexPath: IndexPath, with displayType: WMFFeedDisplayType, layoutOnly: Bool) {
        guard let cell = cell as? ArticleCollectionViewCell, let articleURL = articleURL(forItemAt: indexPath), let article = dataStore?.fetchArticle(with: articleURL) else {
            return
        }
        cell.configure(article: article, displayType: displayType, index: indexPath.row, count: numberOfItems, shouldAdjustMargins: true, theme: theme, layoutOnly: layoutOnly)
        cell.saveButton.eventLoggingLabel = eventLoggingLabel
    }
    
    private func configureNearbyCell(_ cell: UICollectionViewCell, forItemAt indexPath: IndexPath, with displayType: WMFFeedDisplayType, layoutOnly: Bool) {
        guard let cell = cell as? WMFNearbyArticleCollectionViewCell, let articleURL = articleURL(forItemAt: indexPath), let article = dataStore?.fetchArticle(with: articleURL) else {
            return
        }
        cell.titleText = article.displayTitle
        cell.descriptionText = article.capitalizedWikidataDescription
        cell.setImageURL(article.imageURL(forWidth: traitCollection.wmf_nearbyThumbnailWidth))
        (cell as Themeable).apply(theme: theme)
    }
    
    private func configureNewsCell(_ cell: UICollectionViewCell, layoutOnly: Bool) {
        guard let cell = cell as? NewsCollectionViewCell, let story = contentGroup?.contentPreview as? WMFFeedNewsStory else {
            return
        }
        cell.configure(with: story, dataStore: dataStore, theme: theme, layoutOnly: layoutOnly)
    }
    
    private func configureOnThisDayCell(_ cell: UICollectionViewCell, layoutOnly: Bool) {
        guard let cell = cell as? OnThisDayExploreCollectionViewCell, let events = contentGroup?.contentPreview as? [WMFFeedOnThisDayEvent], events.count > 1 else {
            return
        }
        cell.configure(with: events[1], previousEvent: events[0], dataStore: dataStore, theme: theme, layoutOnly: layoutOnly)
    }
    
    private func configurePhotoCell(_ cell: UICollectionViewCell, layoutOnly: Bool) {
        guard let cell = cell as? WMFPicOfTheDayCollectionViewCell, let imageInfo = contentGroup?.contentPreview as? WMFFeedImage else {
            return
        }
        cell.setImageURL(imageInfo.imageThumbURL)
        if imageInfo.imageDescription.count > 0 {
            cell.setDisplayTitle(imageInfo.imageDescription.wmf_stringByRemovingHTML())
        } else {
            cell.setDisplayTitle(imageInfo.canonicalPageTitle)
        }
    }
    
    private func configure(cell: UICollectionViewCell, forItemAt indexPath: IndexPath, layoutOnly: Bool) {
        let displayType = displayTypeAt(indexPath)
        switch displayType {
        case .ranked, .page, .continueReading, .mainPage, .random, .pageWithPreview, .relatedPagesSourceArticle, .relatedPages, .compactList:
            configureArticleCell(cell, forItemAt: indexPath, with: displayType, layoutOnly: layoutOnly)
        case .pageWithLocation:
            configureNearbyCell(cell, forItemAt: indexPath, with: displayType, layoutOnly: layoutOnly)
        case .photo:
            break
        case .story:
            configureNewsCell(cell, layoutOnly: layoutOnly)
        case .event:
             configureOnThisDayCell(cell, layoutOnly: layoutOnly)
        case .theme, .notification, .announcement, .readingList:
            break
        }
    }
    
    
    
    // MARK - WMFColumnarCollectionViewLayoutDelegate
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: resuseIdentifierAt(indexPath), for: indexPath)
        configure(cell: cell, forItemAt: indexPath, layoutOnly: false)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, estimatedHeightForItemAt indexPath: IndexPath, forColumnWidth columnWidth: CGFloat) -> WMFLayoutEstimate {
        var estimate = WMFLayoutEstimate(precalculated: false, height: 100)
        guard let placeholderCell = layoutManager.placeholder(forCellWithReuseIdentifier: resuseIdentifierAt(indexPath)) as? CollectionViewCell else {
            return estimate
        }
        configure(cell: placeholderCell, forItemAt: indexPath, layoutOnly: true)
        estimate.height = placeholderCell.sizeThatFits(CGSize(width: columnWidth, height: UIViewNoIntrinsicMetric), apply: false).height
        estimate.precalculated = true
        return estimate
    }
    
    func collectionView(_ collectionView: UICollectionView, estimatedHeightForHeaderInSection section: Int, forColumnWidth columnWidth: CGFloat) -> WMFLayoutEstimate {
        return WMFLayoutEstimate(precalculated: true, height: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, estimatedHeightForFooterInSection section: Int, forColumnWidth columnWidth: CGFloat) -> WMFLayoutEstimate {
        return WMFLayoutEstimate(precalculated: true, height: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, prefersWiderColumnForSectionAt index: UInt) -> Bool {
        return index % 2 == 0
    }
    
    func metrics(withBoundsSize size: CGSize, readableWidth: CGFloat) -> WMFCVLMetrics {
        return WMFCVLMetrics.singleColumnMetrics(withBoundsSize: size, readableWidth: readableWidth, interItemSpacing: 0, interSectionSpacing: 0)
    }
}

