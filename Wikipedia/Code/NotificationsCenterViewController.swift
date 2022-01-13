import UIKit
import WMF
import SwiftUI

@objc
final class NotificationsCenterViewController: ViewController {

    // MARK: - Properties

    var notificationsView: NotificationsCenterView {
        return view as! NotificationsCenterView
    }

    let viewModel: NotificationsCenterViewModel
    
    var didUpdateFiltersCallback: (() -> Void)?
    
    // MARK: Properties - Diffable Data Source
    typealias DataSource = UICollectionViewDiffableDataSource<NotificationsCenterSection, NotificationsCenterCellViewModel>
    typealias Snapshot = NSDiffableDataSourceSnapshot<NotificationsCenterSection, NotificationsCenterCellViewModel>
    private var dataSource: DataSource?
    private let snapshotUpdateQueue = DispatchQueue(label: "org.wikipedia.notificationscenter.snapshotUpdateQueue", qos: .userInteractive)

    // MARK: - Properties: Toolbar Buttons

    fileprivate lazy var typeFilterButton: IconBarButtonItem = IconBarButtonItem(image: viewModel.typeFilterButtonImage, style: .plain, target: self, action: #selector(userDidTapTypeFilterButton))
    fileprivate lazy var projectFilterButton: IconBarButtonItem = IconBarButtonItem(image: viewModel.projectFilterButtonImage, style: .plain, target: self, action: #selector(userDidTapProjectFilterButton))
    
    fileprivate var markButton: TextBarButtonItem!
    
    // = TextBarButtonItem(title: WMFLocalizedString("notifications-center-mark", value: "Mark", comment: "Button text in Notifications Center. Presents menu of options to mark selected notifications as read or unread."), target: nil, action: nil)
    fileprivate lazy var markAllAsReadButton: TextBarButtonItem = TextBarButtonItem(title: WMFLocalizedString("notifications-center-mark-all-as-read", value: "Mark all as read", comment: "Toolbar button text in Notifications Center that marks all user notifications as read on the server."), target: self, action: #selector(didTapMarkAllAsReadButton(_:)))
    fileprivate lazy var statusBarButton: StatusTextBarButtonItem = StatusTextBarButtonItem(text: "")

    // MARK: - Properties: Cell Swipe Actions

    fileprivate struct CellSwipeData {
        var activelyPannedCellIndexPath: IndexPath? // `IndexPath` of actively panned or open or opening cell
        var activelyPannedCellTranslationX: CGFloat? // current translation on x-axis of open or opening cell

        func activeCell(in collectionView: UICollectionView) -> NotificationsCenterCell? {
            guard let activelyPannedCellIndexPath = activelyPannedCellIndexPath else {
                return nil
            }

            return collectionView.cellForItem(at: activelyPannedCellIndexPath) as? NotificationsCenterCell
        }

        mutating func resetActiveData() {
            activelyPannedCellIndexPath = nil
            activelyPannedCellTranslationX = nil
        }
    }

    fileprivate struct CellSwipeData {
        var activelyPannedCellIndexPath: IndexPath? // IndexPath of actively panned or open cell
        var activelyPannedCellTranslationX: CGFloat? // translation on x-axis of open cell

        func activeCell(in collectionView: UICollectionView) -> NotificationsCenterCell? {
            guard let activelyPannedCellIndexPath = activelyPannedCellIndexPath else {
                return nil
            }

            return collectionView.cellForItem(at: activelyPannedCellIndexPath) as? NotificationsCenterCell
        }

        mutating func resetActiveData() {
            activelyPannedCellIndexPath = nil
            activelyPannedCellTranslationX = nil
        }
    }

    fileprivate lazy var cellPanGestureRecognizer = UIPanGestureRecognizer()
    fileprivate lazy var cellSwipeData = CellSwipeData()

    // MARK: - Lifecycle

    @objc
    init(theme: Theme, viewModel: NotificationsCenterViewModel) {
        self.viewModel = viewModel
        super.init(theme: theme)
        viewModel.delegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let notificationsCenterView = NotificationsCenterView(frame: UIScreen.main.bounds)
        notificationsCenterView.addSubheaderTapGestureRecognizer(target: self, action: #selector(tappedEmptyStateSubheader))
        view = notificationsCenterView
        scrollView = notificationsView.collectionView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        notificationsView.apply(theme: theme)

        title = CommonStrings.notificationsCenterTitle
        setupBarButtons()
        updateToolbarDisplayState(isEditing: false)
        
        notificationsView.collectionView.delegate = self
        setupDataSource()
        //TODO: Revisit and enable importing empty states in a delayed manner to avoid flashing.
        //configureEmptyState(isEmpty: true, subheaderText: NotificationsCenterView.EmptyOverlayStrings.checkingForNotifications)
        viewModel.fetchFirstPage()
        
        notificationsView.collectionView.addGestureRecognizer(cellPanGestureRecognizer)
        cellPanGestureRecognizer.addTarget(self, action: #selector(userDidPanCell(_:)))
        cellPanGestureRecognizer.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel.refreshNotifications(force: true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        closeActiveSwipePanelIfNecessary()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        closeSwipeActionsPanelIfNecessary()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            closeSwipeActionsPanelIfNecessary()
            notificationsView.collectionView.reloadData()
        }
    }

	// MARK: - Configuration

    fileprivate func setupBarButtons() {
        enableToolbar()
        setToolbarHidden(false, animated: false)

        navigationItem.rightBarButtonItem = editButtonItem
        isEditing = false
	}

	// MARK: - Public
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        notificationsView.collectionView.allowsMultipleSelection = editing

        viewModel.updateStateFromEditingModeChange(isEditing: isEditing)
        viewModel.isEditing = editing
        updateToolbarDisplayState(isEditing: isEditing)

        //might need this?
//        reconfigureCells()
//        deselectCells()
    }


    // MARK: - Themable

    override func apply(theme: Theme) {
        super.apply(theme: theme)

        notificationsView.apply(theme: theme)

        closeSwipeActionsPanelIfNecessary()
        notificationsView.collectionView.reloadData()

        typeFilterButton.apply(theme: theme)
        projectFilterButton.apply(theme: theme)
        markButton.apply(theme: theme)
        markAllAsReadButton.apply(theme: theme)
        statusBarButton.apply(theme: theme)
    }
    
}

//MARK: Private

private extension NotificationsCenterViewController {

    func setupDataSource() {
        dataSource = DataSource(
        collectionView: notificationsView.collectionView,
        cellProvider: { [weak self] (collectionView, indexPath, cellViewModel) ->
            NotificationsCenterCell? in

            guard let self = self,
                  let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NotificationsCenterCell.reuseIdentifier, for: indexPath) as? NotificationsCenterCell else {
                return nil
            }
            
            //from main
            //let isSelected = (collectionView.indexPathsForSelectedItems ?? []).contains(indexPath)
            //self.viewModel.updateCellDisplayStates(cellViewModels: [cellViewModel], isSelected: isSelected)
            cell.configure(viewModel: cellViewModel, theme: self.theme)
            cell.delegate = self
            return cell
        })
    }
    
    func applySnapshot(cellViewModels: [NotificationsCenterCellViewModel], animatingDifferences: Bool = true) {
        
        guard let dataSource = dataSource else {
            return
        }
        
        snapshotUpdateQueue.async {
            var snapshot = Snapshot()
            snapshot.appendSections([.main])
            snapshot.appendItems(cellViewModels)
            dataSource.apply(snapshot, animatingDifferences: animatingDifferences)
        }
    }
    
    func configureEmptyState(isEmpty: Bool, subheaderText: String = "", subheaderAttributedString: NSAttributedString? = nil) {
        notificationsView.updateEmptyOverlay(visible: isEmpty, headerText: NotificationsCenterView.EmptyOverlayStrings.noUnreadMessages, subheaderText: subheaderText, subheaderAttributedString: subheaderAttributedString)
        notificationsView.collectionView.isHidden = isEmpty
        navigationItem.rightBarButtonItems?.forEach { $0.isEnabled = !isEmpty }
        navigationItem.rightBarButtonItem?.isEnabled = !isEmpty
    }
    
    func selectedCellViewModels() -> [NotificationsCenterCellViewModel] {
        guard let selectedIndexPaths = notificationsView.collectionView.indexPathsForSelectedItems,
        let dataSource = dataSource else {
            return []
        }
        
        let selectedViewModels = selectedIndexPaths.compactMap { dataSource.itemIdentifier(for: $0) }
        return selectedViewModels
    }
    
    func deselectCells() {
        notificationsView.collectionView.indexPathsForSelectedItems?.forEach {
            notificationsView.collectionView.deselectItem(at: $0, animated: false)
        }

        closeSwipeActionsPanelIfNecessary()
    }
    
    /// Calls cell configure methods again without instantiating a new cell.
    func reconfigureCells() {
        
        if #available(iOS 15.0, *) {
            snapshotUpdateQueue.async {
                if var snapshot = self.dataSource?.snapshot() {
                    
                    let viewModelsToUpdate = snapshot.itemIdentifiers
                    snapshot.reconfigureItems(viewModelsToUpdate)
                    self.dataSource?.apply(snapshot, animatingDifferences: false)
                }
            }
        } else {
            
            let cellsToReconfigure = notificationsView.collectionView.visibleCells as? [NotificationsCenterCell] ?? []
            
            cellsToReconfigure.forEach { cell in
                cell.configure(theme: theme)
            }
        }
    }
    
    func markButtonForNumberOfSelectedMessages(numSelectedMessages: Int) -> UIBarButtonItem {
        let titleFormat = WMFLocalizedString("notifications-center-num-selected-messages-format", value:"{{PLURAL:%1$d|%1$d message|%1$d messages}}", comment:"Title for options menu when choosing \"Mark\" toolbar button in notifications center editing mode - %1$d is replaced with the number of selected notifications.")
        let title = String.localizedStringWithFormat(titleFormat, numSelectedMessages)
        let optionsMenu = UIMenu(title: title, children: [
            UIAction.init(title: CommonStrings.notificationsCenterMarkAsRead, image: UIImage(systemName: "envelope.open"), handler: { _ in
                let selectedCellViewModels = self.selectedCellViewModels()
                self.viewModel.markAsReadOrUnread(viewModels: selectedCellViewModels, shouldMarkRead: true)
                self.isEditing = false
            }),
            UIAction(title: CommonStrings.notificationsCenterMarkAsUnread, image: UIImage(systemName: "envelope"), handler: { _ in
                let selectedCellViewModels = self.selectedCellViewModels()
                self.viewModel.markAsReadOrUnread(viewModels: selectedCellViewModels, shouldMarkRead: false)
                self.isEditing = false
            })
        ])
        
        let markText = WMFLocalizedString("notifications-center-mark", value: "Mark", comment: "Button text in Notifications Center. Presents menu of options to mark selected notifications as read or unread.")
        if #available(iOS 14.0, *) {
            return UIBarButtonItem(title: markText, image: nil, primaryAction: nil, menu: optionsMenu)
        } else {
            return UIBarButtonItem(title: markText, style: .plain, target: self, action: #selector(didTapMarkButtonIOS13(_:)))
        }
        return markButton
    }
    
    @objc func didTapMarkButtonIOS13(_ sender: UIBarButtonItem) {
        
        var numberSelected: Int?
        switch viewModel.state {
        case .data(_, let dataState):
            switch dataState {
            case .editing(let editingState):
                switch editingState {
                case .oneOrMoreSelected(let num):
                    numberSelected = num
                default:
                    assertionFailure("Unexpected view model state, should be in oneOrMoreSelected editing state.")
                    return
                }
            default:
                assertionFailure("Unexpected view model state, should be in oneOrMoreSelected editing state.")
                return
            }
        default:
            assertionFailure("Unexpected view model state, should be in oneOrMoreSelected editing state.")
            return
        }
        
        guard let numberSelected = numberSelected else {
            return
        }
        
        let titleFormat = WMFLocalizedString("notifications-center-num-selected-messages-format", value:"{{PLURAL:%1$d|%1$d message|%1$d messages}}", comment:"Title for options menu when choosing \"Mark\" toolbar button in notifications center editing mode - %1$d is replaced with the number of selected notifications.")
        let title = String.localizedStringWithFormat(titleFormat, numberSelected)

        let alertController = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
        let action1 = UIAlertAction(title: CommonStrings.notificationsCenterMarkAsRead, style: .default) { _ in
            let selectedCellViewModels = self.selectedCellViewModels()
            self.viewModel.markAsReadOrUnread(viewModels: selectedCellViewModels, shouldMarkRead: true)
            self.isEditing = false
        }
        
        let action2 = UIAlertAction(title: CommonStrings.notificationsCenterMarkAsUnread, style: .default) { _ in
            let selectedCellViewModels = self.selectedCellViewModels()
            self.viewModel.markAsReadOrUnread(viewModels: selectedCellViewModels, shouldMarkRead: false)
            self.isEditing = false
        }
        
        let cancelAction = UIAlertAction(title: CommonStrings.cancelActionTitle, style: .cancel, handler: nil)
        alertController.addAction(action1)
        alertController.addAction(action2)
        alertController.addAction(cancelAction)
        
        if let popoverController = alertController.popoverPresentationController {
            popoverController.barButtonItem = sender
        }
        
        present(alertController, animated: true, completion: nil)
    }
    
    @objc func didTapMarkAllAsReadButton(_ sender: UIBarButtonItem) {
        
        var numberOfUnreadNotifications: Int?
        switch viewModel.state {
        case .data(_, let dataState):
            switch dataState {
            case .editing(let editingState):
                switch editingState {
                case .noneSelected(let num):
                    numberOfUnreadNotifications = num
                default:
                    assertionFailure("Unexpected view model state, should be in oneOrMoreSelected editing state.")
                    return
                }
            default:
                assertionFailure("Unexpected view model state, should be in oneOrMoreSelected editing state.")
                return
            }
        default:
            assertionFailure("Unexpected view model state, should be in oneOrMoreSelected editing state.")
            return
        }
        
        let titleText: String
        if let numberOfUnreadNotifications = numberOfUnreadNotifications {
            let titleFormat = WMFLocalizedString("notifications-center-mark-all-as-read-confirmation-format", value:"Are you sure that you want to mark all {{PLURAL:%1$d|%1$d message|%1$d messages}} of your notifications as read? Your notifications will be marked as read on all of your devices.", comment:"Title format for confirmation alert when choosing \"Mark all as read\" toolbar button in notifications center editing mode - %1$d is replaced with the number of unread notifications on the server.")
            titleText = String.localizedStringWithFormat(titleFormat, numberOfUnreadNotifications)
        } else {
            titleText = WMFLocalizedString("notifications-center-mark-all-as-read-missing-number", value:"Are you sure that you want to mark all of your notifications as read? Your notifications will be marked as read on all of your devices.", comment:"Title for confirmation alert when choosing \"Mark all as read\" toolbar button in notifications center editing mode, when there was an issue with pulling the count of unread notifications on the server.")
        }
        
        let alertController = UIAlertController(title: titleText, message: nil, preferredStyle: .actionSheet)
        let action = UIAlertAction(title: CommonStrings.notificationsCenterMarkAsRead, style: .destructive) { _ in
            self.viewModel.markAllAsRead()
            self.isEditing = false
        }
        let cancelAction = UIAlertAction(title: CommonStrings.cancelActionTitle, style: .cancel, handler: nil)
        alertController.addAction(action)
        alertController.addAction(cancelAction)
        
        if let popoverController = alertController.popoverPresentationController {
            popoverController.barButtonItem = sender
        }
        
        present(alertController, animated: true, completion: nil)
    }
    
    func presentFiltersViewController() {
        
        let filtersViewModel = NotificationsCenterFiltersViewModel(remoteNotificationsController: viewModel.remoteNotificationsController, theme: theme)
        
        guard let filtersViewModel = filtersViewModel else {
            return
        }
        
        let filterView = NotificationsCenterFilterView(viewModel: filtersViewModel) { [weak self] in
                
                self?.dismiss(animated: true)
        }
        
        let hostingVC = UIHostingController(rootView: filterView)
        
        let nc = DisappearingCallbackNavigationController(rootViewController: hostingVC, theme: self.theme)
        nc.willDisappearCallback = { [weak self] in
            guard let self = self else {
                return
            }
            
            self.viewModel.resetAndRefreshData()
            self.viewModel.filtersToolbarViewModelNeedsReload()
            self.scrollToTop()
        }
        
        nc.modalPresentationStyle = .pageSheet
        self.present(nc, animated: true, completion: nil)
    }
    
    func presentInboxViewController() {
        
        viewModel.remoteNotificationsController.allInboxProjects(languageLinkController: viewModel.languageLinkController) { [weak self] projects in
            
            guard let self = self else {
                return
            }
            
            guard let inboxViewModel = NotificationsCenterInboxViewModel(remoteNotificationsController: self.viewModel.remoteNotificationsController, allInboxProjects: Set(projects), theme: self.theme) else {
                return
            }
            
            let inboxView = NotificationsCenterInboxView(viewModel: inboxViewModel) { [weak self] in
            
                self?.dismiss(animated: true)
            }

            let hostingVC = UIHostingController(rootView: inboxView)
            
            let nc = DisappearingCallbackNavigationController(rootViewController: hostingVC, theme: self.theme)
            nc.willDisappearCallback = { [weak self] in
                guard let self = self else {
                    return
                }
                
                self.viewModel.resetAndRefreshData()
                self.viewModel.filtersToolbarViewModelNeedsReload()
                self.scrollToTop()
            }
            
            nc.modalPresentationStyle = .pageSheet
            self.present(nc, animated: true, completion: nil)
            
        }
    }
    
//    func filterButtonImageForFiltersEnabled(_ filtersEnabled: Bool) -> UIImage? {
//        if #available(iOS 15.0, *) {
//            return UIImage(systemName: filterButtonNameForFiltersEnabled(filtersEnabled))
//        } else {
//            return UIImage(named: filterButtonNameForFiltersEnabled(filtersEnabled))
//        }
//    }
//
//    func inboxButtonImageForFiltersEnabled(_ filtersEnabled: Bool) -> UIImage? {
//            return UIImage(systemName: inboxButtonNameForFiltersEnabled(filtersEnabled))
//    }
//
//    func filterButtonNameForFiltersEnabled(_ filtersEnabled: Bool) -> String {
//        return filtersEnabled ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle"
//    }
//
//    func inboxButtonNameForFiltersEnabled(_ filtersEnabled: Bool) -> String {
//        return filtersEnabled ? "tray.fill" : "tray.2"
//    }
    
    func filterEmptyStateSubtitleAttributedStringForFilterViewModel(_ filterViewModel: NotificationsCenterViewModel.FiltersToolbarViewModel) -> NSAttributedString? {
            let filtersLinkFormat = WMFLocalizedString("notifications-center-empty-state-num-filters", value:"{{PLURAL:%1$d|%1$d filter|%1$d filters}}", comment:"Portion of empty state subtitle showing number of filters the user has set in notifications center - %1$d is replaced with the number filters.")
            let filtersSubtitleFormat = WMFLocalizedString("notifications-center-empty-state-filters-subtitle", value:"Modify %1$@ to see more messages", comment:"Format of empty state subtitle when the user has filters on - %1$@ is replaced with a string representing the number of filters the user has set.")
            let filtersLink = String.localizedStringWithFormat(filtersLinkFormat, filterViewModel.countOfTypeFilters)
            let filtersSubtitle = String.localizedStringWithFormat(filtersSubtitleFormat, filtersLink)

            let rangeOfFiltersLink = (filtersSubtitle as NSString).range(of: filtersLink)

            let font = UIFont.wmf_font(.subheadline, compatibleWithTraitCollection: traitCollection)
            let attributes: [NSAttributedString.Key: Any] = [
                NSAttributedString.Key.font: font,
                NSAttributedString.Key.foregroundColor: theme.colors.secondaryText
                ]
            let linkAttributes = [
                NSAttributedString.Key.font: font,
                NSAttributedString.Key.foregroundColor: theme.colors.link
                ]
        
            let attributedString = NSMutableAttributedString(string: filtersSubtitle)
            attributedString.setAttributes(attributes, range: NSRange(location: 0, length: filtersSubtitle.count) )
            if rangeOfFiltersLink.location != NSNotFound {
                attributedString.setAttributes(linkAttributes, range: rangeOfFiltersLink)
            }

            return attributedString.copy() as? NSAttributedString
    }
    
    @objc func tappedEmptyStateSubheader() {
        presentFiltersViewController()
    }
}

// MARK: - NotificationCenterViewModelDelegate

extension NotificationsCenterViewController: NotificationCenterViewModelDelegate {
    
    func stateDidChange(_ newState: NotificationsCenterViewModel.State) {
        updateToolbarDisplayState(isEditing: newState.isEditing)
        switch newState {
        case .empty(let emptyState):
            switch emptyState {
            case .loading:
                configureEmptyState(isEmpty: true, subheaderText: NotificationsCenterView.EmptyOverlayStrings.checkingForNotifications)
            case .noData, .inboxFilters:
                configureEmptyState(isEmpty: true)
            case .filters:
                if viewModel.filtersToolbarViewModel.countOfTypeFilters == 0 {
                    configureEmptyState(isEmpty: true)
                } else {
                    configureEmptyState(isEmpty: true, subheaderAttributedString: filterEmptyStateSubtitleAttributedStringForFilterViewModel(viewModel.filtersToolbarViewModel))
                }
            case .initial:
                configureEmptyState(isEmpty: false)
            case .subscriptions:
                //TODO: subscriptions text
                configureEmptyState(isEmpty: true)
            }
        case .data(let cellViewModels, let dataState):
            configureEmptyState(isEmpty: false)
            applySnapshot(cellViewModels: cellViewModels, animatingDifferences: true)
            reconfigureCells()
            
            switch dataState {
            case .nonEditing:
                deselectCells()
            case .editing(let editingState):
                switch editingState {
                case .noneSelected:
                    deselectCells()
                case .oneOrMoreSelected:
                    break
                }
            }
        }
    }
    
    var numCellsSelected: Int {
        return notificationsView.collectionView.indexPathsForSelectedItems?.count ?? 0
    }
    
//    func filtersToolbarViewModelDidChange(_ newViewModel: NotificationsCenterViewModel.FiltersToolbarViewModel) {
//        filterButton.image = filterButtonImageForFiltersEnabled(newViewModel.areFiltersEnabled)
//        inboxButton.image = inboxButtonImageForFiltersEnabled(newViewModel.areInboxFiltersEnabled)
//    }
    
    func cellViewModelsDidChange(cellViewModels: [NotificationsCenterCellViewModel]) {
        configureEmptyState(isEmpty: cellViewModels.isEmpty)
        applySnapshot(cellViewModels: cellViewModels, animatingDifferences: true)
    }

    func toolbarContentDidUpdate() {
        refreshToolbarContent()
    }
}

extension NotificationsCenterViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        guard let dataSource = dataSource else {
            return
        }
        
        let count = dataSource.collectionView(collectionView, numberOfItemsInSection: indexPath.section)
        let isLast = indexPath.row == count - 1
        if isLast {
            viewModel.fetchNextPage()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldBeginMultipleSelectionInteractionAt indexPath: IndexPath) -> Bool {
        if viewModel.state.isEditing {
            return true
        }
        
        return false
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        guard let cellViewModel = dataSource?.itemIdentifier(for: indexPath) else {
            return
        }

        if !viewModel.state.isEditing {
            
            collectionView.deselectItem(at: indexPath, animated: true)

            if let primaryURL = cellViewModel.primaryURL(for: viewModel.configuration) {
                navigate(to: primaryURL)
                if !cellViewModel.isRead {
                    viewModel.markAsReadOrUnread(viewModels: [cellViewModel], shouldMarkRead: true)
                }
            }
        } else {
            viewModel.updateCellDisplayStates(cellViewModels: [cellViewModel], isSelected: true)
            reconfigureCells()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        
        guard let cellViewModel = dataSource?.itemIdentifier(for: indexPath) else {
            return
        }

        viewModel.updateCellDisplayStates(cellViewModels: [cellViewModel], isSelected: false)
        reconfigureCells()
    }
}

// MARK: - Cell Swipe Actions

@objc extension NotificationsCenterViewController: UIGestureRecognizerDelegate {

    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        super.scrollViewWillBeginDragging(scrollView)
        closeSwipeActionsPanelIfNecessary()
    }

    func closeSwipeActionsPanelIfNecessary() {
        if let activeCell = cellSwipeData.activeCell(in: notificationsView.collectionView) {
            animateSwipePanel(open: false, for: activeCell)
            cellSwipeData.resetActiveData()
        }
    }

    /// Only allow cell pan gesture if user's horizontal cell panning behavior seems intentional
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == cellPanGestureRecognizer {
            let panVelocity = cellPanGestureRecognizer.velocity(in: notificationsView.collectionView)
            if abs(panVelocity.x) > abs(panVelocity.y) {
                return true
            }
        }

        return false
    }

