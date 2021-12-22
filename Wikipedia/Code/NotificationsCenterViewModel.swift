import Foundation
import CocoaLumberjackSwift

protocol NotificationCenterViewModelDelegate: AnyObject {
    /// This causes snapshot to update entirely, inserting new cells as needed
    func cellViewModelsDidChange(cellViewModels: [NotificationsCenterCellViewModel])
    
    /// This seeks out cells that are currently displaying and reconfigures them
    func reconfigureCellsWithViewModelsIfNeeded(_ cellViewModels: [NotificationsCenterCellViewModel]?)

    func toolbarContentDidUpdate()
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

    lazy private var modelController = NotificationsCenterModelController(languageLinkController: self.languageLinkController, delegate: self)

    private var isLoading: Bool = false {
        didSet {
            delegate?.toolbarContentDidUpdate()
        }
    }

    private var isPagingEnabled = true

    var isEditing: Bool = false
    
    var configuration: Configuration {
        return remoteNotificationsController.configuration
    }

    // MARK: - Lifecycle

    @objc
    init(remoteNotificationsController: RemoteNotificationsController, languageLinkController: MWKLanguageLinkController) {
        self.remoteNotificationsController = remoteNotificationsController
        self.languageLinkController = languageLinkController

        super.init()

        NotificationCenter.default.addObserver(self, selector: #selector(remoteNotificationsControllerDidUpdateFilterState), name: RemoteNotificationsController.didUpdateFilterStateNotification, object: nil)
	}

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Public
    
    @objc func contextObjectsDidChange(_ notification: NSNotification) {
        
        let refreshedNotifications = notification.userInfo?[NSRefreshedObjectsKey] as? Set<RemoteNotification> ?? []
        let newNotifications = notification.userInfo?[NSInsertedObjectsKey] as? Set<RemoteNotification> ?? []
        
        guard (refreshedNotifications.count > 0 || newNotifications.count > 0) else {
            return
        }
        
        modelController.addNewCellViewModelsWith(notifications: Array(newNotifications))
        modelController.updateCurrentCellViewModelsWith(updatedNotifications: Array(refreshedNotifications))
        self.delegate?.cellViewModelsDidChange(cellViewModels: modelController.sortedCellViewModels)
    }

    // MARK: - Public
    
    func refreshNotifications() {
        isLoading = true
        remoteNotificationsController.refreshNotifications { _ in
            //TODO: Set any refreshing loading states here
            self.isLoading = false
        }
    }
    
    func markAsReadOrUnread(viewModels: [NotificationsCenterCellViewModel], shouldMarkRead: Bool) {
        let identifierGroups = viewModels.map { $0.notification.identifierGroup }
        remoteNotificationsController.markAsReadOrUnread(identifierGroups: Set(identifierGroups), shouldMarkRead: shouldMarkRead)
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
                self.modelController.addNewCellViewModelsWith(notifications: notifications)
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
        
        modelController.addNewCellViewModelsWith(notifications: notifications)
        self.delegate?.cellViewModelsDidChange(cellViewModels: modelController.sortedCellViewModels)
    }
    
    func updateCellDisplayStates(cellViewModels: [NotificationsCenterCellViewModel]? = nil, isSelected: Bool) {
        modelController.updateCellDisplayStates(cellViewModels: cellViewModels, isEditing: isEditing, isSelected: isSelected)
    }
}

private extension NotificationsCenterViewModel {
    func kickoffImportIfNeeded(completion: @escaping () -> Void) {
        remoteNotificationsController.importNotificationsIfNeeded() { [weak self] error in
            
            guard let self = self else {
                return
            }
            
            if let error = error,
               error == RemoteNotificationsOperationsError.dataUnavailable {
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
    func reconfigureCellsWithViewModelsIfNeeded(cellViewModels: [NotificationsCenterCellViewModel]) {
        delegate?.reconfigureCellsWithViewModelsIfNeeded(cellViewModels)
    }
}

// MARK: - Toolbar

extension NotificationsCenterViewModel {

    // MARK: - Private

    @objc fileprivate func remoteNotificationsControllerDidUpdateFilterState() {
        delegate?.toolbarContentDidUpdate()
    }

    fileprivate func toolbarImageForTypeFilter(engaged: Bool) -> UIImage? {
        let symbolName = engaged ? "line.horizontal.3.decrease.circle.fill" : "line.horizontal.3.decrease.circle"
        return UIImage(systemName: symbolName)
    }

    fileprivate func toolbarImageForProjectFilter(engaged: Bool) -> UIImage? {
        let symbolName = engaged ? "tray.fill" : "tray.2"
        return UIImage(systemName: symbolName)
    }

    // MARK: - Public

    var typeFilterButtonImage: UIImage? {
        return toolbarImageForTypeFilter(engaged: remoteNotificationsController.filterState.types.count > 0 || remoteNotificationsController.filterState.readStatus != .all)
    }

    var projectFilterButtonImage: UIImage? {
        return toolbarImageForProjectFilter(engaged: remoteNotificationsController.filterState.projects.count > 0)
    }

    var statusBarText: String {
        if isLoading {
            return "Checking for notifications..."
        }

        // Logic for status bar text based on type, project, and read filters here

        return "All Notifications"
    }

}
