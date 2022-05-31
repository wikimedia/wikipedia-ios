import Foundation
import WMF

// Keeps track of the RemoteNotification managed objects and NotificationsCenterCellViewModels that power Notification Center in a performant way
final class NotificationsCenterModelController {
    
    typealias RemoteNotificationKey = String

    private var cellViewModelsDict: [RemoteNotificationKey: NotificationsCenterCellViewModel] = [:]
    private var cellViewModels: Set<NotificationsCenterCellViewModel> = []
    
    private let languageLinkController: MWKLanguageLinkController
    private let remoteNotificationsController: RemoteNotificationsController
    private let configuration: Configuration
    
    private(set) var oldestDisplayedNotificationDate: Date?
    
    init(languageLinkController: MWKLanguageLinkController, remoteNotificationsController: RemoteNotificationsController, configuration: Configuration) {
        self.languageLinkController = languageLinkController
        self.remoteNotificationsController = remoteNotificationsController
        self.configuration = configuration
    }
    
    @discardableResult func addNewCellViewModelsWith(notifications: [RemoteNotification], isEditing: Bool) -> NotificationsCenterUpdateType? {
        
        var newCellViewModels: [NotificationsCenterCellViewModel] = []
        for notification in notifications {
            
            // Instantiate new view model and insert it into tracking properties
            
            guard let key = notification.key,
                  let newCellViewModel = NotificationsCenterCellViewModel(notification: notification, languageLinkController: languageLinkController, isEditing: isEditing, configuration: configuration) else {
                continue
            }
            
            if !cellViewModels.contains(newCellViewModel) {
                newCellViewModels.append(newCellViewModel)
            }
            cellViewModelsDict[key] = newCellViewModel
            cellViewModels.insert(newCellViewModel)
        }
        
        return newCellViewModels.count > 0 ? .updateSnapshot(sortedCellViewModels) : nil
    }
    
    @discardableResult func evaluateUpdatedNotifications(updatedNotifications: [RemoteNotification], isEditing: Bool) -> [NotificationsCenterUpdateType] {
        // Find existing cell view models via tracking properties
        
        var didRemoveValueFromTrackingProperties: Bool = false
        let viewModelsToUpdate: [NotificationsCenterCellViewModel] = updatedNotifications.compactMap { notification in
            
            guard let key = notification.key else {
                return nil
            }
            
            guard let viewModel = cellViewModelsDict[key] else {
                return nil
            }
            
            // updated notification read state may cause tracked models here to be out of date (i.e. models only contain unread notifications due to filter, and user marks a notification as read). Remove model from tracking properties if filter indicates we should. This allows cell to disappear from screen when marking it's read/unread state while a read/unread filter is on.
            let filterState = remoteNotificationsController.filterState
            if (filterState.readStatus == .read && !notification.isRead) ||
                (filterState.readStatus == .unread && notification.isRead) {
                cellViewModels.remove(viewModel)
                cellViewModelsDict.removeValue(forKey: key)
                didRemoveValueFromTrackingProperties = true
                return nil
            }
            
            return viewModel
            
        }
        
        updateCellDisplayStates(cellViewModels: viewModelsToUpdate, isEditing: isEditing)
        
        var updateTypes: [NotificationsCenterUpdateType] = []
        if viewModelsToUpdate.count > 0 {
            updateTypes.append(.reconfigureCells(viewModelsToUpdate))
        }
        
        if didRemoveValueFromTrackingProperties {
            updateTypes.append(.updateSnapshot(sortedCellViewModels))
        }
        
        return updateTypes
    }
    
    var countOfTrackingModels: Int {
        return cellViewModels.count
    }
    
    @discardableResult func updateCellDisplayStates(cellViewModels: [NotificationsCenterCellViewModel]? = nil, isEditing: Bool, isSelected: Bool? = nil) -> NotificationsCenterUpdateType? {
        
        let cellViewModels = cellViewModels ?? Array(self.cellViewModels)
        
        var dataChanged = false
        
        cellViewModels.forEach { cellViewModel in
            
            let oldDisplayState = cellViewModel.displayState
            cellViewModel.updateDisplayState(isEditing: isEditing, isSelected: isSelected)
            if cellViewModel.displayState != oldDisplayState {
                    dataChanged = true
            }
        }
        
        return dataChanged ? .reconfigureCells(cellViewModels) : nil
    }
    
    func reset() {
        cellViewModelsDict.removeAll()
        cellViewModels.removeAll()
    }
    
    private var sortedCellViewModels: [NotificationsCenterCellViewModel] {
        let sortedCellViewModels = cellViewModels.sorted { lhs, rhs in
            guard let lhsDate = lhs.notification.date,
                  let rhsDate = rhs.notification.date else {
                return false
            }
            return lhsDate > rhsDate
        }
        
        oldestDisplayedNotificationDate = sortedCellViewModels.last?.notification.date
        return sortedCellViewModels
    }
}
