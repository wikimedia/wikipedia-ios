import UIKit
import WMF

@objc
final class NotificationsCenterViewController: ViewController {

    // MARK: - Properties

    var notificationsView: NotificationsCenterView {
        return view as! NotificationsCenterView
    }

    let viewModel: NotificationsCenterViewModel
    
    typealias DataSource = UICollectionViewDiffableDataSource<NotificationsCenterSection, NotificationsCenterCellViewModel>
    typealias Snapshot = NSDiffableDataSourceSnapshot<NotificationsCenterSection, NotificationsCenterCellViewModel>
    private var dataSource: DataSource?
    private let snapshotUpdateQueue = DispatchQueue(label: "org.wikipedia.notificationscenter.snapshotUpdateQueue", qos: .userInteractive)

    // MARK: - Properties: Toolbar Buttons

    fileprivate lazy var typeFilterButton: IconBarButtonItem = IconBarButtonItem(image: viewModel.typeFilterButtonImage, style: .plain, target: self, action: #selector(userDidTapTypeFilterButton))
    fileprivate lazy var projectFilterButton: IconBarButtonItem = IconBarButtonItem(image: viewModel.projectFilterButtonImage, style: .plain, target: self, action: #selector(userDidTapProjectFilterButton))
    fileprivate lazy var markButton: TextBarButtonItem = TextBarButtonItem(title: WMFLocalizedString("notifications-center-mark", value: "Mark", comment: "Button text in Notifications Center. Presents menu of options to mark selected notifications as read or unread."), target: nil, action: nil)
    fileprivate lazy var markAllAsReadButton: TextBarButtonItem = TextBarButtonItem(title: WMFLocalizedString("notifications-center-mark-all-as-read", value: "Mark all as read", comment: "Toolbar button text in Notifications Center that marks all user notifications as read on the server."), target: nil, action: nil)
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
        viewModel.refreshNotifications()
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
        viewModel.isEditing = editing
        viewModel.updateCellDisplayStates(isSelected: false)
        updateToolbarDisplayState(isEditing: isEditing)

        reconfigureCells()
        deselectCells()
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
            
            let isSelected = (collectionView.indexPathsForSelectedItems ?? []).contains(indexPath)
            self.viewModel.updateCellDisplayStates(cellViewModels: [cellViewModel], isSelected: isSelected)
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
        notificationsView.collectionView.indexPathsForSelectedItems?.forEach {
            notificationsView.collectionView.deselectItem(at: $0, animated: false)
        }

        closeSwipeActionsPanelIfNecessary()
    }
    
    /// Calls cell configure methods again without instantiating a new cell.
    /// - Parameter viewModels: Cell view models whose associated cells you want to configure again. If nil, method uses all available items in the snapshot (or visible cells) to configure.
    func reconfigureCells(with viewModels: [NotificationsCenterCellViewModel]? = nil) {
        
        if #available(iOS 15.0, *) {
            snapshotUpdateQueue.async {
                if var snapshot = self.dataSource?.snapshot() {
                    
                    let viewModelsToUpdate = snapshot.itemIdentifiers.filter {
                        guard let viewModels = viewModels else {
                            return true
                        }
                        
                        return viewModels.contains($0)
                    }
                    
                    snapshot.reconfigureItems(viewModelsToUpdate)
                    self.dataSource?.apply(snapshot, animatingDifferences: false)
                }
            }
        } else {
            
            let cellsToReconfigure: [NotificationsCenterCell]
            if let viewModels = viewModels, let dataSource = dataSource {
                let indexPathsToReconfigure = viewModels.compactMap { dataSource.indexPath(for: $0) }
                cellsToReconfigure = indexPathsToReconfigure.compactMap { notificationsView.collectionView.cellForItem(at: $0) as? NotificationsCenterCell}
            } else {
                cellsToReconfigure = notificationsView.collectionView.visibleCells as? [NotificationsCenterCell] ?? []
            }
            
            cellsToReconfigure.forEach { cell in
                cell.configure(theme: theme)
            }
        }
    }

}

// MARK: - NotificationCenterViewModelDelegate

extension NotificationsCenterViewController: NotificationCenterViewModelDelegate {
    func reconfigureCellsWithViewModelsIfNeeded(_ cellViewModels: [NotificationsCenterCellViewModel]?) {
        reconfigureCells(with: cellViewModels)
    }
    
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
        if viewModel.isEditing {
            return true
        }
        
        return false
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        guard let cellViewModel = dataSource?.itemIdentifier(for: indexPath) else {
            return
        }

        viewModel.updateCellDisplayStates(cellViewModels: [cellViewModel], isSelected: true)
        reconfigureCells(with: [cellViewModel])
        
        if !viewModel.isEditing {
            collectionView.deselectItem(at: indexPath, animated: true)
            
            if let primaryURL = cellViewModel.primaryURL(for: viewModel.configuration) {
                navigate(to: primaryURL)
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        
        guard let cellViewModel = dataSource?.itemIdentifier(for: indexPath) else {
            return
        }

        viewModel.updateCellDisplayStates(cellViewModels: [cellViewModel], isSelected: false)
        reconfigureCells(with: [cellViewModel])
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
            return
        }
    }

}

//MARK: NotificationCenterCellDelegate

extension NotificationsCenterViewController: NotificationsCenterCellDelegate {

    func userDidTapSecondaryActionForCell(_ cell: NotificationsCenterCell) {
        guard let cellViewModel = cell.viewModel, let url = cellViewModel.secondaryURL(for: viewModel.configuration) else {
            return
        }

        navigate(to: url)
    }

    func userDidTapMoreActionForCell(_ cell: NotificationsCenterCell) {
        guard let cellViewModel = cell.viewModel else  {
            return
        }

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
                    self.closeSwipeActionsPanelIfNecessary()
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

    }

    @objc fileprivate func userDidTapTypeFilterButton() {
        
    }

}
