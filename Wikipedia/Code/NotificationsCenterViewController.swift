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
    private let snapshotUpdateQueue = DispatchQueue(label: "org.wikipedia.notificationcenter.snapshotUpdateQueue", qos: .userInteractive)
    
    private let editTitle = WMFLocalizedString("notifications-center-edit-button-edit", value: "Edit", comment: "Title for navigation bar button to turn on edit mode for toggling notification read status")
    private let doneTitle = WMFLocalizedString("notifications-center-edit-button-done", value: "Done", comment: "Title for navigation bar button to turn off edit mode for toggling notification read status")
    private lazy var editButton = {
        return UIBarButtonItem(title: editTitle, style: .plain, target: self, action: #selector(userDidTapEditButton))
    }()
    
    //super temporary to get to a build
    private var cellViewModels: [NotificationsCenterCellViewModel] = []

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
        configureEmptyState(isEmpty: true)
        viewModel.fetchFirstPage()
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

		navigationItem.rightBarButtonItem = editButton
	}

	// MARK: - Edit button

	@objc func userDidTapEditButton() {
        viewModel.editMode.toggle()
        editButton.title = viewModel.editMode ? doneTitle : editTitle
	}

	// MARK: - Public


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
        notificationsView.collectionView.addGestureRecognizer(cellPanGestureRecognizer)
        cellPanGestureRecognizer.addTarget(self, action: #selector(userDidPanCell(_:)))
        cellPanGestureRecognizer.delegate = self
    }
    
    func setupDataSource() {
        dataSource = DataSource(
        collectionView: notificationsView.collectionView,
        cellProvider: { [weak self] (collectionView, indexPath, viewModel) ->
            UICollectionViewCell? in

            guard let self = self,
                  let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NotificationsCenterCell.reuseIdentifier, for: indexPath) as? NotificationsCenterCell else {
                return nil
            }
            cell.configure(viewModel: viewModel, theme: self.theme)
            cell.delegate = self
            return cell
        })
    }
    
    func applySnapshot(cellViewModels: [NotificationsCenterCellViewModel], animatingDifferences: Bool = true) {
        
        guard let dataSource = dataSource else {
            return
        }
        
        snapshotUpdateQueue.async {
            self.cellViewModels.removeAll()
            var snapshot = Snapshot()
            snapshot.appendSections([.main])
            snapshot.appendItems(cellViewModels)
            dataSource.apply(snapshot, animatingDifferences: animatingDifferences)
            self.cellViewModels.append(contentsOf: cellViewModels)
        }
    }
    
    func configureEmptyState(isEmpty: Bool) {
        notificationsView.updateEmptyOverlay(visible: isEmpty, headerText: NotificationsCenterView.EmptyOverlayStrings.noUnreadMessages, subheaderText: NotificationsCenterView.EmptyOverlayStrings.checkingForNotifications)
        navigationItem.rightBarButtonItems?.forEach { $0.isEnabled = !isEmpty }
        navigationItem.rightBarButtonItem?.isEnabled = !isEmpty
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
            
            cell.configure(viewModel: viewModel, theme: theme)
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
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        guard let cellViewModel = cellViewModels[safeIndex: indexPath.item],
              let url = cellViewModel.primaryURL(for: viewModel.configuration) else {
            return
        }
        navigate(to: url)
    }
}

extension NotificationsCenterViewController: NotificationsCenterCellDelegate {
    func userDidTapSecondaryActionForViewModel(_ cellViewModel: NotificationsCenterCellViewModel) {
        guard let url = cellViewModel.secondaryURL(for: viewModel.configuration) else {
            return
        }
        navigate(to: url)
    }
    
    func toggleCheckedStatus(viewModel: NotificationsCenterCellViewModel) {
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

    /// TODO: This will be removed in the final implementation
    fileprivate func userDidSwipeCell(indexPath: IndexPath?) {
        guard let indexPath = indexPath,
              let cellViewModel = cellViewModels[safeIndex: indexPath.item] else {
            return
        }
        
        let swipeActions = cellViewModel.swipeActions(for: viewModel.configuration)
        guard !swipeActions.isEmpty else {
            return
        }

        let alertController = UIAlertController(title: cellViewModel.headerText, message: cellViewModel.bodyText, preferredStyle: .actionSheet)

        swipeActions.forEach { action in
            
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
        
        //Temporary Cancel action for non-popover
        if (traitCollection.horizontalSizeClass == .compact) {
            let cancelAction = UIAlertAction(title: "Cancel", style: .destructive, handler: nil)
            alertController.addAction(cancelAction)
        }

        if let popoverController = alertController.popoverPresentationController, let cell = notificationsView.collectionView.cellForItem(at: indexPath) {
            popoverController.sourceView = cell
            popoverController.sourceRect = CGRect(x: cell.bounds.midX, y: cell.bounds.midY, width: 0, height: 0)
        }

        present(alertController, animated: true, completion: nil)
    }
}
