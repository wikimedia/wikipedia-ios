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
        isRefreshControlEnabled = true
    }
    
    private var fetchedResultsController: NSFetchedResultsController<WMFContentGroup>!
    private var collectionViewUpdater: CollectionViewUpdater<WMFContentGroup>!
    lazy var layoutCache: ColumnarCollectionViewControllerLayoutCache = {
       return ColumnarCollectionViewControllerLayoutCache()
    }()
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startMonitoringReachabilityIfNeeded()
        showOfflineEmptyViewIfNeeded()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopMonitoringReachability()
    }
    
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

    // MARK - Refresh
    
    open override func refresh() {
        updateFeedSources(with: nil, userInitiated: true) {
            
        }
    }
    
    // MARK - Scroll
    
    var isLoadingOlderContent: Bool = false
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        super.scrollViewDidScroll(scrollView)
        guard !isLoadingOlderContent else {
            return
        }
        
        let ratio: CGFloat = scrollView.contentOffset.y / (scrollView.contentSize.height - scrollView.bounds.size.height)
        if ratio < 0.8 {
            return
        }
        
        let lastSectionIndex = numberOfSectionsInExploreFeed - 1
        guard lastSectionIndex >= 0 else {
            return
        }

        let lastItemIndex = numberOfItemsInSection(lastSectionIndex) - 1
        guard lastItemIndex >= 0 else {
            return
        }
        
        let lastGroup = fetchedResultsController.object(at: IndexPath(item: lastItemIndex, section: lastSectionIndex))
        let now = Date()
        let midnightUTC: Date = (now as NSDate).wmf_midnightUTCDateFromLocal
        guard let lastGroupMidnightUTC = lastGroup.midnightUTCDate else {
            return
        }
        
        let calendar = NSCalendar.wmf_gregorian()
        let days: Int = calendar?.wmf_days(from: lastGroupMidnightUTC, to: midnightUTC) ?? 0
        guard days < Int(WMFExploreFeedMaximumNumberOfDays) else {
            return
        }
        
        guard let nextOldestDate: Date = calendar?.date(byAdding: .day, value: -1, to: lastGroupMidnightUTC, options: .matchStrictly) else {
            return
        }
        
        isLoadingOlderContent = true
        updateFeedSources(with: (nextOldestDate as NSDate).wmf_midnightLocalDateForEquivalentUTC, userInitiated: false) {
            self.isLoadingOlderContent = false
        }
    }
    
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
    
    var numberOfSectionsInExploreFeed: Int {
        guard let sections = fetchedResultsController.sections else {
            return 0
        }
        return sections.count
    }
    
    func numberOfItemsInSection(_ section: Int) -> Int {
        guard let sections = fetchedResultsController.sections, sections.count > section else {
            return 0
        }
        return sections[section].numberOfObjects
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return numberOfSectionsInExploreFeed
    }
    
    private func resetRefreshControl() {
        guard let refreshControl = collectionView.refreshControl,
            refreshControl.isRefreshing else {
            return
        }
        refreshControl.endRefreshing()
    }
    
    lazy var reachabilityManager: AFNetworkReachabilityManager = {
        return AFNetworkReachabilityManager(forDomain: WMFDefaultSiteDomain)
    }()
    
    private func stopMonitoringReachability() {
        reachabilityManager.setReachabilityStatusChange(nil)
        reachabilityManager.stopMonitoring()
    }
    
    private func startMonitoringReachabilityIfNeeded() {
        guard numberOfSectionsInExploreFeed == 0 else {
            stopMonitoringReachability()
            return
        }
        
        reachabilityManager.startMonitoring()
        reachabilityManager.setReachabilityStatusChange { [weak self] (status) in
            switch status {
            case .reachableViaWiFi:
                fallthrough
            case .reachableViaWWAN:
                DispatchQueue.main.async {
                    self?.updateFeedSources(userInitiated: false)
                }
            case .notReachable:
                DispatchQueue.main.async {
                    self?.showOfflineEmptyViewIfNeeded()
                }
            default:
                break
            }
        }
    }
    
    private func showOfflineEmptyViewIfNeeded() {
        guard isViewLoaded && fetchedResultsController != nil else {
            return
        }
        
        guard numberOfSectionsInExploreFeed == 0 else {
            wmf_hideEmptyView()
            return
        }
        
        guard !wmf_isShowingEmptyView() else {
            return
        }
        
        guard reachabilityManager.networkReachabilityStatus == .notReachable else {
            return
        }
        
        resetRefreshControl()
        wmf_showEmptyView(of: .noFeed, theme: theme, frame: view.bounds)
    }
    
    var isLoadingNewContent = false

    @objc(updateFeedSourcesWithDate:userInitiated:completion:)
    public func updateFeedSources(with date: Date? = nil, userInitiated: Bool, completion: @escaping () -> Void = { }) {
        assert(Thread.isMainThread)
        guard !isLoadingNewContent else {
            completion()
            return
        }
        isLoadingNewContent = true
        if date == nil, let refreshControl = collectionView.refreshControl, !refreshControl.isRefreshing {
            #if UI_TEST
            #else
            refreshControl.beginRefreshing()
            #endif
            if numberOfSectionsInExploreFeed == 0 {
                collectionView.contentOffset = CGPoint(x: 0, y: 0 - collectionView.contentInset.top - refreshControl.frame.size.height)
            }
        }
        self.dataStore.feedContentController.updateFeedSources(with: date, userInitiated: userInitiated) {
            DispatchQueue.main.async {
                self.isLoadingNewContent = false
                self.resetRefreshControl()
                if date == nil {
                    self.startMonitoringReachabilityIfNeeded()
                    self.showOfflineEmptyViewIfNeeded()
                }
                completion()
            }
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
       return numberOfItemsInSection(section)
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let maybeCell = collectionView.dequeueReusableCell(withReuseIdentifier: ExploreCardCollectionViewCell.identifier, for: indexPath)
        guard let cell = maybeCell as? ExploreCardCollectionViewCell else {
            return maybeCell
        }
        cell.apply(theme: theme)
        configure(cell: cell, forItemAt: indexPath, layoutOnly: false)
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
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        let group = fetchedResultsController.object(at: indexPath)
        guard group.contentGroupKind != .announcement else {
            return false
        }
        return true
    }
    
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

    func configure(cell: ExploreCardCollectionViewCell, forItemAt indexPath: IndexPath, layoutOnly: Bool) {
        let cardVC = cell.cardContent as? ExploreCardViewController ?? createNewCardVCFor(cell)
        let group = fetchedResultsController.object(at: indexPath)
        cardVC.contentGroup = group
        cell.titleLabel.text = group.headerTitle
        cell.subtitleLabel.text = group.headerSubTitle
        cell.footerButton.setTitle(group.moreTitle, for: .normal)
        cell.customizationButton.isHidden = !group.contentGroupKind.isCustomizable
        cell.apply(theme: theme)
        cell.delegate = self
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
    
    // MARK: - ColumnarCollectionViewLayoutDelegate
    override func collectionView(_ collectionView: UICollectionView, estimatedHeightForItemAt indexPath: IndexPath, forColumnWidth columnWidth: CGFloat) -> ColumnarCollectionViewLayoutHeightEstimate {
        var estimate = ColumnarCollectionViewLayoutHeightEstimate(precalculated: false, height: 100)
        guard let placeholderCell = layoutManager.placeholder(forCellWithReuseIdentifier: ExploreCardCollectionViewCell.identifier) as? ExploreCardCollectionViewCell else {
            return estimate
        }
        configure(cell: placeholderCell, forItemAt: indexPath, layoutOnly: true)
        estimate.height = placeholderCell.sizeThatFits(CGSize(width: columnWidth, height: UIViewNoIntrinsicMetric), apply: false).height
        estimate.precalculated = true
        return estimate
    }
    
    override func collectionView(_ collectionView: UICollectionView, estimatedHeightForHeaderInSection section: Int, forColumnWidth columnWidth: CGFloat) -> ColumnarCollectionViewLayoutHeightEstimate {
        let group = fetchedResultsController.object(at: IndexPath(item: 0, section: section))
        guard let date = group.midnightUTCDate, date < Date() else {
            return ColumnarCollectionViewLayoutHeightEstimate(precalculated: true, height: 0)
        }
        var estimate = ColumnarCollectionViewLayoutHeightEstimate(precalculated: false, height: 100)
        guard let header = layoutManager.placeholder(forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: ExploreHeaderCollectionReusableView.identifier) as? ExploreHeaderCollectionReusableView else {
            return estimate
        }
        configureHeader(header, for: section)
        estimate.height = header.sizeThatFits(CGSize(width: columnWidth, height: UIViewNoIntrinsicMetric), apply: false).height
        estimate.precalculated = true
        return estimate
    }
    
    override func metrics(with size: CGSize, readableWidth: CGFloat, layoutMargins: UIEdgeInsets) -> ColumnarCollectionViewLayoutMetrics {
        return ColumnarCollectionViewLayoutMetrics.exploreViewMetrics(with: size, readableWidth: readableWidth, layoutMargins: layoutMargins)
    }
    
    // MARK - Prefetching
    
    override func imageURLsForItemAt(_ indexPath: IndexPath) -> Set<URL>? {
        let contentGroup = fetchedResultsController.object(at: indexPath)
        return contentGroup.imageURLsCompatibleWithTraitCollection(traitCollection, dataStore: dataStore)
    }
}


extension ExploreViewController: CollectionViewUpdaterDelegate {
    func collectionViewUpdater<T>(_ updater: CollectionViewUpdater<T>, didUpdate collectionView: UICollectionView) where T : NSFetchRequestResult {
        
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

private extension WMFContentGroupKind {
    var hideCardsActionTitle: String {
        switch self {
        case .featuredArticle:
            return WMFLocalizedString("explore-feed-preferences-hide-featured-article-action-title", value: "Hide all Featured article cards", comment: "Title for action that allows users to hide all Featured article cards")
        case .topRead:
            return WMFLocalizedString("explore-feed-preferences-hide-top-read-action-title", value: "Hide all Top read cards", comment: "Title for action that allows users to hide all Top read cards")
        case .news:
            return WMFLocalizedString("explore-feed-preferences-hide-news-action-title", value: "Hide all Top read cards", comment: "Title for action that allows users to hide all In the news cards")
        case .onThisDay:
            return WMFLocalizedString("explore-feed-preferences-hide-on-this-day-action-title", value: "Hide all On this day cards", comment: "Title for action that allows users to hide all On this day cards")
        case .location:
            fallthrough
        case .locationPlaceholder:
            return WMFLocalizedString("explore-feed-preferences-hide-places-action-title", value: "Hide all Places cards", comment: "Title for action that allows users to hide all Places cards")
        case .random:
            return WMFLocalizedString("explore-feed-preferences-hide-randomizer-action-title", value: "Hide all Randomizer cards", comment: "Title for action that allows users to hide all Randomizer cards")
        case .pictureOfTheDay:
            return WMFLocalizedString("explore-feed-preferences-hide-picture-of-the-day-action-title", value: "Hide all Picture of the day cards", comment: "Title for action that allows users to hide all Picture of the day cards")
        case .continueReading:
            return WMFLocalizedString("explore-feed-preferences-hide-continue-reading-action-title", value: "Hide all Continue reading cards", comment: "Title for action that allows users to hide all Continue reading cards")
        case .relatedPages:
            return WMFLocalizedString("explore-feed-preferences-hide-because-you-read-action-title", value: "Hide all Because you read cards", comment: "Title for action that allows users to hide all Because you read cards")
        default:
            assertionFailure("\(self) is not customizable")
            return ""
            
        }
    }
}

extension ExploreViewController: ExploreCardCollectionViewCellDelegate {
    func exploreCardCollectionViewCellWantsCustomization(_ cell: ExploreCardCollectionViewCell) {
        guard let vc = cell.cardContent as? ExploreCardViewController,
            let group = vc.contentGroup else {
            return
        }
        guard let sheet = menuActionSheetForGroup(group) else {
            return
        }
        present(sheet, animated: true)
    }

    private func menuActionSheetForGroup(_ group: WMFContentGroup) -> UIAlertController? {
        guard group.contentGroupKind.isCustomizable else {
            return nil
        }
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let customizeExploreFeed = UIAlertAction(title: WMFLocalizedString("explore-feed-preferences-customize-explore-feed-action-title", value: "Customize Explore feed", comment: "Title for action that allows users to go to the Explore feed settings screen"), style: .default) { (_) in
            let exploreFeedSettingsViewController = ExploreFeedSettingsViewController()
            exploreFeedSettingsViewController.showCloseButton = true
            exploreFeedSettingsViewController.apply(theme: self.theme)
            let themeableNavigationController = WMFThemeableNavigationController(rootViewController: exploreFeedSettingsViewController, theme: self.theme)
            self.present(themeableNavigationController, animated: true)
        }
        let hideThisCard = UIAlertAction(title: WMFLocalizedString("explore-feed-preferences-hide-card-action-title", value: "Hide this card", comment: "Title for action that allows users to hide a feed card"), style: .default) { (_) in
            self.dataStore.viewContext.remove(group)
            group.updateVisibility()
        }
        let hideAllCards = UIAlertAction(title: group.contentGroupKind.hideCardsActionTitle, style: .default) { (_) in
            self.dataStore.feedContentController.toggleContentGroup(of: group.contentGroupKind, isOn: false)
        }
        let cancel = UIAlertAction(title: CommonStrings.cancelActionTitle, style: .cancel)
        sheet.addAction(hideThisCard)
        sheet.addAction(hideAllCards)
        sheet.addAction(customizeExploreFeed)
        sheet.addAction(cancel)

        return sheet
    }
    
    
}



