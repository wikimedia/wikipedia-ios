
import Foundation
import WMF

protocol NotificationsCenterFiltersItemViewModelDelegate: AnyObject {
    func setFilterReadStatus(newReadStatus: RemoteNotificationsFiltersSavedState.ReadStatus)
    func appendFilterType(_ type: RemoteNotificationType)
    func removeFilterType(_ type: RemoteNotificationType)
}

class NotificationsCenterFiltersViewModel: ObservableObject, NotificationsCenterFiltersItemViewModelDelegate {
    
    class SectionViewModel: Identifiable {
        let id = UUID()
        let title: String
        let items: [ItemViewModel]
        
        init(title: String, items: [ItemViewModel]) {
            self.title = title
            self.items = items
        }
    }
    
    class ItemViewModel: ObservableObject, Identifiable {
        
        enum SelectionType {
            case checkmark(RemoteNotificationsFiltersSavedState.ReadStatus)
            case toggle(RemoteNotificationType)
        }
        
        let id = UUID()
        let title: String
        let selectionType: SelectionType
        weak var delegate: NotificationsCenterFiltersItemViewModelDelegate? = nil
        let didUpdateFiltersCallback: () -> Void
        
        @Published var isSelected: Bool {
            didSet {
                //todo: this will get called too much. look into only calling this when entire modal is about to be dismissed
                didUpdateFiltersCallback()
                
                switch selectionType {
                case .toggle:
                    toggleSelectionForToggleType()
                case .checkmark:
                    //toggleSelectionForCheckmarkType is called directly from View rather than from isSelected property observer.
                    break
                }
            }
        }
        
        init(title: String, selectionType: SelectionType, isSelected: Bool,  didUpdateFiltersCallback: @escaping () -> Void) {
            self.title = title
            self.selectionType = selectionType
            self.isSelected = isSelected
            self.didUpdateFiltersCallback = didUpdateFiltersCallback
        }
        
        func toggleSelectionForCheckmarkType() {
            //note, this is called directly from view instead of isSelected property observer. because setFilterReadStatus resets the OTHER view models isSelected status, the property observer calling this method caused an infinite loop.
            
            //do not allow a selected status to be deselected
            guard !isSelected else {
                return
            }
            
            switch selectionType {
            case .checkmark(let newReadStatus):
                delegate?.setFilterReadStatus(newReadStatus: newReadStatus)
                isSelected.toggle()
            case .toggle:
                break
            }
        }
        
        func toggleSelectionForToggleType() {
            switch selectionType {
            case .checkmark:
                break
            case .toggle(let type):
                if isSelected {
                    delegate?.removeFilterType(type)
                } else {
                    delegate?.appendFilterType(type)
                }
                
            }
        }
        
    }
    
    let sections: [SectionViewModel]
    let remoteNotificationsController: RemoteNotificationsController
    let theme: Theme
    let didUpdateFiltersCallback: () -> Void
 
    init?(remoteNotificationsController: RemoteNotificationsController, theme: Theme, didUpdateFiltersCallback: @escaping () -> Void) {
        
        guard let savedState = remoteNotificationsController.filterSavedState else {
            return nil
        }
     
        self.remoteNotificationsController = remoteNotificationsController
        self.theme = theme
        self.didUpdateFiltersCallback = didUpdateFiltersCallback
        
        let items1 = RemoteNotificationsFiltersSavedState.ReadStatus.allCases.map {
            
            return ItemViewModel(title: $0.title, selectionType: .checkmark($0), isSelected: $0 == savedState.readStatusSetting, didUpdateFiltersCallback: didUpdateFiltersCallback)
            
        }
        
        let section1 = SectionViewModel(title: "Read Status", items: items1)
        
        let items2: [ItemViewModel] = RemoteNotificationType.orderingForFilters.compactMap {
            
            guard let title = $0.title else {
                return nil
            }
            
            let isSelected = !savedState.filterTypeSetting.contains($0)
            return ItemViewModel(title: title, selectionType:.toggle($0), isSelected: isSelected, didUpdateFiltersCallback: didUpdateFiltersCallback)
            
        }
        
        let section2 = SectionViewModel(title: "Types of notifications", items: items2)
        
        self.sections = [section1, section2]
        
        let itemViewModels = [section1.items, section2.items].flatMap { $0 }
        itemViewModels.forEach { $0.delegate = self }
    }
    
    func setFilterReadStatus(newReadStatus: RemoteNotificationsFiltersSavedState.ReadStatus) {
        
        guard let currentSavedState = remoteNotificationsController.filterSavedState else {
            return
        }
        
        let newSavedState = RemoteNotificationsFiltersSavedState(readStatusSetting: newReadStatus, filterTypeSetting: currentSavedState.filterTypeSetting, projectsSetting: currentSavedState.projectsSetting)
        remoteNotificationsController.filterSavedState = newSavedState
        
        guard let readStatusSection = sections[safeIndex: 0] else {
            return
        }
        
        for itemViewModel in readStatusSection.items {
            switch itemViewModel.selectionType {
            case .checkmark(let readStatus):
                if readStatus != newReadStatus {
                    itemViewModel.isSelected = false
                }
            default:
                break
            }
        }
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


