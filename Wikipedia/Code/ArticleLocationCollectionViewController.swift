import UIKit

class ArticleLocationCollectionViewController: ColumnarCollectionViewController, ReadingListHintPresenter {
    var readingListHintController: ReadingListHintController?
    
    var articleURLs: [URL] {
        didSet {
            collectionView.reloadData()
        }
    }
    let dataStore: MWKDataStore
    fileprivate let locationManager = WMFLocationManager.fine()
    private var feedFunnelContext: FeedFunnelContext?
    private var previewedIndexPath: IndexPath?

    required init(articleURLs: [URL], dataStore: MWKDataStore, contentGroup: WMFContentGroup?, theme: Theme) {
        self.articleURLs = articleURLs
        self.dataStore = dataStore
        super.init()
        self.theme = theme
        if contentGroup != nil {
            self.feedFunnelContext = FeedFunnelContext(contentGroup)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not supported")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        layoutManager.register(ArticleLocationCollectionViewCell.self, forCellWithReuseIdentifier: ArticleLocationCollectionViewCell.identifier, addPlaceholder: true)
        readingListHintController = ReadingListHintController(dataStore: dataStore, presenter: self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        locationManager.delegate = self
        if WMFLocationManager.isAuthorized() {
            locationManager.startMonitoringLocation()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        locationManager.delegate = nil
        locationManager.stopMonitoringLocation()
        if isMovingFromParent, let context = feedFunnelContext {
            FeedFunnel.shared.logFeedCardClosed(for: context, maxViewed: maxViewed)
        }
    }
    
    func articleURL(at indexPath: IndexPath) -> URL {
        return articleURLs[indexPath.item]
    }
    
    override func collectionView(_ collectionView: UICollectionView, estimatedHeightForItemAt indexPath: IndexPath, forColumnWidth columnWidth: CGFloat) -> ColumnarCollectionViewLayoutHeightEstimate {
        var estimate = ColumnarCollectionViewLayoutHeightEstimate(precalculated: false, height: 150)
        guard let placeholderCell = layoutManager.placeholder(forCellWithReuseIdentifier: ArticleLocationCollectionViewCell.identifier) as? ArticleLocationCollectionViewCell else {
            return estimate
        }
        placeholderCell.layoutMargins = layout.itemLayoutMargins
        configure(cell: placeholderCell, forItemAt: indexPath, layoutOnly: true)
        estimate.height = placeholderCell.sizeThatFits(CGSize(width: columnWidth, height: UIView.noIntrinsicMetric), apply: false).height
        estimate.precalculated = true
        return estimate
    }
    
    override func metrics(with size: CGSize, readableWidth: CGFloat, layoutMargins: UIEdgeInsets) -> ColumnarCollectionViewLayoutMetrics {
        return ColumnarCollectionViewLayoutMetrics.tableViewMetrics(with: size, readableWidth: readableWidth, layoutMargins: layoutMargins)
    }

    // MARK: - CollectionViewFooterDelegate

    override func collectionViewFooterButtonWasPressed(_ collectionViewFooter: CollectionViewFooter) {
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - UICollectionViewDataSource
extension ArticleLocationCollectionViewController {
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    var numberOfItems: Int {
        return articleURLs.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return numberOfItems
    }
    
    private func configure(cell: UICollectionViewCell, forItemAt indexPath: IndexPath, layoutOnly: Bool) {
        guard let cell = cell as? ArticleLocationCollectionViewCell else {
            return
        }
        
        let url = articleURL(at: indexPath)
        guard let article = dataStore.fetchArticle(with: url) else {
            return
        }
        
        var userLocation: CLLocation?
        var userHeading: CLHeading?
        
        if locationManager.isUpdating {
            userLocation = locationManager.location
            userHeading = locationManager.heading
        }
        
        cell.articleLocation = article.location
        cell.update(userLocation: userLocation, heading: userHeading)
        
        cell.configure(article: article, displayType: .pageWithLocation, index: indexPath.row, theme: theme, layoutOnly: layoutOnly)
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ArticleLocationCollectionViewCell.identifier, for: indexPath)
        configure(cell: cell, forItemAt: indexPath, layoutOnly: false)
        return cell
    }
}

// MARK: - WMFLocationManagerDelegate
extension ArticleLocationCollectionViewController: WMFLocationManagerDelegate {
    func updateLocationOnVisibleCells() {
        for cell in collectionView.visibleCells {
            guard let locationCell = cell as? ArticleLocationCollectionViewCell else {
                continue
            }
            locationCell.update(userLocation: locationManager.location, heading: locationManager.heading)
        }
    }
    
    func locationManager(_ controller: WMFLocationManager, didUpdate location: CLLocation) {
        updateLocationOnVisibleCells()
    }
    
    func locationManager(_ controller: WMFLocationManager, didUpdate heading: CLHeading) {
        updateLocationOnVisibleCells()
    }

    func locationManager(_ controller: WMFLocationManager, didChangeEnabledState enabled: Bool) {
        if enabled {
            locationManager.startMonitoringLocation()
        }
    }
}

// MARK: - UICollectionViewDelegate
extension ArticleLocationCollectionViewController {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let context = feedFunnelContext {
            FeedFunnel.shared.logArticleInFeedDetailReadingStarted(for: context, index: indexPath.item, maxViewed: maxViewed)
        }
        wmf_pushArticle(with: articleURLs[indexPath.item], dataStore: dataStore, theme: self.theme, animated: true)
    }
}

// MARK: - UIViewControllerPreviewingDelegate
extension ArticleLocationCollectionViewController {
    override func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = collectionViewIndexPathForPreviewingContext(previewingContext, location: location) else {
                return nil
        }
        previewedIndexPath = indexPath
        let articleURL = self.articleURL(at: indexPath)
        let articleViewController = WMFArticleViewController(articleURL: articleURL, dataStore: dataStore, theme: self.theme)
        articleViewController.articlePreviewingActionsDelegate = self
        articleViewController.wmf_addPeekableChildViewController(for: articleURL, dataStore: dataStore, theme: theme)
        if let context = feedFunnelContext {
            FeedFunnel.shared.logArticleInFeedDetailPreviewed(for: context, index: indexPath.item)
        }
        return articleViewController
    }
    
    override func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        if let context = feedFunnelContext {
            FeedFunnel.shared.logArticleInFeedDetailReadingStarted(for: context, index: previewedIndexPath?.item, maxViewed: maxViewed)
        }
        viewControllerToCommit.wmf_removePeekableChildViewControllers()
        wmf_push(viewControllerToCommit, animated: true)
    }
}

// MARK: - Reading lists event logging
extension ArticleLocationCollectionViewController: EventLoggingEventValuesProviding {
    var eventLoggingCategory: EventLoggingCategory {
        return .places
    }
    
