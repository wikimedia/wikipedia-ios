import UIKit
import WMF

@objc
final class NotificationsCenterViewController: ViewController {

    // MARK: - Properties

    var notificationsView: NotificationsCenterView {
        return view as! NotificationsCenterView
    }

    let viewModel: NotificationsCenterViewModel
    
    lazy var markAllAsReadButton: UIBarButtonItem = {
        let markAllAsReadText = WMFLocalizedString("notifications-center-mark-all-as-read", value: "Mark all as read", comment: "Toolbar button text in Notifications Center that marks all user notifications as read on the server.")
        return UIBarButtonItem(title: markAllAsReadText, style: .plain, target: self, action: #selector(didTapMarkAllAsReadButton(_:)))
    }()
    
    // MARK: Properties - Diffable Data Source
    typealias DataSource = UICollectionViewDiffableDataSource<NotificationsCenterSection, NotificationsCenterCellViewModel>
    typealias Snapshot = NSDiffableDataSourceSnapshot<NotificationsCenterSection, NotificationsCenterCellViewModel>
    private var dataSource: DataSource?
    private let snapshotUpdateQueue = DispatchQueue(label: "org.wikipedia.notificationscenter.snapshotUpdateQueue", qos: .userInteractive)

    // MARK: - Properties - Cell Swipe Actions

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
        view = NotificationsCenterView(frame: UIScreen.main.bounds)
        scrollView = notificationsView.collectionView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        notificationsView.apply(theme: theme)

        title = CommonStrings.notificationsCenterTitle
        setupBarButtons()
        
        notificationsView.collectionView.delegate = self
        setupDataSource()
        viewModel.fetchFirstPage()
        
        notificationsView.collectionView.addGestureRecognizer(cellPanGestureRecognizer)
        cellPanGestureRecognizer.addTarget(self, action: #selector(userDidPanCell(_:)))
        cellPanGestureRecognizer.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel.refreshNotifications()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        closeActiveSwipePanelIfNecessary()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            notificationsView.collectionView.reloadData()
        }
    }

	// MARK: - Configuration

    fileprivate func setupBarButtons() {
        enableToolbar()
        setToolbarHidden(false, animated: false)

		navigationItem.rightBarButtonItem = editButtonItem
	}

