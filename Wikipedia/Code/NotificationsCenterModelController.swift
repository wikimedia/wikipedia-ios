
import Foundation
import WMF

protocol NotificationsCenterModelControllerDelegate: AnyObject {
    func dataDidChange()
}

//Keeps track of the RemoteNotification managed objects and NotificationCenterCellViewModels that power Notification Center in a performant way
final class NotificationsCenterModelController {
    
    typealias RemoteNotificationKey = String

    private var cellViewModelsDict: [RemoteNotificationKey: NotificationsCenterCellViewModel] = [:]
    private var cellViewModels: Set<NotificationsCenterCellViewModel> = []
    
    private let languageLinkController: MWKLanguageLinkController
    private let remoteNotificationsController: RemoteNotificationsController
    
    private weak var delegate: NotificationsCenterModelControllerDelegate?
    
    init(languageLinkController: MWKLanguageLinkController, delegate: NotificationsCenterModelControllerDelegate?, remoteNotificationsController: RemoteNotificationsController) {
        self.languageLinkController = languageLinkController
        self.delegate = delegate
        self.remoteNotificationsController = remoteNotificationsController
    }
    
    func addNewCellViewModelsWith(notifications: [RemoteNotification], isEditing: Bool) {
        
        var atLeastOneNewCellViewModelInserted = false
        
        for notification in notifications {

            //Instantiate new view model and insert it into tracking properties
            
            guard let key = notification.key,
                  let newCellViewModel = NotificationsCenterCellViewModel(notification: notification, languageLinkController: languageLinkController, isEditing: isEditing) else {
                continue
            }
            
            atLeastOneNewCellViewModelInserted = true
            
            if atLeastOneNewCellViewModelInserted == false && !cellViewModels.contains(newCellViewModel) {
                atLeastOneNewCellViewModelInserted = true
            }
            cellViewModelsDict[key] = newCellViewModel
            cellViewModels.insert(newCellViewModel)
        }
        
        if atLeastOneNewCellViewModelInserted {
            delegate?.dataDidChange()
        }
    }
    
    func evaluateUpdatedNotifications(updatedNotifications: [RemoteNotification], isEditing: Bool) {
        //Find existing cell view models via tracking properties
        
        var didRemoveValueFromTrackingProperties: Bool = false
        let viewModelsToUpdate: [NotificationsCenterCellViewModel] = updatedNotifications.compactMap { notification in
            
            guard let key = notification.key else {
                return nil
            }
            
            guard let viewModel = cellViewModelsDict[key] else {
                return nil
            }
            
            //updated notification read state may cause tracked models here to be out of date (i.e. models only contain unread notifications due to filter, and user marks a notification as read). Remove model from tracking properties if filter indicates we should. This allows cell to disappear from screen when marking it's read/unread state while a read/unread filter is on.
            if (remoteNotificationsController.filterSavedState.readStatusSetting == .read && !notification.isRead) ||
                (remoteNotificationsController.filterSavedState.readStatusSetting == .unread && notification.isRead) {
                cellViewModels.remove(viewModel)
                cellViewModelsDict.removeValue(forKey: key)
                didRemoveValueFromTrackingProperties = true
                return nil
            }
            
            return viewModel
            
        }
        
        updateCellDisplayStates(cellViewModels: viewModelsToUpdate, isEditing: isEditing)
        
        if viewModelsToUpdate.count > 0 || didRemoveValueFromTrackingProperties {
            delegate?.dataDidChange()
        }
    }
    
    var fetchOffset: Int {
        return cellViewModels.count
    }
    
    var sortedCellViewModels: [NotificationsCenterCellViewModel] {
        return cellViewModels.sorted { lhs, rhs in
            guard let lhsDate = lhs.notification.date,
                  let rhsDate = rhs.notification.date else {
                return false
            }
            return lhsDate > rhsDate
        }
    }
    
    func updateCellDisplayStates(cellViewModels: [NotificationsCenterCellViewModel], isEditing: Bool, isSelected: Bool? = nil, callbackForReload: Bool = true) {
        var dataChanged = false
        
        cellViewModels.forEach { cellViewModel in
            
            let oldDisplayState = cellViewModel.displayState
            cellViewModel.updateDisplayState(isEditing: isEditing, isSelected: isSelected)
            if cellViewModel.displayState != oldDisplayState {
                    dataChanged = true
            }
        }
        
        if dataChanged && callbackForReload {
            delegate?.dataDidChange()
        }
    }
    
    func reset(callbackForReload: Bool = false) {
        cellViewModelsDict.removeAll()
        cellViewModels.removeAll()
        if callbackForReload {
            delegate?.dataDidChange()
        }
    }
}
