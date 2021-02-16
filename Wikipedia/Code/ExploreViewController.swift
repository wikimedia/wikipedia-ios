import UIKit
import WMF
import CocoaLumberjackSwift

class ExploreViewController: ColumnarCollectionViewController, ExploreCardViewControllerDelegate, UISearchBarDelegate, CollectionViewUpdaterDelegate, ImageScaleTransitionProviding, DetailTransitionSourceProviding, EventLoggingEventValuesProviding {

    public var presentedContentGroupKey: String?
    public var shouldRestoreScrollPosition = false

    // MARK - UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        layoutManager.register(ExploreCardCollectionViewCell.self, forCellWithReuseIdentifier: ExploreCardCollectionViewCell.identifier, addPlaceholder: true)
        
        navigationItem.titleView = titleView
        navigationBar.addUnderNavigationBarView(searchBarContainerView)
        navigationBar.isUnderBarViewHidingEnabled = true
        navigationBar.displayType = .largeTitle
        navigationBar.shouldTransformUnderBarViewWithBar = true
        navigationBar.isShadowHidingEnabled = true

        isRefreshControlEnabled = true
        collectionView.refreshControl?.layer.zPosition = 0
        
        title = CommonStrings.exploreTabTitle

        NotificationCenter.default.addObserver(self, selector: #selector(exploreFeedPreferencesDidSave(_:)), name: NSNotification.Name.WMFExploreFeedPreferencesDidSave, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(articleDidChange(_:)), name: NSNotification.Name.WMFArticleUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(articleDeleted(_:)), name: NSNotification.Name.WMFArticleDeleted, object: nil)
#if UI_TEST
        if UserDefaults.standard.wmf_isFastlaneSnapshotInProgress() {
            collectionView.decelerationRate = .fast
        }
#endif
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
    }
    