    var eventLoggingLabel: EventLoggingLabel? {
        return nil
    }
}

// MARK: - WMFArticlePreviewingActionsDelegate
extension ArticleLocationCollectionViewController {
    override func shareArticlePreviewActionSelected(withArticleController articleController: WMFArticleViewController, shareActivityController: UIActivityViewController) {
        guard let context = feedFunnelContext else {
            super.shareArticlePreviewActionSelected(withArticleController: articleController, shareActivityController: shareActivityController)
            return
        }
        super.shareArticlePreviewActionSelected(withArticleController: articleController, shareActivityController: shareActivityController)
        FeedFunnel.shared.logFeedDetailShareTapped(for: context, index: previewedIndexPath?.item, midnightUTCDate: context.midnightUTCDate)
    }

    override func readMoreArticlePreviewActionSelected(withArticleController articleController: WMFArticleViewController) {
        guard let context = feedFunnelContext else {
            super.readMoreArticlePreviewActionSelected(withArticleController: articleController)
            return
        }
        articleController.wmf_removePeekableChildViewControllers()
        wmf_push(articleController, context: context, index: previewedIndexPath?.item, animated: true)
    }

    override func saveArticlePreviewActionSelected(withArticleController articleController: WMFArticleViewController, didSave: Bool, articleURL: URL) {
        guard let context = feedFunnelContext else {
            super.saveArticlePreviewActionSelected(withArticleController: articleController, didSave: didSave, articleURL: articleURL)
            return
        }
        readingListHintController?.didSave(didSave, articleURL: articleURL, theme: theme)
        if didSave {
            ReadingListsFunnel.shared.logSaveInFeed(context: context, articleURL: articleURL, index: previewedIndexPath?.item)
        } else {
            ReadingListsFunnel.shared.logUnsaveInFeed(context: context, articleURL: articleURL, index: previewedIndexPath?.item)
        }
    }
}
