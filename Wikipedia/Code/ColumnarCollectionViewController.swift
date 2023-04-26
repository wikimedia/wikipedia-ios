import UIKit
import WMF

class ColumnarCollectionViewController: ViewController, ColumnarCollectionViewLayoutDelegate, UICollectionViewDataSourcePrefetching, CollectionViewFooterDelegate, HintPresenting {
    
    enum HeaderStyle {
        case sections
        case exploreFeedDetail
    }
    
    open var headerStyle: HeaderStyle {
        return .exploreFeedDetail
    }
    
    lazy var layout: ColumnarCollectionViewLayout = {
        return ColumnarCollectionViewLayout()
    }()
    
    lazy var layoutCache: ColumnarCollectionViewControllerLayoutCache = {
        return ColumnarCollectionViewControllerLayoutCache()
    }()
    
    @objc lazy var collectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.delegate = self
        cv.dataSource = self
        cv.isPrefetchingEnabled = true
        cv.prefetchDataSource = self
        cv.preservesSuperviewLayoutMargins = true
        scrollView = cv
        return cv
    }()

    lazy var layoutManager: ColumnarCollectionViewLayoutManager = {
        return ColumnarCollectionViewLayoutManager(view: view, collectionView: collectionView)
    }()
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.wmf_addSubviewWithConstraintsToEdges(collectionView)
        layoutManager.register(CollectionViewHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: CollectionViewHeader.identifier, addPlaceholder: true)
        layoutManager.register(CollectionViewFooter.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: CollectionViewFooter.identifier, addPlaceholder: true)
        collectionView.alwaysBounceVertical = true
        extendedLayoutIncludesOpaqueBars = true
    }

    @objc open func contentSizeCategoryDidChange(_ notification: Notification?) {
        collectionView.reloadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if isFirstAppearance {
            isFirstAppearance = false
            viewWillHaveFirstAppearance(animated)
            updateEmptyState()
            isEmptyDidChange() // perform initial update even though the value might not have changed
        } else {
            updateEmptyState()
        }
        if let selectedIndexPaths = collectionView.indexPathsForSelectedItems {
            for selectedIndexPath in selectedIndexPaths {
                collectionView.deselectItem(at: selectedIndexPath, animated: animated)
            }
        }
        for cell in collectionView.visibleCells {
            guard let cellWithSubItems = cell as? SubCellProtocol else {
                continue
            }
            cellWithSubItems.deselectSelectedSubItems(animated: animated)
        }
    }
    
    open func viewWillHaveFirstAppearance(_ animated: Bool) {
        // subclassers can override
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            contentSizeCategoryDidChange(nil)
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { (context) in
            let boundsChange = self.collectionView.bounds
            guard self.layout.shouldInvalidateLayout(forBoundsChange: boundsChange) else {
                return
            }
            let invalidationContext = self.layout.invalidationContext(forBoundsChange: boundsChange)
            self.layout.invalidateLayout(with: invalidationContext)
        })
    }

    // MARK: HintPresenting

    var hintController: HintController?
    
    // MARK: - UIScrollViewDelegate
    
    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        super.scrollViewWillBeginDragging(scrollView)
        hintController?.dismissHintDueToUserInteraction()
    }
    
    // MARK: - Refresh Control
    
    final var isRefreshControlEnabled: Bool = false {
        didSet {
            if isRefreshControlEnabled {
                let refreshControl = UIRefreshControl()
                refreshControl.tintColor = theme.colors.refreshControlTint
                refreshControl.layer.zPosition = -100
                refreshControl.addTarget(self, action: #selector(refreshControlActivated), for: .valueChanged)
                collectionView.refreshControl = refreshControl
            } else {
                collectionView.refreshControl = nil
            }
        }
    }
    
    var refreshStart: Date = Date()
    @objc func refreshControlActivated() {
        refreshStart = Date()
        self.refresh()
    }
    
    open func refresh() {
        assert(false, "default implementation shouldn't be called")
        self.endRefreshing()
    }
    
    open func endRefreshing() {
        let now = Date()
        let timeInterval = 0.5 - now.timeIntervalSince(refreshStart)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + timeInterval, execute: {
            self.collectionView.refreshControl?.endRefreshing()
        })
    }
    
    // MARK: - Empty State
    
    var emptyViewType: WMFEmptyViewType = .none
    
    final var isEmpty = true
    final var showingEmptyViewType: WMFEmptyViewType?
    final func updateEmptyState() {
        let sectionCount = numberOfSections(in: collectionView)
        
        var isCurrentlyEmpty = true
        for sectionIndex in 0..<sectionCount {
            if self.collectionView(collectionView, numberOfItemsInSection: sectionIndex) > 0 {
                isCurrentlyEmpty = false
                break
            }
        }
        
        guard isCurrentlyEmpty != isEmpty || showingEmptyViewType != emptyViewType else {
            return
        }
        
        isEmpty = isCurrentlyEmpty
        
        isEmptyDidChange()
    }
    
    private var emptyViewFrame: CGRect {
        let insets = scrollView?.contentInset ?? UIEdgeInsets.zero
        let frame = view.bounds.inset(by: insets)
        return frame
    }

    open weak var emptyViewTarget: AnyObject?
    open var emptyViewAction: Selector?
    
    open func isEmptyDidChange() {
        if isEmpty {
            wmf_showEmptyView(of: emptyViewType, target: emptyViewTarget, action: emptyViewAction, theme: theme, frame: emptyViewFrame)
            showingEmptyViewType = emptyViewType
        } else {
            wmf_hideEmptyView()
            showingEmptyViewType = nil
        }
    }
    
    override func scrollViewInsetsDidChange() {
        super.scrollViewInsetsDidChange()
        wmf_setEmptyViewFrame(emptyViewFrame)
    }
    
    // MARK: - Themeable
    
    override func apply(theme: Theme) {
        super.apply(theme: theme)
        guard viewIfLoaded != nil else {
            return
        }
        view.backgroundColor = theme.colors.baseBackground
        collectionView.backgroundColor = theme.colors.paperBackground
        collectionView.indicatorStyle = theme.scrollIndicatorStyle
        collectionView.reloadData()
        wmf_applyTheme(toEmptyView: theme)
    }
    
    
    // MARK: - UICollectionViewDataSourcePrefetching
    
    private lazy var imageURLsCurrentlyBeingPrefetched: Set<URL> = {
        return []
    }()
    
    open func imageURLsForItemAt(_ indexPath: IndexPath) -> Set<URL>? {
        return nil
    }

    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            guard let imageURLs = imageURLsForItemAt(indexPath) else {
                continue
            }
            let imageURLsToPrefetch = imageURLs.subtracting(imageURLsCurrentlyBeingPrefetched)
            // SINGLETONTODO
            let imageController = MWKDataStore.shared().cacheController.imageCache
            imageURLsCurrentlyBeingPrefetched.formUnion(imageURLsToPrefetch)
            for imageURL in imageURLsToPrefetch {
                imageController.prefetch(withURL: imageURL) {
                    self.imageURLsCurrentlyBeingPrefetched.remove(imageURL)
                }
            }
        }
    }
    
    // MARK: - Header
    
    var headerTitle: String?
    var headerSubtitle: String?
    
    open func configure(header: CollectionViewHeader, forSectionAt sectionIndex: Int, layoutOnly: Bool) {
        header.title = headerTitle
        header.subtitle = headerSubtitle
        header.style = .detail
        header.apply(theme: theme)
    }

    // MARK: - Footer

    var footerButtonTitle: String?

    open func configure(footer: CollectionViewFooter, forSectionAt sectionIndex: Int, layoutOnly: Bool) {
        footer.buttonTitle = footerButtonTitle
        footer.delegate = self
        footer.apply(theme: theme)
    }
    
    // MARK: - ColumnarCollectionViewLayoutDelegate
    
    func collectionView(_ collectionView: UICollectionView, estimatedHeightForHeaderInSection section: Int, forColumnWidth columnWidth: CGFloat) -> ColumnarCollectionViewLayoutHeightEstimate {
        var estimate = ColumnarCollectionViewLayoutHeightEstimate(precalculated: true, height: 0)
        switch headerStyle {
        case .exploreFeedDetail:
            guard section == 0, headerTitle != nil else {
                return estimate
            }
        case .sections:
            guard self.collectionView(collectionView, numberOfItemsInSection: section) > 0 else {
                return estimate
            }
        }
        guard let placeholder = layoutManager.placeholder(forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: CollectionViewHeader.identifier) as? CollectionViewHeader else {
            return estimate
        }
        configure(header: placeholder, forSectionAt: section, layoutOnly: true)
        estimate.height = placeholder.sizeThatFits(CGSize(width: columnWidth, height: UIView.noIntrinsicMetric), apply: false).height
        estimate.precalculated = true
        return estimate
    }
    
    open func collectionView(_ collectionView: UICollectionView, estimatedHeightForFooterInSection section: Int, forColumnWidth columnWidth: CGFloat) -> ColumnarCollectionViewLayoutHeightEstimate {
        var estimate = ColumnarCollectionViewLayoutHeightEstimate(precalculated: true, height: 0)
        guard footerButtonTitle != nil else {
            return estimate
        }
        guard let placeholder = layoutManager.placeholder(forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: CollectionViewFooter.identifier) as? CollectionViewFooter else {
            return estimate
        }
        configure(footer: placeholder, forSectionAt: section, layoutOnly: true)
        estimate.height = placeholder.sizeThatFits(CGSize(width: columnWidth, height: UIView.noIntrinsicMetric), apply: false).height
        estimate.precalculated = true
        return estimate
    }

    func collectionView(_ collectionView: UICollectionView, shouldShowFooterForSection section: Int) -> Bool {
        return section == collectionView.numberOfSections - 1
    }
    
    open func collectionView(_ collectionView: UICollectionView, estimatedHeightForItemAt indexPath: IndexPath, forColumnWidth columnWidth: CGFloat) -> ColumnarCollectionViewLayoutHeightEstimate {
        return ColumnarCollectionViewLayoutHeightEstimate(precalculated: false, height: 0)
    }
    
    func metrics(with size: CGSize, readableWidth: CGFloat, layoutMargins: UIEdgeInsets) -> ColumnarCollectionViewLayoutMetrics {
        return ColumnarCollectionViewLayoutMetrics.tableViewMetrics(with: size, readableWidth: readableWidth, layoutMargins: layoutMargins)
    }

    // MARK: - Event logging utiities

    var percentViewed: Double {
        guard collectionView.contentSize.height > 0 else {
            return 0
        }
        return Double(((collectionView.contentOffset.y + collectionView.bounds.height) / collectionView.contentSize.height) * 100)
    }
    
    var _maxViewed: Double = 0
    var maxViewed: Double {
        return min(max(_maxViewed, percentViewed), 100)
    }

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        super.scrollViewDidScroll(scrollView)
        _maxViewed = max(_maxViewed, percentViewed)
    }

    // MARK: - CollectionViewFooterDelegate

    func collectionViewFooterButtonWasPressed(_ collectionViewFooter: CollectionViewFooter) {

    }
}

