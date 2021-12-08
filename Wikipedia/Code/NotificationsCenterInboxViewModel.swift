
import Foundation
import WMF
import UIKit

class NotificationsCenterInboxViewModel: ObservableObject {
    
    class SectionViewModel: Identifiable {
        let id = UUID()
        let header: String
        let footer: String
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
        
        init(title: String, isSelected: Bool, imageName: String?, project: RemoteNotificationsProject, remoteNotificationsController: RemoteNotificationsController) {
            self.title = title
            self.isSelected = isSelected
            self.imageName = imageName
            self.remoteNotificationsController = remoteNotificationsController
            self.project = project
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
    @Published var theme: Theme
    let remoteNotificationsController: RemoteNotificationsController
    let oldStandardAppearance:UINavigationBarAppearance = UINavigationBar.appearance().standardAppearance
    let oldCompactAppearance = UINavigationBar.appearance().standardAppearance
    let oldScrollEdgeAppearance = UINavigationBar.appearance().scrollEdgeAppearance
    let oldTableViewBackgroundColor = UITableView.appearance().backgroundColor
 
    init?(remoteNotificationsController: RemoteNotificationsController, allInboxProjects: Set<RemoteNotificationsProject>, theme: Theme) {
     
        guard let savedState = remoteNotificationsController.filterSavedState else {
            return nil
        }
        
        self.remoteNotificationsController = remoteNotificationsController
        self.theme = theme
        
        let unselectedProjects = Set(savedState.projectsSetting)
        
        let nonLanguageProjects: [RemoteNotificationsProject] = [.commons, .wikidata]
        var appLanguageProjects = allInboxProjects
        appLanguageProjects.remove(.commons)
        appLanguageProjects.remove(.wikidata)
        
        let alphabeticalAppLanguageProjects = Array(appLanguageProjects).sorted { lhs, rhs in
            return lhs.projectName(shouldReturnCodedFormat: false) < rhs.projectName(shouldReturnCodedFormat: false)
        }
        
        let firstSectionItems = nonLanguageProjects.map { ItemViewModel(title: $0.projectName(shouldReturnCodedFormat: false), isSelected: !unselectedProjects.contains($0), imageName: nil, project: $0, remoteNotificationsController: remoteNotificationsController) }
        
        let secondSectionItems = alphabeticalAppLanguageProjects.map { ItemViewModel(title: $0.projectName(shouldReturnCodedFormat: false), isSelected: !unselectedProjects.contains($0), imageName: nil, project: $0, remoteNotificationsController: remoteNotificationsController) }
        
        let firstSection = SectionViewModel(header: "Wikimedia Projects".uppercased(), footer: "Only projects you have created an account for will appear here", items: firstSectionItems)
        let secondSection = SectionViewModel(header: "Wikipedias".uppercased(), footer: "", items: secondSectionItems)
        self.sections = [firstSection, secondSection]
    }
}
