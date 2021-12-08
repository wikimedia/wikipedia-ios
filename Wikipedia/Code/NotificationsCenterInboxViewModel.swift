
import Foundation
import WMF

class NotificationsCenterInboxViewModel: ObservableObject {
    
    class SectionViewModel: Identifiable {
        let id = UUID()
        let header: String
        let footer: String?
        let items: [ItemViewModel]
        
        init(header: String, footer: String, items: [ItemViewModel]) {
            self.header = header
            self.footer = footer
            self.items = items
        }
    }
    
    class ItemViewModel: ObservableObject, Identifiable {
                
        let id = UUID()
        let title: String
        @Published var isSelected: Bool {
            didSet {
                if isSelected {
                    removeProjectFromFilter(self.project)
                } else {
                    appendProjectToFilter(self.project)
                }
            }
        }
        let imageName: String?
        let project: RemoteNotificationsProject
        let remoteNotificationsController: RemoteNotificationsController
        let allInboxProjects: Set<RemoteNotificationsProject>
        
        init(title: String, isSelected: Bool, imageName: String?, project: RemoteNotificationsProject, remoteNotificationsController: RemoteNotificationsController, allInboxProjects: Set<RemoteNotificationsProject>) {
            self.title = title
            self.isSelected = isSelected
            self.imageName = imageName
            self.remoteNotificationsController = remoteNotificationsController
            self.project = project
            self.allInboxProjects = allInboxProjects
        }
        
        private func appendProjectToFilter(_ project: RemoteNotificationsProject) {
            guard let currentSavedState = remoteNotificationsController.filterSavedState else {
                return
            }
            
            var newProjectsSetting = currentSavedState.projectsSetting
            newProjectsSetting.append(project)
            
            let newSavedState = RemoteNotificationsFiltersSavedState(readStatusSetting: currentSavedState.readStatusSetting, filterTypeSetting: currentSavedState.filterTypeSetting, projectsSetting: newProjectsSetting)
            remoteNotificationsController.filterSavedState = newSavedState
        }
        
        private func removeProjectFromFilter(_ project: RemoteNotificationsProject) {
            
            guard let currentSavedState = remoteNotificationsController.filterSavedState else {
                return
            }
            
            var newProjectsSetting = currentSavedState.projectsSetting
            newProjectsSetting.removeAll { loopProject in
                return loopProject == project
            }
            
            let newSavedState = RemoteNotificationsFiltersSavedState(readStatusSetting: currentSavedState.readStatusSetting, filterTypeSetting: currentSavedState.filterTypeSetting, projectsSetting: newProjectsSetting)
            remoteNotificationsController.filterSavedState = newSavedState
        }
    }
    
    let sections: [SectionViewModel]
    let remoteNotificationsController: RemoteNotificationsController
 
    init?(remoteNotificationsController: RemoteNotificationsController, allInboxProjects: Set<RemoteNotificationsProject>) {
     
        guard let savedState = remoteNotificationsController.filterSavedState else {
            return nil
        }
        
        self.remoteNotificationsController = remoteNotificationsController
        
        let unselectedProjects = Set(savedState.projectsSetting)
        
        let items = allInboxProjects.map { ItemViewModel(title: $0.projectName(shouldReturnCodedFormat: false), isSelected: !unselectedProjects.contains($0), imageName: nil, project: $0, remoteNotificationsController: remoteNotificationsController, allInboxProjects: allInboxProjects) }
        let section = SectionViewModel(header: "Header text", footer: "Footer text", items: items)
        self.sections = [section]
    }
}