// MARK: - UICollectionViewDataSource
extension ColumnarCollectionViewController: UICollectionViewDataSource {
    open func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 0
    }
    
    open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 0
    }
    
    open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(withReuseIdentifier: "", for: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: CollectionViewHeader.identifier, for: indexPath)
            guard let header = view as? CollectionViewHeader else {
                return view
            }
            configure(header: header, forSectionAt: indexPath.section, layoutOnly: false)
            return header
        } else if kind == UICollectionView.elementKindSectionFooter {
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: CollectionViewFooter.identifier, for: indexPath)
            guard let footer = view as? CollectionViewFooter else {
                return view
            }
            configure(footer: footer, forSectionAt: indexPath.section, layoutOnly: false)
            return footer
        }
        return UICollectionReusableView()
    }
}

extension ColumnarCollectionViewController: UICollectionViewDelegate {
    
}

// MARK: - CollectionViewContextMenuShowing
extension ColumnarCollectionViewController {
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard let contextMenuCollectionVC = self as? CollectionViewContextMenuShowing, let vc = contextMenuCollectionVC.previewingViewController(for: indexPath, at: point) else {
            return nil
        }
        let previewProvider: () -> UIViewController? = {
            return vc
        }
        return UIContextMenuConfiguration(identifier: nil, previewProvider: previewProvider) { (suggestedActions) -> UIMenu? in
            guard let previewActions = (vc as? ArticleViewController)?.contextMenuItems else {
                return nil
            }
            return UIMenu(title: "", image: nil, identifier: nil, options: [], children: previewActions)
        }
    }

    func collectionView(_ collectionView: UICollectionView, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {

        guard let previewedViewController = animator.previewViewController else {
            assertionFailure("Should be able to find previewed VC")
            return
        }
        animator.addCompletion { [weak self] in
            previewedViewController.wmf_removePeekableChildViewControllers()
            self?.push(previewedViewController, animated: true)
        }
    }
}
