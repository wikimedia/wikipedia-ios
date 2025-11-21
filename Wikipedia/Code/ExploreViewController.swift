import WMF
import SwiftUI
import CocoaLumberjackSwift
import WMFComponents
import WMFData

class ExploreViewController: ColumnarCollectionViewController, ExploreCardViewControllerDelegate, CollectionViewUpdaterDelegate, ImageScaleTransitionProviding, DetailTransitionSourceProviding, MEPEventsProviding, WMFNavigationBarConfiguring {

    public var presentedContentGroupKey: String?
    public var shouldRestoreScrollPosition = false
    @objc var checkForSurveyUponAppear: Bool = false

    @objc public weak var notificationsCenterPresentationDelegate: NotificationsCenterPresentationDelegate?

    private weak var imageRecommendationsViewModel: WMFImageRecommendationsViewModel?

    private var yirDataController: WMFYearInReviewDataController? {
        return try? WMFYearInReviewDataController()
    }

    private lazy var tabsCoordinator: TabsOverviewCoordinator? = { [weak self] in
        guard let self, let nav = self.navigationController else { return nil }
        return TabsOverviewCoordinator(
            navigationController: nav,
            theme: self.theme,
            dataStore: self.dataStore
        )
    }()

    // Coordinator
    private var _profileCoordinator: ProfileCoordinator?
    private var profileCoordinator: ProfileCoordinator? {
        guard let navigationController = navigationController,
        let yirCoordinator = self.yirCoordinator else {
            return nil
        }
        
        guard let existingProfileCoordinator = _profileCoordinator else {
            _profileCoordinator = ProfileCoordinator(navigationController: navigationController, theme: theme, dataStore: dataStore, donateSouce: .exploreProfile, logoutDelegate: self, sourcePage: ProfileCoordinatorSource.explore, yirCoordinator: yirCoordinator)
            _profileCoordinator?.badgeDelegate = self
            return _profileCoordinator
        }

        return existingProfileCoordinator
    }

    private var _yirCoordinator: YearInReviewCoordinator?
    private var yirCoordinator: YearInReviewCoordinator? {
            guard let navigationController = navigationController,
            let yirDataController else {
                return nil
            }
            
            guard let existingYirCoordinator = _yirCoordinator else {
                _yirCoordinator = YearInReviewCoordinator(navigationController: navigationController, theme: theme, dataStore: dataStore, dataController: yirDataController)
                _yirCoordinator?.badgeDelegate = self
                return _yirCoordinator
            }
            
            return existingYirCoordinator
    }
    
    private var presentingSearchResults: Bool = false

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        layoutManager.register(ExploreCardCollectionViewCell.self, forCellWithReuseIdentifier: ExploreCardCollectionViewCell.identifier, addPlaceholder: true)

        isRefreshControlEnabled = true
        collectionView.refreshControl?.layer.zPosition = 0

        NotificationCenter.default.addObserver(self, selector: #selector(exploreFeedPreferencesDidSave(_:)), name: NSNotification.Name.WMFExploreFeedPreferencesDidSave, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(articleDidChange(_:)), name: NSNotification.Name.WMFArticleUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(articleDeleted(_:)), name: NSNotification.Name.WMFArticleDeleted, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(pushNotificationBannerDidDisplayInForeground(_:)), name: .pushNotificationBannerDidDisplayInForeground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(viewContextDidReset(_:)), name: NSNotification.Name.WMFViewContextDidReset, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(databaseHousekeeperDidComplete), name: .databaseHousekeeperDidComplete, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(coreDataStoreSetup), name: WMFNSNotification.coreDataStoreSetup, object: nil)
        
        setupTopSafeAreaOverlay(scrollView: collectionView)
    }

    @objc var isGranularUpdatingEnabled: Bool = true {
        didSet {
            collectionViewUpdater?.isGranularUpdatingEnabled = isGranularUpdatingEnabled
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        NSObject.cancelPreviousPerformRequests(withTarget: self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startMonitoringReachabilityIfNeeded()
        showOfflineEmptyViewIfNeeded()
        imageScaleTransitionView = nil
        detailTransitionSourceRect = nil
        logFeedImpressionAfterDelay()
        dataStore.remoteNotificationsController.loadNotifications(force: false)
#if UITEST
        presentUITestHelperController()
#endif
        presentModalsIfNeeded()

        if tabBarSnapshotImage == nil {
            if #available(iOS 18, *), UIDevice.current.userInterfaceIdiom == .pad {
                tabBarSnapshotImage = nil
            } else {
                updateTabBarSnapshotImage()
            }
        }
        ArticleTabsFunnel.shared.logIconImpression(interface: .feed, project: nil)
    }

    override func viewWillHaveFirstAppearance(_ animated: Bool) {
        super.viewWillHaveFirstAppearance(animated)
        setupFetchedResultsController()
    }

    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        isGranularUpdatingEnabled = true
        restoreScrollPositionIfNeeded()
        configureNavigationBar()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(alongsideTransition: nil) { [weak self] _ in
            self?.updateTabBarSnapshotImage()
            self?.calculateTopSafeAreaOverlayHeight()
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        dataStore.feedContentController.dismissCollapsedContentGroups()
        stopMonitoringReachability()
        isGranularUpdatingEnabled = false
        resetNavBarAppearance()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if #available(iOS 18, *) {
            if UIDevice.current.userInterfaceIdiom == .pad {
                if previousTraitCollection?.horizontalSizeClass != traitCollection.horizontalSizeClass {
                    configureNavigationBar()
                }
            }
        }
    }
    
    open override func refresh() {
        updateFeedSources(with: nil, userInitiated: true) {
        }
    }
    
    private func presentUITestHelperController() {
        let viewController = UITestHelperViewController(theme: theme)
        present(viewController, animated: false)
    }
    
    @objc private func databaseHousekeeperDidComplete() {
        DispatchQueue.main.async {
            self.refresh()
        }
    }
    
    // MARK: Navigation Bar
    
    private func configureNavigationBar() {
        
        var titleConfig: WMFNavigationBarTitleConfig = WMFNavigationBarTitleConfig(title: CommonStrings.exploreTabTitle, customView: titleView, alignment: .leadingCompact)
        extendedLayoutIncludesOpaqueBars = false
        if #available(iOS 18, *) {
            if UIDevice.current.userInterfaceIdiom == .pad && traitCollection.horizontalSizeClass == .regular {

                var customLargeTitleFont: UIFont? = nil
                if let logoFont = UIFont(name: "icomoon", size: 24) {
                    customLargeTitleFont = logoFont
                    titleConfig = WMFNavigationBarTitleConfig(title: "", customView: nil, alignment: .leadingLarge, customLargeTitleFont: customLargeTitleFont)
                } else {
                    titleConfig = WMFNavigationBarTitleConfig(title: CommonStrings.exploreTabTitle, customView: nil, alignment: .hidden, customLargeTitleFont: nil)
                }
                
                extendedLayoutIncludesOpaqueBars = true
            }
        }
        
