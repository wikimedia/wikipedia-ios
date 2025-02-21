import WMF
import WMFComponents

class OnThisDayViewController: ColumnarCollectionViewController, WMFNavigationBarConfiguring {
    fileprivate static let cellReuseIdentifier = "OnThisDayCollectionViewCell"
    fileprivate static let headerReuseIdentifier = "OnThisDayViewControllerHeader"
    fileprivate static let blankHeaderReuseIdentifier = "OnThisDayViewControllerBlankHeader"

    let events: [WMFFeedOnThisDayEvent]
    let dataStore: MWKDataStore
    let midnightUTCDate: Date
    var initialEvent: WMFFeedOnThisDayEvent?

    let contentGroupIDURIString: String?

    required public init(events: [WMFFeedOnThisDayEvent], dataStore: MWKDataStore, midnightUTCDate: Date, contentGroup: WMFContentGroup, theme: Theme) {
        self.events = events
        self.dataStore = dataStore
        self.midnightUTCDate = midnightUTCDate
        self.contentGroupIDURIString = contentGroup.objectID.uriRepresentation().absoluteString
        super.init(nibName: nil, bundle: nil)
        self.theme = theme
        title = CommonStrings.onThisDayTitle
        hidesBottomBarWhenPushed = true
    }
    
    override func metrics(with size: CGSize, readableWidth: CGFloat, layoutMargins: UIEdgeInsets) -> ColumnarCollectionViewLayoutMetrics {
        return ColumnarCollectionViewLayoutMetrics.tableViewMetrics(with: size, readableWidth: readableWidth, layoutMargins: layoutMargins)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not supported")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        layoutManager.register(OnThisDayCollectionViewCell.self, forCellWithReuseIdentifier: OnThisDayViewController.cellReuseIdentifier, addPlaceholder: true)
        layoutManager.register(UINib(nibName: OnThisDayViewController.headerReuseIdentifier, bundle: nil), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: OnThisDayViewController.headerReuseIdentifier, addPlaceholder: false)
        layoutManager.register(OnThisDayViewControllerBlankHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: OnThisDayViewController.blankHeaderReuseIdentifier, addPlaceholder: false)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        scrollToInitialEvent()
        configureNavigationBar()
    }
    
    private func configureNavigationBar() {
        let titleConfig = WMFNavigationBarTitleConfig(title: CommonStrings.onThisDayTitle, customView: nil, alignment: .hidden)
        
        configureNavigationBar(titleConfig: titleConfig, closeButtonConfig: nil, profileButtonConfig: nil, searchBarConfig: nil, hideNavigationBarOnScroll: false)
    }
    
    func scrollToInitialEvent() {
        guard let event = initialEvent, let eventIndex = events.firstIndex(of: event), events.indices.contains(eventIndex) else {
            return
        }
        let sectionIndex = eventIndex + 1 // index + 1 because section 0 is the header
        collectionView.scrollToItem(at: IndexPath(item: 0, section: sectionIndex), at: sectionIndex < 1 ? .top : .centeredVertically, animated: false)
    }
    
    override func scrollViewInsetsDidChange() {
        super.scrollViewInsetsDidChange()
        scrollToInitialEvent()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        initialEvent = nil
    }
    
    // MARK: - ColumnarCollectionViewLayoutDelegate
    
    override func collectionView(_ collectionView: UICollectionView, estimatedHeightForHeaderInSection section: Int, forColumnWidth columnWidth: CGFloat) -> ColumnarCollectionViewLayoutHeightEstimate {

        guard section > 0 else {
            return super.collectionView(collectionView, estimatedHeightForHeaderInSection: section, forColumnWidth: columnWidth)
        }
        return ColumnarCollectionViewLayoutHeightEstimate(precalculated: false, height: section == 1 ? 150 : 0)
    }
    
    override func collectionView(_ collectionView: UICollectionView, estimatedHeightForItemAt indexPath: IndexPath, forColumnWidth columnWidth: CGFloat) -> ColumnarCollectionViewLayoutHeightEstimate {
        var estimate = ColumnarCollectionViewLayoutHeightEstimate(precalculated: false, height: 350)
        guard let placeholderCell = layoutManager.placeholder(forCellWithReuseIdentifier: OnThisDayViewController.cellReuseIdentifier) as? OnThisDayCollectionViewCell else {
            return estimate
        }
        guard let event = event(for: indexPath.section) else {
            return estimate
        }
        placeholderCell.layoutMargins = layout.itemLayoutMargins
        placeholderCell.configure(with: event, dataStore: dataStore, theme: theme, layoutOnly: true, shouldAnimateDots: false)
        estimate.height = placeholderCell.sizeThatFits(CGSize(width: columnWidth, height: UIView.noIntrinsicMetric), apply: false).height
        estimate.precalculated = true
        return estimate
    }

    // For ContextMenu delegate work, in extension below
    var previewedIndex: Int?

    // MARK: - CollectionViewFooterDelegate

    override func collectionViewFooterButtonWasPressed(_ collectionViewFooter: CollectionViewFooter) {
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: ArticlePreviewingDelegate
    
    override func shareArticlePreviewActionSelected(with articleController: ArticleViewController, shareActivityController: UIActivityViewController) {
        super.shareArticlePreviewActionSelected(with: articleController, shareActivityController: shareActivityController)
        previewedIndex = nil
    }

    override func readMoreArticlePreviewActionSelected(with articleController: ArticleViewController) {
        articleController.wmf_removePeekableChildViewControllers()
        push(articleController, animated: true)
    }
}

class OnThisDayViewControllerBlankHeader: UICollectionReusableView {

}

// MARK: - UICollectionViewDataSource/Delegate
extension OnThisDayViewController {
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return events.count + 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return section > 0 ? 1 : 0
    }
    
