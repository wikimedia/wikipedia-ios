import UIKit
import WMF


class ExploreViewController: ColumnarCollectionViewController, ExploreCardViewControllerDelegate, UISearchBarDelegate {
    
    // MARK - UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        layoutManager.register(ExploreCardCollectionViewCell.self, forCellWithReuseIdentifier: ExploreCardCollectionViewCell.identifier, addPlaceholder: true)
        layoutManager.register(ExploreHeaderCollectionReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: ExploreHeaderCollectionReusableView.identifier, addPlaceholder: true)
        
        navigationItem.titleView = titleView
        navigationBar.addExtendedNavigationBarView(searchBarContainerView)
    }
    
    private var fetchedResultsController: NSFetchedResultsController<WMFContentGroup>!
    private var collectionViewUpdater: CollectionViewUpdater<WMFContentGroup>!
    lazy var layoutCache: ColumnarCollectionViewControllerLayoutCache = {
       return ColumnarCollectionViewControllerLayoutCache()
    }()
    
    // MARK - ViewController
    
    override func navigationBarHider(_ hider: NavigationBarHider, didSetNavigationBarPercentHidden navigationBarPercentHidden: CGFloat, underBarViewPercentHidden: CGFloat, extendedViewPercentHidden: CGFloat, animated: Bool) {
        super.navigationBarHider(hider, didSetNavigationBarPercentHidden: navigationBarPercentHidden, underBarViewPercentHidden: underBarViewPercentHidden, extendedViewPercentHidden: extendedViewPercentHidden, animated: animated)
        shortTitleButton.alpha = extendedViewPercentHidden
        longTitleButton.alpha = 1.0 - extendedViewPercentHidden
        navigationItem.rightBarButtonItem?.customView?.alpha = extendedViewPercentHidden
    }
    
    // MARK - NavBar
    
    @objc func titleBarButtonPressed(_ sender: UIButton?) {
        scrollToTop()
    }
    
    @objc public var titleButton: UIView {
        return titleView
    }
    
    lazy var longTitleButton: UIButton = {
        let longTitleButton = UIButton(type: .custom)
        longTitleButton.adjustsImageWhenHighlighted = true
        longTitleButton.setImage(UIImage(named: "wikipedia"), for: .normal)
        longTitleButton.sizeToFit()
        longTitleButton.addTarget(self, action: #selector(titleBarButtonPressed), for: .touchUpInside)
        return longTitleButton
    }()
    
    lazy var shortTitleButton: UIButton = {
        let shortTitleButton = UIButton(type: .custom)
        shortTitleButton.adjustsImageWhenHighlighted = true
        shortTitleButton.setImage(UIImage(named: "W"), for: .normal)
        shortTitleButton.alpha = 0
        shortTitleButton.sizeToFit()
        shortTitleButton.addTarget(self, action: #selector(titleBarButtonPressed), for: .touchUpInside)
        return shortTitleButton
    }()
    
    lazy var titleView: UIView = {
        let titleView = UIView(frame: longTitleButton.bounds)
        titleView.addSubview(longTitleButton)
        titleView.addSubview(shortTitleButton)
        shortTitleButton.center = titleView.center
        return titleView
    }()

    // MARK - Search
    
    lazy var searchBarContainerView: UIView = {
        let searchContainerView = UIView()
        let searchHeightConstraint = searchContainerView.heightAnchor.constraint(equalToConstant: 44)
        searchContainerView.addConstraint(searchHeightConstraint)
        searchContainerView.wmf_addSubview(searchBar, withConstraintsToEdgesWithInsets: UIEdgeInsets(top: 0, left: 0, bottom: 3, right: 0), priority: .required)
        return searchContainerView
    }()
    
    lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.searchBarStyle = .minimal
        searchBar.delegate = self
        searchBar.placeholder =  WMFLocalizedString("search-field-placeholder-text", value: "Search Wikipedia", comment: "Search field placeholder text")
        return searchBar
    }()
    
    // MARK - UISearchBarDelegate
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        let searchActivity = NSUserActivity.wmf_searchView()
        NotificationCenter.default.post(name: .WMFNavigateToActivity, object: searchActivity)
        return false
    }
    
    // MARK - State
    
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
            collectionViewUpdater.isSlidingNewContentInFromTheTopEnabled = true
        }
    }
    
    lazy var saveButtonsController: SaveButtonsController = {
        let sbc = SaveButtonsController(dataStore: dataStore)
        sbc.delegate = self
        return sbc
    }()
    
    lazy var readingListHintController: ReadingListHintController = {
        return ReadingListHintController(dataStore: dataStore, presenter: self)
    }()
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        guard let sections = fetchedResultsController.sections else {
            return 0
        }
        return sections.count
    }
    
    private func resetRefreshControl() {
        
    }
    
    private func startMonitoringReachabilityIfNeeded() {
        
    }
    
    private func showOfflineEmptyViewIfNeeded() {
        
    }
    
    @objc(updateFeedSourcesWithDate:userInitiated:completion:)
    public func updateFeedSources(with date: Date?, userInitiated: Bool, completion: @escaping () -> Void) {
        self.dataStore.feedContentController.updateFeedSources(with: date, userInitiated: userInitiated) {
           self.resetRefreshControl()
            if date == nil {
                self.startMonitoringReachabilityIfNeeded()
                self.showOfflineEmptyViewIfNeeded()
            }
            completion()
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        layoutCache.reset()
        super.traitCollectionDidChange(previousTraitCollection)
        registerForPreviewingIfAvailable()
    }
    
    override func contentSizeCategoryDidChange(_ notification: Notification?) {
        layoutCache.reset()
        super.contentSizeCategoryDidChange(notification)
        collectionView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        layoutCache.reset()
    }
    
    // MARK - UICollectionViewDataSource
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let sections = fetchedResultsController.sections, sections.count > section else {
            return 0
        }
        return sections[section].numberOfObjects
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let maybeCell = collectionView.dequeueReusableCell(withReuseIdentifier: ExploreCardCollectionViewCell.identifier, for: indexPath)
        guard let cell = maybeCell as? ExploreCardCollectionViewCell else {
            return maybeCell
        }
        cell.apply(theme: theme)
        let width = self.layout.layoutAttributesForItem(at: indexPath)?.bounds.size.width ?? 1
        configure(cell: cell, forItemAt: indexPath, width: width, layoutOnly: false)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard kind == UICollectionElementKindSectionHeader else {
            abort()
        }
        guard let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: ExploreHeaderCollectionReusableView.identifier, for: indexPath) as? ExploreHeaderCollectionReusableView else {
            abort()
        }
        configureHeader(header, for: indexPath.section)
        return header
    }
    
    // MARK - UICollectionViewDelegate
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let group = fetchedResultsController.object(at: indexPath)
        if let vc = group.detailViewControllerWithDataStore(dataStore, theme: theme) {
            wmf_push(vc, animated: true)
            return
        }
        
        if let vc = group.detailViewControllerForPreviewItemAtIndex(0, dataStore: dataStore, theme: theme) {
            if vc is WMFImageGalleryViewController {
                present(vc, animated: true)
            } else {
                wmf_push(vc, animated: true)
            }
            return
        }
    }
    
    func configureHeader(_ header: ExploreHeaderCollectionReusableView, for sectionIndex: Int) {
        guard collectionView(collectionView, numberOfItemsInSection: sectionIndex) > 0 else {
            return
        }
        let group = fetchedResultsController.object(at: IndexPath(item: 0, section: sectionIndex))
        header.titleLabel.text = (group.midnightUTCDate as NSDate?)?.wmf_localizedRelativeDateFromMidnightUTCDate()
        header.apply(theme: theme)
    }
    
    func createNewCardVCFor(_ cell: ExploreCardCollectionViewCell) -> ExploreCardViewController {
        let cardVC = ExploreCardViewController()
        cardVC.delegate = self
        cardVC.dataStore = dataStore
        cardVC.view.autoresizingMask = []
        addChildViewController(cardVC)
        cell.cardContent = cardVC
        cardVC.didMove(toParentViewController: self)
        return cardVC
    }

    func configure(cell: ExploreCardCollectionViewCell, forItemAt indexPath: IndexPath, width: CGFloat, layoutOnly: Bool) {
        let cardVC = cell.cardContent as? ExploreCardViewController ?? createNewCardVCFor(cell)
        let group = fetchedResultsController.object(at: indexPath)
        cardVC.contentGroup = group
        cell.titleLabel.text = group.headerTitle
        cell.subtitleLabel.text = group.headerSubTitle
        cell.footerButton.setTitle(group.moreTitle, for: .normal)
        cell.apply(theme: theme)
    }
    
    override func apply(theme: Theme) {
        super.apply(theme: theme)
        guard viewIfLoaded != nil else {
            return
        }
        searchBar.setSearchFieldBackgroundImage(theme.searchBarBackgroundImage, for: .normal)
        searchBar.wmf_enumerateSubviewTextFields { (textField) in
            textField.textColor = theme.colors.primaryText
            textField.keyboardAppearance = theme.keyboardAppearance
            textField.font = UIFont.systemFont(ofSize: 14)
        }
        searchBar.searchTextPositionAdjustment = UIOffset(horizontal: 7, vertical: 0) 
        collectionView.backgroundColor = .clear
        view.backgroundColor = theme.colors.paperBackground
        for cell in collectionView.visibleCells {
            guard let themeable = cell as? Themeable else {
                continue
            }
            themeable.apply(theme: theme)
        }
        for header in collectionView.visibleSupplementaryViews(ofKind: UICollectionElementKindSectionHeader) {
            guard let themeable = header as? Themeable else {
                continue
            }
            themeable.apply(theme: theme)
        }
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
        guard let placeholderCell = layoutManager.placeholder(forCellWithReuseIdentifier: ExploreCardCollectionViewCell.identifier) as? ExploreCardCollectionViewCell else {
            return estimate
        }
        placeholderCell.prepareForReuse()
        configure(cell: placeholderCell, forItemAt: indexPath, width: columnWidth, layoutOnly: true)
        estimate.height = placeholderCell.sizeThatFits(CGSize(width: columnWidth, height: UIViewNoIntrinsicMetric), apply: false).height
        estimate.precalculated = true
        return estimate
    }
    
    override func collectionView(_ collectionView: UICollectionView, estimatedHeightForHeaderInSection section: Int, forColumnWidth columnWidth: CGFloat) -> WMFLayoutEstimate {
        var estimate = WMFLayoutEstimate(precalculated: false, height: 100)
        guard let header = layoutManager.placeholder(forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: ExploreHeaderCollectionReusableView.identifier) as? ExploreHeaderCollectionReusableView else {
            return estimate
        }
        header.prepareForReuse()
        configureHeader(header, for: section)
        estimate.height = header.sizeThatFits(CGSize(width: columnWidth, height: UIViewNoIntrinsicMetric), apply: false).height
        estimate.precalculated = true
        return estimate
    }
    
    override func metrics(withBoundsSize size: CGSize, readableWidth: CGFloat) -> WMFCVLMetrics {
        return WMFCVLMetrics(boundsSize: size, readableWidth: readableWidth, layoutDirection: UIApplication.shared.userInterfaceLayoutDirection)
    }
    
    override func collectionView(_ collectionView: UICollectionView, prefersWiderColumnForSectionAt index: UInt) -> Bool {
        return index % 2 == 0
    }
}

