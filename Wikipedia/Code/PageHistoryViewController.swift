import UIKit
import WMF

typealias PageHistoryCollectionViewCellSelectionThemeModel = PageHistoryViewController.SelectionThemeModel

enum SelectionOrder: Int, CaseIterable {
    case first
    case second

    init?(_ rawValue: Int?) {
        if let rawValue = rawValue, let SelectionOrder = SelectionOrder(rawValue: rawValue) {
            self = SelectionOrder
        } else {
            return nil
        }
    }
}

@objc(WMFPageHistoryViewController)
class PageHistoryViewController: ColumnarCollectionViewController {
    private let pageTitle: String
    private let pageURL: URL

    private let pageHistoryFetcher = PageHistoryFetcher()
    private var pageHistoryFetcherParams: PageHistoryRequestParameters

    private var batchComplete = false
    private var isLoadingData = false

    private var cellLayoutEstimate: ColumnarCollectionViewLayoutHeightEstimate?
    private var firstRevision: WMFPageHistoryRevision?

    var shouldLoadNewData: Bool {
        if batchComplete || isLoadingData {
            return false
        }
        let maxY = collectionView.contentOffset.y + collectionView.frame.size.height + 200.0;
        if (maxY >= collectionView.contentSize.height) {
            return true
        }
        return false;
    }

    private lazy var countsViewController = PageHistoryCountsViewController(pageTitle: pageTitle, locale: NSLocale.wmf_locale(for: pageURL.wmf_language))
    private lazy var comparisonSelectionViewController: PageHistoryComparisonSelectionViewController = {
        let comparisonSelectionViewController = PageHistoryComparisonSelectionViewController(nibName: "PageHistoryComparisonSelectionViewController", bundle: nil)
        comparisonSelectionViewController.delegate = self
        return comparisonSelectionViewController
    }()

