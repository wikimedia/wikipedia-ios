import Foundation
import WMF

protocol NotificationsCenterFiltersItemViewModelDelegate: AnyObject {
    func setFilterReadStatus(newReadStatus: RemoteNotificationsFilterState.ReadStatus)
    func appendFilterType(_ type: RemoteNotificationFilterType)
    func removeFilterType(_ type: RemoteNotificationFilterType)
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
            case checkmark(RemoteNotificationsFilterState.ReadStatus)
            case toggleAll
            case toggle(RemoteNotificationFilterType)
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
            // note, this is called directly from view instead of isSelected property observer. because setFilterReadStatus resets the OTHER view models isSelected status, the property observer calling this method caused an infinite loop.
            
            // do not allow a selected status to be deselected
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
            
            // note, this is called directly from view instead of isSelected property observer. because appendAllFilterTypes/removeAllFilterTypes resets the OTHER view models isSelected status, the property observer calling this method will cause an infinite loop.
            
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
        
        let filterState = remoteNotificationsController.filterState
     
        self.remoteNotificationsController = remoteNotificationsController
        self.theme = theme
        
        let items1 = RemoteNotificationsFilterState.ReadStatus.allCases.map {
            
            return ItemViewModel(title: $0.title, selectionType: .checkmark($0), isSelected: $0 == filterState.readStatus)
            
        }
        
        let section1 = SectionViewModel(title: WMFLocalizedString("notifications-center-filters-read-status-section-title", value: "Read Status", comment: "Section title of the read status filter controls on the notifications center filter view."), footer: nil, items: items1)
        
        let allTypesItemTitle = WMFLocalizedString("notifications-center-filters-types-item-title-all", value: "All types", comment: "Title of the All types toggle in the notifications center filter view. Selecting this turns on or off all notification type filter toggles.")
        let item2 = ItemViewModel(title: allTypesItemTitle, selectionType: .toggleAll, isSelected: filterState.offTypes.count == 0)

        let typesSectionTitle = WMFLocalizedString("notifications-center-filters-types-section-title", value: "Types of notifications", comment: "Section title of the notification types filter controls on the notifications center filter view.")
        let typesFooter = WMFLocalizedString("notifications-center-filters-types-footer", value: "Modify notification types to filter them in/out of your notification inbox. Types that are turned off will not be visible, but their content and any new notifications will be available when the toggle is turned on again.", comment: "Footer text for the types toggles in the notifications center filter view. Explains how the types toggles work.")
        let section2 = SectionViewModel(title: typesSectionTitle, footer: typesFooter, items: [item2])
        
        let items3: [ItemViewModel] = RemoteNotificationFilterType.orderingForFilters.map {
            let isSelected = !filterState.offTypes.contains($0)
            return ItemViewModel(title: $0.title, selectionType:.toggle($0), isSelected: isSelected)
        }
        
        let section3 = SectionViewModel(title: nil, footer: nil, items: items3)
        
        self.sections = [section1, section2, section3]
        
        let itemViewModels = [section1.items, section2.items, section3.items].flatMap { $0 }
        itemViewModels.forEach { $0.delegate = self }
    }
    
    func setFilterReadStatus(newReadStatus: RemoteNotificationsFilterState.ReadStatus) {
        
        let currentFilterState = remoteNotificationsController.filterState
        
        let newFilterState = RemoteNotificationsFilterState(readStatus: newReadStatus, offTypes: currentFilterState.offTypes, offProjects: currentFilterState.offProjects)
        remoteNotificationsController.filterState = newFilterState
        
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
        
        let currentFilterState = remoteNotificationsController.filterState
        
        let newFilterState = RemoteNotificationsFilterState(readStatus: currentFilterState.readStatus, offTypes: [], offProjects: currentFilterState.offProjects)
        remoteNotificationsController.filterState = newFilterState
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
        
        let currentFilterState = remoteNotificationsController.filterState
        
        let newFilterState = RemoteNotificationsFilterState(readStatus: currentFilterState.readStatus, offTypes: Set(RemoteNotificationFilterType.orderingForFilters), offProjects: currentFilterState.offProjects)
        remoteNotificationsController.filterState = newFilterState
    }
    
    func appendFilterType(_ type: RemoteNotificationFilterType) {

        let currentFilterState = remoteNotificationsController.filterState
        
        var newTypes = currentFilterState.offTypes
        newTypes.insert(type)
        
        let newFilterState = RemoteNotificationsFilterState(readStatus: currentFilterState.readStatus, offTypes: newTypes, offProjects: currentFilterState.offProjects)
        remoteNotificationsController.filterState = newFilterState
        
        guard let allTypeSection = sections[safeIndex: 1],
        let allTypeItem = allTypeSection.items.first else {
            return
        }
        
        allTypeItem.isSelected = false
    }
    
    func removeFilterType(_ type: RemoteNotificationFilterType) {
        
        let currentFilterState = remoteNotificationsController.filterState
        
        var newTypes = currentFilterState.offTypes
        newTypes.remove(type)
        
        let newFilterState = RemoteNotificationsFilterState(readStatus: currentFilterState.readStatus, offTypes: newTypes, offProjects: currentFilterState.offProjects)
        remoteNotificationsController.filterState = newFilterState
        
        if newTypes.count == 0 {
            
            guard let allTypeSection = sections[safeIndex: 1],
                  let allTypeItem = allTypeSection.items.first else {
                return
            }
            
            allTypeItem.isSelected = true
            
        }
    }
}

extension RemoteNotificationsFilterState.ReadStatus {
    var title: String {
        switch self {
        case .all:
            return WMFLocalizedString("notifications-center-filters-read-status-item-title-all", value: "All", comment: "Title of All option in the read status section of the notifications center filter view. Selecting this allows all read statuses to display in the notifications center.")
        case .unread:
            return WMFLocalizedString("notifications-center-filters-read-status-item-title-unread", value: "Unread", comment: "Title of Unread option in the read status section of the notifications center filter view. Selecting this only displays unread notifications in the notifications center.")
        case .read:
            return WMFLocalizedString("notifications-center-filters-read-status-item-title-read", value: "Read", comment: "Title of Read option in the read status section of the notifications center filter view. Selecting this only displays read notifications in the notifications center.")
        }
    }
}
