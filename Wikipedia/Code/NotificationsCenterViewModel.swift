import Foundation
import CocoaLumberjackSwift

protocol NotificationCenterViewModelDelegate: AnyObject {
    func cellViewModelsDidChange(cellViewModels: [NotificationsCenterCellViewModel])
    func reloadCellWithViewModelIfNeeded(_ viewModel: NotificationsCenterCellViewModel)
}

enum NotificationsCenterSection {
  case main
}

@objc
final class NotificationsCenterViewModel: NSObject {

    // MARK: - Properties

    private let remoteNotificationsController: RemoteNotificationsController
    weak var delegate: NotificationCenterViewModelDelegate?
    private let languageLinkController: MWKLanguageLinkController
    
    var configuration: Configuration {
        return remoteNotificationsController.configuration
    }

    lazy private var modelController = NotificationsCenterModelController(languageLinkController: self.languageLinkController, delegate: self)
    
    private var isPagingEnabled = true
    var editMode = false {
        didSet {
            if oldValue != editMode {
                modelController.updateCurrentCellViewModelsWith(editMode: editMode)
            }
        }
    }

    // MARK: - Lifecycle

    @objc
    init(remoteNotificationsController: RemoteNotificationsController, languageLinkController: MWKLanguageLinkController) {
        self.remoteNotificationsController = remoteNotificationsController
        self.languageLinkController = languageLinkController

        super.init()
	}

    // MARK: - Public
    
    @objc func contextObjectsDidChange(_ notification: NSNotification) {
        
        let refreshedNotifications = notification.userInfo?[NSRefreshedObjectsKey] as? Set<RemoteNotification> ?? []
        let newNotifications = notification.userInfo?[NSInsertedObjectsKey] as? Set<RemoteNotification> ?? []
        
        guard (refreshedNotifications.count > 0 || newNotifications.count > 0) else {
            return
        }
        
        modelController.addNewCellViewModelsWith(notifications: Array(newNotifications), editMode: self.editMode)
        modelController.updateCurrentCellViewModelsWith(updatedNotifications: Array(refreshedNotifications), editMode: self.editMode)
        self.delegate?.cellViewModelsDidChange(cellViewModels: modelController.sortedCellViewModels)
    }

    // MARK: - Public
    
    func refreshNotifications() {
        remoteNotificationsController.refreshNotifications { _ in
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
    
    func fetchFirstPage() {
        kickoffImportIfNeeded { [weak self] in
            
            DispatchQueue.main.async {
                guard let self = self else {
                    return
                }
                
                let notifications = self.remoteNotificationsController.fetchNotifications()
                self.modelController.addNewCellViewModelsWith(notifications: notifications, editMode: self.editMode)
                self.delegate?.cellViewModelsDidChange(cellViewModels: self.modelController.sortedCellViewModels)
            }
        }
    }
    
    func fetchNextPage() {
        
        guard isPagingEnabled == true else {
            DDLogDebug("Request to fetch next page while paging is disabled. Ignoring.")
            return
        }
        
        let notifications = self.remoteNotificationsController.fetchNotifications(fetchOffset: modelController.fetchOffset)
        
        guard notifications.count > 0 else {
            isPagingEnabled = false
            return
        }
        
        modelController.addNewCellViewModelsWith(notifications: notifications, editMode: self.editMode)
        self.delegate?.cellViewModelsDidChange(cellViewModels: modelController.sortedCellViewModels)
    }
    
    func toggleCheckedStatus(cellViewModel: NotificationsCenterCellViewModel) {
        cellViewModel.toggleCheckedStatus()
        reloadCellWithViewModelIfNeeded(viewModel: cellViewModel)
    }

}

private extension NotificationsCenterViewModel {
    func kickoffImportIfNeeded(completion: @escaping () -> Void) {
        remoteNotificationsController.importNotificationsIfNeeded() { [weak self] error in
            
            guard let self = self else {
                return
            }
            
            if let error = error,
               error == RemoteNotificationsOperationsError.failureSettingUpModelController {
                //TODO: trigger error state of some sort
                completion()
                return
            }
            
            NotificationCenter.default.addObserver(self, selector: #selector(self.contextObjectsDidChange(_:)), name: Notification.Name.NSManagedObjectContextObjectsDidChange, object: self.remoteNotificationsController.viewContext)

            completion()
        }
    }
}

extension NotificationsCenterViewModel: NotificationsCenterModelControllerDelegate {
    func reloadCellWithViewModelIfNeeded(viewModel: NotificationsCenterCellViewModel) {
        delegate?.reloadCellWithViewModelIfNeeded(viewModel)
    }
}
