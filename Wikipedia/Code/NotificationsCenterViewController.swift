import UIKit

@objc
final class NotificationsCenterViewController: ViewController {

    // MARK: - Properties

    var notificationsView: NotificationsCenterView {
        return view as! NotificationsCenterView
    }

    let viewModel: NotificationsCenterViewModel

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

		viewModel.fetchNotifications(collectionView: notificationsView.collectionView)
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
		return cell
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
