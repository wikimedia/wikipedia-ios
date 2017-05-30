import UIKit

@objc(WMFArticleLocationCollectionViewController)
class ArticleLocationCollectionViewController: ColumnarCollectionViewController {
    fileprivate static let cellReuseIdentifier = "ArticleLocationCollectionViewControllerCell"
    
    let articleURLs: [URL]
    let dataStore: MWKDataStore
    fileprivate let locationManager = WMFLocationManager.fine()

    required init(articleURLs: [URL], dataStore: MWKDataStore) {
        self.articleURLs = articleURLs
        self.dataStore = dataStore
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not supported")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        register(WMFNearbyArticleCollectionViewCell.wmf_classNib(), forCellWithReuseIdentifier: ArticleLocationCollectionViewController.cellReuseIdentifier)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        locationManager.delegate = self
        locationManager.startMonitoringLocation()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        locationManager.delegate = nil
        locationManager.stopMonitoringLocation()
    }
    
    func articleURL(at indexPath: IndexPath) -> URL {
        return articleURLs[indexPath.section]
    }
}

// MARK: - UICollectionViewDataSource
extension ArticleLocationCollectionViewController {
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return articleURLs.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ArticleLocationCollectionViewController.cellReuseIdentifier, for: indexPath)
        guard let articleCell = cell as? WMFNearbyArticleCollectionViewCell else {
            return cell
        }
        let url = articleURL(at: indexPath)
        guard let article = dataStore.fetchArticle(with: url) else {
            return articleCell
        }
        
        var userLocation: CLLocation?
        var userHeading: CLHeading?
        
        if locationManager.isUpdating {
            userLocation = locationManager.location
            userHeading = locationManager.heading
        }
        
        articleCell.titleText = article.displayTitle
        articleCell.descriptionText = article.capitalizedWikidataDescriptionOrSnippet
        articleCell.setImageURL(article.imageURL(forWidth: traitCollection.wmf_nearbyThumbnailWidth))
        articleCell.articleLocation = article.location
        articleCell.update(userLocation: userLocation, heading: userHeading)
        return articleCell
    }
}

// MARK: - WMFLocationManagerDelegate
extension ArticleLocationCollectionViewController: WMFLocationManagerDelegate {
    func updateLocationOnVisibleCells() {
        guard let visibleCells = collectionView?.visibleCells else {
            return
        }
        
        for cell in visibleCells {
            guard let locationCell = cell as? WMFNearbyArticleCollectionViewCell else {
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
}

// MARK: - UICollectionViewDelegate
extension ArticleLocationCollectionViewController {
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        wmf_pushArticle(with: articleURLs[indexPath.item], dataStore: dataStore, animated: true)
    }
}

// MARK: - UIViewControllerPreviewingDelegate
extension ArticleLocationCollectionViewController {
    override func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let collectionView = collectionView,
            let indexPath = collectionView.indexPathForItem(at: location) else {
                return nil
        }
        let url = articleURL(at: indexPath)
        return WMFArticleViewController(articleURL: url, dataStore: dataStore)
    }
    
    override func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        wmf_push(viewControllerToCommit, animated: true)
    }
}

// MARK: - WMFColumnarCollectionViewLayoutDelegate
extension ArticleLocationCollectionViewController {
    override func collectionView(_ collectionView: UICollectionView, estimatedHeightForItemAt indexPath: IndexPath, forColumnWidth columnWidth: CGFloat) -> WMFLayoutEstimate {
        return WMFLayoutEstimate(precalculated: false, height: WMFNearbyArticleCollectionViewCell.estimatedRowHeight())
    }
    override func metrics(withBoundsSize size: CGSize) -> WMFCVLMetrics {
        return WMFCVLMetrics.singleColumnMetrics(withBoundsSize: size, collapseSectionSpacing: true)
 
    }
}
