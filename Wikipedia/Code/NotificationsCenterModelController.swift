
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
    
    private weak var delegate: NotificationsCenterModelControllerDelegate?
    
    init(languageLinkController: MWKLanguageLinkController, delegate: NotificationsCenterModelControllerDelegate?) {
        self.languageLinkController = languageLinkController
        self.delegate = delegate
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
        
        let viewModelsToUpdate: [NotificationsCenterCellViewModel] = updatedNotifications.compactMap { notification in
            
            guard let key = notification.key else {
                return nil
            }
            
            return cellViewModelsDict[key]
            
        }
        
        updateCellDisplayStates(cellViewModels: viewModelsToUpdate, isEditing: isEditing)
        
        if viewModelsToUpdate.count > 0 {
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
    
    func updateCellDisplayStates(cellViewModels: [NotificationsCenterCellViewModel], isEditing: Bool, isSelected: Bool? = nil) {
        var dataChanged = false
        
        cellViewModels.forEach { cellViewModel in
            
            let oldDisplayState = cellViewModel.displayState
            cellViewModel.updateDisplayState(isEditing: isEditing, isSelected: isSelected)
            if cellViewModel.displayState != oldDisplayState {
                    dataChanged = true
            }
        }
        
        if dataChanged {
            delegate?.dataDidChange()
        }
    }
}
