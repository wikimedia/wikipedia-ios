
import Foundation
import WMF

protocol NotificationModelsContainerDelegate: AnyObject {
    func reloadCellWithViewModelIfNeeded(viewModel: NotificationsCenterCellViewModel)
}

//Keeps track of the RemoteNotification managed objects and NotificationCenterCellViewModels that power Notification Center in a performant way
final class NotificationModelsContainer {

    private var notifications: Set<RemoteNotification> = []
    private var cellViewModelsDict: [String: NotificationsCenterCellViewModel] = [:]
    private var cellViewModels: Set<NotificationsCenterCellViewModel> = []
    
    weak var delegate: NotificationModelsContainerDelegate?
    private let languageLinkController: MWKLanguageLinkController
    
    init(languageLinkController: MWKLanguageLinkController, delegate: NotificationModelsContainerDelegate?) {
        self.delegate = delegate
        self.languageLinkController = languageLinkController
    }
    
    func appendNotifications(notifications: [RemoteNotification], editMode: Bool) {
        for notification in notifications {
            self.notifications.insert(notification)
        }
        
        syncNewNotifications(notifications: notifications, editMode: editMode)
    }
    
    func syncNewNotifications(notifications: [RemoteNotification], editMode: Bool) {
        for notification in notifications {
            
            guard let key = notification.key else {
                continue
            }
            
            guard let currentViewModel = cellViewModelsDict[key] else {
                
                //There is no current view model of this key, so let's insert a new one in tracking properties
                if let newCellViewModel = NotificationsCenterCellViewModel(notification: notification, languageLinkController: languageLinkController, editMode: editMode) {
                    cellViewModelsDict[key] = newCellViewModel
                    cellViewModels.insert(newCellViewModel)
                }
                
                continue
            }
            
            //If view model already exists, update existing view model with any valuable new data from managed object.
            currentViewModel.copyAnyValuableNewDataFromNotification(notification, editMode: editMode)
            
            // If it's on screen, trigger a cell reconfiguration from here.
            delegate?.reloadCellWithViewModelIfNeeded(viewModel: currentViewModel)
        }
    }
    
    var fetchOffset: Int {
        return notifications.count
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
    
    func updateEditModeInViewModels(editMode: Bool) {
        syncNewNotifications(notifications: Array(notifications), editMode: editMode)
    }
}