        let profileButtonConfig = profileButtonConfig(target: self, action: #selector(userDidTapProfile), dataStore: dataStore, yirDataController: yirDataController,  leadingBarButtonItem: nil)
        
        let tabsButtonConfig = tabsButtonConfig(target: self, action: #selector(userDidTapTabs), dataStore: dataStore)
        
        let searchViewController = SearchViewController(source: .topOfFeed, customArticleCoordinatorNavigationController: navigationController)
        searchViewController.dataStore = dataStore
        
        let populateSearchBarWithTextAction: (String) -> Void = { [weak self] searchTerm in
            self?.navigationItem.searchController?.searchBar.text = searchTerm
            self?.navigationItem.searchController?.searchBar.becomeFirstResponder()
        }
        
        searchViewController.populateSearchBarWithTextAction = populateSearchBarWithTextAction
        
        searchViewController.theme = theme
        
        let searchConfig = WMFNavigationBarSearchConfig(
            searchResultsController: searchViewController,
            searchControllerDelegate: self,
            searchResultsUpdater: self,
            searchBarDelegate: nil,
            searchBarPlaceholder: CommonStrings.searchBarPlaceholder,
            showsScopeBar: false, scopeButtonTitles: nil)
        

        configureNavigationBar(titleConfig: titleConfig, closeButtonConfig: nil, profileButtonConfig: profileButtonConfig, tabsButtonConfig: tabsButtonConfig, searchBarConfig: searchConfig, hideNavigationBarOnScroll: !presentingSearchResults)
        
        // Need to override this so that "" does not appear as back button title.
        navigationItem.backButtonTitle = CommonStrings.exploreTabTitle
    }
    
    @objc func updateProfileButton() {
        let config = self.profileButtonConfig(target: self, action: #selector(userDidTapProfile), dataStore: dataStore, yirDataController: yirDataController, leadingBarButtonItem: nil)
        updateNavigationBarProfileButton(needsBadge: config.needsBadge, needsBadgeLabel: CommonStrings.profileButtonBadgeTitle, noBadgeLabel: CommonStrings.profileButtonTitle)
    }
    
    @objc func userDidTapTabs() {
        tabsCoordinator?.start()
        ArticleTabsFunnel.shared.logIconClick(interface: .feed, project: nil)
    }

    @objc func scrollToTop() {
        navigationController?.setNavigationBarHidden(false, animated: true)
        collectionView.setContentOffset(CGPoint(x: collectionView.contentOffset.x, y: 0 - collectionView.contentInset.top), animated: true)
    }
    
    @objc func titleBarButtonPressed(_ sender: UIButton?) {
        scrollToTop()
    }
    
    @objc public var titleButton: UIView {
        return titleView
    }
    
    lazy var longTitleButton: UIButton = {
        let longTitleButton = UIButton(type: .custom)
        var deprecatedLongTitleButton = longTitleButton as DeprecatedButton
        deprecatedLongTitleButton.deprecatedAdjustsImageWhenHighlighted = true
        longTitleButton.setImage(UIImage(named: "wikipedia"), for: .normal)
        longTitleButton.sizeToFit()
        longTitleButton.addTarget(self, action: #selector(titleBarButtonPressed), for: .touchUpInside)
        longTitleButton.isAccessibilityElement = false
        return longTitleButton
    }()
    
    lazy var titleView: UIView = {
        let titleView = UIView(frame: longTitleButton.bounds)
        titleView.addSubview(longTitleButton)
        titleView.isAccessibilityElement = false
        return titleView
    }()

    @objc func userDidTapProfile() {
        
        guard let languageCode = dataStore.languageLinkController.appLanguage?.languageCode,
        let metricsID = DonateCoordinator.metricsID(for: .exploreProfile, languageCode: languageCode) else {
            return
        }
        
        DonateFunnel.shared.logExploreProfile(metricsID: metricsID)

        profileCoordinator?.start()
    }
    
    // MARK: - Scroll
    
    private func restoreScrollPositionIfNeeded() {
        guard
            shouldRestoreScrollPosition,
            let presentedContentGroupKey = presentedContentGroupKey,
            let contentGroup = fetchedResultsController?.fetchedObjects?.first(where: { $0.key == presentedContentGroupKey }),
            let indexPath = fetchedResultsController?.indexPath(forObject: contentGroup)
        else {
            return
        }
        collectionView.scrollToItem(at: indexPath, at: [], animated: false)
        self.shouldRestoreScrollPosition = false
        self.presentedContentGroupKey = nil
    }
    
    var isLoadingOlderContent: Bool = false
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        super.scrollViewDidScroll(scrollView)
        
        calculateNavigationBarHiddenState(scrollView: scrollView)
        
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
        
        guard let lastGroup = group(at: IndexPath(item: lastItemIndex, section: lastSectionIndex)) else {
            return
        }
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

    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        logFeedImpressionAfterDelay()
    }
    
    func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    // MARK: - Event logging

    private func logFeedImpressionAfterDelay() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(logFeedImpression), object: nil)
        perform(#selector(logFeedImpression), with: self, afterDelay: 3)
    }

    @objc private func logFeedImpression() {
        for indexPath in collectionView.indexPathsForVisibleItems {
            guard let group = group(at: indexPath), group.undoType == .none, let itemFrame = collectionView.layoutAttributesForItem(at: indexPath)?.frame else {
                continue
            }
            let navBarVisibleHeight = CGFloat(0)
            let visibleRectOrigin = CGPoint(x: collectionView.contentOffset.x, y: collectionView.contentOffset.y + navBarVisibleHeight)
            let visibleRectSize = view.layoutMarginsGuide.layoutFrame.size
            let itemCenter = CGPoint(x: itemFrame.midX, y: itemFrame.midY)
            let visibleRect = CGRect(origin: visibleRectOrigin, size: visibleRectSize)
            let isUnobstructed = visibleRect.contains(itemCenter)
            guard isUnobstructed else {
                continue
            }
        }
    }
    
    // MARK: - Search
    
    @objc func ensureWikipediaSearchIsShowing() {
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    // MARK: - State
    
    @objc var dataStore: MWKDataStore!
    private var fetchedResultsController: NSFetchedResultsController<WMFContentGroup>?
    private var collectionViewUpdater: CollectionViewUpdater<WMFContentGroup>?
    
    private var wantsDeleteInsertOnNextItemUpdate: Bool = false

    private func setupFetchedResultsController() {
        let fetchRequest: NSFetchRequest<WMFContentGroup> = WMFContentGroup.fetchRequest()
        let today = NSDate().wmf_midnightUTCDateFromLocal as Date
        let oldestDate = Calendar.current.date(byAdding: .day, value: -WMFExploreFeedMaximumNumberOfDays, to: today) ?? today
        fetchRequest.predicate = NSPredicate(format: "isVisible == YES && (placement == NULL || placement == %@) && midnightUTCDate >= %@", "feed", oldestDate as NSDate)
        fetchRequest.sortDescriptors = dataStore.feedContentController.exploreFeedSortDescriptors()
        let frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataStore.viewContext, sectionNameKeyPath: "midnightUTCDate", cacheName: nil)
        fetchedResultsController = frc
        let updater = CollectionViewUpdater(fetchedResultsController: frc, collectionView: collectionView)
        collectionViewUpdater = updater
        updater.delegate = self
        updater.isSlidingNewContentInFromTheTopEnabled = true
        updater.performFetch()
    }
    
    private func group(at indexPath: IndexPath) -> WMFContentGroup? {
        guard let frc = fetchedResultsController, frc.isValidIndexPath(indexPath) else {
            return nil
        }
        return frc.object(at: indexPath)
    }
    
    private func groupKey(at indexPath: IndexPath) -> WMFInMemoryURLKey? {
        return group(at: indexPath)?.inMemoryKey
    }
    
    lazy var saveButtonsController: SaveButtonsController = {
        let sbc = SaveButtonsController(dataStore: dataStore)
        sbc.delegate = self
        return sbc
    }()
    
    var numberOfSectionsInExploreFeed: Int {
        guard let sections = fetchedResultsController?.sections else {
            return 0
        }
        return sections.count
    }
    
    func numberOfItemsInSection(_ section: Int) -> Int {
        guard let sections = fetchedResultsController?.sections, sections.count > section else {
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
    
    lazy var reachabilityNotifier: ReachabilityNotifier = {
        let notifier = ReachabilityNotifier(Configuration.current.defaultSiteDomain) { [weak self] (reachable, flags) in
            if reachable {
                DispatchQueue.main.async {
                    self?.updateFeedSources(userInitiated: false)
                }
            } else {
                DispatchQueue.main.async {
                    self?.showOfflineEmptyViewIfNeeded()

                }
            }
        }
        return notifier
    }()
    
    private func stopMonitoringReachability() {
        reachabilityNotifier.stop()
    }
    
    private func startMonitoringReachabilityIfNeeded() {
        guard numberOfSectionsInExploreFeed == 0 else {
            stopMonitoringReachability()
            return
        }
        reachabilityNotifier.start()
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
        
        guard !reachabilityNotifier.isReachable else {
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
            refreshControl.beginRefreshing()
            if numberOfSectionsInExploreFeed == 0 {
                scrollToTop()
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
    
    override func contentSizeCategoryDidChange(_ notification: Notification?) {
        layoutCache.reset()
        super.contentSizeCategoryDidChange(notification)
    }
    
    // MARK: - ImageScaleTransitionProviding
    
    var imageScaleTransitionView: UIImageView?
    
    // MARK: - DetailTransitionSourceProviding
    
    var detailTransitionSourceRect: CGRect?
    
    var tabBarSnapshotImage: UIImage?
    
    private func updateTabBarSnapshotImage() {
        guard let tabBar = self.tabBarController?.tabBar else {
            return
        }
        
        let renderer = UIGraphicsImageRenderer(size: tabBar.bounds.size)
        let image = renderer.image { ctx in
            tabBar.drawHierarchy(in: tabBar.bounds, afterScreenUpdates: true)
        }
        
        self.tabBarSnapshotImage = image
    }
    
    // MARK: - UICollectionViewDataSource
    
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
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionHeader else {
            abort()
        }
        guard let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: CollectionViewHeader.identifier, for: indexPath) as? CollectionViewHeader else {
            abort()
        }
        configureHeader(header, for: indexPath.section)
        return header
    }
    
    // MARK: - UICollectionViewDelegate
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        guard let group = group(at: indexPath) else {
            return false
        }
        return group.isSelectable
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        var titleAreaTapped = false
        if let cell = collectionView.cellForItem(at: indexPath) as? ExploreCardCollectionViewCell {
            detailTransitionSourceRect = view.convert(cell.frame, from: collectionView)
            if
                let vc = cell.cardContent as? ExploreCardViewController,
                vc.collectionView.numberOfSections > 0, vc.collectionView.numberOfItems(inSection: 0) > 0,
                let cell = vc.collectionView.cellForItem(at: IndexPath(item: 0, section: 0)) as? ArticleCollectionViewCell {
                imageScaleTransitionView = cell.imageView.isHidden ? nil : cell.imageView
            } else {
                imageScaleTransitionView = nil
            }
            titleAreaTapped = cell.titleAreaTapped
        }
        guard let group = group(at: indexPath) else {
            return
        }

        presentedContentGroupKey = group.key
        
        // When a random article title is tapped, show the previewed article, not another random article
        let useRandomArticlePreviewItem = titleAreaTapped && group.moreType == .pageWithRandomButton

        if !useRandomArticlePreviewItem {
            
            // first try random coordinator
            if let navigationController,
               group.contentGroupKind == .random,
               let randomSiteURL = group.siteURL {
                
                // let articleSource = Explore tapped "Another random article" title
                let randomCoordinator = RandomArticleCoordinator(navigationController: navigationController, articleURL: nil, siteURL: randomSiteURL, dataStore: dataStore, theme: theme, source: .undefined, animated: true)
                randomCoordinator.start()
                return
            } else if let vc = group.detailViewControllerWithDataStore(dataStore, theme: theme, imageRecDelegate: self, imageRecLoggingDelegate: self) {
                
                if vc is WMFImageRecommendationsViewController {
                    ImageRecommendationsFunnel.shared.logExploreCardDidTapAddImage()
                }
                
                push(vc, animated: true)
                return
            }
        }
        
        if let vc = group.detailViewControllerForPreviewItemAtIndex(0, dataStore: dataStore, theme: theme, source: .undefined) {
            if vc is WMFImageGalleryViewController {
                present(vc, animated: true)
            } else {
                push(vc, animated: true)
            }
            return
        }
    }
    
    func configureHeader(_ header: CollectionViewHeader, for sectionIndex: Int) {
        guard collectionView(collectionView, numberOfItemsInSection: sectionIndex) > 0 else {
            return
        }
        guard let group = group(at: IndexPath(item: 0, section: sectionIndex)) else {
            return
        }
        header.title = (group.midnightUTCDate as NSDate?)?.wmf_localizedRelativeDateFromMidnightUTCDate()
        header.apply(theme: theme)
    }
    
    func createNewCardVCFor(_ cell: ExploreCardCollectionViewCell) -> ExploreCardViewController {
        let cardVC = ExploreCardViewController()
        cardVC.delegate = self
        cardVC.dataStore = dataStore
        cardVC.view.autoresizingMask = []
        addChild(cardVC)
        cell.cardContent = cardVC
        cardVC.didMove(toParent: self)
        return cardVC
    }

    func configure(cell: ExploreCardCollectionViewCell, forItemAt indexPath: IndexPath, layoutOnly: Bool) {
        let cardVC = cell.cardContent as? ExploreCardViewController ?? createNewCardVCFor(cell)
        guard let group = group(at: indexPath) else {
            return
        }
        cardVC.contentGroup = group
        cell.title = group.headerTitle
        cell.subtitle = group.headerSubTitle
        cell.footerTitle = cardVC.footerText
        cell.isCustomizationButtonHidden = !(group.contentGroupKind.isCustomizable || group.contentGroupKind.isGlobal)
        cell.undoType = group.undoType
        cell.apply(theme: theme)
        cell.delegate = self
        if group.undoType == .contentGroupKind {
            indexPathsForCollapsedCellsThatCanReappear.insert(indexPath)
        }
    }
    
    override func apply(theme: Theme) {
        super.apply(theme: theme)
        guard viewIfLoaded != nil else {
            return
        }

        self.theme = theme
        tabBarSnapshotImage = nil

        collectionView.backgroundColor = .clear
        view.backgroundColor = theme.colors.paperBackground
        for cell in collectionView.visibleCells {
            guard let themeable = cell as? Themeable else {
                continue
            }
            themeable.apply(theme: theme)
        }
        for header in collectionView.visibleSupplementaryViews(ofKind: UICollectionView.elementKindSectionHeader) {
            guard let themeable = header as? Themeable else {
                continue
            }
            themeable.apply(theme: theme)
        }
        
        yirCoordinator?.theme = theme
        profileCoordinator?.theme = theme
        
        updateProfileButton()
        themeNavigationBarLeadingTitleView()
        themeNavigationBarCustomCenteredTitleView()
        
        if let searchVC = navigationItem.searchController?.searchResultsController as? SearchViewController {
            searchVC.theme = theme
            searchVC.apply(theme: theme)
        }
        
        themeTopSafeAreaOverlay()
    }
    
    // MARK: - ColumnarCollectionViewLayoutDelegate

    override func collectionView(_ collectionView: UICollectionView, estimatedHeightForItemAt indexPath: IndexPath, forColumnWidth columnWidth: CGFloat) -> ColumnarCollectionViewLayoutHeightEstimate {
        guard let group = group(at: indexPath) else {
            return ColumnarCollectionViewLayoutHeightEstimate(precalculated: true, height: 0)
        }
        let identifier = ExploreCardCollectionViewCell.identifier
        let userInfo = "evc-cell-\(group.inMemoryKey?.userInfoString ?? "")"
        if let cachedHeight = layoutCache.cachedHeightForCellWithIdentifier(identifier, columnWidth: columnWidth, userInfo: userInfo) {
            return ColumnarCollectionViewLayoutHeightEstimate(precalculated: true, height: cachedHeight)
        }
        var estimate = ColumnarCollectionViewLayoutHeightEstimate(precalculated: false, height: 100)
        guard let placeholderCell = layoutManager.placeholder(forCellWithReuseIdentifier: ExploreCardCollectionViewCell.identifier) as? ExploreCardCollectionViewCell else {
            return estimate
        }
        configure(cell: placeholderCell, forItemAt: indexPath, layoutOnly: true)
        estimate.height = placeholderCell.sizeThatFits(CGSize(width: columnWidth, height: UIView.noIntrinsicMetric), apply: false).height
        estimate.precalculated = true
        layoutCache.setHeight(estimate.height, forCellWithIdentifier: identifier, columnWidth: columnWidth, groupKey: group.inMemoryKey, userInfo: userInfo)
        return estimate
    }
    
    override func collectionView(_ collectionView: UICollectionView, estimatedHeightForHeaderInSection section: Int, forColumnWidth columnWidth: CGFloat) -> ColumnarCollectionViewLayoutHeightEstimate {
        guard let group = self.group(at: IndexPath(item: 0, section: section)), let date = group.midnightUTCDate, date < Date() else {
            return ColumnarCollectionViewLayoutHeightEstimate(precalculated: true, height: 0)
        }
        var estimate = ColumnarCollectionViewLayoutHeightEstimate(precalculated: false, height: 100)
        guard let header = layoutManager.placeholder(forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: CollectionViewHeader.identifier) as? CollectionViewHeader else {
            return estimate
        }
        configureHeader(header, for: section)
        estimate.height = header.sizeThatFits(CGSize(width: columnWidth, height: UIView.noIntrinsicMetric), apply: false).height
        estimate.precalculated = true
        return estimate
    }
    
    override func metrics(with size: CGSize, readableWidth: CGFloat, layoutMargins: UIEdgeInsets) -> ColumnarCollectionViewLayoutMetrics {
        return ColumnarCollectionViewLayoutMetrics.exploreViewMetrics(with: size, readableWidth: readableWidth, layoutMargins: layoutMargins)
    }

    override func collectionView(_ collectionView: UICollectionView, shouldShowFooterForSection section: Int) -> Bool {
        return false
    }
    
    // MARK: - ExploreCardViewControllerDelegate
    
    func exploreCardViewController(_ exploreCardViewController: ExploreCardViewController, didSelectItemAtIndexPath indexPath: IndexPath) {
        
        guard let contentGroup = exploreCardViewController.contentGroup else {
            return
        }
        
        if let cell = exploreCardViewController.collectionView.cellForItem(at: indexPath) {
            detailTransitionSourceRect = view.convert(cell.frame, from: exploreCardViewController.collectionView)
            if let articleCell = cell as? ArticleCollectionViewCell, !articleCell.imageView.isHidden {
                imageScaleTransitionView = articleCell.imageView
            } else {
                imageScaleTransitionView = nil
            }
        }
        
        // First try pushing articles via coordinators
        let successWithCoordinators = pushArticlesViaCoordinators(contentGroup: contentGroup, indexPath: indexPath)
        
        if successWithCoordinators {
            return
        }
        
        // If that didn't work (probably not pushing to an article), fall back to legacy logic
        guard let vc = contentGroup.detailViewControllerForPreviewItemAtIndex(indexPath.row, dataStore: dataStore, theme: theme, source: .undefined, imageRecDelegate: self, imageRecLoggingDelegate: self) else {
            return
        }
    
        if let otdvc = vc as? OnThisDayViewController {
            otdvc.initialEvent = (contentGroup.contentPreview as? [Any])?[indexPath.item] as? WMFFeedOnThisDayEvent
        }
        
        if vc is WMFImageRecommendationsViewController {
            ImageRecommendationsFunnel.shared.logExploreCardDidTapAddImage()
        }
        
        presentedContentGroupKey = contentGroup.key
        switch contentGroup.detailType {
        case .gallery:
            present(vc, animated: true)
        default:
            push(vc, animated: true)
        }
    }
    
    private func pushArticlesViaCoordinators(contentGroup: WMFContentGroup, indexPath: IndexPath) -> Bool {
        // First try pushing articles via coordinators
        if let navigationController,
           let articleURL = contentGroup.previewArticleURLForItemAtIndex(indexPath.row) {
            switch contentGroup.detailType {
            case .page:
                let articleSource = ArticleSource.undefined
                // todo: we may want to switch to get article source if we want to be more specific:
                switch contentGroup.contentGroupKind {
                case .featuredArticle:
                    // articleSource = explore featured article cell, etc.
                    break
                default:
                    break
                }
                
                let articleCoordinator = ArticleCoordinator(navigationController: navigationController, articleURL: articleURL, dataStore: dataStore, theme: theme, source: articleSource)
                articleCoordinator.start()
                return true
            case .pageWithRandomButton:
                let articleSource = ArticleSource.undefined
                // todo: we may want to switch to get article source if we want to be more specific:
                switch contentGroup.contentGroupKind {
                case .random:
                    // articleSource = explore random article, etc.
                    break
                default:
                    break
                }
                
                let randomArticleCoordinator = RandomArticleCoordinator(navigationController: navigationController, articleURL: articleURL, siteURL: nil, dataStore: dataStore, theme: theme, source: articleSource, animated: true)
                randomArticleCoordinator.start()
                return true
            default:
                break
            }
        }
        
        return false
    }
    
    // MARK: - Prefetching
    
    override func imageURLsForItemAt(_ indexPath: IndexPath) -> Set<URL>? {
        guard let contentGroup = group(at: indexPath) else {
            return nil
        }
        return contentGroup.imageURLsCompatibleWithTraitCollection(traitCollection, dataStore: dataStore)
    }
    
    #if DEBUG
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        guard motion == .motionShake else {
            return
        }
        dataStore.feedContentController.debugChaos()
    }
    #endif
    
    // MARK: - CollectionViewUpdaterDelegate
    
    var needsReloadVisibleCells = false
    var indexPathsForCollapsedCellsThatCanReappear = Set<IndexPath>()
    
    private func reloadVisibleCells() {
        for indexPath in collectionView.indexPathsForVisibleItems {
            guard let cell = collectionView.cellForItem(at: indexPath) as? ExploreCardCollectionViewCell else {
                continue
            }
            configure(cell: cell, forItemAt: indexPath, layoutOnly: false)
        }
    }
    
    func collectionViewUpdater<T: NSFetchRequestResult>(_ updater: CollectionViewUpdater<T>, didUpdate collectionView: UICollectionView) {
		
        guard needsReloadVisibleCells else {
            return
        }
        
        reloadVisibleCells()
        
        needsReloadVisibleCells = false
        layout.currentSection = nil
    }
    
    func collectionViewUpdater<T: NSFetchRequestResult>(_ updater: CollectionViewUpdater<T>, updateItemAtIndexPath indexPath: IndexPath, in collectionView: UICollectionView) {
        layoutCache.invalidateGroupKey(groupKey(at: indexPath))
        collectionView.collectionViewLayout.invalidateLayout()
        if wantsDeleteInsertOnNextItemUpdate {
            layout.currentSection = indexPath.section
            collectionView.deleteItems(at: [indexPath])
            collectionView.insertItems(at: [indexPath])
        } else {
            needsReloadVisibleCells = true
        }
    }

    // MARK: Event logging

    var eventLoggingCategory: EventCategoryMEP {
        return .feed
    }

    var eventLoggingLabel: EventLabelMEP? {
        return previewed.context?.getAnalyticsLabel()
    }

    // MARK: - For NestedCollectionViewContextMenuDelegate
    private var previewed: (context: WMFContentGroup?, indexPathItem: Int?)

    func contextMenu(contentGroup: WMFContentGroup? = nil, articleURL: URL? = nil, article: WMFArticle? = nil, itemIndex: Int) -> UIContextMenuConfiguration? {
        guard let contentGroup = contentGroup else {
            return nil
        }
        
        var previewVC: UIViewController? = viewController(for: contentGroup, at: itemIndex)
        
        if let articleURL,
           let article {
            switch contentGroup.detailType {
            case .page:
                 previewVC = ArticlePeekPreviewViewController(articleURL: articleURL, article: article, dataStore: dataStore, theme: theme, articlePreviewingDelegate: self)

            case .pageWithRandomButton:
                previewVC = ArticlePeekPreviewViewController(articleURL: articleURL, article: article, dataStore: dataStore, theme: theme, articlePreviewingDelegate: self, needsRandomOnPush: true)
                
            default:
                break
            }
        }

        let previewProvider: () -> UIViewController? = {
            return previewVC
        }
        return UIContextMenuConfiguration(identifier: nil, previewProvider: previewProvider) { (suggestedActions) -> UIMenu? in
            if let previewVC = previewVC as? ArticlePeekPreviewViewController {
                return UIMenu(title: "", image: nil, identifier: nil, options: [], children: previewVC.contextMenuItems)
            } else {
                return nil
            }
        }
    }

    func viewController(for contentGroup: WMFContentGroup, at itemIndex: Int) -> UIViewController? {
        previewed.context = contentGroup

        if let viewControllerToCommit = contentGroup.detailViewControllerForPreviewItemAtIndex(itemIndex, dataStore: dataStore, theme: theme, source: .undefined) {
            if let potd = viewControllerToCommit as? WMFImageGalleryViewController {
                potd.setOverlayViewTopBarHidden(true)
            } else if let otdVC = viewControllerToCommit as? OnThisDayViewController {
                otdVC.initialEvent = (contentGroup.contentPreview as? [Any])?[itemIndex] as? WMFFeedOnThisDayEvent
            }

            previewed.indexPathItem = itemIndex


            return viewControllerToCommit
        } else if contentGroup.contentGroupKind != .random {
            return contentGroup.detailViewControllerWithDataStore(dataStore, theme: theme)
        } else {
            return nil
        }
    }

    func willCommitPreview(with animator: UIContextMenuInteractionCommitAnimating) {
        guard let viewControllerToCommit = animator.previewViewController else {
            assertionFailure("Should be able to find previewed VC")
            return
        }
        animator.addCompletion { [weak self] in
            guard let self = self else {
                return
            }
            if let potd = viewControllerToCommit as? WMFImageGalleryViewController {
                potd.setOverlayViewTopBarHidden(false)
                self.present(potd, animated: false)
            } else if let peekVC = viewControllerToCommit as? ArticlePeekPreviewViewController {
                if let navVC = navigationController {
                    if peekVC.needsRandomOnPush {
                        let coordinator = RandomArticleCoordinator(navigationController: navVC, articleURL: peekVC.articleURL, siteURL: nil, dataStore: dataStore, theme: theme, source: .undefined, animated: true)
                        coordinator.start()
                    } else {
                        let coordinator = ArticleCoordinator(navigationController: navVC, articleURL: peekVC.articleURL, dataStore: dataStore, theme: theme, source: .undefined)
                        coordinator.start()
                    }
                }
                
            } else {
                self.push(viewControllerToCommit, animated: true)
            }
        }
    }

    override func readMoreArticlePreviewActionSelected(with peekController: ArticlePeekPreviewViewController) {
        guard let navVC = navigationController else { return }
        if peekController.needsRandomOnPush {
            let coordinator = RandomArticleCoordinator(navigationController: navVC, articleURL: peekController.articleURL, siteURL: nil, dataStore: dataStore, theme: theme, source: .undefined, animated: true)
            coordinator.start()
        } else {
            let coordinator = ArticleCoordinator(navigationController: navVC, articleURL: peekController.articleURL, dataStore: dataStore, theme: theme, source: .undefined)
            coordinator.start()
        }
        
    }

    override func saveArticlePreviewActionSelected(with peekController: ArticlePeekPreviewViewController, didSave: Bool, articleURL: URL) {
        if let date = previewed.context?.midnightUTCDate {
            if didSave {
                ReadingListsFunnel.shared.logSaveInFeed(label: previewed.context?.getAnalyticsLabel(), measureAge: date, articleURL: articleURL, index: previewed.indexPathItem)
            } else {
                ReadingListsFunnel.shared.logUnsaveInFeed(label: previewed.context?.getAnalyticsLabel(), measureAge: date, articleURL: articleURL, index: previewed.indexPathItem)
            }
        }
    }

    var addArticlesToReadingListVCDidDisappear: (() -> Void)? = nil
}

// MARK: - Modal Presentation Logic

extension ExploreViewController {
    
    /// Catch-all method for deciding what is the best modal to present on top of Explore at this point. This method needs careful if-else logic so that we do not present two modals at the same time, which may unexpectedly suppress one.
    fileprivate func presentModalsIfNeeded() {
        
        if needsYearInReviewAnnouncement() {
            updateProfileButton()
            presentYearInReviewAnnouncement()
        } else if shouldShowExploreSurvey {
            presentExploreSurveyIfNeeded()
        }
        
        #if DEBUG
        presentSearchWidgetAnnouncement()
        #endif
    }
    
    private func needsYearInReviewAnnouncement() -> Bool {

        if UIDevice.current.userInterfaceIdiom == .pad && (navigationController?.navigationBar.isHidden ?? false) {
            return false
        }
        
        guard let yirDataController else {
                  return false
        }
        
        guard yirDataController.shouldShowYearInReviewFeatureAnnouncement() else {
            return false
        }

        guard presentedViewController == nil else {
            return false
        }

        guard self.isViewLoaded && self.view.window != nil else {
            return false
        }
        
        return true
    }
    
    private func displayURLWebView(url: URL) {
        guard let presentedViewController = navigationController?.presentedViewController else {
            DDLogError("Unexpected navigation controller state. Skipping Learn About Tabs presentation.")
            return
        }

        let webVC: SinglePageWebViewController

        let config = SinglePageWebViewController.StandardConfig(url: url, useSimpleNavigationBar: true)
        webVC = SinglePageWebViewController(configType: .standard(config), theme: theme)

        let newNavigationVC =
        WMFComponentNavigationController(rootViewController: webVC, modalPresentationStyle: .formSheet)
        presentedViewController.present(newNavigationVC, animated: true, completion: { })
    }

    // TODO: Remove after expiry date (1 March 2025)
    private func presentYearInReviewAnnouncement() {
        guard let yirDataController = try? WMFYearInReviewDataController() else {
            return
        }
        yirCoordinator?.setupForFeatureAnnouncement(introSlideLoggingID: "explore_prompt")
        self.yirCoordinator?.start()
        yirDataController.hasPresentedYiRFeatureAnnouncementModel = true
    }
    
    private func shouldShowSearchWidgetAnnouncement() -> Bool {
        // Check if user has already seen the announcement
        if UserDefaults.standard.wmf_didShowSearchWidgetFeatureAnnouncement {
            return false
        }
        
        // Check if current date is before the temporary date (September 30, 2025)
        let calendar = Calendar.current
        var expiryDateComponents = DateComponents()
        expiryDateComponents.year = 2025
        expiryDateComponents.month = 9
        expiryDateComponents.day = 30
        
        guard let expiryDate = calendar.date(from: expiryDateComponents) else {
            return false
        }
        
        let currentDate = Date()
        return currentDate <= expiryDate
    }
    
    private func markSearchWidgetAnnouncementAsSeen() {
        UserDefaults.standard.wmf_didShowSearchWidgetFeatureAnnouncement = true
    }
    
    private func presentSearchWidgetAnnouncement() {
        // Check if the announcement should show
        guard shouldShowSearchWidgetAnnouncement() else {
            return
        }
        
        let title = CommonStrings.searchWidgetAnnouncementTitle
        let body = CommonStrings.searchWidgetAnnouncementBody
        let primaryButtonTitle = CommonStrings.gotItButtonTitle
        
        let foregroundImage = UIImage(named: "widget")
        let backgroundImage = UIImage(named: "gradient")
        
        let viewModel = WMFFeatureAnnouncementViewModel(title: title,body: body,
        primaryButtonTitle: primaryButtonTitle, image: foregroundImage, backgroundImage: backgroundImage, backgroundImageHeight: 250,
            gifName: nil, altText: CommonStrings.searchWidgetAnnouncementBody,
            primaryButtonAction: { [weak self] in
                self?.dismiss(animated: true)
            },
            closeButtonAction: { [weak self] in
                self?.dismiss(animated: true)
            }
        )
        
        if let profileBarButtonItem = navigationItem.rightBarButtonItem {
            announceFeature(viewModel: viewModel, sourceView: nil, sourceRect: nil, barButtonItem: profileBarButtonItem)
            // Mark as seen after successful presentation
            markSearchWidgetAnnouncementAsSeen()
        }
    }
}

// MARK: - Analytics
extension ExploreViewController {
    private func logArticleSavedStateChange(_ wasArticleSaved: Bool, saveButton: SaveButton?, article: WMFArticle, userInfo: Any?) {
        guard let articleURL = article.url else {
            assert(false, "Article missing url: \(article)")
            return
        }
        guard
            let userInfo = userInfo as? ExploreSaveButtonUserInfo,
            let midnightUTCDate = userInfo.midnightUTCDate,
            let kind = userInfo.kind
        else {
            assert(false, "Article missing user info: \(article)")
            return
        }
        let index = userInfo.indexPath.item
        if wasArticleSaved {
            ReadingListsFunnel.shared.logSaveInFeed(saveButton: saveButton, articleURL: articleURL, kind: kind, index: index, date: midnightUTCDate)
        } else {
            ReadingListsFunnel.shared.logUnsaveInFeed(saveButton: saveButton, articleURL: articleURL, kind: kind, index: index, date: midnightUTCDate)
        }
    }
}

extension ExploreViewController: SaveButtonsControllerDelegate {
    func didSaveArticle(_ saveButton: SaveButton?, didSave: Bool, article: WMFArticle, userInfo: Any?) {
        let logSavedEvent = {
            self.logArticleSavedStateChange(didSave, saveButton: saveButton, article: article, userInfo: userInfo)
        }
        if isPresentingAddArticlesToReadingListVC() {
            addArticlesToReadingListVCDidDisappear = logSavedEvent
        } else {
            logSavedEvent()
        }
    }
    
    func willUnsaveArticle(_ article: WMFArticle, userInfo: Any?) {
        if article.userCreatedReadingListsCount > 0 {
            let alertController = ReadingListsAlertController()
            alertController.showAlert(presenter: self, article: article)
        } else {
            saveButtonsController.updateSavedState()
        }
    }
    
    func showAddArticlesToReadingListViewController(for article: WMFArticle) {
        let addArticlesToReadingListViewController = AddArticlesToReadingListViewController(with: dataStore, articles: [article], moveFromReadingList: nil, theme: theme)
        addArticlesToReadingListViewController.delegate = self
        let navigationController = WMFComponentNavigationController(rootViewController: addArticlesToReadingListViewController, modalPresentationStyle: .overFullScreen)
        present(navigationController, animated: true)
    }

    private func isPresentingAddArticlesToReadingListVC() -> Bool {
        guard let navigationController = presentedViewController as? UINavigationController else {
            return false
        }
        return navigationController.viewControllers.contains { $0 is AddArticlesToReadingListViewController }
    }
}

extension ExploreViewController: AddArticlesToReadingListDelegate {
    func addArticlesToReadingListWillClose(_ addArticlesToReadingList: AddArticlesToReadingListViewController) {
    }

    func addArticlesToReadingListDidDisappear(_ addArticlesToReadingList: AddArticlesToReadingListViewController) {
        addArticlesToReadingListVCDidDisappear?()
        addArticlesToReadingListVCDidDisappear = nil
    }

    func addArticlesToReadingList(_ addArticlesToReadingList: AddArticlesToReadingListViewController, didAddArticles articles: [WMFArticle], to readingList: ReadingList) {
    }
}

extension ExploreViewController: ReadingListsAlertControllerDelegate {
    func readingListsAlertController(_ readingListsAlertController: ReadingListsAlertController, didSelectUnsaveForArticle: WMFArticle) {
        saveButtonsController.updateSavedState()
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
        sheet.popoverPresentationController?.sourceView = cell.customizationButton
        sheet.popoverPresentationController?.sourceRect = cell.customizationButton.bounds
        present(sheet, animated: true)
    }

    private func save() {
        do {
            try self.dataStore.save()
        } catch let error {
            DDLogError("Error saving after cell customization update: \(error)")
        }
    }

    @objc func exploreFeedPreferencesDidSave(_ note: Notification) {
        DispatchQueue.main.async {
            for indexPath in self.indexPathsForCollapsedCellsThatCanReappear {
                guard self.fetchedResultsController?.isValidIndexPath(indexPath) ?? false else {
                    continue
                }
                self.layoutCache.invalidateGroupKey(self.groupKey(at: indexPath))
                self.collectionView.collectionViewLayout.invalidateLayout()
            }
            self.indexPathsForCollapsedCellsThatCanReappear = []
        }
    }
    
    @objc func articleDidChange(_ note: Notification) {
        guard
            let article = note.object as? WMFArticle,
            let articleKey = article.inMemoryKey
        else {
            return
        }

        var needsReload = false
        if article.hasChangedValuesForCurrentEventThatAffectPreviews, layoutCache.invalidateArticleKey(articleKey) {
            needsReload = true
            collectionView.collectionViewLayout.invalidateLayout()
        } else if !article.hasChangedValuesForCurrentEventThatAffectSavedState {
            return
        }

        let visibleIndexPathsWithChanges = collectionView.indexPathsForVisibleItems.filter { (indexPath) -> Bool in
            guard let contentGroup = group(at: indexPath) else {
                return false
            }
            return contentGroup.previewArticleKeys.contains(articleKey)
        }
        
        guard !visibleIndexPathsWithChanges.isEmpty else {
            return
        }
        
        for indexPath in visibleIndexPathsWithChanges {
            guard let cell = collectionView.cellForItem(at: indexPath) as? ExploreCardCollectionViewCell else {
                continue
            }
            if needsReload {
                configure(cell: cell, forItemAt: indexPath, layoutOnly: false)
            } else if let cardVC = cell.cardContent as? ExploreCardViewController {
                cardVC.savedStateDidChangeForArticleWithKey(articleKey)
            }
        }
    }
    
    @objc func articleDeleted(_ note: Notification) {
        guard let articleKey = note.userInfo?[WMFArticleDeletedNotificationUserInfoArticleKeyKey] as? WMFInMemoryURLKey else {
            return
        }
        layoutCache.invalidateArticleKey(articleKey)
    }
    
    @objc func viewContextDidReset(_ note: Notification) {
        collectionView.reloadData()
    }

    private func menuActionSheetForGroup(_ group: WMFContentGroup) -> UIAlertController? {
        guard group.contentGroupKind.isCustomizable || group.contentGroupKind.isGlobal else {
            return nil
        }
        let hideThisCardHidesAll = group.contentGroupKind.isGlobal && group.contentGroupKind.isNonDateBased
        
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let customizeExploreFeed = UIAlertAction(title: CommonStrings.customizeExploreFeedTitle, style: .default) { (_) in
            let exploreFeedSettingsViewController = ExploreFeedSettingsViewController()
            exploreFeedSettingsViewController.showCloseButton = true
            exploreFeedSettingsViewController.dataStore = self.dataStore
            exploreFeedSettingsViewController.apply(theme: self.theme)
            let themeableNavigationController = WMFComponentNavigationController(rootViewController: exploreFeedSettingsViewController, modalPresentationStyle: .formSheet)
            self.present(themeableNavigationController, animated: true)
        }
        
        let hideThisCardHandler: ((UIAlertAction) -> Void) = { (_) in
            group.undoType = .contentGroup
            self.wantsDeleteInsertOnNextItemUpdate = true
            self.save()
        }
        
        let hideAllHandler: ((UIAlertAction) -> Void) = { (_) in
            let feedContentController = self.dataStore.feedContentController
            // If there's only one group left it means that we're about to show an alert about turning off the Explore tab. In those cases, we don't want to provide the option to undo.
            if feedContentController.countOfVisibleContentGroupKinds > 1 {
                group.undoType = .contentGroupKind
                self.wantsDeleteInsertOnNextItemUpdate = true
            }
            feedContentController.toggleContentGroup(of: group.contentGroupKind, isOn: false, waitForCallbackFromCoordinator: true, apply: true, updateFeed: false)
        }
        
        let hideThisCard = UIAlertAction(title: WMFLocalizedString("explore-feed-preferences-hide-card-action-title", value: "Hide this card", comment: "Title for action that allows users to hide a feed card"), style: .default, handler: hideThisCardHidesAll ? hideAllHandler : hideThisCardHandler)
        
        guard let title = group.headerTitle else {
            assertionFailure("Expected header title for group \(group.contentGroupKind)")
            return nil
        }
        
        let hideAllCards = UIAlertAction(title: String.localizedStringWithFormat(WMFLocalizedString("explore-feed-preferences-hide-feed-cards-action-title", value: "Hide all “%@” cards", comment: "Title for action that allows users to hide all feed cards of given type - %@ is replaced with feed card type"), title), style: .default, handler: hideAllHandler)
        
        let cancel = UIAlertAction(title: CommonStrings.cancelActionTitle, style: .cancel)
        sheet.addAction(hideThisCard)
        if group.contentGroupKind != WMFContentGroupKind.notification && (!hideThisCardHidesAll) {
            sheet.addAction(hideAllCards)
        }
        sheet.addAction(customizeExploreFeed)
        sheet.addAction(cancel)

        return sheet
    }

    func exploreCardCollectionViewCellWantsToUndoCustomization(_ cell: ExploreCardCollectionViewCell) {
        guard let vc = cell.cardContent as? ExploreCardViewController,
            let group = vc.contentGroup else {
                return
        }
        if group.undoType == .contentGroupKind {
            dataStore.feedContentController.toggleContentGroup(of: group.contentGroupKind, isOn: true, waitForCallbackFromCoordinator: false, apply: true, updateFeed: false)
        }
        group.undoType = .none
        wantsDeleteInsertOnNextItemUpdate = true
        if let indexPath = fetchedResultsController?.indexPath(forObject: group) {
            indexPathsForCollapsedCellsThatCanReappear.remove(indexPath)
        }
        save()
    }
    
}

// MARK: - Notifications Center
extension ExploreViewController {

    @objc func userDidTapNotificationsCenter() {
        notificationsCenterPresentationDelegate?.userDidTapNotificationsCenter(from: self)
    }

    @objc func pushNotificationBannerDidDisplayInForeground(_ notification: Notification) {
        dataStore.remoteNotificationsController.loadNotifications(force: true)
    }
    
    @objc func applicationDidBecomeActive() {
        presentModalsIfNeeded()
    }
    
    @objc func coreDataStoreSetup() {
        configureNavigationBar()
    }
}

extension ExploreViewController: WMFImageRecommendationsDelegate {

    func imageRecommendationsUserDidTapImage(project: WMFProject, data: WMFImageRecommendationsViewModel.WMFImageRecommendationData, presentingVC: UIViewController) {

        guard let siteURL = project.siteURL,
              let articleURL = siteURL.wmf_URL(withTitle: data.pageTitle) else {
            return
        }

        let item = MediaListItem(title: "File:\(data.filename)", sectionID: 0, type: .image, showInGallery: true, isLeadImage: false, sources: nil)
        let mediaList = MediaList(items: [item])

        let gallery = MediaListGalleryViewController(articleURL: articleURL, mediaList: mediaList, dataStore: dataStore, initialItem: item, theme: theme, dismissDelegate: nil)
        presentingVC.present(gallery, animated: true)
    }

    func imageRecommendationsUserDidTapViewArticle(project: WMFData.WMFProject, title: String) {
        
        guard let navigationController,
              let siteURL = project.siteURL,
              let articleURL = siteURL.wmf_URL(withTitle: title) else {
            return
        }
        
        let coordinator = ArticleCoordinator(navigationController: navigationController, articleURL: articleURL, dataStore: dataStore, theme: theme, source: .undefined)
        coordinator.start()
    }
    
    func imageRecommendationsUserDidTapImageLink(commonsURL: URL) {
        navigate(to: commonsURL, useSafari: false)
        ImageRecommendationsFunnel.shared.logCommonsWebViewDidAppear()
    }

    func imageRecommendationsUserDidTapInsertImage(viewModel: WMFImageRecommendationsViewModel, title: String, with imageData: WMFImageRecommendationsViewModel.WMFImageRecommendationData) {

        guard let image = imageData.uiImage,
        let siteURL = viewModel.project.siteURL else {
            return
        }
        
        if let imageURL = URL(string: imageData.descriptionURL),
           let thumbURL = URL(string: imageData.thumbUrl) {

            let fileName = imageData.filename.normalizedPageTitle ?? imageData.filename
            let imageDescription = imageData.description?.removingHTML
            let searchResult = InsertMediaSearchResult(fileTitle: "File:\(imageData.filename)", displayTitle: fileName, thumbnailURL: thumbURL, imageDescription: imageDescription,  filePageURL: imageURL)
            
            let insertMediaViewController = InsertMediaSettingsViewController(image: image, searchResult: searchResult, fromImageRecommendations: true, delegate: self, imageRecLoggingDelegate: self, theme: theme, siteURL: siteURL)
            self.imageRecommendationsViewModel = viewModel
            navigationController?.pushViewController(insertMediaViewController, animated: true)
        }
    }
    
    func imageRecommendationsDidTriggerError(_ error: any Error) {
        WMFAlertManager.sharedInstance.showErrorAlert(error, sticky: false, dismissPreviousAlerts: true)
    }

    func imageRecommendationsDidTriggerTimeWarning() {
        let warningmessage = WMFLocalizedString("image-recs-time-warning-message", value: "Please review the article to understand its topic and inspect the image", comment: "Message displayed in a warning when a user taps yes to an image recommendation within 5 seconds or less")
        WMFAlertManager.sharedInstance.showBottomAlertWithMessage(warningmessage, subtitle: nil, image: nil, type: .normal, customTypeName: nil, dismissPreviousAlerts: true)
    }
}

extension ExploreViewController: InsertMediaSettingsViewControllerDelegate {
    func insertMediaSettingsViewControllerDidTapProgress(imageWikitext: String, caption: String?, altText: String?, localizedFileTitle: String) {
        
        guard let viewModel = imageRecommendationsViewModel,
        let currentRecommendation = viewModel.currentRecommendation,
                    let siteURL = viewModel.project.siteURL,
              let articleURL = siteURL.wmf_URL(withTitle: currentRecommendation.title),
        let articleWikitext = currentRecommendation.imageData.wikitext else {
            return
        }
        
        currentRecommendation.caption = caption
        currentRecommendation.altText = altText
        currentRecommendation.imageWikitext = imageWikitext
        currentRecommendation.localizedFileTitle = localizedFileTitle
        
        do {
            let wikitextWithImage = try WMFWikitextUtils.insertImageWikitextIntoArticleWikitextAfterTemplates(imageWikitext: imageWikitext, into: articleWikitext)
            
            currentRecommendation.fullArticleWikitextWithImage = wikitextWithImage
            
            let editPreviewViewController = EditPreviewViewController(pageURL: articleURL)
            editPreviewViewController.theme = theme
            editPreviewViewController.sectionID = 0
            editPreviewViewController.languageCode = articleURL.wmf_languageCode
            editPreviewViewController.wikitext = wikitextWithImage
            editPreviewViewController.delegate = self
            editPreviewViewController.loggingDelegate = self

            navigationController?.pushViewController(editPreviewViewController, animated: true)
        } catch {
            showGenericError()
        }
    }
}

extension ExploreViewController: EditPreviewViewControllerDelegate {
    func editPreviewViewControllerDidTapNext(pageURL: URL, sectionID: Int?, editPreviewViewController: EditPreviewViewController) {
        guard let saveVC = EditSaveViewController.wmf_initialViewControllerFromClassStoryboard() else {
            return
        }

        saveVC.dataStore = dataStore
        saveVC.pageURL = pageURL
        saveVC.sectionID = sectionID
        saveVC.languageCode = pageURL.wmf_languageCode
        saveVC.wikitext = editPreviewViewController.wikitext
        saveVC.cannedSummaryTypes = [.addedImage, .addedImageAndCaption]
        saveVC.needsSuppressPosting = WMFDeveloperSettingsDataController.shared.doNotPostImageRecommendationsEdit
        saveVC.editTags = [.appSuggestedEdit, .appImageAddTop]

        saveVC.delegate = self
        saveVC.imageRecLoggingDelegate = self
        saveVC.theme = self.theme
        
        navigationController?.pushViewController(saveVC, animated: true)
    }

    func imageRecommendationsUserDidTapLearnMore(url: URL?) {
        navigate(to: url, useSafari: false)
    }

    func imageRecommendationsUserDidTapReportIssue() {
        let emailAddress = "ios-support@wikimedia.org"
        let emailSubject = WMFLocalizedString("image-recommendations-email-title", value: "Issue Report - Add an Image Feature", comment: "Title text for Image recommendations pre-filled issue report email")
        let emailBodyLine1 = WMFLocalizedString("image-recommendations-email-first-line", value: "I’ve encountered a problem with the Add an Image Suggested Edits Feature:", comment: "Text for Image recommendations pre-filled issue report email")
        let emailBodyLine2 = WMFLocalizedString("image-recommendations-email-second-line", value: "- [Describe specific problem]", comment: "Text for Image recommendations pre-filled issue report email. This text is intended to be replaced by the user with a description of the problem they are encountering")
        let emailBodyLine3 = WMFLocalizedString("image-recommendations-email-third-line", value: "The behavior I would like to see is:", comment: "Text for Image recommendations pre-filled issue report email")
        let emailBodyLine4 = WMFLocalizedString("image-recommendations-email-fourth-line", value: "- [Describe proposed solution]", comment: "Text for Image recommendations pre-filled issue report email. This text is intended to be replaced by the user with a description of a user suggested solution")
        let emailBodyLine5 = WMFLocalizedString("image-recommendations-email-fifth-line", value: "[Screenshots or Links]", comment: "Text for Image recommendations pre-filled issue report email. This text is intended to be replaced by the user with a screenshot or link.")
        let emailBody = "\(emailBodyLine1)\n\n\(emailBodyLine2)\n\n\(emailBodyLine3)\n\n\(emailBodyLine4)\n\n\(emailBodyLine5)"
        let mailto = "mailto:\(emailAddress)?subject=\(emailSubject)&body=\(emailBody)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)

        guard let encodedMailto = mailto, let mailtoURL = URL(string: encodedMailto), UIApplication.shared.canOpenURL(mailtoURL) else {
            WMFAlertManager.sharedInstance.showErrorAlertWithMessage(CommonStrings.noEmailClient, sticky: false, dismissPreviousAlerts: false)
            return
        }
        UIApplication.shared.open(mailtoURL)
    }

}

extension ExploreViewController: EditSaveViewControllerDelegate {
    
    func editSaveViewControllerDidSave(_ editSaveViewController: EditSaveViewController, result: Result<EditorChanges, any Error>, needsNewTempAccountToast: Bool? = false) {
        
        switch result {
        case .success(let changes):
            sendFeedbackAndPopToImageRecommendations(revID: changes.newRevisionID)
        case .failure(let error):
            showError(error)
        }
        
    }
    
    private func sendFeedbackAndPopToImageRecommendations(revID: UInt64) {

        guard let viewControllers = navigationController?.viewControllers,
        let imageRecommendationsViewModel,
        let currentRecommendation = imageRecommendationsViewModel.currentRecommendation else {
            return
        }
        
        for viewController in viewControllers {
            if viewController is WMFImageRecommendationsViewController {
                navigationController?.popToViewController(viewController, animated: true)
                
                // Send Feedback
                imageRecommendationsViewModel.sendFeedback(editRevId: revID, accepted: true, caption: currentRecommendation.caption) { result in
                }
                
                currentRecommendation.lastRevisionID = revID
                
                // Go to next recommendation and display success alert
                imageRecommendationsViewModel.next {
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {

                        let title = CommonStrings.editPublishedToastTitle
                        let image = UIImage(systemName: "checkmark.circle.fill")
                        
                        if UIAccessibility.isVoiceOverRunning {
                            UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: title)
                        } else {
                            WMFAlertManager.sharedInstance.showBottomAlertWithMessage(title, subtitle: nil, image: image, type: .custom, customTypeName: "edit-published", dismissPreviousAlerts: true)
                        }
                    }
                    
                }
                
                break
            }
        }
    }

    
    func editSaveViewControllerWillCancel(_ saveData: EditSaveViewController.SaveData) {
        // no-op
    }
    
    func editSaveViewControllerDidTapShowWebPreview() {
        assertionFailure("This should not be called in the Image Recommendations context")
    }
}

extension ExploreViewController: WMFFeatureAnnouncing {
    
}

extension ExploreViewController: WMFImageRecommendationsLoggingDelegate {

