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

    // MARK: - Properties - Cell Swipe Actions

    fileprivate lazy var cellPanGestureRecognizer = UIPanGestureRecognizer()
    fileprivate var activelyPannedCellIndexPath: IndexPath?

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
        isEditing = false
	}

	// MARK: - Public
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        notificationsView.collectionView.allowsMultipleSelection = editing
        viewModel.isEditing = editing
        viewModel.updateCellDisplayStates(isSelected: false)
        reconfigureCells()
        
        deselectCells()
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
                    
                    //snapshot.reconfigureItems(viewModelsToUpdate)
                    //self.dataSource?.apply(snapshot, animatingDifferences: false)
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

    @objc fileprivate func userDidPanCell(_ gestureRecognizer: UIPanGestureRecognizer) {
        switch gestureRecognizer.state {
        case .began:
            let touchPosition = gestureRecognizer.location(in: notificationsView.collectionView)
            guard let cellIndexPath = notificationsView.collectionView.indexPathForItem(at: touchPosition) else {
                gestureRecognizer.state = .ended
                break
            }

            activelyPannedCellIndexPath = cellIndexPath
        case .ended:
            userDidSwipeCell(indexPath: activelyPannedCellIndexPath)
            activelyPannedCellIndexPath = nil
        default:
            return
        }
    }

    /// TODO: This will be removed in the final implementation
    fileprivate func userDidSwipeCell(indexPath: IndexPath?) {
        
        guard let indexPath = indexPath,
              let cellViewModel = dataSource?.itemIdentifier(for: indexPath) else {
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

        if let popoverController = alertController.popoverPresentationController, let cell = notificationsView.collectionView.cellForItem(at: indexPath) {
            popoverController.sourceView = cell
            popoverController.sourceRect = CGRect(x: cell.bounds.midX, y: cell.bounds.midY, width: 0, height: 0)
        }

        present(alertController, animated: true, completion: nil)
    }
}

//MARK: NotificationCenterCellDelegate

extension NotificationsCenterViewController: NotificationsCenterCellDelegate {
    func userDidTapSecondaryActionForViewModel(_ cellViewModel: NotificationsCenterCellViewModel) {
        guard let url = cellViewModel.secondaryURL(for: viewModel.configuration) else {
            return
        }
        navigate(to: url)
    }
}