    init(pageTitle: String, pageURL: URL) {
        self.pageTitle = pageTitle
        self.pageURL = pageURL
        self.pageHistoryFetcherParams = PageHistoryRequestParameters(title: pageTitle)
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var pageHistorySections: [PageHistorySection] = []

    override var headerStyle: ColumnarCollectionViewController.HeaderStyle {
        return .sections
    }

    private lazy var compareButton: UIBarButtonItem = {
        let button = UIBarButtonItem(title: CommonStrings.compareTitle, style: .plain, target: self, action: #selector(compare(_:)))
        button.accessibilityHint = WMFLocalizedString("page-history-compare-accessibility-hint", value: "Tap to select two revisions to compare", comment: "Accessibility hint describing the role of the Compare button")
        return button
    }()

    private lazy var cancelComparisonButton = UIBarButtonItem(title: CommonStrings.cancelActionTitle, style: .done, target: self, action: #selector(cancelComparison(_:)))

    private var comparisonSelectionViewHeightConstraint: NSLayoutConstraint?
    private var comparisonSelectionViewVisibleConstraint: NSLayoutConstraint?
    private var comparisonSelectionViewHiddenConstraint: NSLayoutConstraint?

    private enum State {
        case idle
        case editing
    }

    private var maxNumberOfRevisionsSelected: Bool {
        assert((0...SelectionOrder.allCases.count).contains(selectedCellsCount))
        return selectedCellsCount == 2
    }
    private var selectedCellsCount = 0

    private var pageHistoryHintController: PageHistoryHintController? {
        return hintController as? PageHistoryHintController
    }

    private var state: State = .idle {
        didSet {
            switch state {
            case .idle:
                selectedCellsCount = 0
                pageHistoryHintController?.hide(true, presenter: self, subview: comparisonSelectionViewController.view, additionalBottomSpacing: comparisonSelectionViewController.view.frame.height - view.safeAreaInsets.bottom, theme: theme)
                openSelectionIndex = 0
                UIView.performWithoutAnimation {
                    self.navigationItem.rightBarButtonItem = compareButton
                }
                indexPathsSelectedForComparisonGroupedByButtonTags.removeAll(keepingCapacity: true)
                comparisonSelectionViewController.resetSelectionButtons()
            case .editing:
                UIView.performWithoutAnimation {
                    self.navigationItem.rightBarButtonItem = cancelComparisonButton
                }
                collectionView.allowsMultipleSelection = true
                comparisonSelectionViewController.setCompareButtonEnabled(false)
            }
            setComparisonSelectionViewHidden(state == .idle, animated: true)
            layoutCache.reset()
            collectionView.performBatchUpdates({
                self.collectionView.reloadSections(IndexSet(integersIn: 0..<collectionView.numberOfSections))
            })
        }
    }

    private var comparisonSelectionButtonWidthConstraints = [NSLayoutConstraint]()

    private func setupComparisonSelectionViewController() {
        addChild(comparisonSelectionViewController)
        comparisonSelectionViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(comparisonSelectionViewController.view)
        comparisonSelectionViewController.didMove(toParent: self)
        comparisonSelectionViewVisibleConstraint = view.bottomAnchor.constraint(equalTo: comparisonSelectionViewController.view.bottomAnchor)
        comparisonSelectionViewHiddenConstraint = view.bottomAnchor.constraint(equalTo: comparisonSelectionViewController.view.topAnchor)

        let leadingConstraint = view.leadingAnchor.constraint(equalTo: comparisonSelectionViewController.view.leadingAnchor)
        let trailingConstraint = view.trailingAnchor.constraint(equalTo: comparisonSelectionViewController.view.trailingAnchor)

        NSLayoutConstraint.activate([comparisonSelectionViewHiddenConstraint!, leadingConstraint, trailingConstraint])
    }

    private func setComparisonSelectionViewHidden(_ hidden: Bool, animated: Bool) {
        let changes = {
            if hidden {
                self.comparisonSelectionViewVisibleConstraint?.isActive = false
                self.comparisonSelectionViewHiddenConstraint?.isActive = true
            } else {
                self.comparisonSelectionViewHiddenConstraint?.isActive = false
                self.comparisonSelectionViewVisibleConstraint?.isActive = true
            }
            self.view.layoutIfNeeded()
        }
        if animated {
            UIView.animate(withDuration: 0.3, animations: changes)
        } else {
            changes()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        hintController = PageHistoryHintController()
        title = CommonStrings.historyTabTitle
        if #available(iOS 14.0, *) {
            navigationItem.backButtonTitle = WMFLocalizedString("page-history-revision-history-title", value: "Revision history", comment: "Title for revision history view")
            navigationItem.backButtonDisplayMode = .generic
        }
        navigationItem.rightBarButtonItem = compareButton
        addChild(countsViewController)
        navigationBar.addUnderNavigationBarView(countsViewController.view)
        navigationBar.shadowColorKeyPath = \Theme.colors.border
        countsViewController.didMove(toParent: self)

        navigationBar.isBarHidingEnabled = false
        navigationBar.isUnderBarViewHidingEnabled = true

        layoutManager.register(PageHistoryCollectionViewCell.self, forCellWithReuseIdentifier: PageHistoryCollectionViewCell.identifier, addPlaceholder: true)
        collectionView.dataSource = self
        view.wmf_addSubviewWithConstraintsToEdges(collectionView)

        setupComparisonSelectionViewController()

        apply(theme: theme)

        getEditCounts()
        getPageHistory()
    }

    private func getEditCounts() {
        pageHistoryFetcher.fetchFirstRevision(for: pageTitle, pageURL: pageURL) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else {
                    return
                }
                switch result {
                case .failure(let error):
                    self.showNoInternetConnectionAlertOrOtherWarning(from: error)
                case .success(let firstRevision):
                    self.firstRevision = firstRevision
                    let firstEditDate = firstRevision.revisionDate
                    
                    self.pageHistoryFetcher.fetchEditCounts(.edits, for: self.pageTitle, pageURL: self.pageURL) { [weak self] result in
                        DispatchQueue.main.async {
                            guard let self = self else {
                                return
                            }
                            switch result {
                            case .failure(let error):
                                self.showNoInternetConnectionAlertOrOtherWarning(from: error)
                            case .success(let editCounts):
                                if let totalEditResponse = editCounts[.edits] {
                                    let totalEditCount = totalEditResponse.count
                                    if let firstEditDate = firstEditDate,
                                        totalEditResponse.limit == false {
                                        self.countsViewController.set(totalEditCount: totalEditCount, firstEditDate: firstEditDate)
                                    }
                                    
                                }
                            }
                        }
                    }
                }
            }
        }
        
        pageHistoryFetcher.fetchEditCounts(.edits, .userEdits, .anonymous, .bot, for: pageTitle, pageURL: pageURL) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else {
                    return
                }
                switch result {
                case .failure(let error):
                    self.showNoInternetConnectionAlertOrOtherWarning(from: error)
                case .success(let editCountsGroupedByType):
                    self.countsViewController.editCountsGroupedByType = editCountsGroupedByType
                }
            }
        }
        