	// MARK: - Public
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        notificationsView.collectionView.allowsMultipleSelection = editing
        viewModel.updateStateFromEditingModeChange(isEditing: isEditing)
    }


    // MARK: - Themable

    override func apply(theme: Theme) {
        super.apply(theme: theme)

        notificationsView.apply(theme: theme)
        notificationsView.collectionView.reloadData()
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
    
    func configureEmptyState(isEmpty: Bool, subheaderText: String = "") {
        notificationsView.updateEmptyOverlay(visible: isEmpty, headerText: NotificationsCenterView.EmptyOverlayStrings.noUnreadMessages, subheaderText: subheaderText)
        navigationItem.rightBarButtonItems?.forEach { $0.isEnabled = !isEmpty }
        navigationItem.rightBarButtonItem?.isEnabled = !isEmpty
    }
    
    /// TODO: Use this to determine selected view models when in editing mode. We will send to NotificationsCenterViewModel for marking as read/unread when
    /// the associated toolbar button is pressed.
    /// - Returns:View models that represent cells in the selected state.
    func selectedCellViewModels() -> [NotificationsCenterCellViewModel] {
        guard let selectedIndexPaths = notificationsView.collectionView.indexPathsForSelectedItems,
        let dataSource = dataSource else {
            return []
        }
        
        let selectedViewModels = selectedIndexPaths.compactMap { dataSource.itemIdentifier(for: $0) }
        return selectedViewModels
    }
    
    func deselectCells() {
        closeActiveSwipePanelIfNecessary()
        notificationsView.collectionView.indexPathsForSelectedItems?.forEach {
            notificationsView.collectionView.deselectItem(at: $0, animated: false)
        }
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
    
    func updateToolbar(for state: NotificationsCenterViewModel.State) {
        switch state {
        case .data(_, let dataState):
            switch dataState {
            case .editing(let dataEditingState):
                
                let markButton: UIBarButtonItem
                let markAllAsReadButton = self.markAllAsReadButton
                switch dataEditingState {
                case .noneSelected:
                    markButton = markButtonForNumberOfSelectedMessages(numSelectedMessages: 0)
                    markButton.isEnabled = false
                    markAllAsReadButton.isEnabled = true
                case .oneOrMoreSelected(let numSelected):
                    markButton = markButtonForNumberOfSelectedMessages(numSelectedMessages: numSelected)
                    markButton.isEnabled = true
                    markAllAsReadButton.isEnabled = false
                }
                
                toolbar.items = [
                    markButton,
                    UIBarButtonItem.flexibleSpaceToolbar(),
                    markAllAsReadButton
                ]
            case .nonEditing:
                toolbar.items = []
            }
        case .empty:
            toolbar.items = []
        }
    }
    
    func markButtonForNumberOfSelectedMessages(numSelectedMessages: Int) -> UIBarButtonItem {
        let titleFormat = WMFLocalizedString("notifications-center-num-selected-messages-format", value:"{{PLURAL:%1$d|%1$d message|%1$d messages}}", comment:"Title for options menu when choosing \"Mark\" toolbar button in notifications center editing mode - %1$@ is replaced with the number of selected notifications.")
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
        let markButton: UIBarButtonItem
        let markText = WMFLocalizedString("notifications-center-mark", value: "Mark", comment: "Button text in Notifications Center. Presents menu of options to mark selected notifications as read or unread.")
        if #available(iOS 14.0, *) {
            markButton = UIBarButtonItem(title: markText, image: nil, primaryAction: nil, menu: optionsMenu)
        } else {
            markButton = UIBarButtonItem(title: markText, style: .plain, target: self, action: #selector(didTapMarkButtonIOS13(_:)))
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
        
        let titleFormat = WMFLocalizedString("notifications-center-num-selected-messages-format", value:"{{PLURAL:%1$d|%1$d message|%1$d messages}}", comment:"Title for options menu when choosing \"Mark\" toolbar button in notifications center editing mode - %1$@ is replaced with the number of selected notifications.")
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
            let titleFormat = WMFLocalizedString("notifications-center-mark-all-as-read-confirmation-format", value:"Are you sure that you want to mark all {{PLURAL:%1$d|%1$d message|%1$d messages}} of your notifications as read? Your notifications will be marked as read on all of your devices.", comment:"Title format for confirmation alert when choosing \"Mark all as read\" toolbar button in notifications center editing mode - %1$@ is replaced with the number of unread notifications on the server.")
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
}

// MARK: - NotificationCenterViewModelDelegate

extension NotificationsCenterViewController: NotificationCenterViewModelDelegate {
    
    func stateDidChange(_ newState: NotificationsCenterViewModel.State) {
        updateToolbar(for: newState)
        switch newState {
        case .empty(let emptyState):
            switch emptyState {
            case .loading:
                print("empty loading")
                configureEmptyState(isEmpty: true, subheaderText: NotificationsCenterView.EmptyOverlayStrings.checkingForNotifications)
            case .noData:
                print("empty nodata")
                configureEmptyState(isEmpty: true)
            case .filters:
                print("empty filters")
                //TODO: filters text
                configureEmptyState(isEmpty: true)
            case .initial:
                print("empty initial")
                configureEmptyState(isEmpty: false)
            case .subscriptions:
                print("empty subscriptions")
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
        
        if cellSwipeData.activeCell(in: collectionView) != nil {
            closeActiveSwipePanelIfNecessary()
            return
        }
        
        let callbackForReload = viewModel.state.isEditing
        viewModel.updateCellSelectionState(cellViewModel: cellViewModel, isSelected: true, callbackForReload: callbackForReload)

        if !viewModel.state.isEditing {

            if let primaryURL = cellViewModel.primaryURL(for: viewModel.configuration) {
                navigate(to: primaryURL)
            }
            
            viewModel.updateCellSelectionState(cellViewModel: cellViewModel, isSelected: false)
            notificationsView.collectionView.deselectItem(at: indexPath, animated: true)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        
        guard let cellViewModel = dataSource?.itemIdentifier(for: indexPath) else {
            return
        }
        
        let callbackForReload = viewModel.state.isEditing
        viewModel.updateCellSelectionState(cellViewModel: cellViewModel, isSelected: false, callbackForReload: callbackForReload)
    }
}

// MARK: - Cell Swipe Actions

@objc extension NotificationsCenterViewController: UIGestureRecognizerDelegate {

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

    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        super.scrollViewWillBeginDragging(scrollView)
        closeActiveSwipePanelIfNecessary()
    }

    func closeActiveSwipePanelIfNecessary() {
        if let activeCell = cellSwipeData.activeCell(in: notificationsView.collectionView) {
            animateSwipePanel(open: false, for: activeCell)
            cellSwipeData.resetActiveData()
        }
    }

    fileprivate func animateSwipePanel(open: Bool, for cell: NotificationsCenterCell) {
       UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: [.allowUserInteraction, .beginFromCurrentState], animations: {
           if open {
               cell.foregroundContentContainer.transform = CGAffineTransform.identity.translatedBy(x: -cell.swipeActionButtonStack.frame.size.width, y: 0)
           } else {
               cell.foregroundContentContainer.transform = CGAffineTransform.identity
           }
       }, completion: nil)
    }

    @objc fileprivate func userDidPanCell(_ gestureRecognizer: UIPanGestureRecognizer) {
        // TODO let isRTL = UIApplication.shared.wmf_isRTL
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
                cellSwipeData.activelyPannedCellTranslationX = cell.foregroundContentContainer.transform.tx
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

            cell.foregroundContentContainer.transform = CGAffineTransform(translationX: totalTranslationX, y: 0)
        case .ended:
            guard let cell = cellSwipeData.activeCell(in: notificationsView.collectionView) else {
                break
            }

            var shouldOpenSwipePanel: Bool
            let currentCellTranslationX = cell.foregroundContentContainer.transform.tx

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

    func userDidTapSecondaryActionForViewModel(_ cellViewModel: NotificationsCenterCellViewModel) {
        guard cellSwipeData.activeCell(in: notificationsView.collectionView) == nil else {
            closeActiveSwipePanelIfNecessary()
            return
        }

        guard let url = cellViewModel.secondaryURL(for: viewModel.configuration) else {
            return
        }

        navigate(to: url)
    }

    func userDidTapMoreActionForCell(_ cell: NotificationsCenterCell) {
        guard let cellViewModel = cell.viewModel else {
            return
        }

        closeActiveSwipePanelIfNecessary()

        let sheetActions = cellViewModel.sheetActions(for: viewModel.configuration)
        guard !sheetActions.isEmpty else {
            return
        }

        let alertController = UIAlertController(title: cellViewModel.headerText, message: cellViewModel.bodyText, preferredStyle: .actionSheet)

        sheetActions.forEach { action in

            let alertAction: UIAlertAction
            switch action {
            case .markAsReadOrUnread(let data):
                alertAction = UIAlertAction(title: data.text, style: .default, handler: { alertAction in
                    let shouldMarkRead = cellViewModel.isRead ? false : true
                    self.viewModel.markAsReadOrUnread(viewModels: [cellViewModel], shouldMarkRead: shouldMarkRead)
                })
            case .notificationSubscriptionSettings(let data):
                alertAction = UIAlertAction(title: data.text, style: .default, handler: { alertAction in
                    let userActivity = NSUserActivity.wmf_notificationSettings()
                    NSUserActivity.wmf_navigate(to: userActivity)
                })
            case .custom(let data):
                alertAction = UIAlertAction(title: data.text, style: .default, handler: { alertAction in
                    let url = data.url
                    self.navigate(to: url)
                })
            }

            alertController.addAction(alertAction)
        }

        let cancelAction = UIAlertAction(title: CommonStrings.cancelActionTitle, style: .cancel)
        alertController.addAction(cancelAction)

        if let popoverController = alertController.popoverPresentationController {
            popoverController.sourceView = cell
            popoverController.sourceRect = CGRect(x: cell.bounds.midX, y: cell.bounds.midY, width: 0, height: 0)
        }

        present(alertController, animated: true, completion: nil)
    }

    func userDidTapMarkAsReadUnreadActionForCell(_ cell: NotificationsCenterCell) {
        guard let cellViewModel = cell.viewModel else {
            return
        }
        
        closeActiveSwipePanelIfNecessary()
        viewModel.markAsReadOrUnread(viewModels: [cellViewModel], shouldMarkRead: !cellViewModel.isRead)
    }

}