// MARK - Analytics
extension ExploreViewController {
    private func logArticleSavedStateChange(_ wasArticleSaved: Bool, saveButton: SaveButton?, article: WMFArticle) {
        guard let articleURL = article.url else {
            assert(false, "Article missing url: \(article)")
            return
        }
        if wasArticleSaved {
            ReadingListsFunnel.shared.logSaveInFeed(saveButton: saveButton, articleURL: articleURL)
        } else {
            ReadingListsFunnel.shared.logUnsaveInFeed(saveButton: saveButton, articleURL: articleURL)
            
        }
    }
}

extension ExploreViewController: SaveButtonsControllerDelegate {
    func didSaveArticle(_ saveButton: SaveButton?, didSave: Bool, article: WMFArticle) {
        readingListHintController.didSave(didSave, article: article, theme: theme)
        logArticleSavedStateChange(didSave, saveButton: saveButton, article: article)
    }
    
    func willUnsaveArticle(_ article: WMFArticle) {
        if article.userCreatedReadingListsCount > 0 {
            let alertController = ReadingListsAlertController()
            alertController.showAlert(presenter: self, article: article)
        } else {
            saveButtonsController.updateSavedState()
        }
    }
    
    func showAddArticlesToReadingListViewController(for article: WMFArticle) {
        let addToArticlesReadingListViewController = AddArticlesToReadingListViewController(with: dataStore, articles: [article], moveFromReadingList: nil, theme: theme)
        present(addToArticlesReadingListViewController, animated: true)
    }
}

extension ExploreViewController: ReadingListsAlertControllerDelegate {
    func readingListsAlertController(_ readingListsAlertController: ReadingListsAlertController, didSelectUnsaveForArticle: WMFArticle) {
        saveButtonsController.updateSavedState()
    }
}