    func logOnboardingDidTapPrimaryButton() {
        ImageRecommendationsFunnel.shared.logOnboardingDidTapContinue()
    }
    
    func logOnboardingDidTapSecondaryButton() {
        ImageRecommendationsFunnel.shared.logOnboardingDidTapLearnMore()
    }
    
    func logTooltipsDidTapFirstNext() {
        ImageRecommendationsFunnel.shared.logTooltipDidTapFirstNext()
    }
    
    func logTooltipsDidTapSecondNext() {
        ImageRecommendationsFunnel.shared.logTooltipDidTapSecondNext()
    }
    
    func logTooltipsDidTapThirdOK() {
        ImageRecommendationsFunnel.shared.logTooltipDidTapThirdOk()
    }
    
    func logBottomSheetDidAppear() {
        ImageRecommendationsFunnel.shared.logBottomSheetDidAppear()
    }

    func logDialogWarningMessageDidDisplay(fileName: String, recommendationSource: String) {
        ImageRecommendationsFunnel.shared.logDialogWarningMessageDidDisplay(fileName: fileName, recommendationSource: recommendationSource)
    }

    func logBottomSheetDidTapYes() {
        
        if let viewModel = imageRecommendationsViewModel,
              let currentRecommendation = viewModel.currentRecommendation,
           let siteURL = viewModel.project.siteURL,
           let pageURL = siteURL.wmf_URL(withTitle: currentRecommendation.title) {
            currentRecommendation.suggestionAcceptDate = Date()
            EditAttemptFunnel.shared.logInit(pageURL: pageURL)
        }
        
        ImageRecommendationsFunnel.shared.logBottomSheetDidTapYes()
    }
    
