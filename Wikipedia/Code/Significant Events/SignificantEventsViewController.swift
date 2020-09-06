
import UIKit
import WMF

protocol SignificantEventsViewControllerDelegate: class {
    func fetchNextPage(nextRvStartId: UInt)
    var significantEventsViewModel: SignificantEventsViewModel? {
        get
    }
}

class SignificantEventsViewController: ColumnarCollectionViewController {
    
    private let significantEventsController = SignificantEventsController()
    private let articleTitle: String?
    private var headerView: SignificantEventsHeaderView?
    private let headerText = WMFLocalizedString("significant-events-header-text", value: "Recent Changes", comment: "Header text of significant changes view.")
    private let editMetrics: [NSNumber]?
    private weak var delegate: SignificantEventsViewControllerDelegate?
    
    fileprivate static let sideScrollingCellReuseIdentifier = "SignificantEventsSideScrollingCollectionViewCell"
    
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
    }
    
    func reloadData() {
        collectionView.reloadData()
    }

    override func viewDidLoad() {
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: WMFLocalizedString("close-button", value: "Close", comment: "Close button used in navigation bar that closes out a presented modal screen."), style: .done, target: self, action: #selector(closeButtonPressed))
        
        super.viewDidLoad()

        layoutManager.register(SignificantEventsSideScrollingCollectionViewCell.self, forCellWithReuseIdentifier: SignificantEventsViewController.sideScrollingCellReuseIdentifier, addPlaceholder: true)
        layoutManager.register(SignificantEventsHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: SignificantEventsHeaderView.identifier, addPlaceholder: true)
        
        self.title = headerText
    }
    
    @objc private func closeButtonPressed() {
        dismiss(animated: true, completion: nil)
    }
    
    override func metrics(with size: CGSize, readableWidth: CGFloat, layoutMargins: UIEdgeInsets) -> ColumnarCollectionViewLayoutMetrics {
        return ColumnarCollectionViewLayoutMetrics.tableViewMetrics(with: size, readableWidth: readableWidth, layoutMargins: layoutMargins)
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionHeader,
              let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: SignificantEventsHeaderView.identifier, for: indexPath) as? SignificantEventsHeaderView else {
            return UICollectionReusableView()
        }
        
        configureHeaderView(headerView)
        self.headerView = headerView
        
        return headerView
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
        guard let placeholderCell = layoutManager.placeholder(forCellWithReuseIdentifier: SignificantEventsViewController.sideScrollingCellReuseIdentifier) as? SignificantEventsSideScrollingCollectionViewCell else {
            return estimate
        }
        
        guard let significantEventsViewModel = delegate?.significantEventsViewModel else {
            return estimate
        }
        
        guard let event = significantEventsViewModel.events[safeIndex: indexPath.item] else {
            return estimate
        }
        placeholderCell.layoutMargins = layout.itemLayoutMargins
        
        switch event {
        case .largeEvent(let largeEvent):
            placeholderCell.configure(with: largeEvent, theme: theme)
        default:
            break
        }
        
        estimate.height = placeholderCell.sizeThatFits(CGSize(width: columnWidth, height: UIView.noIntrinsicMetric), apply: false).height
        estimate.precalculated = true
        return estimate
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        guard let significantEventsViewModel = delegate?.significantEventsViewModel else {
            return
        }
        
        if indexPath.item == significantEventsViewModel.events.count - 1 {
            guard let nextRvStartId = significantEventsViewModel.nextRvStartId,
                  nextRvStartId != 0 else {
                return
            }
            
            delegate?.fetchNextPage(nextRvStartId: nextRvStartId)
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SignificantEventsViewController.sideScrollingCellReuseIdentifier, for: indexPath)
        guard let significantEventsSideScrollingCell = cell as? SignificantEventsSideScrollingCollectionViewCell,
              let significantEventsViewModel = delegate?.significantEventsViewModel else {
            return cell
        }
        guard let event = significantEventsViewModel.events[safeIndex: indexPath.item] else {
            return cell
        }

        significantEventsSideScrollingCell.layoutMargins = layout.itemLayoutMargins
        
        switch event {
        case .largeEvent(let largeEvent):
            significantEventsSideScrollingCell.configure(with: largeEvent, theme: theme)
            significantEventsSideScrollingCell.apply(theme: theme)
        default:
            break
        }
        
        significantEventsSideScrollingCell.timelineView.extendTimelineAboveDot = indexPath.item == 0 ? true : false

        return significantEventsSideScrollingCell
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        guard let significantEventsViewModel = delegate?.significantEventsViewModel else {
            return 0
        }

        return significantEventsViewModel.events.count
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
