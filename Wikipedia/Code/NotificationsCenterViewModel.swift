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

    let remoteNotificationsController: RemoteNotificationsController
    weak var delegate: NotificationCenterViewModelDelegate?

    private let languageLinkController: MWKLanguageLinkController
    lazy private var modelController = NotificationsCenterModelController(languageLinkController: self.languageLinkController, delegate: self)
    
    private var isPagingEnabled = true
    var editMode = false {
        didSet {
            if oldValue != editMode {
                modelController.updateEditModeInViewModels(editMode: editMode)
            }
        }
    }

    // MARK: - Lifecycle

    @objc
    init(remoteNotificationsController: RemoteNotificationsController, languageLinkController: MWKLanguageLinkController) {
        self.remoteNotificationsController = remoteNotificationsController
        self.languageLinkController = languageLinkController

        super.init()
                NotificationCenter.default.addObserver(self, selector: #selector(contextObjectsDidChange(_:)), name: Notification.Name.NSManagedObjectContextObjectsDidChange, object: remoteNotificationsController.viewContext)
	}
    
    @objc func contextObjectsDidChange(_ notification: NSNotification) {
        
        let refreshedNotifications = notification.userInfo?[NSRefreshedObjectsKey] as? Set<RemoteNotification> ?? []
        let newNotifications = notification.userInfo?[NSInsertedObjectsKey] as? Set<RemoteNotification> ?? []
        
        guard (refreshedNotifications.count > 0 || newNotifications.count > 0) else {
            return
        }
        
        modelController.appendNotifications(notifications: Array(newNotifications), editMode: self.editMode)
        modelController.syncNewNotifications(notifications: Array(refreshedNotifications), editMode: self.editMode)
        self.delegate?.cellViewModelsDidChange(cellViewModels: modelController.sortedCellViewModels)
    }

    // MARK: - Public
    
    func fetchFirstPage() {
        kickoffImportIfNeeded { [weak self] in
            
            DispatchQueue.main.async {
                guard let self = self else {
                    return
                }
                
                let notifications = self.remoteNotificationsController.fetchNotifications()
                self.modelController.appendNotifications(notifications: notifications, editMode: self.editMode)
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
        
        modelController.appendNotifications(notifications: notifications, editMode: self.editMode)
        self.delegate?.cellViewModelsDidChange(cellViewModels: modelController.sortedCellViewModels)
    }
    
    func toggleCheckedStatus(cellViewModel: NotificationsCenterCellViewModel) {
        cellViewModel.toggleCheckedStatus()
        reloadCellWithViewModelIfNeeded(viewModel: cellViewModel)
    }

}

private extension NotificationsCenterViewModel {
    func kickoffImportIfNeeded(completion: @escaping () -> Void) {
        //TODO: This will change to triggering the import operations once that's merged (https://github.com/wikimedia/wikipedia-ios/pull/4047).
        remoteNotificationsController.fetchFirstPageNotifications() {
            completion()
        }
    }
}

extension NotificationsCenterViewModel: NotificationsCenterModelControllerDelegate {
    func reloadCellWithViewModelIfNeeded(viewModel: NotificationsCenterCellViewModel) {
        delegate?.reloadCellWithViewModelIfNeeded(viewModel)
    }
}