        pageHistoryFetcher.fetchEditMetrics(for: pageTitle, pageURL: pageURL) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else {
                    return
                }
                switch result {
                case .failure(let error):
                    self.showNoInternetConnectionAlertOrOtherWarning(from: error)
                    self.countsViewController.timeseriesOfEditsCounts = []
                case .success(let timeseriesOfEditCounts):
                    self.countsViewController.timeseriesOfEditsCounts = timeseriesOfEditCounts
                }
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cancelComparison(nil)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        cellLayoutEstimate = nil
    }
    
    private func appendSections(from results: HistoryFetchResults) {
        assert(Thread.isMainThread)
        var items = results.items()
        guard
            let last = self.pageHistorySections.last,
            let first = items.first,
            first.sectionTitle == last.sectionTitle // maybe not the best metric
        else {
            self.pageHistorySections.append(contentsOf: items)
            return
        }
        var lastItems = last.items
        let firstItems = first.items
        lastItems.append(contentsOf: firstItems)
        let combinedSection = PageHistorySection(sectionTitle: first.sectionTitle, items: lastItems)
        self.pageHistorySections.removeLast()
        self.pageHistorySections.append(combinedSection)
        items.removeFirst()
        self.pageHistorySections.append(contentsOf: items)
    }
    
    private func getPageHistory() {
        isLoadingData = true

        pageHistoryFetcher.fetchRevisionInfo(pageURL, requestParams: pageHistoryFetcherParams, failure: { [weak self] error in
            DispatchQueue.main.async {
                guard let self = self else {
                    return
                }
                self.isLoadingData = false
                self.showNoInternetConnectionAlertOrOtherWarning(from: error)
            }
        }) { results in
            DispatchQueue.main.async {
                self.appendSections(from: results)
                self.pageHistoryFetcherParams = results.getPageHistoryRequestParameters(self.pageURL)
                self.batchComplete = results.batchComplete()
                self.isLoadingData = false
                self.collectionView.reloadData()
            }
        }
    }

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        super.scrollViewDidScroll(scrollView)
        guard shouldLoadNewData else {
            return
        }
        getPageHistory()
    }

    @objc private func compare(_ sender: UIBarButtonItem) {
        EditHistoryCompareFunnel.shared.logCompare1(articleURL: pageURL)
        state = .editing
    }

    @objc private func cancelComparison(_ sender: UIBarButtonItem?) {
        state = .idle
    }

    private func forEachVisibleCell(_ block: (IndexPath, PageHistoryCollectionViewCell) -> Void) {
        for indexPath in collectionView.indexPathsForVisibleItems {
            guard let pageHistoryCollectionViewCell = collectionView.cellForItem(at: indexPath) as? PageHistoryCollectionViewCell else {
                continue
            }
            block(indexPath, pageHistoryCollectionViewCell)
        }
    }
    
    private func showDiff(from: WMFPageHistoryRevision?, to: WMFPageHistoryRevision, type: DiffContainerViewModel.DiffType) {
        if let siteURL = pageURL.wmf_site {
            
            if type == .single {
                EditHistoryCompareFunnel.shared.logRevisionView(url: pageURL)
            }
            
            let diffContainerVC = DiffContainerViewController(articleTitle: pageTitle, siteURL: siteURL, type: type, fromModel: from, toModel: to, pageHistoryFetcher: pageHistoryFetcher, theme: theme, revisionRetrievingDelegate: self, firstRevision: firstRevision)
            push(diffContainerVC, animated: true)
        }
    }

    override func apply(theme: Theme) {
        super.apply(theme: theme)
        guard viewIfLoaded != nil else {
            return
        }
        view.backgroundColor = theme.colors.paperBackground
        collectionView.backgroundColor = view.backgroundColor
        compareButton.tintColor = theme.colors.link
        cancelComparisonButton.tintColor = theme.colors.link
        countsViewController.apply(theme: theme)
        comparisonSelectionViewController.apply(theme: theme)
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return pageHistorySections.count
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return pageHistorySections[section].items.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PageHistoryCollectionViewCell.identifier, for: indexPath) as? PageHistoryCollectionViewCell else {
            return UICollectionViewCell()
        }
        configure(cell: cell, at: indexPath)
        return cell
    }

    override func configure(header: CollectionViewHeader, forSectionAt sectionIndex: Int, layoutOnly: Bool) {
        let section = pageHistorySections[sectionIndex]
        let sectionTitle: String?

        if sectionIndex == 0, let date = section.items.first?.revisionDate {
            sectionTitle = (date as NSDate).wmf_localizedRelativeDateFromMidnightUTCDate()
        } else {
            sectionTitle = section.sectionTitle
        }
        header.style = .pageHistory
        header.title = sectionTitle
        header.titleTextColorKeyPath = \Theme.colors.secondaryText
        header.layoutMargins = .zero
        header.apply(theme: theme)
    }

    // MARK: Layout

    // Reset on refresh
    private var cellContentCache = NSCache<NSNumber, CellContent>()

    private class CellContent: NSObject {
        let time: String?
        let displayTime: String?
        let author: String?
        let authorImage: UIImage?
        let sizeDiff: Int?
        let comment: String?
        var selectionThemeModel: SelectionThemeModel?
        var selectionOrderRawValue: Int?

        init(time: String?, displayTime: String?, author: String?, authorImage: UIImage?, sizeDiff: Int?, comment: String?, selectionThemeModel: SelectionThemeModel?, selectionOrderRawValue: Int?) {
            self.time = time
            self.displayTime = displayTime
            self.author = author
            self.authorImage = authorImage
            self.sizeDiff = sizeDiff
            self.comment = comment
            self.selectionThemeModel = selectionThemeModel
            self.selectionOrderRawValue = selectionOrderRawValue
            super.init()
        }
    }

    private func configure(cell: PageHistoryCollectionViewCell, for item: WMFPageHistoryRevision? = nil, at indexPath: IndexPath) {
        let item = item ?? pageHistorySections[indexPath.section].items[indexPath.item]
        let revisionID = NSNumber(value: item.revisionID)
        let isSelected = indexPathsSelectedForComparison.contains(indexPath)
        defer {
            cell.setEditing(state == .editing)
            if !isSelected {
                cell.enableEditing(!maxNumberOfRevisionsSelected)
            }
            cell.apply(theme: theme)
        }
        if let cachedCellContent = cellContentCache.object(forKey: revisionID) {
            cell.time = cachedCellContent.time
            cell.displayTime = cachedCellContent.displayTime
            cell.authorImage = cachedCellContent.authorImage
            cell.author = cachedCellContent.author
            cell.sizeDiff = cachedCellContent.sizeDiff
            cell.comment = cachedCellContent.comment
            if state == .editing {
                if cachedCellContent.selectionOrderRawValue != nil {
                    cell.isSelected = true
                    collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
                }
                if isSelected {
                    cell.selectionThemeModel = cachedCellContent.selectionThemeModel
                } else {
                    cell.selectionThemeModel = maxNumberOfRevisionsSelected ? disabledSelectionThemeModel : nil
                    cell.isSelected = false
                }
                cell.selectionOrder = SelectionOrder(cachedCellContent.selectionOrderRawValue)
            } else {
                cell.selectionOrder = nil
                cell.selectionThemeModel = nil
            }
        } else {
            if let date = item.revisionDate {
                if indexPath.section == 0, (date as NSDate).wmf_isTodayUTC() {
                    let dateStrings = (date as NSDate).wmf_localizedRelativeDateStringFromLocalDateToNowAbbreviated()
                    cell.time = dateStrings[WMFAbbreviatedRelativeDate]
                    cell.displayTime = dateStrings[WMFAbbreviatedRelativeDateAgo]
                } else {
                    cell.time = DateFormatter.wmf_24hshortTime()?.string(from: date)
                    cell.displayTime = DateFormatter.wmf_24hshortTimeWithUTCTimeZone()?.string(from: date)
                }
            }
            cell.authorImage = item.isAnon ? UIImage(named: "anon") : UIImage(named: "user-edit")
            cell.author = item.user
            cell.sizeDiff = item.revisionSize
            cell.comment = item.parsedComment?.removingHTML
            if isSelected, let selectionIndex = indexPathsSelectedForComparisonGroupedByButtonTags.first(where: { $0.value == indexPath })?.key {
                cell.isSelected = true
                collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
                cell.selectionThemeModel = selectionIndex == 0 ? firstSelectionThemeModel : secondSelectionThemeModel
                cell.selectionOrder = SelectionOrder(rawValue: selectionIndex)
            } else {
                cell.selectionThemeModel = maxNumberOfRevisionsSelected ? disabledSelectionThemeModel : nil
            }
        }

        cell.isMinor = item.isMinor
        cell.layoutMargins = layout.itemLayoutMargins

        cellContentCache.setObject(CellContent(time: cell.time, displayTime: cell.displayTime, author: cell.author, authorImage: cell.authorImage, sizeDiff: cell.sizeDiff, comment: cell.comment, selectionThemeModel: cell.selectionThemeModel, selectionOrderRawValue: cell.selectionOrder?.rawValue), forKey: revisionID)

        cell.apply(theme: theme)
        cell.updateAccessibilityLabel()
    }

    private func revisionID(forItemAtIndexPath indexPath: IndexPath) -> NSNumber {
        let item = pageHistorySections[indexPath.section].items[indexPath.item]
        return NSNumber(value: item.revisionID)
    }

    override func contentSizeCategoryDidChange(_ notification: Notification?) {
        layoutCache.reset()
        super.contentSizeCategoryDidChange(notification)
    }

    private func updateSelectionThemeModel(_ selectionThemeModel: SelectionThemeModel?, for cell: PageHistoryCollectionViewCell, at indexPath: IndexPath) {
        cell.selectionThemeModel = selectionThemeModel
        cellContentCache.object(forKey: revisionID(forItemAtIndexPath: indexPath))?.selectionThemeModel = selectionThemeModel
    }

    private func updateSelectionOrder(_ selectionOrder: SelectionOrder?, for cell: PageHistoryCollectionViewCell, at indexPath: IndexPath) {
        cell.selectionOrder = selectionOrder
        cellContentCache.object(forKey: revisionID(forItemAtIndexPath: indexPath))?.selectionOrderRawValue = selectionOrder?.rawValue
    }

    public class SelectionThemeModel {
        let selectedImage: UIImage?
        let borderColor: UIColor
        let backgroundColor: UIColor
        let authorColor: UIColor
        let commentColor: UIColor
        let timeColor: UIColor
        let sizeDiffAdditionColor: UIColor
        let sizeDiffSubtractionColor: UIColor
        let sizeDiffNoDifferenceColor: UIColor

        init(selectedImage: UIImage?, borderColor: UIColor, backgroundColor: UIColor, authorColor: UIColor, commentColor: UIColor, timeColor: UIColor, sizeDiffAdditionColor: UIColor, sizeDiffSubtractionColor: UIColor, sizeDiffNoDifferenceColor: UIColor) {
            self.selectedImage = selectedImage
            self.borderColor = borderColor
            self.backgroundColor = backgroundColor
            self.authorColor = authorColor
            self.commentColor = commentColor
            self.timeColor = timeColor
            self.sizeDiffAdditionColor = sizeDiffAdditionColor
            self.sizeDiffSubtractionColor = sizeDiffSubtractionColor
            self.sizeDiffNoDifferenceColor = sizeDiffNoDifferenceColor
        }
    }

    private lazy var firstSelectionThemeModel: SelectionThemeModel = {
        let backgroundColor: UIColor
        let timeColor: UIColor
        // themeTODO: define a semantic color for this instead of checking isDark
        if theme.isDark {
            backgroundColor = UIColor.orange50.withAlphaComponent(0.15)
            timeColor = theme.colors.tertiaryText
        } else {
            backgroundColor = .yellow90
            timeColor = .base30
        }
        return SelectionThemeModel(selectedImage: UIImage(named: "selected-accent"), borderColor: UIColor.orange50.withAlphaComponent(0.5), backgroundColor: backgroundColor, authorColor: UIColor.orange50, commentColor: theme.colors.primaryText, timeColor: timeColor, sizeDiffAdditionColor: theme.colors.accent, sizeDiffSubtractionColor: theme.colors.destructive, sizeDiffNoDifferenceColor: theme.colors.link)
    }()

    private lazy var secondSelectionThemeModel: SelectionThemeModel = {
        let backgroundColor: UIColor
        let timeColor: UIColor
        // themeTODO: define a semantic color for this instead of checking isDark
        if theme.isDark {
            backgroundColor = theme.colors.link.withAlphaComponent(0.2)
            timeColor = theme.colors.tertiaryText
        } else {
            backgroundColor = .accent90
            timeColor = .base30
        }
        return SelectionThemeModel(selectedImage: nil, borderColor: theme.colors.link, backgroundColor: backgroundColor, authorColor: theme.colors.link, commentColor: theme.colors.primaryText, timeColor: timeColor, sizeDiffAdditionColor: theme.colors.accent, sizeDiffSubtractionColor: theme.colors.destructive, sizeDiffNoDifferenceColor: theme.colors.link)
    }()

    private lazy var disabledSelectionThemeModel: SelectionThemeModel = {
        return SelectionThemeModel(selectedImage: nil, borderColor: theme.colors.border, backgroundColor: theme.colors.paperBackground, authorColor: theme.colors.secondaryText, commentColor: theme.colors.secondaryText, timeColor: .base30, sizeDiffAdditionColor: theme.colors.secondaryText, sizeDiffSubtractionColor: theme.colors.secondaryText, sizeDiffNoDifferenceColor: theme.colors.secondaryText)
    }()

    override func collectionView(_ collectionView: UICollectionView, estimatedHeightForItemAt indexPath: IndexPath, forColumnWidth columnWidth: CGFloat) -> ColumnarCollectionViewLayoutHeightEstimate {
        let identifier = PageHistoryCollectionViewCell.identifier
        let item = pageHistorySections[indexPath.section].items[indexPath.item]
        let userInfo = "phc-cell-\(item.revisionID)"
        if let cachedHeight = layoutCache.cachedHeightForCellWithIdentifier(identifier, columnWidth: columnWidth, userInfo: userInfo) {
            return ColumnarCollectionViewLayoutHeightEstimate(precalculated: true, height: cachedHeight)
        }
        var estimate = ColumnarCollectionViewLayoutHeightEstimate(precalculated: false, height: 80)
        guard let placeholderCell = layoutManager.placeholder(forCellWithReuseIdentifier: PageHistoryCollectionViewCell.identifier) as? PageHistoryCollectionViewCell else {
            return estimate
        }
        configure(cell: placeholderCell, for: item, at: indexPath)
        estimate.height = placeholderCell.sizeThatFits(CGSize(width: columnWidth, height: UIView.noIntrinsicMetric), apply: false).height
        estimate.precalculated = true
        layoutCache.setHeight(estimate.height, forCellWithIdentifier: identifier, columnWidth: columnWidth, userInfo: userInfo)
        return estimate
    }

    override func metrics(with boundsSize: CGSize, readableWidth: CGFloat, layoutMargins: UIEdgeInsets) -> ColumnarCollectionViewLayoutMetrics {
        return ColumnarCollectionViewLayoutMetrics.tableViewMetrics(with: boundsSize, readableWidth: readableWidth, layoutMargins: layoutMargins, interSectionSpacing: 0, interItemSpacing: 20)
    }

    private var postedMaxRevisionsSelectedAccessibilityNotification = false

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        
        switch state {
        case .editing:
            if maxNumberOfRevisionsSelected {
                pageHistoryHintController?.hide(false, presenter: self, subview: comparisonSelectionViewController.view, additionalBottomSpacing: comparisonSelectionViewController.view.frame.height - view.safeAreaInsets.bottom, theme: theme)
                if !postedMaxRevisionsSelectedAccessibilityNotification {
                    UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: CommonStrings.maxRevisionsSelectedWarningTitle)
                    postedMaxRevisionsSelectedAccessibilityNotification = true
                }
                return false
            } else {
                return true
            }
        case .idle:
            return true
        }
    }
    
    private func pushToSingleRevisionDiff(indexPath: IndexPath) {
        
        guard let section = pageHistorySections[safeIndex: indexPath.section] else {
            return
        }
        
        if let toRevision = section.items[safeIndex: indexPath.item] {

            var sectionOffset = 0
            var fromItemIndex = indexPath.item + 1
            //if last revision in section, go to next section for selecting second
            let isLastInSection = indexPath.item == section.items.count - 1
            
            if isLastInSection {
                sectionOffset = 1
                fromItemIndex = 0
            }
            
            let fromRevision = pageHistorySections[safeIndex: indexPath.section + sectionOffset]?.items[safeIndex: fromItemIndex]
            
            showDiff(from: fromRevision, to: toRevision, type: .single)
        }
    }

    var openSelectionIndex = 0

    private var indexPathsSelectedForComparisonGroupedByButtonTags = [Int: IndexPath]() {
        didSet {
            indexPathsSelectedForComparison = Set(indexPathsSelectedForComparisonGroupedByButtonTags.values)
        }
    }
    private var indexPathsSelectedForComparison = Set<IndexPath>()

    private func selectionThemeModel(for selectionOrder: SelectionOrder) -> SelectionThemeModel? {
        if selectionOrder == .first {
            return firstSelectionThemeModel
        } else if selectionOrder == .second {
            return secondSelectionThemeModel
        } else {
            return nil
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if state == .editing {
            selectedCellsCount += 1

            defer {
                comparisonSelectionViewController.setCompareButtonEnabled(maxNumberOfRevisionsSelected)
            }

            guard let cell = collectionView.cellForItem(at: indexPath) as? PageHistoryCollectionViewCell else {
                return
            }

            if maxNumberOfRevisionsSelected {
                assert(indexPathsSelectedForComparisonGroupedByButtonTags.count == 1)
                if let previouslySelectedIndexPath = indexPathsSelectedForComparisonGroupedByButtonTags.first?.value, let previouslySelectedCell = collectionView.cellForItem(at: previouslySelectedIndexPath) as?  PageHistoryCollectionViewCell, let newSelectionOrder = SelectionOrder(rawValue: openSelectionIndex), let previousSelectionOrder = previouslySelectedCell.selectionOrder {
                    if previouslySelectedIndexPath > indexPath, previousSelectionOrder == .first {
                        swapSelection(.second, newSelectionOrder: newSelectionOrder, for: previouslySelectedCell, at: previouslySelectedIndexPath)
                        openSelectionIndex = previousSelectionOrder.rawValue
                    } else if previouslySelectedIndexPath < indexPath, previousSelectionOrder == .second {
                        swapSelection(.first, newSelectionOrder: newSelectionOrder, for: previouslySelectedCell, at: previouslySelectedIndexPath)
                        openSelectionIndex = previousSelectionOrder.rawValue
                    }

                }
                forEachVisibleCell { (indexPath: IndexPath, cell: PageHistoryCollectionViewCell) in
                    if !cell.isSelected {
                        self.updateSelectionThemeModel(self.disabledSelectionThemeModel, for: cell, at: indexPath)
                    }
                    cell.enableEditing(false)
                }
            }
            if let selectionOrder = SelectionOrder(rawValue: openSelectionIndex), let themeModel = selectionThemeModel(for: selectionOrder) {
                comparisonSelectionViewController.updateSelectionButton(selectionOrder, with: themeModel, cell: cell)
                updateSelectionThemeModel(themeModel, for: cell, at: indexPath)
                indexPathsSelectedForComparisonGroupedByButtonTags[openSelectionIndex] = indexPath
                updateSelectionOrder(selectionOrder, for: cell, at: indexPath)
                openSelectionIndex += 1
                collectionView.reloadData()
            }
        } else {
            let cell = collectionView.cellForItem(at: indexPath)
            cell?.isSelected = false
            pushToSingleRevisionDiff(indexPath: indexPath)
        }
    }

    private func swapSelection(_ selectionOrder: SelectionOrder, newSelectionOrder: SelectionOrder, for cell: PageHistoryCollectionViewCell, at indexPath: IndexPath) {
        guard let newSelectionThemeModel = selectionThemeModel(for: selectionOrder) else {
            return
        }
        comparisonSelectionViewController.updateSelectionButton(newSelectionOrder, with: newSelectionThemeModel, cell: cell)
        indexPathsSelectedForComparisonGroupedByButtonTags[selectionOrder.rawValue] = indexPath
        updateSelectionOrder(newSelectionOrder, for: cell, at: indexPath)
        updateSelectionThemeModel(newSelectionThemeModel, for: cell, at: indexPath)
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        selectedCellsCount -= 1
        pageHistoryHintController?.hide(true, presenter: self, subview: comparisonSelectionViewController.view, additionalBottomSpacing: comparisonSelectionViewController.view.frame.height - view.safeAreaInsets.bottom, theme: theme)

        if let cell = collectionView.cellForItem(at: indexPath) as? PageHistoryCollectionViewCell, let selectionOrder = cell.selectionOrder {
            indexPathsSelectedForComparisonGroupedByButtonTags.removeValue(forKey: selectionOrder.rawValue)
            openSelectionIndex = indexPathsSelectedForComparisonGroupedByButtonTags.isEmpty ? 0 : selectionOrder.rawValue

            forEachVisibleCell { (indexPath: IndexPath, cell: PageHistoryCollectionViewCell) in
                if !cell.isSelected {
                    self.updateSelectionThemeModel(nil, for: cell, at: indexPath)
                    cell.enableEditing(true)
                }
            }
            comparisonSelectionViewController.resetSelectionButton(selectionOrder)
            updateSelectionOrder(nil, for: cell, at: indexPath)
            updateSelectionThemeModel(nil, for: cell, at: indexPath)
            cell.apply(theme: theme)
            collectionView.reloadData()
        }
        comparisonSelectionViewController.setCompareButtonEnabled(maxNumberOfRevisionsSelected)
    }

    // MARK: Error handling

    private func showNoInternetConnectionAlertOrOtherWarning(from error: Error, noInternetConnectionAlertMessage: String = CommonStrings.noInternetConnection) {
        DispatchQueue.main.async {
            if (error as NSError).wmf_isNetworkConnectionError() {
                if UIAccessibility.isVoiceOverRunning {
                    UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: noInternetConnectionAlertMessage)
                } else {
                    WMFAlertManager.sharedInstance.showErrorAlertWithMessage(noInternetConnectionAlertMessage, sticky: true, dismissPreviousAlerts: true)
                }
            } else {
                if UIAccessibility.isVoiceOverRunning {
                    UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: error.localizedDescription)
                } else {
                    WMFAlertManager.sharedInstance.showErrorAlertWithMessage(error.localizedDescription, sticky: true, dismissPreviousAlerts: true)
                }
            }
        }
    }
}

