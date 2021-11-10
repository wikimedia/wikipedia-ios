import UIKit
import WMF

@objc
final class NotificationsCenterViewController: ViewController {

    // MARK: - Properties

    var notificationsView: NotificationsCenterView {
        return view as! NotificationsCenterView
    }

    let viewModel: NotificationsCenterViewModel

    // MARK: - Properties - Cell Swipe Actions

    fileprivate lazy var cellPanGestureRecognizer = UIPanGestureRecognizer()
    fileprivate var activelyPannedCellIndexPath: IndexPath?

    // MARK: - Lifecycle

    @objc
    init(theme: Theme, viewModel: NotificationsCenterViewModel) {
        self.viewModel = viewModel
        super.init(theme: theme)
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
        notificationsView.collectionView.dataSource = self

        notificationsView.collectionView.addGestureRecognizer(cellPanGestureRecognizer)
        cellPanGestureRecognizer.addTarget(self, action: #selector(userDidPanCell(_:)))
        cellPanGestureRecognizer.delegate = self

        viewModel.fetchNotifications(collectionView: notificationsView.collectionView)
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

		let editButton = UIBarButtonItem(title: WMFLocalizedString("notifications-center-edit-button", value: "Edit", comment: "Title for navigation bar button to toggle mode for editing notification read status"), style: .plain, target: self, action: #selector(userDidTapEditButton))
		navigationItem.rightBarButtonItem = editButton
	}

	// MARK: - Edit button

	@objc func userDidTapEditButton() {

	}

	// MARK: - Public


    // MARK: - Themable

    override func apply(theme: Theme) {
        super.apply(theme: theme)

        notificationsView.apply(theme: theme)
        notificationsView.collectionView.reloadData()
    }
}

extension NotificationsCenterViewController: UICollectionViewDelegate, UICollectionViewDataSource {

	func numberOfSections(in collectionView: UICollectionView) -> Int {
        let hasNotificationContent = viewModel.numberOfSections != 0
        notificationsView.updateEmptyOverlay(visible: !hasNotificationContent, headerText: NotificationsCenterView.EmptyOverlayStrings.noUnreadMessages)
        navigationItem.rightBarButtonItem?.isEnabled = hasNotificationContent
        
		return viewModel.numberOfSections
	}

	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return viewModel.numberOfItems(section: section)
	}

	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NotificationsCenterCell.reuseIdentifier, for: indexPath) as? NotificationsCenterCell, let cellViewModel = viewModel.cellViewModel(indexPath: indexPath) else {
			fatalError()
		}

		cell.configure(viewModel: cellViewModel, theme: theme)
        cell.delegate = self
		return cell
	}
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cellViewModel = viewModel.cellViewModel(indexPath: indexPath),
              let url = cellViewModel.primaryURL(for: viewModel.configuration) else {
            return
        }
        navigate(to: url)
    }

}

// MARK: - NotificationCenterViewModelDelegate

extension NotificationsCenterViewController: NotificationCenterViewModelDelegate {

	func collectionViewUpdaterDidUpdate() {
		for indexPath in notificationsView.collectionView.indexPathsForVisibleItems {
			if let cellViewModel = viewModel.cellViewModel(indexPath: indexPath), let cell = notificationsView.collectionView.cellForItem(at: indexPath) as? NotificationsCenterCell {
				cell.configure(viewModel: cellViewModel, theme: theme)
			}
		}
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
              let cellViewModel = viewModel.cellViewModel(indexPath: indexPath) else {
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
                    //TODO: Mark as Read handling
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
        
        let cancelAction = UIAlertAction(title: CommonStrings.cancelActionTitle, style: .cancel, handler: nil)
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
