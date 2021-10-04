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
    lazy private var modelContainer = NotificationModelsContainer(languageLinkController: self.languageLinkController, delegate: self)
    
    private var isImportingPrimaryLanguage = true
    private var isPagingEnabled = true
    var editMode = false {
        didSet {
            if oldValue != editMode {
                modelContainer.updateEditModeInViewModels(editMode: editMode)
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
        
        modelContainer.appendNotifications(notifications: Array(newNotifications), editMode: self.editMode)
        modelContainer.syncNewNotifications(notifications: Array(refreshedNotifications), editMode: self.editMode)
        self.delegate?.cellViewModelsDidChange(cellViewModels: modelContainer.sortedCellViewModels)
    }

    // MARK: - Public
    
    func refreshNotifications() {
        remoteNotificationsController.refreshNotifications {
            //TODO: Set any refreshing loading states here
        }
    }
    
    func fetchFirstPage() {
        self.isImportingPrimaryLanguage = true
        kickoffImportIfNeeded { [weak self] in
            
            DispatchQueue.main.async {
                guard let self = self else {
                    return
                }
                
                self.isImportingPrimaryLanguage = false
                
                let notifications = self.remoteNotificationsController.fetchNotifications()
                self.modelContainer.appendNotifications(notifications: notifications, editMode: self.editMode)
                self.delegate?.cellViewModelsDidChange(cellViewModels: self.modelContainer.sortedCellViewModels)
            }
        }
    }
    
    func fetchNextPage() {
        guard isImportingPrimaryLanguage == false else {
            DDLogDebug("Request to fetch next page while importing primary language. Ignoring.")
            return
        }
        
        guard isPagingEnabled == true else {
            DDLogDebug("Request to fetch next page while paging is disabled. Ignoring.")
            return
        }
        
        let notifications = self.remoteNotificationsController.fetchNotifications(fetchOffset: modelContainer.fetchOffset)
        
        guard notifications.count > 0 else {
            isPagingEnabled = false
            return
        }
        
        modelContainer.appendNotifications(notifications: notifications, editMode: self.editMode)
        self.delegate?.cellViewModelsDidChange(cellViewModels: modelContainer.sortedCellViewModels)
    }
    
    func toggleCheckedStatus(cellViewModel: NotificationsCenterCellViewModel) {
        cellViewModel.toggleCheckedStatus()
        reloadCellWithViewModelIfNeeded(viewModel: cellViewModel)
    }

}

private extension NotificationsCenterViewModel {
    func kickoffImportIfNeeded(primaryLanguageImportedCompletion: @escaping () -> Void) {
        remoteNotificationsController.importNotificationsIfNeeded(primaryLanguageCompletion: primaryLanguageImportedCompletion, allLanguagesCompletion: ({
            DDLogDebug("All notification projects imported.")
        }))
    }
}

extension NotificationsCenterViewModel: NotificationModelsContainerDelegate {
    func reloadCellWithViewModelIfNeeded(viewModel: NotificationsCenterCellViewModel) {
        delegate?.reloadCellWithViewModelIfNeeded(viewModel)
    }
}
