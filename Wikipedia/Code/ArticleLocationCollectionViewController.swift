import UIKit

class ArticleLocationCollectionViewController: ColumnarCollectionViewController2, DetailPresentingFromContentGroup {
    var articleURLs: [URL] {
        didSet {
            collectionView.reloadData()
        }
    }
    let dataStore: MWKDataStore
    fileprivate let locationManager = LocationManager()
    private var previewedIndexPath: IndexPath?
    private let contentGroup: WMFContentGroup?
    private let needsCloseButton: Bool

    let contentGroupIDURIString: String?

    required init(articleURLs: [URL], dataStore: MWKDataStore, contentGroup: WMFContentGroup?, theme: Theme, needsCloseButton: Bool = false) {
        self.articleURLs = articleURLs
        self.dataStore = dataStore
        self.contentGroup = contentGroup
        contentGroupIDURIString = contentGroup?.objectID.uriRepresentation().absoluteString
        self.needsCloseButton = needsCloseButton
        super.init(nibName: nil, bundle: nil)
        self.theme = theme
        if needsCloseButton {
            // hidesBottomBarWhenPushed = true
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.articleURLs = []
        self.dataStore = MWKDataStore.shared()
        self.contentGroup = nil
        self.contentGroupIDURIString = nil
        self.needsCloseButton = false
        super.init(coder: aDecoder)
        if needsCloseButton {
            // hidesBottomBarWhenPushed = true
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        layoutManager.register(ArticleLocationCollectionViewCell.self, forCellWithReuseIdentifier: ArticleLocationCollectionViewCell.identifier, addPlaceholder: true)
        if needsCloseButton {
            addCloseButton()
        }
    }
    
    private var closeButton: UIButton?
    private func addCloseButton() {
        guard closeButton == nil else {
            return
        }
        let button = UIButton(type: .custom)
        button.setImage(#imageLiteral(resourceName: "close-inverse"), for: .normal)
        button.addTarget(self, action: #selector(close), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.accessibilityLabel = CommonStrings.closeButtonAccessibilityLabel
        view.addSubview(button)
        let height = button.heightAnchor.constraint(greaterThanOrEqualToConstant: 50)
        let width = button.widthAnchor.constraint(greaterThanOrEqualToConstant: 32)
        button.addConstraints([height, width])
        let top = button.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 45)
        let trailing = button.trailingAnchor.constraint(equalTo: view.readableContentGuide.trailingAnchor)
        view.addConstraints([top, trailing])
        closeButton = button
        applyThemeToCloseButton()
    }
    
    private func applyThemeToCloseButton() {
        closeButton?.tintColor = theme.colors.tertiaryText
    }
    
    @objc private func close() {
        navigationController?.popViewController(animated: true)
    }
    
    override func apply(theme: Theme) {
        super.apply(theme: theme)
        
        applyThemeToCloseButton()
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

    override func saveArticlePreviewActionSelected(with articleController: ArticleViewController, didSave: Bool, articleURL: URL) {
        guard let context = contentGroup, let contextDate = context.midnightUTCDate else {
            super.saveArticlePreviewActionSelected(with: articleController, didSave: didSave, articleURL: articleURL)
            return
        }
        if didSave {
            ReadingListsFunnel.shared.logSaveInFeed(label: context.getAnalyticsLabel(), measureAge: contextDate, articleURL: articleURL, index: previewedIndexPath?.item)
        } else {
            ReadingListsFunnel.shared.logUnsaveInFeed(label: context.getAnalyticsLabel(), measureAge: contextDate, articleURL: articleURL, index: previewedIndexPath?.item)
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
