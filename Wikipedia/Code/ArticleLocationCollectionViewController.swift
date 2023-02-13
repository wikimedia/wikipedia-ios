import UIKit

class ArticleLocationCollectionViewController: ColumnarCollectionViewController, DetailPresentingFromContentGroup {
    var articleURLs: [URL] {
        didSet {
            collectionView.reloadData()
        }
    }
    let dataStore: MWKDataStore
    fileprivate let locationManager = LocationManager()
    private var previewedIndexPath: IndexPath?
    private var contentGroup: WMFContentGroup?

    let contentGroupIDURIString: String?

    required init(articleURLs: [URL], dataStore: MWKDataStore, contentGroup: WMFContentGroup?, theme: Theme) {
        self.articleURLs = articleURLs
        self.dataStore = dataStore
        self.contentGroup = contentGroup
        contentGroupIDURIString = contentGroup?.objectID.uriRepresentation().absoluteString
        super.init()
        self.theme = theme
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not supported")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        layoutManager.register(ArticleLocationCollectionViewCell.self, forCellWithReuseIdentifier: ArticleLocationCollectionViewCell.identifier, addPlaceholder: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        locationManager.delegate = self
        if locationManager.isAuthorized {
            locationManager.startMonitoringLocation()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        locationManager.delegate = nil
        locationManager.stopMonitoringLocation()
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
    
    // MARK: ArticlePreviewingDelegate
    
    override func shareArticlePreviewActionSelected(with articleController: ArticleViewController, shareActivityController: UIActivityViewController) {
        super.shareArticlePreviewActionSelected(with: articleController, shareActivityController: shareActivityController)
    }

    override func readMoreArticlePreviewActionSelected(with articleController: ArticleViewController) {
        guard let context = contentGroup else {
            super.readMoreArticlePreviewActionSelected(with: articleController)
            return
        }
        articleController.wmf_removePeekableChildViewControllers()
        push(articleController, animated: true)
    }

    override func saveArticlePreviewActionSelected(with articleController: ArticleViewController, didSave: Bool, articleURL: URL) {
        guard let context = contentGroup else {
            super.saveArticlePreviewActionSelected(with: articleController, didSave: didSave, articleURL: articleURL)
            return
        }
        if didSave {
            // Todo MArina - safely unwrap the date first
            ReadingListsFunnel.shared.logSaveInFeed(label: getLabelfor(context), measureAge: context.midnightUTCDate ?? Date(), articleURL: articleURL, index: previewedIndexPath?.item)
        } else {
            ReadingListsFunnel.shared.logUnsaveInFeed(label: getLabelfor(context), measureAge: context.midnightUTCDate ?? Date(), articleURL: articleURL, index: previewedIndexPath?.item)
        }
    }

    func updateLocationOnVisibleCells() {
        for cell in collectionView.visibleCells {
            guard let locationCell = cell as? ArticleLocationCollectionViewCell else {
                continue
            }
            locationCell.update(userLocation: locationManager.location, heading: locationManager.heading)
        }
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

// MARK: - LocationManagerDelegate
extension ArticleLocationCollectionViewController: LocationManagerDelegate {
    func locationManager(_ locationManager: LocationManagerProtocol, didUpdate location: CLLocation) {
        updateLocationOnVisibleCells()
    }

    func locationManager(_ locationManager: LocationManagerProtocol, didUpdate heading: CLHeading) {
        updateLocationOnVisibleCells()
    }

    func locationManager(_ locationManager: LocationManagerProtocol, didUpdateAuthorized authorized: Bool) {
        if authorized {
            locationManager.startMonitoringLocation()
        }
    }
}

// MARK: - UICollectionViewDelegate
extension ArticleLocationCollectionViewController {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        navigate(to: articleURLs[indexPath.item])
    }
}

// MARK: - CollectionViewContextMenuShowing
extension ArticleLocationCollectionViewController: CollectionViewContextMenuShowing {
    func articleViewController(for indexPath: IndexPath) -> ArticleViewController? {
        let articleURL = articleURL(at: indexPath)
        let articleViewController = ArticleViewController(articleURL: articleURL, dataStore: dataStore, theme: theme)
        return articleViewController
    }

    func previewingViewController(for indexPath: IndexPath, at location: CGPoint) -> UIViewController? {
        guard let articleViewController = articleViewController(for: indexPath) else {
            return nil
        }
        let articleURL = articleViewController.articleURL
        articleViewController.articlePreviewingDelegate = self
        articleViewController.wmf_addPeekableChildViewController(for: articleURL, dataStore: dataStore, theme: theme)

        previewedIndexPath = indexPath
        return articleViewController
    }

    var poppingIntoVCCompletion: () -> Void {
        return {}
        }
    
}

// MARK: - Reading lists event logging
extension ArticleLocationCollectionViewController: MEPEventsProviding {
    var eventLoggingCategory: EventCategoryMEP {
        return .places
    }
    
    var eventLoggingLabel: EventLabelMEP? {
        return nil
    }
}

// MARK: - MEP analytics extension

extension ArticleLocationCollectionViewController {
    func getLabelfor(_ contentGroup: WMFContentGroup?) -> EventLabelMEP? {
        if let contentGroup {
            switch contentGroup.contentGroupKind {
            case .featuredArticle:
                return .featuredArticle
            case .topRead:
                return .topRead
            case .onThisDay:
                return .onThisDay
            case .random:
                return .random
            case .news:
                return .news
            case .relatedPages:
                return .relatedPages
            case .continueReading:
                return .continueReading
            case .locationPlaceholder:
                fallthrough
            case .location:
                return .location
            case .mainPage:
                return .mainPage
            case .pictureOfTheDay:
                return .pictureOfTheDay
            case .announcement:
                guard let announcement = contentGroup.contentPreview as? WMFAnnouncement else {
                    return .announcement
                }
                return announcement.placement == "article" ? .articleAnnouncement : .announcement
            default:
                return nil
            }
        }
        return nil
    }
}