    func logBottomSheetDidTapNo() {
        ImageRecommendationsFunnel.shared.logBottomSheetDidTapNo()
    }
    
    func logBottomSheetDidTapNotSure() {
        ImageRecommendationsFunnel.shared.logBottomSheetDidTapNotSure()
    }
    
    func logOverflowDidTapLearnMore() {
        ImageRecommendationsFunnel.shared.logOverflowDidTapLearnMore()
    }
    
    func logOverflowDidTapTutorial() {
        ImageRecommendationsFunnel.shared.logOverflowDidTapTutorial()
    }
    
    func logOverflowDidTapProblem() {
        ImageRecommendationsFunnel.shared.logOverflowDidTapProblem()
    }
    
    func logBottomSheetDidTapFileName() {
        ImageRecommendationsFunnel.shared.logBottomSheetDidTapFileName()
    }
    
    func logRejectSurveyDidAppear() {
        ImageRecommendationsFunnel.shared.logRejectSurveyDidAppear()
    }
    
    func logRejectSurveyDidTapCancel() {
        ImageRecommendationsFunnel.shared.logRejectSurveyDidTapCancel()
    }
    
    func logRejectSurveyDidTapSubmit(rejectionReasons: [String], otherReason: String?, fileName: String, recommendationSource: String) {
        
        ImageRecommendationsFunnel.shared.logRejectSurveyDidTapSubmit(rejectionReasons: rejectionReasons, otherReason: otherReason, fileName: fileName, recommendationSource: recommendationSource)
    }
    