    func event(for section: Int) -> WMFFeedOnThisDayEvent? {
        guard section > 0 else {
            return nil
        }
        return events[section - 1]
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: OnThisDayViewController.cellReuseIdentifier, for: indexPath)
        guard let onThisDayCell = cell as? OnThisDayCollectionViewCell else {
            return cell
        }
        guard let event = event(for: indexPath.section) else {
            return cell
        }
        onThisDayCell.layoutMargins = layout.itemLayoutMargins
        onThisDayCell.configure(with: event, dataStore: dataStore, theme: self.theme, layoutOnly: false, shouldAnimateDots: true)
        onThisDayCell.timelineView.extendTimelineAboveDot = indexPath.section == 0 ? false : true
        onThisDayCell.contextMenuShowingDelegate = self

        return onThisDayCell
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {

        guard indexPath.section > 0, kind == UICollectionView.elementKindSectionHeader else {
            return super.collectionView(collectionView, viewForSupplementaryElementOfKind: kind, at: indexPath)
        }

        guard indexPath.section == 1, kind == UICollectionView.elementKindSectionHeader else {
            return collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: OnThisDayViewController.blankHeaderReuseIdentifier, for: indexPath)
        }

        if  let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: OnThisDayViewController.headerReuseIdentifier, for: indexPath) as? OnThisDayViewControllerHeader {
                    header.configureFor(eventCount: events.count, firstEvent: events.first, lastEvent: events.last, midnightUTCDate: midnightUTCDate)
                    header.apply(theme: theme)
                    return header
                } else {
                    return collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: OnThisDayViewController.blankHeaderReuseIdentifier, for: indexPath)
                }
    }
    
    @objc func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? OnThisDayCollectionViewCell else {
            return
        }
        cell.selectionDelegate = self
        cell.pauseDotsAnimation = false
    }
    
    @objc func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? OnThisDayCollectionViewCell else {
            return
        }
        cell.selectionDelegate = nil
        cell.pauseDotsAnimation = true
    }
    
    @objc func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath) {
        guard indexPath.section == 0, elementKind == UICollectionView.elementKindSectionHeader else {
            return
        }
    }
    
    @objc func collectionView(_ collectionView: UICollectionView, didEndDisplayingSupplementaryView view: UICollectionReusableView, forElementOfKind elementKind: String, at indexPath: IndexPath) {
        guard indexPath.section == 0, elementKind == UICollectionView.elementKindSectionHeader else {
            return
        }
    }
    
    @objc func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    @objc func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return false
    }
}

// MARK: - SideScrollingCollectionViewCellDelegate
extension OnThisDayViewController: SideScrollingCollectionViewCellDelegate {
    func sideScrollingCollectionViewCell(_ sideScrollingCollectionViewCell: SideScrollingCollectionViewCell, didSelectArticleWithURL articleURL: URL, at indexPath: IndexPath) {
        guard let navigationController else { return }
        
        let articleCoordinator = ArticleCoordinator(navigationController: navigationController, articleURL: articleURL, dataStore: dataStore, theme: theme, source: .undefined)
        articleCoordinator.start()
    }
}

// MARK: - EventLoggingEventValuesProviding
extension OnThisDayViewController: MEPEventsProviding {
    var eventLoggingCategory: EventCategoryMEP {
        return .feed
    }
    
    var eventLoggingLabel: EventLabelMEP? {
        return .onThisDay
    }
}

// MARK: - NestedCollectionViewContextMenuDelegate
extension OnThisDayViewController: NestedCollectionViewContextMenuDelegate {
    func contextMenu(with contentGroup: WMFContentGroup? = nil, for articleURL: URL? = nil, at itemIndex: Int) -> UIContextMenuConfiguration? {

        guard let articleURL = articleURL, let vc = ArticleViewController(articleURL: articleURL, dataStore: dataStore, theme: theme, source: .undefined) else {
            return nil
        }
        vc.articlePreviewingDelegate = self
        vc.wmf_addPeekableChildViewController(for: articleURL, dataStore: dataStore, theme: theme)
        if let themeable = vc as Themeable? {
            themeable.apply(theme: self.theme)
        }

        previewedIndex = itemIndex

        let previewProvider: () -> UIViewController? = {
            return vc
        }
        return UIContextMenuConfiguration(identifier: nil, previewProvider: previewProvider) { (suggestedActions) -> UIMenu? in
            return nil

            // While we'd like to use this next line to give context menu items, the "collection view within a collection view architecture
            // results in an assertion failure in dev mode due to constraints that are automatically added by the preview's action menu, which
            // further results in the horizontally scrollable collection view being broken when coming back to it. I'm not sure that this
            // functionality was present before this re-write, and so leaving it out for now.
//            return UIMenu(title: "", image: nil, identifier: nil, options: [], children: vc.contextMenuItems)
        }
    }

    func willCommitPreview(with animator: UIContextMenuInteractionCommitAnimating) {
        guard let previewedViewController = animator.previewViewController else {
            assertionFailure("Should be able to find previewed VC")
            return
        }
        animator.addCompletion { [weak self] in
            previewedViewController.wmf_removePeekableChildViewControllers()

            guard let self = self else {
                return
            }
            self.push(previewedViewController, animated: true)
            self.previewedIndex = nil
        }
    }
}