extension PageHistoryViewController: PageHistoryComparisonSelectionViewControllerDelegate {
    func pageHistoryComparisonSelectionViewController(_ pageHistoryComparisonSelectionViewController: PageHistoryComparisonSelectionViewController, selectionOrder: SelectionOrder) {
        guard let indexPath = indexPathsSelectedForComparisonGroupedByButtonTags[selectionOrder.rawValue] else {
            return
        }
        collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: true)
    }

    func pageHistoryComparisonSelectionViewControllerDidTapCompare(_ pageHistoryComparisonSelectionViewController: PageHistoryComparisonSelectionViewController) {
        
        EditHistoryCompareFunnel.shared.logCompare2(articleURL: pageURL)
        
        guard let firstIndexPath = indexPathsSelectedForComparisonGroupedByButtonTags[SelectionOrder.first.rawValue], let secondIndexPath = indexPathsSelectedForComparisonGroupedByButtonTags[SelectionOrder.second.rawValue] else {
            return
        }
        let revision1 = pageHistorySections[firstIndexPath.section].items[firstIndexPath.item]
        let revision2 = pageHistorySections[secondIndexPath.section].items[secondIndexPath.item]

        guard let date1 = revision1.revisionDate,
            let date2 = revision2.revisionDate else {
                return
        }

        //show older revision as "from" no matter what order was selected
        let fromRevision: WMFPageHistoryRevision
        let toRevision: WMFPageHistoryRevision
        if date1.compare(date2) == .orderedAscending {
            fromRevision = revision1
            toRevision = revision2
        } else {
            fromRevision = revision2
            toRevision = revision1
        }

        showDiff(from: fromRevision, to: toRevision, type: .compare)
    }
}