    func logEmptyStateDidAppear() {
        ImageRecommendationsFunnel.shared.logEmptyStateDidAppear()
    }
    
    func logEmptyStateDidTapBack() {
        ImageRecommendationsFunnel.shared.logEmptyStateDidTapBack()
    }
}

extension ExploreViewController: InsertMediaSettingsViewControllerLoggingDelegate {
    func logInsertMediaSettingsViewControllerDidAppear() {
        ImageRecommendationsFunnel.shared.logAddImageDetailsDidAppear()
    }
    
    func logInsertMediaSettingsViewControllerDidTapFileName() {
        ImageRecommendationsFunnel.shared.logAddImageDetailsDidTapFileName()
    }
    
    func logInsertMediaSettingsViewControllerDidTapCaptionLearnMore() {
        ImageRecommendationsFunnel.shared.logAddImageDetailsDidTapCaptionLearnMore()
    }
    
    func logInsertMediaSettingsViewControllerDidTapAltTextLearnMore() {
        ImageRecommendationsFunnel.shared.logAddImageDetailsDidTapAltTextLearnMore()
    }
    
    func logInsertMediaSettingsViewControllerDidTapAdvancedSettings() {
        ImageRecommendationsFunnel.shared.logAddImageDetailsDidTapAdvancedSettings()
    }
}

extension ExploreViewController: EditPreviewViewControllerLoggingDelegate {
    func logEditPreviewDidAppear() {
        ImageRecommendationsFunnel.shared.logPreviewDidAppear()
    }
    