    fileprivate func animateSwipePanel(open: Bool, for cell: NotificationsCenterCell) {
        let isRTL = UIApplication.shared.wmf_isRTL
        UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: [.allowUserInteraction, .beginFromCurrentState], animations: {
            if open {
                let translationX = isRTL ? cell.swipeActionButtonStack.frame.size.width : -cell.swipeActionButtonStack.frame.size.width
                cell.foregroundContentContainer.transform = CGAffineTransform.identity.translatedBy(x: translationX, y: 0)
            } else {
                cell.foregroundContentContainer.transform = CGAffineTransform.identity
            }
        }, completion: nil)
    }

    @objc fileprivate func userDidPanCell(_ gestureRecognizer: UIPanGestureRecognizer) {
        let isRTL = UIApplication.shared.wmf_isRTL
        let triggerVelocity: CGFloat = 400
        let swipeEdgeBuffer = NotificationsCenterCell.swipeEdgeBuffer
        let touchPosition = gestureRecognizer.location(in: notificationsView.collectionView)
        let translationX = gestureRecognizer.translation(in: notificationsView.collectionView).x
        let velocityX = gestureRecognizer.velocity(in: notificationsView.collectionView).x

        switch gestureRecognizer.state {
        case .began:
            guard let touchCellIndexPath = notificationsView.collectionView.indexPathForItem(at: touchPosition), let cell = notificationsView.collectionView.cellForItem(at: touchCellIndexPath) as? NotificationsCenterCell else {
                gestureRecognizer.state = .ended
                break
            }

            // If the new touch is on a new cell, and a current cell is already open, close it first
            if let currentlyActiveIndexPath = cellSwipeData.activelyPannedCellIndexPath, currentlyActiveIndexPath != touchCellIndexPath, let cell = notificationsView.collectionView.cellForItem(at: currentlyActiveIndexPath) as? NotificationsCenterCell {
                animateSwipePanel(open: false, for: cell)
            }

            if cell.foregroundContentContainer.transform.isIdentity {
                cellSwipeData.activelyPannedCellTranslationX = nil
                if velocityX > 0 {
                    gestureRecognizer.state = .ended
                    break
                }
            } else {
                cellSwipeData.activelyPannedCellTranslationX = isRTL ? -cell.foregroundContentContainer.transform.tx : cell.foregroundContentContainer.transform.tx
            }

            cellSwipeData.activelyPannedCellIndexPath = touchCellIndexPath
        case .changed:
            guard let cell = cellSwipeData.activeCell(in: notificationsView.collectionView) else {
                break
            }

            let swipeStackWidth = cell.swipeActionButtonStack.frame.size.width
            var totalTranslationX = translationX + (cellSwipeData.activelyPannedCellTranslationX ?? 0)

            let maximumTranslationX = swipeStackWidth + swipeEdgeBuffer

            // The user is trying to pan too far left
            if totalTranslationX < -maximumTranslationX {
                totalTranslationX = -maximumTranslationX - log(abs(translationX))
            }

            // Extends too far right
            if totalTranslationX > swipeEdgeBuffer {
                totalTranslationX = swipeEdgeBuffer + log(abs(translationX))
            }

            let finalTranslationX = isRTL ? -totalTranslationX : totalTranslationX
            cell.foregroundContentContainer.transform = CGAffineTransform(translationX: finalTranslationX, y: 0)
        case .ended:
            guard let cell = cellSwipeData.activeCell(in: notificationsView.collectionView) else {
                break
            }

            var shouldOpenSwipePanel: Bool
            
            let currentCellTranslationX = isRTL ? -cell.foregroundContentContainer.transform.tx : cell.foregroundContentContainer.transform.tx

            if currentCellTranslationX > 0 {
                shouldOpenSwipePanel = false
            } else {
                if velocityX < -triggerVelocity {
                    shouldOpenSwipePanel = true
                } else {
                    shouldOpenSwipePanel = abs(currentCellTranslationX) > (0.5 * cell.swipeActionButtonStack.frame.size.width)
                }
            }

            if velocityX > triggerVelocity {
                shouldOpenSwipePanel = false
            }

            if !shouldOpenSwipePanel {
                cellSwipeData.resetActiveData()
            }

            animateSwipePanel(open: shouldOpenSwipePanel, for: cell)
        default:
            break
        }
    }

}

