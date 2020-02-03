import WMF

@objc(WMFNewsViewController)
class NewsViewController: ColumnarCollectionViewController, DetailPresentingFromContentGroup {
    fileprivate static let cellReuseIdentifier = "NewsCollectionViewCell"
    fileprivate static let headerReuseIdentifier = "NewsCollectionViewHeader"
    
    let stories: [WMFFeedNewsStory]
    let dataStore: MWKDataStore
    let feedFunnelContext: FeedFunnelContext
    let cellImageViewHeight: CGFloat = 170

    let contentGroupIDURIString: String?

    @objc required init(stories: [WMFFeedNewsStory], dataStore: MWKDataStore, contentGroup: WMFContentGroup?, theme: Theme) {
        self.stories = stories
        self.dataStore = dataStore
        contentGroupIDURIString = contentGroup?.objectID.uriRepresentation().absoluteString
        feedFunnelContext = FeedFunnelContext(contentGroup)
        super.init()
        self.theme = theme
        title = CommonStrings.inTheNewsTitle
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not supported")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        layoutManager.register(NewsCollectionViewCell.self, forCellWithReuseIdentifier: NewsViewController.cellReuseIdentifier, addPlaceholder: true)
        layoutManager.register(UINib(nibName: NewsViewController.headerReuseIdentifier, bundle: nil), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: NewsViewController.headerReuseIdentifier, addPlaceholder: false)
        collectionView.allowsSelection = false
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent {
            FeedFunnel.shared.logFeedCardClosed(for: feedFunnelContext, maxViewed: maxViewed)
        }
    }
    
    override func metrics(with size: CGSize, readableWidth: CGFloat, layoutMargins: UIEdgeInsets) -> ColumnarCollectionViewLayoutMetrics {
        return ColumnarCollectionViewLayoutMetrics.tableViewMetrics(with: size, readableWidth: readableWidth, layoutMargins: layoutMargins, interSectionSpacing: 0, interItemSpacing: 22)
    }
    
    // MARK: - ColumnarCollectionViewLayoutDelegate
    override func collectionView(_ collectionView: UICollectionView, estimatedHeightForHeaderInSection section: Int, forColumnWidth columnWidth: CGFloat) -> ColumnarCollectionViewLayoutHeightEstimate {
        guard section > 0 else {
            return super.collectionView(collectionView, estimatedHeightForHeaderInSection: section, forColumnWidth: columnWidth)
        }
        return ColumnarCollectionViewLayoutHeightEstimate(precalculated: false, height: headerTitle(for: section) == nil ? 0 : 57)
    }
    
    override func collectionView(_ collectionView: UICollectionView, estimatedHeightForItemAt indexPath: IndexPath, forColumnWidth columnWidth: CGFloat) -> ColumnarCollectionViewLayoutHeightEstimate {
        var estimate = ColumnarCollectionViewLayoutHeightEstimate(precalculated: false, height: 350)
        guard let placeholderCell = layoutManager.placeholder(forCellWithReuseIdentifier: NewsViewController.cellReuseIdentifier) as? NewsCollectionViewCell else {
            return estimate
        }
        guard let story = story(for: indexPath.section) else {
            return estimate
        }
        placeholderCell.layoutMargins = layout.itemLayoutMargins
        placeholderCell.imageViewHeight = cellImageViewHeight
        placeholderCell.configure(with: story, dataStore: dataStore, theme: theme, layoutOnly: true)
        estimate.height = placeholderCell.sizeThatFits(CGSize(width: columnWidth, height: UIView.noIntrinsicMetric), apply: false).height
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
    
    // MARK: ArticlePreviewingDelegate
    
    override func shareArticlePreviewActionSelected(with articleController: ArticleViewController, shareActivityController: UIActivityViewController) {
        FeedFunnel.shared.logFeedDetailShareTapped(for: feedFunnelContext, index: previewedIndex)
        super.shareArticlePreviewActionSelected(with: articleController, shareActivityController: shareActivityController)
    }

    override func readMoreArticlePreviewActionSelected(with articleController: ArticleViewController) {
        articleController.wmf_removePeekableChildViewControllers()
        push(articleController, context: feedFunnelContext, index: previewedIndex, animated: true)
    }

    // MARK: - UIViewControllerPreviewingDelegate

    private var previewedIndex: Int?

    override func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {

        guard let indexPath = collectionViewIndexPathForPreviewingContext(previewingContext, location: location),
            let cell = collectionView.cellForItem(at: indexPath) as? NewsCollectionViewCell else {
                return nil
        }

        let pointInCellCoordinates =  view.convert(location, to: cell)
        let index = cell.subItemIndex(at: pointInCellCoordinates)
        guard index != NSNotFound, let subItemView = cell.viewForSubItem(at: index) else {
            return nil
        }

        previewedIndex = index

        guard let story = story(for: indexPath.section), let previews = story.articlePreviews, index < previews.count else {
            return nil
        }

        previewingContext.sourceRect = view.convert(subItemView.bounds, from: subItemView)
        let article = previews[index]
        guard let articleVC = ArticleViewController(articleURL: article.articleURL, dataStore: dataStore, theme: theme) else {
            return nil
        }
        articleVC.wmf_addPeekableChildViewController(for: article.articleURL, dataStore: dataStore, theme: theme)
        articleVC.articlePreviewingDelegate = self
        FeedFunnel.shared.logArticleInFeedDetailPreviewed(for: feedFunnelContext, index: index)
        return articleVC
    }

    override func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        viewControllerToCommit.wmf_removePeekableChildViewControllers()
        FeedFunnel.shared.logArticleInFeedDetailReadingStarted(for: feedFunnelContext, index: previewedIndex, maxViewed: maxViewed)
        push(viewControllerToCommit, animated: true)
    }

