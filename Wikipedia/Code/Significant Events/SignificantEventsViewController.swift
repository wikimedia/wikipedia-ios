
import UIKit
import WMF

protocol SignificantEventsViewControllerDelegate: class {
    func fetchNextPage(nextRvStartId: UInt)
    var significantEventsViewModel: SignificantEventsViewModel? {
        get
    }
}

enum SignificantEventsSection {
  case standard
}

extension LargeEventViewModel: Equatable {
    public static func == (lhs: LargeEventViewModel, rhs: LargeEventViewModel) -> Bool {
        return lhs.revId == rhs.revId
    }
}

extension SectionHeaderViewModel: Equatable {
    public static func == (lhs: SectionHeaderViewModel, rhs: SectionHeaderViewModel) -> Bool {
        return lhs.timestamp == rhs.timestamp
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
        case .sectionHeader(let leftSectionHeader):
            switch rhs {
            case .sectionHeader(let rightSectionHeader):
                return leftSectionHeader == rightSectionHeader
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
        case .sectionHeader(let viewModel):
            hasher.combine(viewModel.timestamp)
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
    
    fileprivate static let largeEventCellReuseIdentifier = "SignificantEventsLargeEventCollectionViewCell"
    fileprivate static let sectionHeaderCellReuseIdentifier = "SignificantEventsSectionHeaderCell"
    fileprivate static let smallEventReuseIdentifier = "SignificantEventsSmallEventCollectionViewCell"
    fileprivate static let blankReuseIdentifier = "SignificantEventsBlankCell"
    
    private var dataSource: UICollectionViewDiffableDataSource<SignificantEventsSection, TimelineEventViewModel>!
    
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
        
        dataSource = UICollectionViewDiffableDataSource<SignificantEventsSection, TimelineEventViewModel>(collectionView: collectionView) { (collectionView: UICollectionView, indexPath: IndexPath, event: TimelineEventViewModel) -> UICollectionViewCell? in
            
            let cell: CollectionViewCell
            switch event {
            case .largeEvent(let largeEvent):
                guard let largeEventCell = collectionView.dequeueReusableCell(withReuseIdentifier: SignificantEventsViewController.largeEventCellReuseIdentifier, for: indexPath) as? SignificantEventsLargeEventCollectionViewCell else {
                    return nil
                }
                
                largeEventCell.configure(with: largeEvent, theme: theme)
                cell = largeEventCell
                //tonitodo: look into this commented out need
                //significantEventsSideScrollingCell.timelineView.extendTimelineAboveDot = indexPath.item == 0 ? true : false
            case .smallEvent(let smallEvent):
                guard let smallEventCell = collectionView.dequeueReusableCell(withReuseIdentifier: SignificantEventsViewController.smallEventReuseIdentifier, for: indexPath) as? SignificantEventsSmallEventCollectionViewCell else {
                    return nil
                }
                
                smallEventCell.configure(viewModel: smallEvent, theme: theme)
                cell = smallEventCell
                //tonitodo: look into this commented out need
                //significantEventsSideScrollingCell.timelineView.extendTimelineAboveDot = indexPath.item == 0 ? true : false
            case .sectionHeader(let sectionHeader):
                guard let sectionHeaderCell = collectionView.dequeueReusableCell(withReuseIdentifier: SignificantEventsViewController.sectionHeaderCellReuseIdentifier, for: indexPath) as? SignificantEventsSectionHeaderCell else {
                    return nil
                }
                
                sectionHeaderCell.configure(viewModel: sectionHeader, theme: theme)
                cell = sectionHeaderCell
            }
            
            //cell.layoutMargins = layout.itemLayoutMargins
            return cell
            
        }
        

        dataSource.supplementaryViewProvider = { collectionView, kind, indexPath in

            guard kind == UICollectionView.elementKindSectionHeader,
                  let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: SignificantEventsHeaderView.identifier, for: indexPath) as? SignificantEventsHeaderView else {
                return UICollectionReusableView()
            }
            
            self.configureHeaderView(headerView)
            self.headerView = headerView
            
            return headerView
        }
    }
    
    func addInitialEvents(timelineEvents: [TimelineEventViewModel]) {
        var snapshot = NSDiffableDataSourceSnapshot<SignificantEventsSection, TimelineEventViewModel>()
        snapshot.appendSections([.standard])
        snapshot.appendItems(timelineEvents, toSection: .standard)
        dataSource.apply(snapshot, animatingDifferences: true)
    }
    
    func addEvents(timelineEvents: [TimelineEventViewModel]) {
        var currentSnapshot = dataSource.snapshot()
        currentSnapshot.appendItems(timelineEvents, toSection: .standard)
        dataSource.apply(currentSnapshot, animatingDifferences: true)
    }
    
    func reloadData() {
        collectionView.reloadData()
    }

    override func viewDidLoad() {
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: WMFLocalizedString("close-button", value: "Close", comment: "Close button used in navigation bar that closes out a presented modal screen."), style: .done, target: self, action: #selector(closeButtonPressed))
        
        super.viewDidLoad()

        layoutManager.register(SignificantEventsLargeEventCollectionViewCell.self, forCellWithReuseIdentifier: SignificantEventsViewController.largeEventCellReuseIdentifier, addPlaceholder: true)
        layoutManager.register(SignificantEventsSmallEventCollectionViewCell.self, forCellWithReuseIdentifier: SignificantEventsViewController.smallEventReuseIdentifier, addPlaceholder: true)
        layoutManager.register(SignificantEventsHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: SignificantEventsHeaderView.identifier, addPlaceholder: true)
        layoutManager.register(SignificantEventsSectionHeaderCell.self, forCellWithReuseIdentifier: SignificantEventsViewController.sectionHeaderCellReuseIdentifier, addPlaceholder: true)
        layoutManager.register(UICollectionViewCell.self, forCellWithReuseIdentifier: SignificantEventsViewController.blankReuseIdentifier, addPlaceholder: true)
        
        self.title = headerText
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
        
        guard let headerView = layoutManager.placeholder(forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: SignificantEventsHeaderView.identifier) as? SignificantEventsHeaderView else {
            return estimate
        }
        
        configureHeaderView(headerView)
        estimate.height = headerView.sizeThatFits(CGSize(width: columnWidth, height: UIView.noIntrinsicMetric), apply: false).height
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
            guard let largeEventCell = layoutManager.placeholder(forCellWithReuseIdentifier: SignificantEventsViewController.largeEventCellReuseIdentifier) as? SignificantEventsLargeEventCollectionViewCell else {
                return estimate
            }
            
            
            largeEventCell.configure(with: largeEvent, theme: theme)
            cell = largeEventCell
        case .smallEvent(let smallEvent):
            guard let smallEventCell = layoutManager.placeholder(forCellWithReuseIdentifier: SignificantEventsViewController.smallEventReuseIdentifier) as? SignificantEventsSmallEventCollectionViewCell else {
                return estimate
            }
            
            smallEventCell.configure(viewModel: smallEvent, theme: theme)
            cell = smallEventCell
        case .sectionHeader(let sectionHeader):
            guard let sectionHeaderCell = layoutManager.placeholder(forCellWithReuseIdentifier: SignificantEventsViewController.sectionHeaderCellReuseIdentifier) as? SignificantEventsSectionHeaderCell else {
                return estimate
            }
            
            sectionHeaderCell.configure(viewModel: sectionHeader, theme: theme)
            cell = sectionHeaderCell
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
        
        let numberOfEvents = dataSource.collectionView(collectionView, numberOfItemsInSection: indexPath.section)
        
        if indexPath.item == numberOfEvents - 1 {
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