//MARK: NotificationCenterCellDelegate

extension NotificationsCenterViewController: NotificationsCenterCellDelegate {

    func userDidTapMoreActionForCell(_ cell: NotificationsCenterCell) {
        guard let cellViewModel = cell.viewModel else  {
            return
        }

        let sheetActions = cellViewModel.sheetActions(for: viewModel.configuration)
        guard !sheetActions.isEmpty else {
            return
        }

        let alertController = UIAlertController(title: cellViewModel.headerText, message: cellViewModel.bodyText ?? cellViewModel.subheaderText, preferredStyle: .actionSheet)

        sheetActions.forEach { action in
            let alertAction: UIAlertAction
            switch action {
            case .markAsReadOrUnread(let data):
                alertAction = UIAlertAction(title: data.text, style: .default, handler: { alertAction in
                    let shouldMarkRead = cellViewModel.isRead ? false : true
                    self.viewModel.markAsReadOrUnread(viewModels: [cellViewModel], shouldMarkRead: shouldMarkRead)
                    self.closeSwipeActionsPanelIfNecessary()
                })
            case .notificationSubscriptionSettings(let data):
                alertAction = UIAlertAction(title: data.text, style: .default, handler: { alertAction in
                    let userActivity = NSUserActivity.wmf_notificationSettings()
                    NSUserActivity.wmf_navigate(to: userActivity)
                    if !cellViewModel.isRead {
                        self.viewModel.markAsReadOrUnread(viewModels: [cellViewModel], shouldMarkRead: true)
                    }
                })
            case .custom(let data):
                alertAction = UIAlertAction(title: data.text, style: .default, handler: { alertAction in
                    let url = data.url
                    self.navigate(to: url)
                    if !cellViewModel.isRead {
                        self.viewModel.markAsReadOrUnread(viewModels: [cellViewModel], shouldMarkRead: true)
                    }
                })
            }

            alertController.addAction(alertAction)
        }

        let cancelAction = UIAlertAction(title: CommonStrings.cancelActionTitle, style: .cancel)
        alertController.addAction(cancelAction)

        if let popoverController = alertController.popoverPresentationController {
            if let activeCell = cellSwipeData.activeCell(in: notificationsView.collectionView) {
                let sourceView = activeCell.swipeMoreStack
                popoverController.sourceView = sourceView
                popoverController.sourceRect = CGRect(x: sourceView.bounds.midX, y: sourceView.bounds.midY, width: 0, height: 0)
            } else {
                popoverController.sourceView = cell
                popoverController.sourceRect = CGRect(x: cell.bounds.midX, y: cell.bounds.midY, width: 0, height: 0)

            }
        }

        present(alertController, animated: true, completion: nil)
    }

