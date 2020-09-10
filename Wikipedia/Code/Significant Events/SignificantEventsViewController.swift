
import UIKit
import WMF

protocol SignificantEventsViewControllerDelegate: class {
    func fetchNextPage(nextRvStartId: UInt)
    var significantEventsViewModel: SignificantEventsViewModel? {
        get
    }
}

extension LargeEventViewModel: Equatable {
    public static func == (lhs: LargeEventViewModel, rhs: LargeEventViewModel) -> Bool {
        return lhs.revId == rhs.revId
    }
}

extension SectionHeaderViewModel: Hashable {
    public static func == (lhs: SectionHeaderViewModel, rhs: SectionHeaderViewModel) -> Bool {
        return lhs.subtitleTimestampDisplay == rhs.subtitleTimestampDisplay
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(subtitleTimestampDisplay)
    }
}

extension SmallEventViewModel: Equatable {
    public static func == (lhs: SmallEventViewModel, rhs: SmallEventViewModel) -> Bool {
        return lhs.smallChanges == rhs.smallChanges
    }
}

extension SignificantEvents.SmallChange: Equatable {
    public static func == (lhs: SignificantEvents.SmallChange, rhs: SignificantEvents.SmallChange) -> Bool {
        return lhs.revId == rhs.revId
    }
}

extension TimelineEventViewModel: Hashable {
    public static func == (lhs: TimelineEventViewModel, rhs: TimelineEventViewModel) -> Bool {
        switch lhs {
        case .largeEvent(let leftLargeEvent):
            switch rhs {
            case .largeEvent(let rightLargeEvent):
                return leftLargeEvent == rightLargeEvent
            default:
                return false
            }
        case .smallEvent(let leftSmallEvent):
            switch rhs {
            case .smallEvent(let rightSmallEvent):
                return leftSmallEvent == rightSmallEvent
            default:
                return false
            }
        
        }
    }
    
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .smallEvent(let smallEvent):
            smallEvent.smallChanges.forEach { hasher.combine($0.revId) }
        case .largeEvent(let largeEvent):
            hasher.combine(largeEvent.revId)
        }
    }
}

@available(iOS 13.0, *)
class SignificantEventsViewController: ColumnarCollectionViewController {
    
    private let significantEventsController = SignificantEventsController()
    private let articleTitle: String?
    private var headerView: SignificantEventsHeaderView?
    private let headerText = WMFLocalizedString("significant-events-header-text", value: "Recent Changes", comment: "Header text of significant changes view.")
    private let editMetrics: [NSNumber]?
    private weak var delegate: SignificantEventsViewControllerDelegate?
    