    // MARK: - CollectionViewFooterDelegate

    override func collectionViewFooterButtonWasPressed(_ collectionViewFooter: CollectionViewFooter) {
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - UICollectionViewDataSource
extension NewsViewController {
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return stories.count + 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return section == 0 ? 0 : 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NewsViewController.cellReuseIdentifier, for: indexPath)
        guard let newsCell = cell as? NewsCollectionViewCell else {
            return cell
        }
        newsCell.layoutMargins = layout.itemLayoutMargins
        newsCell.imageViewHeight = cellImageViewHeight
        if let story = story(for: indexPath.section) {
            newsCell.configure(with: story, dataStore: dataStore, theme: theme, layoutOnly: false)
        }
        return newsCell
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard indexPath.section > 0 else {
            return super.collectionView(collectionView, viewForSupplementaryElementOfKind: kind, at: indexPath)
        }
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: NewsViewController.headerReuseIdentifier, for: indexPath)
            guard let header = view as? NewsCollectionViewHeader else {
                return view
            }
            header.label.text = headerTitle(for: indexPath.section)
            header.apply(theme: theme)
            return header
        case UICollectionView.elementKindSectionFooter:
            return super.collectionView(collectionView, viewForSupplementaryElementOfKind: kind, at: indexPath)
        default:
            assert(false, "ensure you've registered cells and added cases to this switch statement to handle all header/footer types")
            return UICollectionReusableView()
        }
    }
    
    @objc func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? NewsCollectionViewCell else {
            return
        }
        cell.selectionDelegate = self
    }
    
    @objc func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
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
    
    func story(for section: Int) -> WMFFeedNewsStory? {
        guard section > 0 else {
            return nil
        }
        return stories[section - 1]
    }
    
    func headerTitle(for section: Int) -> String? {
        guard let story = story(for: section), let date = story.midnightUTCMonthAndDay else {
            return nil
        }
        return NewsViewController.headerDateFormatter.string(from: date)
    }
}

// MARK: - SideScrollingCollectionViewCellDelegate
extension NewsViewController: SideScrollingCollectionViewCellDelegate {
    func sideScrollingCollectionViewCell(_ sideScrollingCollectionViewCell: SideScrollingCollectionViewCell, didSelectArticleWithURL articleURL: URL, at indexPath: IndexPath) {
        let index: Int?
        if let indexPath = collectionView.indexPath(for: sideScrollingCollectionViewCell) {
            index = indexPath.section - 1
        } else {
            index = nil
        }
        FeedFunnel.shared.logArticleInFeedDetailReadingStarted(for: feedFunnelContext, index: index, maxViewed: maxViewed)
        navigate(to: articleURL)
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