    func userDidTapMarkAsReadUnreadActionForCell(_ cell: NotificationsCenterCell) {
        guard let cellViewModel = cell.viewModel else {
            return
        }

        closeSwipeActionsPanelIfNecessary()
        viewModel.markAsReadOrUnread(viewModels: [cellViewModel], shouldMarkRead: !cellViewModel.isRead)
    }
    
}

// MARK: - Toolbar

extension NotificationsCenterViewController {

    /// Update the bar buttons displayed in the toolbar based on the editing state
    fileprivate func updateToolbarDisplayState(isEditing: Bool) {
        markButton = markButtonForNumberOfSelectedMessages(numSelectedMessages: numCellsSelected)
        if isEditing {
            toolbar.items = [markButton, .flexibleSpaceToolbar(), markAllAsReadButton]
        } else {
            toolbar.items = [typeFilterButton, .flexibleSpaceToolbar(), statusBarButton, .flexibleSpaceToolbar(), projectFilterButton]
        }

        refreshToolbarContent()
    }

    /// Refresh the images and strings used in the toolbar, regardless of editing state
    @objc fileprivate func refreshToolbarContent() {
        typeFilterButton.image = viewModel.typeFilterButtonImage
        projectFilterButton.image = viewModel.projectFilterButtonImage
        statusBarButton.label.text = viewModel.statusBarText
    }

    @objc fileprivate func userDidTapProjectFilterButton() {
        presentFiltersViewController()
    }

    @objc fileprivate func userDidTapTypeFilterButton() {
        presentInboxViewController()
    }
}
