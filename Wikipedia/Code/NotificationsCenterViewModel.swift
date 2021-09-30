import Foundation

protocol NotificationCenterViewModelDelegate: AnyObject {
	func collectionViewUpdaterDidUpdate()
}

@objc
final class NotificationsCenterViewModel: NSObject {

    // MARK: - Properties

    let remoteNotificationsController: RemoteNotificationsController

	fileprivate let fetchedResultsController: NSFetchedResultsController<RemoteNotification>?
	fileprivate var collectionViewUpdater: CollectionViewUpdater<RemoteNotification>?

	weak var delegate: NotificationCenterViewModelDelegate?

	// MARK: - Lifecycle

	@objc
	init(remoteNotificationsController: RemoteNotificationsController) {
		self.remoteNotificationsController = remoteNotificationsController

		fetchedResultsController = remoteNotificationsController.fetchedResultsController()

		// TODO: DM-Remove
		remoteNotificationsController.fetchFirstPageNotifications {}
	}

    // MARK: - Public

	func fetchNotifications(collectionView: UICollectionView) {
		guard let fetchedResultsController = fetchedResultsController else {
			return
		}

		collectionViewUpdater = CollectionViewUpdater(fetchedResultsController: fetchedResultsController, collectionView: collectionView)
		collectionViewUpdater?.delegate = self
		collectionViewUpdater?.performFetch()
	}

	var numberOfSections: Int {
		return fetchedResultsController?.sections?.count ?? 0
	}

	func numberOfItems(section: Int) -> Int {
		return fetchedResultsController?.sections?[section].numberOfObjects ?? 0
	}

	func cellViewModel(indexPath: IndexPath) -> NotificationsCenterCellViewModel? {
		if let remoteNotification =  fetchedResultsController?.object(at: indexPath) {
			return NotificationsCenterCellViewModel(notification: remoteNotification)
		}

		return nil
	}

}

extension NotificationsCenterViewModel: CollectionViewUpdaterDelegate {

	func collectionViewUpdater<T>(_ updater: CollectionViewUpdater<T>, didUpdate collectionView: UICollectionView) where T : NSFetchRequestResult {
		delegate?.collectionViewUpdaterDidUpdate()
	}

	func collectionViewUpdater<T>(_ updater: CollectionViewUpdater<T>, updateItemAtIndexPath indexPath: IndexPath, in collectionView: UICollectionView) where T : NSFetchRequestResult {
		
	}

}
