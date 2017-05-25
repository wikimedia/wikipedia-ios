@objc(WMFNewsViewController)
class NewsViewController: ColumnarCollectionViewController {
    static let cellReuseIdentifier = "NewsCollectionViewCell"
    static let headerReuseIdentifier = "NewsCollectionViewHeader"
    
    let stories: [WMFFeedNewsStory]
    let dataStore: MWKDataStore
    
    required init(stories: [WMFFeedNewsStory], dataStore: MWKDataStore) {
        self.stories = stories
        self.dataStore = dataStore
        super.init()
        title = WMFLocalizedString("in-the-news-title", value:"In the news", comment:"Title for the 'In the news' notification & feed section")
        navigationItem.backBarButtonItem = UIBarButtonItem(title: WMFLocalizedString("back", value:"Back", comment:"Generic 'Back' title for back button\n{{Identical|Back}}"), style: .plain, target:nil, action:nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not supported")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        register(NewsCollectionViewCell.self, forCellWithReuseIdentifier: NewsViewController.cellReuseIdentifier)
        register(UINib(nibName: NewsViewController.headerReuseIdentifier, bundle: nil), forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: NewsViewController.headerReuseIdentifier)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        registerForPreviewingIfAvailable()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        unregisterForPreviewing()
    }
    
    // MARK - UICollectionViewDataSource
    
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
        let story = stories[indexPath.section]
        newsCell.configure(with: story, dataStore: dataStore, layoutOnly: false)
        return newsCell
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionElementKindSectionHeader:
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: NewsViewController.headerReuseIdentifier, for: indexPath)
            guard let header = view as? NewsCollectionViewHeader else {
                return view
            }
            header.label.text = headerTitle(for: indexPath.section)
            return header
        default:
            return UICollectionReusableView()
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? NewsCollectionViewCell else {
            return
        }
        cell.newsDelegate = self
    }
    
    override func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? NewsCollectionViewCell else {
            return
        }
        cell.newsDelegate = nil
    }
    
    static var headerDateFormatter: DateFormatter = {
        let headerDateFormatter = DateFormatter()
        headerDateFormatter.locale = Locale.autoupdatingCurrent
        headerDateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        headerDateFormatter.setLocalizedDateFormatFromTemplate("dMMMM") // Year is invalid on news content dates, we can only show month and day
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

extension NewsViewController { // WMFColumnarCollectionViewLayoutDelegate {
    override func collectionView(_ collectionView: UICollectionView, estimatedHeightForHeaderInSection section: Int, forColumnWidth columnWidth: CGFloat) -> CGFloat {
        return headerTitle(for: section) == nil ? 0 : 50
    }
    
    override func collectionView(_ collectionView: UICollectionView, estimatedHeightForItemAt indexPath: IndexPath, forColumnWidth columnWidth: CGFloat) -> WMFLayoutEstimate {
        return WMFLayoutEstimate(precalculated: false, height: 350)
    }
}

extension NewsViewController: NewsCollectionViewCellDelegate {
    func newsCollectionViewCell(_ newsCollectionViewCell: NewsCollectionViewCell, didSelectNewsArticleWithURL articleURL: URL) {
        wmf_pushArticle(with: articleURL, dataStore: dataStore, animated: true)
    }
}

extension NewsViewController { // UIViewControllerPreviewingDelegate
    override func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let collectionView = collectionView,
            let indexPath = collectionView.indexPathForItem(at: location),
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
        return WMFArticleViewController(articleURL: article.articleURL, dataStore: dataStore)
    }
    
    override func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        wmf_push(viewControllerToCommit, animated: true)
    }
}
