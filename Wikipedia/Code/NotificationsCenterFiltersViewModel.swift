
import Foundation
import WMF

struct NotificationsCenterFiltersViewModel {
    
    struct SectionViewModel {
        let title: String
        let items: [ItemViewModel]
    }
    
    struct ItemViewModel {
        
        enum SelectionType {
            case checkmark
            case toggle
        }
        
        let title: String
        let selectionType: SelectionType
        let isSelected: Bool
        //todo: must be one or the other. clean up.
        let readStatus: RemoteNotificationsFiltersSavedState.ReadStatus?
        let type: RemoteNotificationType?
    }
    
    let sections: [SectionViewModel]
    let remoteNotificationsController: RemoteNotificationsController
 
    init?(remoteNotificationsController: RemoteNotificationsController) {
        
        guard let savedState = remoteNotificationsController.filterSavedState else {
            return nil
        }
     
        self.remoteNotificationsController = remoteNotificationsController
        
        let items1 = RemoteNotificationsFiltersSavedState.ReadStatus.allCases.map {
            
            return ItemViewModel(title: $0.title, selectionType: .checkmark, isSelected: $0 == savedState.readStatusSetting, readStatus: $0, type: nil)
            
        }
        
        let section1 = SectionViewModel(title: "Read Status", items: items1)
        
        let items2: [ItemViewModel] = RemoteNotificationType.orderingForFilters.compactMap {
            
            guard let title = $0.title else {
                return nil
            }
            
            let isSelected = !savedState.filterTypeSetting.contains($0)
            return ItemViewModel(title: title, selectionType:.toggle, isSelected: isSelected, readStatus: nil, type: $0)
            
        }
        
        let section2 = SectionViewModel(title: "Types of notifications", items: items2)
        
        self.sections = [section1, section2]
    }
    
    func setFilterReadStatus(newReadStatus: RemoteNotificationsFiltersSavedState.ReadStatus) {
        
        guard let currentSavedState = remoteNotificationsController.filterSavedState else {
            return
        }
        
        let newSavedState = RemoteNotificationsFiltersSavedState(readStatusSetting: newReadStatus, filterTypeSetting: currentSavedState.filterTypeSetting, projectsSetting: currentSavedState.projectsSetting)
        remoteNotificationsController.filterSavedState = newSavedState
    }
    
    func appendFilterType(_ type: RemoteNotificationType) {
        guard let currentSavedState = remoteNotificationsController.filterSavedState else {
            return
        }
        
        var newFilterTypeSetting = currentSavedState.filterTypeSetting
        newFilterTypeSetting.append(type)
        
        let newSavedState = RemoteNotificationsFiltersSavedState(readStatusSetting: currentSavedState.readStatusSetting, filterTypeSetting: newFilterTypeSetting, projectsSetting: currentSavedState.projectsSetting)
        remoteNotificationsController.filterSavedState = newSavedState
    }
    
    func removeFilterType(_ type: RemoteNotificationType) {
        
        guard let currentSavedState = remoteNotificationsController.filterSavedState else {
            return
        }
        
        var newFilterTypeSetting = currentSavedState.filterTypeSetting
        newFilterTypeSetting.removeAll { loopType in
            return loopType == type
        }
        
        let newSavedState = RemoteNotificationsFiltersSavedState(readStatusSetting: currentSavedState.readStatusSetting, filterTypeSetting: newFilterTypeSetting, projectsSetting: currentSavedState.projectsSetting)
        remoteNotificationsController.filterSavedState = newSavedState
    }
}

extension RemoteNotificationsFiltersSavedState.ReadStatus {
    var title: String {
        switch self {
        case .all: return "All"
        case .unread: return "Unread"
        case .read: return "Read"
        }
    }
}