    func logEditPreviewDidTapBack() {
        ImageRecommendationsFunnel.shared.logPreviewDidTapBack()
    }
    
    func logEditPreviewDidTapNext() {
        
        if let viewModel = imageRecommendationsViewModel,
              let currentRecommendation = viewModel.currentRecommendation,
           let siteURL = viewModel.project.siteURL,
           let pageURL = siteURL.wmf_URL(withTitle: currentRecommendation.title) {
            EditAttemptFunnel.shared.logSaveIntent(pageURL: pageURL)
        }
        
        ImageRecommendationsFunnel.shared.logPreviewDidTapNext()
    }
}

extension ExploreViewController: EditSaveViewControllerImageRecLoggingDelegate {
    
    func logEditSaveViewControllerDidAppear() {
        ImageRecommendationsFunnel.shared.logSaveChangesDidAppear()
    }
    
    func logEditSaveViewControllerDidTapBack() {
        ImageRecommendationsFunnel.shared.logSaveChangesDidTapBack()
    }
    
    func logEditSaveViewControllerDidTapMinorEditsLearnMore() {
        ImageRecommendationsFunnel.shared.logSaveChangesDidTapMinorEditsLearnMore()
    }
    
    func logEditSaveViewControllerDidTapWatchlistLearnMore() {
        ImageRecommendationsFunnel.shared.logSaveChangesDidTapWatchlistLearnMore()
    }
    
