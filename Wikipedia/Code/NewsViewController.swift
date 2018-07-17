import WMF

@objc(WMFNewsViewController)
class NewsViewController: ColumnarCollectionViewController {
    fileprivate static let cellReuseIdentifier = "NewsCollectionViewCell"
    fileprivate static let headerReuseIdentifier = "NewsCollectionViewHeader"
    
    let stories: [WMFFeedNewsStory]
    let dataStore: MWKDataStore
    
    @objc required init(stories: [WMFFeedNewsStory], dataStore: MWKDataStore, theme: Theme) {
        self.stories = stories
        self.dataStore = dataStore
        super.init()
        self.theme = theme
        title = CommonStrings.inTheNewsTitle
        navigationItem.backBarButtonItem = UIBarButtonItem(title: CommonStrings.backTitle, style: .plain, target:nil, action:nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not supported")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        layoutManager.register(NewsCollectionViewCell.self, forCellWithReuseIdentifier: NewsViewController.cellReuseIdentifier, addPlaceholder: true)
        layoutManager.register(UINib(nibName: NewsViewController.headerReuseIdentifier, bundle: nil), forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: NewsViewController.headerReuseIdentifier, addPlaceholder: false)
        collectionView.allowsSelection = false
    }
    
    override func metrics(with size: CGSize, readableWidth: CGFloat, layoutMargins: UIEdgeInsets) -> ColumnarCollectionViewLayoutMetrics {
        return ColumnarCollectionViewLayoutMetrics.tableViewMetrics(with: size, readableWidth: readableWidth, layoutMargins: layoutMargins, interSectionSpacing: 22, interItemSpacing: 0)
    }
    
    // MARK: - ColumnarCollectionViewLayoutDelegate
    override func collectionView(_ collectionView: UICollectionView, estimatedHeightForHeaderInSection section: Int, forColumnWidth columnWidth: CGFloat) -> ColumnarCollectionViewLayoutHeightEstimate {
        return ColumnarCollectionViewLayoutHeightEstimate(precalculated: false, height: headerTitle(for: section) == nil ? 0 : 57)
    }
    
    override func collectionView(_ collectionView: UICollectionView, estimatedHeightForItemAt indexPath: IndexPath, forColumnWidth columnWidth: CGFloat) -> ColumnarCollectionViewLayoutHeightEstimate {
        var estimate = ColumnarCollectionViewLayoutHeightEstimate(precalculated: false, height: 350)
        guard let placeholderCell = layoutManager.placeholder(forCellWithReuseIdentifier: NewsViewController.cellReuseIdentifier) as? NewsCollectionViewCell else {
            return estimate
        }
        let story = stories[indexPath.section]
        placeholderCell.layoutMargins = layout.itemLayoutMargins
        placeholderCell.configure(with: story, dataStore: dataStore, theme: theme, layoutOnly: true)
        estimate.height = placeholderCell.sizeThatFits(CGSize(width: columnWidth, height: UIViewNoIntrinsicMetric), apply: false).height
        estimate.precalculated = true
        return estimate
    }
    
    override func apply(theme: Theme) {
        super.apply(theme: theme)
        guard viewIfLoaded != nil else {
            return
        }
        view.backgroundColor = theme.colors.paperBackground
        collectionView.backgroundColor = theme.colors.paperBackground
    }
}

// MARK: - UICollectionViewDataSource
extension NewsViewController {
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return stories.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NewsViewController.cellReuseIdentifier, for: indexPath)
        guard let newsCell = cell as? NewsCollectionViewCell else {
            return cell
        }
        cell.layoutMargins = layout.itemLayoutMargins
        let story = stories[indexPath.section]
        newsCell.configure(with: story, dataStore: dataStore, theme: theme, layoutOnly: false)
        return newsCell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionElementKindSectionHeader:
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: NewsViewController.headerReuseIdentifier, for: indexPath)
            guard let header = view as? NewsCollectionViewHeader else {
                return view
            }
            header.label.text = headerTitle(for: indexPath.section)
            header.apply(theme: theme)
            return header
        default:
            assert(false, "ensure you've registered cells and added cases to this switch statement to handle all header/footer types")
            return UICollectionReusableView()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? NewsCollectionViewCell else {
            return
        }
        cell.selectionDelegate = self
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? NewsCollectionViewCell else {
            return
        }
        cell.selectionDelegate = nil
    }
    
    static let headerDateFormatter: DateFormatter = {
        let headerDateFormatter = DateFormatter()
        headerDateFormatter.locale = Locale.autoupdatingCurrent
        headerDateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        headerDateFormatter.setLocalizedDateFormatFromTemplate("EEEEMMMMd") // Year is invalid on news content dates, we can only show month and day
        return headerDateFormatter
    }()
    
    func headerTitle(for section: Int) -> String? {
        let story = stories[section]
        guard let date = story.midnightUTCMonthAndDay else {
            return nil
        }
        return NewsViewController.headerDateFormatter.string(from: date)
    }
}

// MARK: - SideScrollingCollectionViewCellDelegate
extension NewsViewController: SideScrollingCollectionViewCellDelegate {
    func sideScrollingCollectionViewCell(_ sideScrollingCollectionViewCell: SideScrollingCollectionViewCell, didSelectArticleWithURL articleURL: URL) {
        wmf_pushArticle(with: articleURL, dataStore: dataStore, theme: self.theme, animated: true)
    }
}

// MARK: - UIViewControllerPreviewingDelegate
extension NewsViewController {
    override func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = collectionView.indexPathForItem(at: location),
            let cell = collectionView.cellForItem(at: indexPath) as? NewsCollectionViewCell else {
            return nil
        }
        
        let pointInCellCoordinates =  collectionView.convert(location, to: cell)
        let index = cell.subItemIndex(at: pointInCellCoordinates)
        guard index != NSNotFound, let view = cell.viewForSubItem(at: index) else {
            return nil
        }
        
        let story = stories[indexPath.section]
        guard let previews = story.articlePreviews, index < previews.count else {
            return nil
        }
        
        previewingContext.sourceRect = view.convert(view.bounds, to: collectionView)
        let article = previews[index]
        let articleVC = WMFArticleViewController(articleURL: article.articleURL, dataStore: dataStore, theme: theme)
        articleVC.wmf_addPeekableChildViewController(for: article.articleURL, dataStore: dataStore, theme: theme)
        articleVC.articlePreviewingActionsDelegate = self
        return articleVC
    }
    
    override func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        viewControllerToCommit.wmf_removePeekableChildViewControllers()
        wmf_push(viewControllerToCommit, animated: true)
    }
}

// MARK: - EventLoggingEventValuesProviding
extension NewsViewController: EventLoggingEventValuesProviding {
    var eventLoggingCategory: EventLoggingCategory {
        return .feed
    }
    
    var eventLoggingLabel: EventLoggingLabel? {
        return .news
    }
}
