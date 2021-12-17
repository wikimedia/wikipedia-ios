
import Foundation
import WMF

protocol NotificationsCenterFiltersItemViewModelDelegate: AnyObject {
    func setFilterReadStatus(newReadStatus: RemoteNotificationsFiltersSavedState.ReadStatus)
    func appendFilterType(_ type: RemoteNotificationType)
    func removeFilterType(_ type: RemoteNotificationType)
    func removeAllFilterTypes()
    func appendAllFilterTypes()
}

class NotificationsCenterFiltersViewModel: ObservableObject, NotificationsCenterFiltersItemViewModelDelegate {
    
    
    class SectionViewModel: Identifiable {
        let id = UUID()
        let title: String?
        let footer: String?
        let items: [ItemViewModel]
        
        init(title: String?, footer: String?, items: [ItemViewModel]) {
            self.title = title
            self.footer = footer
            self.items = items
        }
    }
    
    class ItemViewModel: ObservableObject, Identifiable {
        
        enum SelectionType {
            case checkmark(RemoteNotificationsFiltersSavedState.ReadStatus)
            case toggleAll
            case toggle(RemoteNotificationType)
        }
        
        let id = UUID()
        let title: String
        let selectionType: SelectionType
        weak var delegate: NotificationsCenterFiltersItemViewModelDelegate? = nil
        
        @Published var isSelected: Bool
        
        init(title: String, selectionType: SelectionType, isSelected: Bool) {
            self.title = title
            self.selectionType = selectionType
            self.isSelected = isSelected
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
            case .toggle, .toggleAll:
                break
            }
        }
        
        func toggleSelectionForAll() {
            
            //note, this is called directly from view instead of isSelected property observer. because appendAllFilterTypes/removeAllFilterTypes resets the OTHER view models isSelected status, the property observer calling this method will cause an infinite loop.
            
            switch selectionType {
            case .toggleAll:
                if isSelected {
                    delegate?.removeAllFilterTypes()
                } else {
                    delegate?.appendAllFilterTypes()
                }
            case .toggle, .checkmark:
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
            case .toggleAll:
                break
            }
        }
        
    }
    
    let sections: [SectionViewModel]
    let remoteNotificationsController: RemoteNotificationsController
    let theme: Theme
 
    init?(remoteNotificationsController: RemoteNotificationsController, theme: Theme) {
        
        guard let savedState = remoteNotificationsController.filterSavedState else {
            return nil
        }
     
        self.remoteNotificationsController = remoteNotificationsController
        self.theme = theme
        
        let items1 = RemoteNotificationsFiltersSavedState.ReadStatus.allCases.map {
            
            return ItemViewModel(title: $0.title, selectionType: .checkmark($0), isSelected: $0 == savedState.readStatusSetting)
            
        }
        
        let section1 = SectionViewModel(title: "Read Status", footer: nil, items: items1)
        
        let item2 = ItemViewModel(title: "All types", selectionType: .toggleAll, isSelected: savedState.filterTypeSetting.count == 0)

        let section2 = SectionViewModel(title: "Types of notifications", footer: "Modify notification types to filter them in/out of your notification inbox. Types that are turned off will not be visible, but their content and any new notifications will be available when the toggle is turned on again.", items: [item2])
        
        let items3: [ItemViewModel] = RemoteNotificationType.orderingForFilters.compactMap {
            
            guard let title = $0.title else {
                return nil
            }
            
            let isSelected = !savedState.filterTypeSetting.contains($0)
            return ItemViewModel(title: title, selectionType:.toggle($0), isSelected: isSelected)
            
        }
        
        let section3 = SectionViewModel(title: nil, footer: nil, items: items3)
        
        self.sections = [section1, section2, section3]
        
        let itemViewModels = [section1.items, section2.items, section3.items].flatMap { $0 }
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
                } else {
                    itemViewModel.isSelected = true
                }
            default:
                break
            }
        }
    }
    
    func removeAllFilterTypes() {
        
        guard let filterTypeSection = sections[safeIndex: 2] else {
            return
        }
        
        for itemViewModel in filterTypeSection.items {
            switch itemViewModel.selectionType {
            case .toggle:
                itemViewModel.isSelected = true
            default:
                break
            }
        }
        
        guard let currentSavedState = remoteNotificationsController.filterSavedState else {
            return
        }
        
        let newSavedState = RemoteNotificationsFiltersSavedState(readStatusSetting: currentSavedState.readStatusSetting, filterTypeSetting: [], projectsSetting: currentSavedState.projectsSetting)
        remoteNotificationsController.filterSavedState = newSavedState
    }
    
    func appendAllFilterTypes() {
        
        guard let filterTypeSection = sections[safeIndex: 2] else {
            return
        }

        for itemViewModel in filterTypeSection.items {
            switch itemViewModel.selectionType {
            case .toggle:
                itemViewModel.isSelected = false
            default:
                break
            }
        }
        
        guard let currentSavedState = remoteNotificationsController.filterSavedState else {
            return
        }
        
        let newSavedState = RemoteNotificationsFiltersSavedState(readStatusSetting: currentSavedState.readStatusSetting, filterTypeSetting: RemoteNotificationType.orderingForFilters, projectsSetting: currentSavedState.projectsSetting)
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
        
        guard let allTypeSection = sections[safeIndex: 1],
        let allTypeItem = allTypeSection.items.first else {
            return
        }
        
        allTypeItem.isSelected = false
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
        
        if newFilterTypeSetting.count == 0 {
            
            guard let allTypeSection = sections[safeIndex: 1],
                  let allTypeItem = allTypeSection.items.first else {
                return
            }
            
            allTypeItem.isSelected = true
            
        }
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


