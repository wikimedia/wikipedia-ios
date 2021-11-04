import UIKit

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
        
        setupCollectionView()
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
        deselectAllCells()
        
        //Reconfigure visible cells to reflect new edit mode.
        //This has a smoother change vs reloadData()
        if #available(iOS 15.0, *) {
            if var snapshot = self.dataSource?.snapshot() {
                snapshot.reconfigureItems(snapshot.itemIdentifiers)
                self.dataSource?.apply(snapshot)
            }
        } else {
            notificationsView.collectionView.visibleCells.forEach { cell in
                guard let cell = cell as? NotificationsCenterCell else {
                    return
                }
                
                cell.configure(theme: theme, isEditing: editing)
            }
        }
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
    func setupCollectionView() {
        notificationsView.collectionView.delegate = self
    }
    
    func setupDataSource() {
        dataSource = DataSource(
        collectionView: notificationsView.collectionView,
        cellProvider: { [weak self] (collectionView, indexPath, viewModel) ->
            NotificationsCenterCell? in

            guard let self = self,
                  let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NotificationsCenterCell.reuseIdentifier, for: indexPath) as? NotificationsCenterCell else {
                return nil
            }
            cell.configure(viewModel: viewModel, theme: self.theme, isEditing: self.isEditing )
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
        let selectedIndexes = notificationsView.collectionView.indexPathsForSelectedItems?.map { $0.item } ?? []
        let currentSnapshot = dataSource?.snapshot()
        let viewModels = currentSnapshot?.itemIdentifiers ?? []
        let selectedViewModels = selectedIndexes.compactMap { viewModels.count > $0 ? viewModels[$0] : nil }
        return selectedViewModels
    }
    
    func deselectAllCells() {
        notificationsView.collectionView.indexPathsForSelectedItems?.forEach {
            notificationsView.collectionView.deselectItem(at: $0, animated: false)
        }
    }
}

// MARK: - NotificationCenterViewModelDelegate

extension NotificationsCenterViewController: NotificationCenterViewModelDelegate {
    func cellViewModelsDidChange(cellViewModels: [NotificationsCenterCellViewModel]) {
        
        configureEmptyState(isEmpty: cellViewModels.isEmpty)
        applySnapshot(cellViewModels: cellViewModels, animatingDifferences: true)
    }
    
    func reloadCellWithViewModelIfNeeded(_ viewModel: NotificationsCenterCellViewModel) {
        for cell in notificationsView.collectionView.visibleCells {
            guard let cell = cell as? NotificationsCenterCell,
                  let cellViewModel = cell.viewModel,
                  cellViewModel == viewModel else {
                continue
            }
            
            cell.configure(viewModel: viewModel, theme: theme, isEditing: isEditing)
        }
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
        if isEditing {
            return true
        }
        
        return false
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if !isEditing {
            collectionView.deselectItem(at: indexPath, animated: true)
        }
    }
}

extension NotificationsCenterViewController: NotificationsCenterCellDelegate {
    func userDidTapSecondaryActionForCellIdentifier(id: String) {
        //TODO
    }
    
    func userDidToggleCheckedStatus(viewModel: NotificationsCenterCellViewModel) {
        self.viewModel.toggleCheckedStatus(cellViewModel: viewModel)
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

    /// This will be removed in the final implementation
    fileprivate func userDidSwipeCell(indexPath: IndexPath?) {
        /*
        guard let indexPath = indexPath, let cellViewModel = viewModel.cellViewModel(indexPath: indexPath) else {
            return
        }

        let alertController = UIAlertController(title: cellViewModel.headerText, message: cellViewModel.bodyText, preferredStyle: .actionSheet)

        let firstAction = UIAlertAction(title: "Action 1", style: .default)
        let secondAction = UIAlertAction(title: "Action 2", style: .default)
        let thirdAction = UIAlertAction(title: "Action 3", style: .default)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)

        alertController.addAction(firstAction)
        alertController.addAction(secondAction)
        alertController.addAction(thirdAction)
        alertController.addAction(cancelAction)

        if let popoverController = alertController.popoverPresentationController, let cell = notificationsView.collectionView.cellForItem(at: indexPath) {
            popoverController.sourceView = cell
            popoverController.sourceRect = CGRect(x: cell.bounds.midX, y: cell.bounds.midY, width: 0, height: 0)
        }

        present(alertController, animated: true, completion: nil)
        */
    }

}