    func logEditSaveViewControllerDidToggleWatchlist(isOn: Bool) {
        ImageRecommendationsFunnel.shared.logSaveChangesDidToggleWatchlist(isOn: isOn)
    }
    
    func logEditSaveViewControllerDidTapPublish(minorEditEnabled: Bool, watchlistEnabled: Bool) {
        ImageRecommendationsFunnel.shared.logSaveChangesDidTapPublish(minorEditEnabled: minorEditEnabled, watchlistEnabled: watchlistEnabled)
    }
    
    func logEditSaveViewControllerPublishSuccess(revisionID: Int, summaryAdded: Bool) {
        
        guard let viewModel = imageRecommendationsViewModel,
              let currentRecommendation = viewModel.currentRecommendation else {
            return
        }
        
        var timeSpent: Int? = nil
        if let suggestionAcceptDate = currentRecommendation.suggestionAcceptDate {
            timeSpent = Int(Date().timeIntervalSince(suggestionAcceptDate))
        }
        
        ImageRecommendationsFunnel.shared.logSaveChangesPublishSuccess(timeSpent: timeSpent, revisionID: revisionID, captionAdded: currentRecommendation.caption != nil, altTextAdded: currentRecommendation.altText != nil, summaryAdded: summaryAdded)
    }
    
