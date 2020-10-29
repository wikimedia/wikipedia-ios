
import UIKit
import WMF

@available(iOS 13.0, *)
protocol ArticleAsLivingDocViewControllerDelegate: class {
    var articleAsLivingDocViewModel: ArticleAsLivingDocViewModel? { get }
    var articleURL: URL { get }
    func fetchNextPage(nextRvStartId: UInt, theme: Theme)
    func showEditHistory(scrolledTo revisionID: Int?)
    func handleLink(with href: String)
    func showTalkPage()
}

protocol ArticleDetailsShowing: class {
    func goToHistory(scrolledTo revisionID: Int?)
    func showTalkPage()
}

@available(iOS 13.0, *)
class ArticleAsLivingDocViewController: ColumnarCollectionViewController {
    
    private let articleTitle: String?
    private var headerView: ArticleAsLivingDocHeaderView?
    private let headerText = WMFLocalizedString("aaald-header-text", value: "Recent Changes", comment: "Header text of article as a living document view.")
    private let editMetrics: [NSNumber]?
    private weak var delegate: ArticleAsLivingDocViewControllerDelegate?
    
    private lazy var dataSource: UICollectionViewDiffableDataSource<ArticleAsLivingDocViewModel.SectionHeader, ArticleAsLivingDocViewModel.TypedEvent> = createDataSource()
    private var initialIndexPath: IndexPath?
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not supported")
    }
    
    required init?(articleTitle: String?, editMetrics: [NSNumber]?, theme: Theme, locale: Locale = Locale.current, delegate: ArticleAsLivingDocViewControllerDelegate, scrollToInitialIndexPath initialIndexPath: IndexPath?) {
        
        guard let _ = delegate.articleAsLivingDocViewModel else {
            return nil
        }
        
        self.articleTitle = articleTitle
        self.editMetrics = editMetrics
        super.init()
        self.theme = theme
        self.delegate = delegate
        self.initialIndexPath = initialIndexPath
        footerButtonTitle = CommonStrings.viewFullHistoryText
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        layoutManager.register(ArticleAsLivingDocLargeEventCollectionViewCell.self, forCellWithReuseIdentifier: ArticleAsLivingDocLargeEventCollectionViewCell.identifier, addPlaceholder: true)
        layoutManager.register(ArticleAsLivingDocSmallEventCollectionViewCell.self, forCellWithReuseIdentifier: ArticleAsLivingDocSmallEventCollectionViewCell.identifier, addPlaceholder: true)
        layoutManager.register(ArticleAsLivingDocSectionHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: ArticleAsLivingDocSectionHeaderView.identifier, addPlaceholder: true)
        
        self.title = headerText
        
        setupNavigationBar()
        
        if let viewModel = delegate?.articleAsLivingDocViewModel {
            addInitialSections(sections: viewModel.sections)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        // for some reason the initial calls to metrics(with size: CGSize...) (triggered from viewDidLoad) have an incorrect view size passed in.
        // this retriggers that method with the correct size, so that we have correct layout margins on load
        if isFirstAppearance {
            collectionView.reloadData()
        }
        super.viewWillAppear(animated)

    }

    private func createDataSource() -> UICollectionViewDiffableDataSource<ArticleAsLivingDocViewModel.SectionHeader, ArticleAsLivingDocViewModel.TypedEvent> {
        let dataSource = UICollectionViewDiffableDataSource<ArticleAsLivingDocViewModel.SectionHeader, ArticleAsLivingDocViewModel.TypedEvent>(collectionView: collectionView) { (collectionView: UICollectionView, indexPath: IndexPath, event: ArticleAsLivingDocViewModel.TypedEvent) -> UICollectionViewCell? in

            let theme = self.theme
            let cell: CollectionViewCell
            switch event {
            case .large(let largeEvent):
                guard let largeEventCell = collectionView.dequeueReusableCell(withReuseIdentifier: ArticleAsLivingDocLargeEventCollectionViewCell.identifier, for: indexPath) as? ArticleAsLivingDocLargeEventCollectionViewCell else {
                    return nil
                }

                largeEventCell.configure(with: largeEvent, theme: theme, extendTimelineAboveDot: indexPath.item != 0)
                largeEventCell.delegate = self
                largeEventCell.articleDelegate = self
                cell = largeEventCell
            case .small(let smallEvent):
                guard let smallEventCell = collectionView.dequeueReusableCell(withReuseIdentifier: ArticleAsLivingDocSmallEventCollectionViewCell.identifier, for: indexPath) as? ArticleAsLivingDocSmallEventCollectionViewCell else {
                    return nil
                }

                smallEventCell.configure(viewModel: smallEvent, theme: theme)
                smallEventCell.delegate = self
                cell = smallEventCell
            }

            if let layout = collectionView.collectionViewLayout as? ColumnarCollectionViewLayout {
                cell.layoutMargins = layout.itemLayoutMargins
            }

            return cell

        }


        dataSource.supplementaryViewProvider = { collectionView, kind, indexPath in

            guard kind == UICollectionView.elementKindSectionHeader || kind == UICollectionView.elementKindSectionFooter else {
                return UICollectionReusableView()
            }

            let theme = self.theme

            if kind == UICollectionView.elementKindSectionHeader {
                let section = self.dataSource.snapshot()
                    .sectionIdentifiers[indexPath.section]

                guard let sectionHeaderView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: ArticleAsLivingDocSectionHeaderView.identifier, for: indexPath) as? ArticleAsLivingDocSectionHeaderView else {
                    return UICollectionReusableView()
                }

                sectionHeaderView.layoutMargins = self.layout.itemLayoutMargins
                sectionHeaderView.configure(viewModel: section, theme: theme)
                return sectionHeaderView
            } else if kind == UICollectionView.elementKindSectionFooter {
                guard let footer = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: CollectionViewFooter.identifier, for: indexPath) as? CollectionViewFooter else {
                    return UICollectionReusableView()
                }
                self.configure(footer: footer, forSectionAt: indexPath.section, layoutOnly: false)
                return footer
            }

            return UICollectionReusableView()
        }

        return dataSource
    }

    func addInitialSections(sections: [ArticleAsLivingDocViewModel.SectionHeader]) {
        var snapshot = NSDiffableDataSourceSnapshot<ArticleAsLivingDocViewModel.SectionHeader, ArticleAsLivingDocViewModel.TypedEvent>()
        snapshot.appendSections(sections)
        for section in sections {
            snapshot.appendItems(section.typedEvents, toSection: section)
        }
        dataSource.apply(snapshot, animatingDifferences: true) {
            self.scrollToInitialIndexPathIfNeeded()
        }
    }

    func scrollToInitialIndexPathIfNeeded() {
        guard let initialIndexPath = initialIndexPath else {
            return
        }

        collectionView.scrollToItem(at: initialIndexPath, at: .top, animated: true)
    }

    func appendSections(_ sections: [ArticleAsLivingDocViewModel.SectionHeader]) {
		guard let dayMonthNumberYearDateFormatter = DateFormatter.wmf_monthNameDayOfMonthNumberYear(), let isoDateFormatter = DateFormatter.wmf_iso8601() else {
			return
		}

        var currentSnapshot = dataSource.snapshot()
        var existingSections: [ArticleAsLivingDocViewModel.SectionHeader] = []

        for currentSection in currentSnapshot.sectionIdentifiers {
            for proposedSection in sections {
                if currentSection == proposedSection {
                    if
                        let lastCurrentEvent = currentSection.typedEvents.last, lastCurrentEvent.isSmall,
                        let firstProposedEvent = proposedSection.typedEvents.first, firstProposedEvent.isSmall {
                        // Collapse sequential small events if appending to the same section
                        let smallChanges = lastCurrentEvent.smallChanges + firstProposedEvent.smallChanges
                        let collapsedSmallEvent = ArticleAsLivingDocViewModel.TypedEvent.small(.init(smallChanges: smallChanges))

                        let proposedSectionCollapsed = proposedSection
                        let currentSectionCollapsed = currentSection

                        proposedSectionCollapsed.typedEvents.removeFirst()
                        currentSectionCollapsed.typedEvents.removeLast()

                        currentSnapshot.deleteItems([lastCurrentEvent])
                        currentSnapshot.appendItems([collapsedSmallEvent], toSection: currentSection)
                        currentSnapshot.appendItems(proposedSectionCollapsed.typedEvents, toSection: currentSection)
                        existingSections.append(proposedSectionCollapsed)
                        } else {
                        currentSnapshot.appendItems(proposedSection.typedEvents, toSection: currentSection)
                        existingSections.append(proposedSection)
                    }
                }
            }
        }

        // Collapse first proposed section into last current section if both only contain small events
        if
            let lastCurrentSection = currentSnapshot.sectionIdentifiers.last, lastCurrentSection.containsOnlySmallEvents,
            let firstProposedSection = sections.first, firstProposedSection.containsOnlySmallEvents {

            let smallChanges = lastCurrentSection.typedEvents.flatMap { $0.smallChanges } + firstProposedSection.typedEvents.flatMap { $0.smallChanges }
            let collapsedSmallEvent = ArticleAsLivingDocViewModel.Event.Small(smallChanges: smallChanges)
            let smallTypedEvent = ArticleAsLivingDocViewModel.TypedEvent.small(collapsedSmallEvent)

            let smallChangeDates = smallChanges.compactMap { isoDateFormatter.date(from: $0.timestampString) }
            var dateRange: DateInterval?
            if let minDate = smallChangeDates.min(), let maxDate = smallChangeDates.max() {
                dateRange = DateInterval(start: minDate, end: maxDate)
            }

            let collapsedSection = ArticleAsLivingDocViewModel.SectionHeader(timestamp: lastCurrentSection.timestamp, typedEvents: [smallTypedEvent], subtitleDateFormatter: dayMonthNumberYearDateFormatter, dateRange: dateRange)

            currentSnapshot.deleteItems(lastCurrentSection.typedEvents)
            currentSnapshot.insertSections([collapsedSection], afterSection: lastCurrentSection)
            currentSnapshot.deleteSections([lastCurrentSection])
            currentSnapshot.appendItems(collapsedSection.typedEvents, toSection: collapsedSection)
            existingSections.append(lastCurrentSection)
            existingSections.append(firstProposedSection)
        }

        // Appending remaining new sections to the snapshot
        for section in sections {
            if !existingSections.contains(section) {
                currentSnapshot.appendSections([section])
                currentSnapshot.appendItems(section.typedEvents, toSection: section)
            }
        }

        dataSource.apply(currentSnapshot, animatingDifferences: true)
    }
    
    private func setupNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: WMFLocalizedString("close-button", value: "Close", comment: "Close button used in navigation bar that closes out a presented modal screen."), style: .done, target: self, action: #selector(closeButtonPressed))
        
        navigationMode = .forceBar
        if let headerView = ArticleAsLivingDocHeaderView.wmf_viewFromClassNib() {
            self.headerView = headerView
            configureHeaderView(headerView)
            navigationBar.isBarHidingEnabled = false
            navigationBar.isUnderBarViewHidingEnabled = true
            navigationBar.isUnderBarFadingEnabled = false
            navigationBar.addUnderNavigationBarView(headerView)
            navigationBar.needsUnderBarHack = true
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
    
    private func configureHeaderView(_ headerView: ArticleAsLivingDocHeaderView) {
        
        guard let articleAsLivingDocViewModel = delegate?.articleAsLivingDocViewModel else {
            return
        }
        
        let headerText = self.headerText.uppercased(with: NSLocale.current)
        headerView.configure(headerText: headerText, titleText: articleTitle, summaryText: articleAsLivingDocViewModel.summaryText, editMetrics: editMetrics, theme: theme)
        headerView.apply(theme: theme)

        headerView.viewFullHistoryButton.addTarget(self, action: #selector(tappedViewFullHistoryButton), for: .touchUpInside)
    }

    override func apply(theme: Theme) {
        guard isViewLoaded else {
            return
        }

        super.apply(theme: theme)
        navigationItem.rightBarButtonItem?.tintColor = theme.colors.link
        navigationController?.navigationBar.barTintColor = theme.colors.cardButtonBackground
        headerView?.apply(theme: theme)
    }

    @objc func tappedViewFullHistoryButton() {
        self.dismiss(animated: true) {
            self.delegate?.showEditHistory(scrolledTo: nil)
        }
    }

    // MARK:- CollectionView functions
    override func collectionView(_ collectionView: UICollectionView, estimatedHeightForHeaderInSection section: Int, forColumnWidth columnWidth: CGFloat) -> ColumnarCollectionViewLayoutHeightEstimate {
        
        var estimate = ColumnarCollectionViewLayoutHeightEstimate(precalculated: false, height: 70)
        
        let section = self.dataSource.snapshot()
            .sectionIdentifiers[section]
        
        guard let sectionHeaderView = layoutManager.placeholder(forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: ArticleAsLivingDocSectionHeaderView.identifier) as? ArticleAsLivingDocSectionHeaderView else {
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
        case .large(let largeEvent):
            guard let largeEventCell = layoutManager.placeholder(forCellWithReuseIdentifier: ArticleAsLivingDocLargeEventCollectionViewCell.identifier) as? ArticleAsLivingDocLargeEventCollectionViewCell else {
                return estimate
            }
            
            
            largeEventCell.configure(with: largeEvent, theme: theme)
            cell = largeEventCell
        case .small(let smallEvent):
            guard let smallEventCell = layoutManager.placeholder(forCellWithReuseIdentifier: ArticleAsLivingDocSmallEventCollectionViewCell.identifier) as? ArticleAsLivingDocSmallEventCollectionViewCell else {
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
        
        guard let articleAsLivingDocViewModel = delegate?.articleAsLivingDocViewModel else {
            return
        }
        
        let numSections = dataSource.numberOfSections(in: collectionView)
        let numEvents = dataSource.collectionView(collectionView, numberOfItemsInSection: indexPath.section)
        
        if indexPath.section == numSections - 1 &&
            indexPath.item == numEvents - 1 {
            guard let nextRvStartId = articleAsLivingDocViewModel.nextRvStartId,
                  nextRvStartId != 0 else {
                return
            }
            
            delegate?.fetchNextPage(nextRvStartId: nextRvStartId, theme: theme)
        }
    }
    
    @objc func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    @objc func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionViewFooterButtonWasPressed(_ collectionViewFooter: CollectionViewFooter) {
        tappedViewFullHistoryButton()
    }
}

// MARK:- ArticleAsLivingDocHorizontallyScrollingCellDelegate
@available(iOS 13.0, *)
extension ArticleAsLivingDocViewController: ArticleAsLivingDocHorizontallyScrollingCellDelegate {
    func tappedLink(_ url: URL) {
        if url.absoluteString.removingPercentEncoding?.contains("/User:") == true {
            // User page, should open it in a modal
            let singlePageWebVC = SinglePageWebViewController(url: url, theme: theme, doesUseSimpleNavigationBar: true)
            let navController = WMFThemeableNavigationController(rootViewController: singlePageWebVC, theme: theme)
            navController.modalPresentationStyle = .pageSheet
            self.present(navController, animated: true, completion: nil)
        } else {
            if let linkURL = delegate?.articleURL.resolvingRelativeWikiHref(url.absoluteString) {
                switch Configuration.current.router.destination(for: linkURL) {
                case .externalLink(_):
                    // We're going to open link in default webbrowser, no need to dismiss current VC
                    self.delegate?.handleLink(with: url.absoluteString)
                default:
                    self.dismiss(animated: true) {
                        self.delegate?.handleLink(with: url.absoluteString)
                    }
                }
            } else {
                self.dismiss(animated: true) {
                    self.delegate?.handleLink(with: url.absoluteString)
                }
            }
        }
    }
}

@available(iOS 13.0, *)
extension ArticleAsLivingDocViewController: ArticleDetailsShowing {
    func showTalkPage() {
        self.dismiss(animated: true) {
            self.delegate?.showTalkPage()
        }
    }

    func goToHistory(scrolledTo revisionID: Int? = nil) {
        self.dismiss(animated: true) {
            self.delegate?.showEditHistory(scrolledTo: revisionID)
        }
    }
}