    override func viewWillHaveFirstAppearance(_ animated: Bool) {
         super.viewWillHaveFirstAppearance(animated)
        setupFetchedResultsController()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        collectionViewUpdater?.isGranularUpdatingEnabled = true
        restoreScrollPositionIfNeeded()

        /// Terrible hack to make back button text appropriate for iOS 14 - need to set the title on `WMFAppViewController`. For all app tabs, this is set in `viewWillAppear`.
        parent?.navigationItem.backButtonTitle = title
    }

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
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        dataStore.feedContentController.dismissCollapsedContentGroups()
        stopMonitoringReachability()
        collectionViewUpdater?.isGranularUpdatingEnabled = false
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
        longTitleButton.isAccessibilityElement = false
        return longTitleButton
    }()
    
    lazy var titleView: UIView = {
        let titleView = UIView(frame: longTitleButton.bounds)
        titleView.addSubview(longTitleButton)
        titleView.isAccessibilityElement = false
        return titleView
    }()

    // MARK - Refresh
    
    override func refreshControlActivated() {
        super.refreshControlActivated()
    }
    
    open override func refresh() {
        FeedFunnel.shared.logFeedRefreshed()
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
        FeedFunnel.shared.logFeedRefreshed()
        updateFeedSources(with: (nextOldestDate as NSDate).wmf_midnightLocalDateForEquivalentUTC, userInitiated: false) {
            self.isLoadingOlderContent = false
        }
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        logFeedImpressionAfterDelay()
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
            let visibleRectOrigin = CGPoint(x: collectionView.contentOffset.x, y: collectionView.contentOffset.y + navigationBar.visibleHeight)
            let visibleRectSize = view.layoutMarginsGuide.layoutFrame.size
            let itemCenter = CGPoint(x: itemFrame.midX, y: itemFrame.midY)
            let visibleRect = CGRect(origin: visibleRectOrigin, size: visibleRectSize)
            let isUnobstructed = visibleRect.contains(itemCenter)
            guard isUnobstructed else {
                continue
            }
            FeedFunnel.shared.logFeedImpression(for: FeedFunnelContext(group))
        }
    }
    
    // MARK - Search

    public var wantsCustomSearchTransition: Bool {
        return true
    }
    
    lazy var searchBarContainerView: UIView = {
        let searchContainerView = UIView()
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchContainerView.addSubview(searchBar)
        let leading = searchContainerView.layoutMarginsGuide.leadingAnchor.constraint(equalTo: searchBar.leadingAnchor)
        let trailing = searchContainerView.layoutMarginsGuide.trailingAnchor.constraint(equalTo: searchBar.trailingAnchor)
        let top = searchContainerView.topAnchor.constraint(equalTo: searchBar.topAnchor)
        let bottom = searchContainerView.bottomAnchor.constraint(equalTo: searchBar.bottomAnchor)
        searchContainerView.addConstraints([leading, trailing, top, bottom])
        return searchContainerView
    }()

    @available(iOS 14.0, *)
    lazy var scribbleIgnoringDelegate = ScribbleIgnoringInteractionDelegate()

    lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.delegate = self
        searchBar.returnKeyType = .search
        searchBar.searchBarStyle = .minimal
        searchBar.placeholder =  WMFLocalizedString("search-field-placeholder-text", value: "Search Wikipedia", comment: "Search field placeholder text")

        // Disable Scribble on this placeholder text field
        if UIDevice.current.userInterfaceIdiom == .pad, #available(iOS 14.0, *) {
            let existingInteractions = searchBar.searchTextField.interactions
            existingInteractions.forEach { searchBar.searchTextField.removeInteraction($0) }
            let scribbleIgnoringInteraction = UIScribbleInteraction(delegate: scribbleIgnoringDelegate)
            searchBar.searchTextField.addInteraction(scribbleIgnoringInteraction)
        }

        return searchBar
    }()
    
    @objc func ensureWikipediaSearchIsShowing() {
        if self.navigationBar.underBarViewPercentHidden > 0 {
            self.navigationBar.setNavigationBarPercentHidden(0, underBarViewPercentHidden: 0, extendedViewPercentHidden: 0, topSpacingPercentHidden: 1, animated: true)
        }
    }

    // MARK - UISearchBarDelegate
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        let searchActivity = NSUserActivity.wmf_searchView()
        NotificationCenter.default.post(name: .WMFNavigateToActivity, object: searchActivity)
        return false
    }
    
    // MARK - State
    
    @objc var dataStore: MWKDataStore!
    private var fetchedResultsController: NSFetchedResultsController<WMFContentGroup>?
    private var collectionViewUpdater: CollectionViewUpdater<WMFContentGroup>?
    
    private var wantsDeleteInsertOnNextItemUpdate: Bool = false

    private func setupFetchedResultsController() {
        let fetchRequest: NSFetchRequest<WMFContentGroup> = WMFContentGroup.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isVisible == YES && (placement == NULL || placement == %@)", "feed")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "midnightUTCDate", ascending: false), NSSortDescriptor(key: "dailySortPriority", ascending: true), NSSortDescriptor(key: "date", ascending: false)]
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
            #if UI_TEST
            #else
            refreshControl.beginRefreshing()
            #endif
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
    
    // MARK - ImageScaleTransitionProviding
    
    var imageScaleTransitionView: UIImageView?
    
    // MARK - DetailTransitionSourceProviding
    
    var detailTransitionSourceRect: CGRect?
    
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
    
    // MARK - UICollectionViewDelegate
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        guard let group = group(at: indexPath) else {
            return false
        }
        return group.isSelectable
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        var titleAreaTapped = false;
        if let cell = collectionView.cellForItem(at: indexPath) as? ExploreCardCollectionViewCell {
            detailTransitionSourceRect = view.convert(cell.frame, from: collectionView)
            if
                let vc = cell.cardContent as? ExploreCardViewController,
                vc.collectionView.numberOfSections > 0, vc.collectionView.numberOfItems(inSection: 0) > 0,
                let cell = vc.collectionView.cellForItem(at: IndexPath(item: 0, section: 0)) as? ArticleCollectionViewCell
            {
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

        if !useRandomArticlePreviewItem, let vc = group.detailViewControllerWithDataStore(dataStore, theme: theme) {
            push(vc, context: FeedFunnelContext(group), index: indexPath.item, animated: true)
            return
        }
        
        if let vc = group.detailViewControllerForPreviewItemAtIndex(0, dataStore: dataStore, theme: theme) {
            if vc is WMFImageGalleryViewController {
                present(vc, animated: true)
                FeedFunnel.shared.logFeedCardOpened(for: FeedFunnelContext(group))
            } else {
                push(vc, context: FeedFunnelContext(group), index: indexPath.item, animated: true)
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
        searchBar.apply(theme: theme)
        searchBarContainerView.backgroundColor = theme.colors.paperBackground
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
    
    // MARK - ExploreCardViewControllerDelegate
    
    func exploreCardViewController(_ exploreCardViewController: ExploreCardViewController, didSelectItemAtIndexPath indexPath: IndexPath) {
        guard
            let contentGroup = exploreCardViewController.contentGroup,
            let vc = contentGroup.detailViewControllerForPreviewItemAtIndex(indexPath.row, dataStore: dataStore, theme: theme) else {
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
    
        if let otdvc = vc as? OnThisDayViewController {
            otdvc.initialEvent = (contentGroup.contentPreview as? [Any])?[indexPath.item] as? WMFFeedOnThisDayEvent
        }
        
        let context = FeedFunnelContext(contentGroup)
        presentedContentGroupKey = contentGroup.key
        switch contentGroup.detailType {
        case .gallery:
            present(vc, animated: true)
            FeedFunnel.shared.logFeedCardOpened(for: context)
        default:
            push(vc, context: context, index: indexPath.item, animated: true)
        }
    }
    
    // MARK - Prefetching
    
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
    
    // MARK - CollectionViewUpdaterDelegate
    
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

    var eventLoggingCategory: EventLoggingCategory {
        return .feed
    }

    var eventLoggingLabel: EventLoggingLabel? {
        return previewed.context?.label
    }

    // MARK: Peek & Pop

    private var previewed: (context: FeedFunnelContext?, indexPath: IndexPath?)

    override func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard
            let indexPath = collectionViewIndexPathForPreviewingContext(previewingContext, location: location),
            let cell = collectionView.cellForItem(at: indexPath) as? ExploreCardCollectionViewCell,
            let vc = cell.cardContent as? ExploreCardViewController,
            let contentGroup = vc.contentGroup
        else {
            return nil
        }

        previewed.context = FeedFunnelContext(contentGroup)
        
        let convertedLocation = view.convert(location, to: vc.collectionView)
        if let indexPath = vc.collectionView.indexPathForItem(at: convertedLocation), let cell = vc.collectionView.cellForItem(at: indexPath), let viewControllerToCommit = contentGroup.detailViewControllerForPreviewItemAtIndex(indexPath.row, dataStore: dataStore, theme: theme) {
            previewingContext.sourceRect = view.convert(cell.bounds, from: cell)
            if let potd = viewControllerToCommit as? WMFImageGalleryViewController {
                potd.setOverlayViewTopBarHidden(true)
            } else if let avc = viewControllerToCommit as? ArticleViewController {
                avc.articlePreviewingDelegate = self
                avc.wmf_addPeekableChildViewController(for: avc.articleURL, dataStore: dataStore, theme: theme)
            }

            previewed.indexPath = indexPath
            FeedFunnel.shared.logFeedCardPreviewed(for: previewed.context, index: indexPath.item)

            return viewControllerToCommit
        } else if contentGroup.contentGroupKind != .random {
            return contentGroup.detailViewControllerWithDataStore(dataStore, theme: theme)
        } else {
            return nil
        }
    }
    
    open override func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        if let potd = viewControllerToCommit as? WMFImageGalleryViewController {
            potd.setOverlayViewTopBarHidden(false)
            present(potd, animated: false)
            FeedFunnel.shared.logFeedCardOpened(for: previewed.context)
        } else if let avc = viewControllerToCommit as? ArticleViewController {
            avc.wmf_removePeekableChildViewControllers()
            push(avc, context: previewed.context, index: previewed.indexPath?.item, animated: false)
        } else {
            push(viewControllerToCommit, context: previewed.context, index: previewed.indexPath?.item, animated: true)
        }
    }

    // MARK: ArticlePreviewingDelegate
    
    override func shareArticlePreviewActionSelected(with articleController: ArticleViewController, shareActivityController: UIActivityViewController) {
        super.shareArticlePreviewActionSelected(with: articleController, shareActivityController: shareActivityController)
        FeedFunnel.shared.logFeedShareTapped(for: previewed.context, index: previewed.indexPath?.item)
    }

    override func readMoreArticlePreviewActionSelected(with articleController: ArticleViewController) {
        articleController.wmf_removePeekableChildViewControllers()
        push(articleController, context: previewed.context, index: previewed.indexPath?.item, animated: true)
    }

    override func saveArticlePreviewActionSelected(with articleController: ArticleViewController, didSave: Bool, articleURL: URL) {
        if didSave {
            ReadingListsFunnel.shared.logSaveInFeed(context: previewed.context, articleURL: articleURL, index: previewed.indexPath?.item)
        } else {
            ReadingListsFunnel.shared.logUnsaveInFeed(context: previewed.context, articleURL: articleURL, index: previewed.indexPath?.item)
        }
    }

    var addArticlesToReadingListVCDidDisappear: (() -> Void)? = nil
}

// MARK - Analytics
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
        let navigationController = WMFThemeableNavigationController(rootViewController: addArticlesToReadingListViewController, theme: self.theme)
        navigationController.isNavigationBarHidden = true
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

    private func menuActionSheetForGroup(_ group: WMFContentGroup) -> UIAlertController? {
        guard group.contentGroupKind.isCustomizable || group.contentGroupKind.isGlobal else {
            return nil
        }
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let customizeExploreFeed = UIAlertAction(title: CommonStrings.customizeExploreFeedTitle, style: .default) { (_) in
            let exploreFeedSettingsViewController = ExploreFeedSettingsViewController()
            exploreFeedSettingsViewController.showCloseButton = true
            exploreFeedSettingsViewController.dataStore = self.dataStore
            exploreFeedSettingsViewController.apply(theme: self.theme)
            let themeableNavigationController = WMFThemeableNavigationController(rootViewController: exploreFeedSettingsViewController, theme: self.theme)
            themeableNavigationController.modalPresentationStyle = .formSheet
            self.present(themeableNavigationController, animated: true)
        }
        let hideThisCard = UIAlertAction(title: WMFLocalizedString("explore-feed-preferences-hide-card-action-title", value: "Hide this card", comment: "Title for action that allows users to hide a feed card"), style: .default) { (_) in
            FeedFunnel.shared.logFeedCardDismissed(for: FeedFunnelContext(group))
            group.undoType = .contentGroup
            self.wantsDeleteInsertOnNextItemUpdate = true
            self.save()
        }
        guard let title = group.headerTitle else {
            assertionFailure("Expected header title for group \(group.contentGroupKind)")
            return nil
        }
        let hideAllCards = UIAlertAction(title: String.localizedStringWithFormat(WMFLocalizedString("explore-feed-preferences-hide-feed-cards-action-title", value: "Hide all “%@” cards", comment: "Title for action that allows users to hide all feed cards of given type - %@ is replaced with feed card type"), title), style: .default) { (_) in
            let feedContentController = self.dataStore.feedContentController
            // If there's only one group left it means that we're about to show an alert about turning off the Explore tab. In those cases, we don't want to provide the option to undo.
            if feedContentController.countOfVisibleContentGroupKinds > 1 {
                group.undoType = .contentGroupKind
                self.wantsDeleteInsertOnNextItemUpdate = true
            }
            feedContentController.toggleContentGroup(of: group.contentGroupKind, isOn: false, waitForCallbackFromCoordinator: true, apply: true, updateFeed: false)
            FeedFunnel.shared.logFeedCardDismissed(for: FeedFunnelContext(group))
        }
        let cancel = UIAlertAction(title: CommonStrings.cancelActionTitle, style: .cancel)
        sheet.addAction(hideThisCard)
        sheet.addAction(hideAllCards)
        sheet.addAction(customizeExploreFeed)
        sheet.addAction(cancel)

        return sheet
    }

    func exploreCardCollectionViewCellWantsToUndoCustomization(_ cell: ExploreCardCollectionViewCell) {
        guard let vc = cell.cardContent as? ExploreCardViewController,
            let group = vc.contentGroup else {
                return
        }
        FeedFunnel.shared.logFeedCardRetained(for: FeedFunnelContext(group))
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

// MARK: - EventLoggingSearchSourceProviding
extension ExploreViewController: EventLoggingSearchSourceProviding {
    var searchSource: String {
        return "top_of_feed"
    }
}