    func logEditSaveViewControllerLogPublishFailed(abortSource: String?) {
        ImageRecommendationsFunnel.shared.logSaveChangesPublishFail(abortSource: abortSource)
    }
    
}

extension ExploreViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let text = searchController.searchBar.text else {
            return
        }
        
        guard let searchViewController = navigationItem.searchController?.searchResultsController as? SearchViewController else {
            return
        }
        
        if text.isEmpty {
            searchViewController.searchTerm = nil
            searchViewController.updateRecentlySearchedVisibility(searchText: nil)
        } else {
            searchViewController.searchTerm = text
            searchViewController.updateRecentlySearchedVisibility(searchText: text)
            searchViewController.search()
        }
    }
}

extension ExploreViewController: LogoutCoordinatorDelegate {
    func didTapLogout() {
        wmf_showKeepSavedArticlesOnDevicePanelIfNeeded(triggeredBy: .logout, theme: theme) {
            self.dataStore.authenticationManager.logout(initiatedBy: .user)
        }
    }
}


extension ExploreViewController: YearInReviewBadgeDelegate {
    func updateYIRBadgeVisibility() {
        updateProfileButton()
    }
}

extension ExploreViewController: UISearchControllerDelegate {
    
    func willPresentSearchController(_ searchController: UISearchController) {
        presentingSearchResults = true
        navigationController?.hidesBarsOnSwipe = false
    }
    
    func didDismissSearchController(_ searchController: UISearchController) {
        presentingSearchResults = false
        navigationController?.hidesBarsOnSwipe = true
        SearchFunnel.shared.logSearchCancel(source: "top_of_feed")
    }
}

// MARK: - Explore Survey

private extension ExploreViewController {
    private var shouldShowExploreSurvey: Bool {
        
        guard checkForSurveyUponAppear else {
            return false
        }
        
        defer {
            checkForSurveyUponAppear = false
        }
        
        guard presentedViewController == nil else {
            return false
        }
        
        guard let languageCode = Locale.current.language.languageCode?.identifier.lowercased(),
              languageCode == "en" else {
            return false
        }
        
        let startDate: Date? = {
            var components = DateComponents()
            components.year = 2025
            components.month = 11
            components.day = 24
            components.hour = 01
            components.minute = 01
            components.second = 01
            return Calendar.current.date(from: components)
        }()
        
        let endDate: Date? = {
            var components = DateComponents()
            components.year = 2025
            components.month = 11
            components.day = 30
            components.hour = 23
            components.minute = 59
            components.second = 59
            return Calendar.current.date(from: components)
        }()
        
        guard let startDate,
              let endDate else {
            return false
        }
        
        let currentDate = Date()
        guard currentDate >= startDate,
              currentDate <= endDate else {
            return false
        }
        
        let dataController = WMFExploreDataController()
        
        guard !dataController.hasSeenExploreSurvey else {
            return false
        }
        
        return true
              
    }

    private func presentExploreSurveyIfNeeded() {
        
        let localizableStrings = WMFToastViewExploreSurveyViewModel.LocalizableStrings(
            title: WMFLocalizedString("explore-survey-title", value: "Help us improve Explore", comment: "Title of one-time survey prompt displayed to users on the Explore feed."),
            subtitle: WMFLocalizedString("explore-survey-subtitle", value: "Please take a short survey about the Explore feed. Your feedback will help shape upcoming app improvements.", comment: "Subtitle of one-time survey prompt displayed to users on the Explore feed."),
            noThanksButtonTitle: CommonStrings.noThanksTitle,
            takeSurveyButtonTitle: CommonStrings.takeSurveyTitle(languageCode: nil))
        
        let noThanksAction: () -> Void = {
            WMFToastPresenter.shared.dismissCurrentToast()
        }
        
        let takeSurveyAction: () -> Void = { [weak self] in
            debugPrint("tapped take survey")
            guard let url = URL(string: "https://wikimedia.qualtrics.com/jfe/form/SV_4V0kURVL6q5Da6y") else {
                return
            }
            
            self?.navigate(to: url, useSafari: true)
            WMFToastPresenter.shared.dismissCurrentToast()
        }
        
        let viewModel = WMFToastViewExploreSurveyViewModel(localizableStrings: localizableStrings, noThanksAction: noThanksAction, takeSurveyAction: takeSurveyAction)
        let view = WMFToastViewExploreSurveyView(viewModel: viewModel)
        
        WMFToastPresenter.shared.presentToastView(
            view: view,
            allowsBackgroundTapToDismiss: false
        )
        
        let dataController = WMFExploreDataController()
        dataController.hasSeenExploreSurvey = true
    }
}
