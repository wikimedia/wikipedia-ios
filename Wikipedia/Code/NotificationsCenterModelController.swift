
import Foundation
import WMF

protocol NotificationsCenterModelControllerDelegate: AnyObject {
    func reconfigureCellsWithViewModelsIfNeeded(cellViewModels: [NotificationsCenterCellViewModel])
}

//Keeps track of the RemoteNotification managed objects and NotificationCenterCellViewModels that power Notification Center in a performant way
final class NotificationsCenterModelController {
    
    typealias RemoteNotificationKey = String

    private var cellViewModelsDict: [RemoteNotificationKey: NotificationsCenterCellViewModel] = [:]
    private var cellViewModels: Set<NotificationsCenterCellViewModel> = []
    
    weak var delegate: NotificationsCenterModelControllerDelegate?
    private let languageLinkController: MWKLanguageLinkController
    
    init(languageLinkController: MWKLanguageLinkController, delegate: NotificationsCenterModelControllerDelegate?) {
        self.delegate = delegate
        self.languageLinkController = languageLinkController
    }
    
    func addNewCellViewModelsWith(notifications: [RemoteNotification]) {
        for notification in notifications {

            //Instantiate new view model and insert it into tracking properties
            
            guard let key = notification.key,
                  let newCellViewModel = NotificationsCenterCellViewModel(notification: notification, languageLinkController: languageLinkController) else {
                continue
            }
            
            cellViewModelsDict[key] = newCellViewModel
            cellViewModels.insert(newCellViewModel)
        }
    }
    
    func updateCurrentCellViewModelsWith(updatedNotifications: [RemoteNotification]? = nil) {

        let cellViewModelsToUpdate: [NotificationsCenterCellViewModel]
        
        if let updatedNotifications = updatedNotifications {
            
            //Find existing cell view models via tracking properties
            cellViewModelsToUpdate = updatedNotifications.compactMap { notification in
                
                guard let key = notification.key else {
                    return nil
                }
                
                return cellViewModelsDict[key]
                
            }
            
        } else {
            cellViewModelsToUpdate = Array(cellViewModels)
        }
        
        delegate?.reconfigureCellsWithViewModelsIfNeeded(cellViewModels: cellViewModelsToUpdate)
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
    
    func updateCellDisplayStates(cellViewModels: [NotificationsCenterCellViewModel]?, isEditing: Bool, isSelected: Bool) {
        
        let viewModelsToUpdate = cellViewModels ?? Array(self.cellViewModels)
        
        viewModelsToUpdate.forEach { cellViewModel in
            cellViewModel.updateDisplayState(isEditing: isEditing, isSelected: isSelected)
        }
    }
}