    private var dataSource: UICollectionViewDiffableDataSource<SectionHeaderViewModel, TimelineEventViewModel>!
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not supported")
    }
    
    required init?(significantEventsViewModel: SignificantEventsViewModel, articleTitle: String?, editMetrics: [NSNumber]?, theme: Theme, locale: Locale = Locale.current, delegate: SignificantEventsViewControllerDelegate) {
        
        guard let _ = delegate.significantEventsViewModel else {
            return nil
        }
        
        self.articleTitle = articleTitle
        self.editMetrics = editMetrics
        super.init()
        self.theme = theme
        self.delegate = delegate
        
        dataSource = UICollectionViewDiffableDataSource<SectionHeaderViewModel, TimelineEventViewModel>(collectionView: collectionView) { (collectionView: UICollectionView, indexPath: IndexPath, event: TimelineEventViewModel) -> UICollectionViewCell? in
            
            let cell: CollectionViewCell
            switch event {
            case .largeEvent(let largeEvent):
                guard let largeEventCell = collectionView.dequeueReusableCell(withReuseIdentifier: SignificantEventsLargeEventCollectionViewCell.identifier, for: indexPath) as? SignificantEventsLargeEventCollectionViewCell else {
                    return nil
                }
                
                largeEventCell.configure(with: largeEvent, theme: theme)
                cell = largeEventCell
                //tonitodo: look into this commented out need
                //significantEventsSideScrollingCell.timelineView.extendTimelineAboveDot = indexPath.item == 0 ? true : false
            case .smallEvent(let smallEvent):
                guard let smallEventCell = collectionView.dequeueReusableCell(withReuseIdentifier: SignificantEventsSmallEventCollectionViewCell.identifier, for: indexPath) as? SignificantEventsSmallEventCollectionViewCell else {
                    return nil
                }
                
                smallEventCell.configure(viewModel: smallEvent, theme: theme)
                cell = smallEventCell
            }
            
            if let layout = collectionView.collectionViewLayout as? ColumnarCollectionViewLayout {
                cell.layoutMargins = layout.itemLayoutMargins
            }
            
            return cell
            
        }
        

        dataSource.supplementaryViewProvider = { collectionView, kind, indexPath in

            guard kind == UICollectionView.elementKindSectionHeader else {
                return UICollectionReusableView()
            }
            
            let section = self.dataSource.snapshot()
                .sectionIdentifiers[indexPath.section]
            
            guard let sectionHeaderView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: SignificantEventsSectionHeaderView.identifier, for: indexPath) as? SignificantEventsSectionHeaderView else {
                return UICollectionReusableView()
            }
            
            sectionHeaderView.configure(viewModel: section, theme: theme)
            return sectionHeaderView
            
        }
    }
    
    func addInitialSections(sections: [SectionHeaderViewModel]) {
        var snapshot = NSDiffableDataSourceSnapshot<SectionHeaderViewModel, TimelineEventViewModel>()
        snapshot.appendSections(sections)
        for section in sections {
            snapshot.appendItems(section.events, toSection: section)
        }
        dataSource.apply(snapshot, animatingDifferences: true)
    }
    
    func appendSections(_ sections: [SectionHeaderViewModel]) {
        
        var currentSnapshot = dataSource.snapshot()
        
        var existingSections: [SectionHeaderViewModel] = []
        for currentSection in currentSnapshot.sectionIdentifiers {
            for proposedSection in sections {
                if currentSection == proposedSection {
                    currentSnapshot.appendItems(proposedSection.events, toSection: currentSection)
                    existingSections.append(proposedSection)
                }
            }
        }
        
        for section in sections {
            if !existingSections.contains(section) {
                currentSnapshot.appendSections([section])
                currentSnapshot.appendItems(section.events, toSection: section)
            }
        }
        
        dataSource.apply(currentSnapshot, animatingDifferences: true)
    }
    
    func reloadData() {
        collectionView.reloadData()
    }

    override func viewDidLoad() {
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: WMFLocalizedString("close-button", value: "Close", comment: "Close button used in navigation bar that closes out a presented modal screen."), style: .done, target: self, action: #selector(closeButtonPressed))
        
        super.viewDidLoad()

        layoutManager.register(SignificantEventsLargeEventCollectionViewCell.self, forCellWithReuseIdentifier: SignificantEventsLargeEventCollectionViewCell.identifier, addPlaceholder: true)
        layoutManager.register(SignificantEventsSmallEventCollectionViewCell.self, forCellWithReuseIdentifier: SignificantEventsSmallEventCollectionViewCell.identifier, addPlaceholder: true)
        layoutManager.register(SignificantEventsSectionHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: SignificantEventsSectionHeaderView.identifier, addPlaceholder: true)
        
        self.title = headerText
        
        setupNavigationBar()
    }
    
    private func setupNavigationBar() {
        
        navigationMode = .forceBar
        if let headerView = SignificantEventsHeaderView.wmf_viewFromClassNib() {
            self.headerView = headerView
            configureHeaderView(headerView)
            navigationBar.isBarHidingEnabled = false
            navigationBar.isUnderBarViewHidingEnabled = true
            useNavigationBarVisibleHeightForScrollViewInsets = true
            navigationBar.addUnderNavigationBarView(headerView)
            navigationBar.underBarViewPercentHiddenForShowingTitle = 0.6
            navigationBar.title = headerText
            navigationBar.setNeedsLayout()
            navigationBar.layoutIfNeeded()
            updateScrollViewInsets()
        }
    }
    
    @objc private func closeButtonPressed() {
        dismiss(animated: true, completion: nil)
    }
    
    override func metrics(with size: CGSize, readableWidth: CGFloat, layoutMargins: UIEdgeInsets) -> ColumnarCollectionViewLayoutMetrics {
        return ColumnarCollectionViewLayoutMetrics.tableViewMetrics(with: size, readableWidth: readableWidth, layoutMargins: layoutMargins)
    }
    
    private func configureHeaderView(_ headerView: SignificantEventsHeaderView) {
        
        guard let significantEventsViewModel = delegate?.significantEventsViewModel else {
            return
        }
        
        let headerText = self.headerText.uppercased(with: NSLocale.current)
        headerView.configure(headerText: headerText, titleText: articleTitle, summaryText: significantEventsViewModel.summaryText, editMetrics: editMetrics, theme: theme)
        headerView.apply(theme: theme)
    }
    
    override func collectionView(_ collectionView: UICollectionView, estimatedHeightForHeaderInSection section: Int, forColumnWidth columnWidth: CGFloat) -> ColumnarCollectionViewLayoutHeightEstimate {
        
        var estimate = ColumnarCollectionViewLayoutHeightEstimate(precalculated: false, height: 70)
        
        let section = self.dataSource.snapshot()
            .sectionIdentifiers[section]
        
        guard let sectionHeaderView = layoutManager.placeholder(forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: SignificantEventsSectionHeaderView.identifier) as? SignificantEventsSectionHeaderView else {
            return estimate
        }
        
        sectionHeaderView.configure(viewModel: section, theme: theme)
        
        estimate.height = sectionHeaderView.sizeThatFits(CGSize(width: columnWidth, height: UIView.noIntrinsicMetric), apply: false).height
        estimate.precalculated = true
        return estimate
    }
    
    override func collectionView(_ collectionView: UICollectionView, estimatedHeightForItemAt indexPath: IndexPath, forColumnWidth columnWidth: CGFloat) -> ColumnarCollectionViewLayoutHeightEstimate {
        var estimate = ColumnarCollectionViewLayoutHeightEstimate(precalculated: false, height: 350)
        
        guard let event = dataSource.itemIdentifier(for: indexPath) else {
            return estimate
        }
        
        let cell: CollectionViewCell
        switch event {
        case .largeEvent(let largeEvent):
            guard let largeEventCell = layoutManager.placeholder(forCellWithReuseIdentifier: SignificantEventsLargeEventCollectionViewCell.identifier) as? SignificantEventsLargeEventCollectionViewCell else {
                return estimate
            }
            
            
            largeEventCell.configure(with: largeEvent, theme: theme)
            cell = largeEventCell
        case .smallEvent(let smallEvent):
            guard let smallEventCell = layoutManager.placeholder(forCellWithReuseIdentifier: SignificantEventsSmallEventCollectionViewCell.identifier) as? SignificantEventsSmallEventCollectionViewCell else {
                return estimate
            }
            
            smallEventCell.configure(viewModel: smallEvent, theme: theme)
            cell = smallEventCell
        }
        
        cell.layoutMargins = layout.itemLayoutMargins
        estimate.height = cell.sizeThatFits(CGSize(width: columnWidth, height: UIView.noIntrinsicMetric), apply: false).height
        estimate.precalculated = true
        
        return estimate
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        guard let significantEventsViewModel = delegate?.significantEventsViewModel else {
            return
        }
        
        let numSections = dataSource.numberOfSections(in: collectionView)
        let numEvents = dataSource.collectionView(collectionView, numberOfItemsInSection: indexPath.section)
        
        if indexPath.section == numSections - 1 &&
            indexPath.item == numEvents - 1 {
            guard let nextRvStartId = significantEventsViewModel.nextRvStartId,
                  nextRvStartId != 0 else {
                return
            }
            
            delegate?.fetchNextPage(nextRvStartId: nextRvStartId)
        }
    }
    
    @objc func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    @objc func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    override func apply(theme: Theme) {
        guard isViewLoaded else {
            return
        }

        super.apply(theme: theme)
        navigationItem.rightBarButtonItem?.tintColor = theme.colors.link
        navigationController?.navigationBar.barTintColor = theme.colors.cardButtonBackground //tonitodo: this doesn't seem to work
    }
}
