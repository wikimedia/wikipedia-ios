import Foundation

protocol NotificationCenterViewModelDelegate: AnyObject {
	func collectionViewUpdaterDidUpdate()
}

@objc
final class NotificationsCenterViewModel: NSObject {

    // MARK: - Properties

    private let remoteNotificationsController: RemoteNotificationsController

    fileprivate let fetchedResultsController: NSFetchedResultsController<RemoteNotification>?
    fileprivate var collectionViewUpdater: CollectionViewUpdater<RemoteNotification>?

    weak var delegate: NotificationCenterViewModelDelegate?

    private let languageLinkController: MWKLanguageLinkController
    
    var configuration: Configuration {
        return remoteNotificationsController.configuration
    }

    // MARK: - Lifecycle

    @objc
    init(remoteNotificationsController: RemoteNotificationsController, languageLinkController: MWKLanguageLinkController) {
        self.remoteNotificationsController = remoteNotificationsController
        self.languageLinkController = languageLinkController

        fetchedResultsController = remoteNotificationsController.fetchedResultsController()

		// TODO: DM-Remove
		remoteNotificationsController.importNotificationsIfNeeded {}
	}

    // MARK: - Public
    
    func refreshNotifications() {
        remoteNotificationsController.refreshNotifications {
            //TODO: Set any refreshing loading states here
        }
    }
    
    func markAsReadOrUnread(viewModels: [NotificationsCenterCellViewModel], shouldMarkRead: Bool) {
        let notifications = viewModels.map { $0.notification }
        remoteNotificationsController.markAsReadOrUnread(notifications: Set(notifications), shouldMarkRead: shouldMarkRead)
    }
    
    func markAllAsRead() {
        remoteNotificationsController.markAllAsRead()
    }

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
            return NotificationsCenterCellViewModel(notification: remoteNotification, languageLinkController: languageLinkController)
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