extension PageHistoryViewController: DiffRevisionRetrieving {
    func retrievePreviousRevision(with sourceRevision: WMFPageHistoryRevision) -> WMFPageHistoryRevision? {
        
        for (sectionIndex, section) in pageHistorySections.enumerated() {
            for (itemIndex, item) in section.items.enumerated() {
                
                if item.revisionID == sourceRevision.revisionID {
                    if itemIndex == (section.items.count - 1) {
                        return pageHistorySections[safeIndex: sectionIndex + 1]?.items.first
                    } else {
                        return section.items[safeIndex: itemIndex + 1]
                    }
                }
            }
        }
        
        return nil
    }
    
    func retrieveNextRevision(with sourceRevision: WMFPageHistoryRevision) -> WMFPageHistoryRevision? {
        
        var previousSection: PageHistorySection?
        var previousItem: WMFPageHistoryRevision?
        
        for section in pageHistorySections {
            for item in section.items {
        
                if item.revisionID == sourceRevision.revisionID {
                    
                    guard let previousItem = previousItem else {
                        
                        guard let previousSection = previousSection else {
                            
                            //user tapped latest revision, no later revision available.
                            return nil
                        }
                        
                        return previousSection.items.last
                        
                    }
                        
                    return previousItem
                    
                }
                
                previousItem = item
            }
            
            previousSection = section
            previousItem = nil
        }
        
        return nil
        
    }
    
    
}
