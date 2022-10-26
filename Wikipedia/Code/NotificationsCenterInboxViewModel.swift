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
        let iconName: String?
        let project: WikimediaProject
        let remoteNotificationsController: RemoteNotificationsController
        
        init(title: String, isSelected: Bool, iconName: String?, project: WikimediaProject, remoteNotificationsController: RemoteNotificationsController) {
            self.title = title
            self.isSelected = isSelected
            self.iconName = iconName
            self.remoteNotificationsController = remoteNotificationsController
            self.project = project
        }
        
        private func appendProjectToFilter(_ project: WikimediaProject) {
            
            let currentFilterState = remoteNotificationsController.filterState
            
            var newProjects = currentFilterState.offProjects
            newProjects.insert(project)
            
            let newFilterState = RemoteNotificationsFilterState(readStatus: currentFilterState.readStatus, offTypes: currentFilterState.offTypes, offProjects: newProjects)
            remoteNotificationsController.filterState = newFilterState
        }
        
        private func removeProjectFromFilter(_ project: WikimediaProject) {
            
            let currentFilterState = remoteNotificationsController.filterState
            
            var newProjects = currentFilterState.offProjects
            newProjects.remove(project)
            
            let newFilterState = RemoteNotificationsFilterState(readStatus: currentFilterState.readStatus, offTypes: currentFilterState.offTypes, offProjects: newProjects)
            remoteNotificationsController.filterState = newFilterState
        }
    }
    
    let sections: [SectionViewModel]
    @Published var theme: Theme
    let remoteNotificationsController: RemoteNotificationsController
 
    init?(remoteNotificationsController: RemoteNotificationsController, allInboxProjects: Set<WikimediaProject>, theme: Theme) {
     
        let filterState = remoteNotificationsController.filterState
        
        self.remoteNotificationsController = remoteNotificationsController
        self.theme = theme
        
        let unselectedProjects = Set(filterState.offProjects)
        
        let nonLanguageProjects = allInboxProjects.filter { project in
            switch project {
            case .wikipedia:
                return false
            default:
                return true
            }
        }
        
        let appLanguageProjects = allInboxProjects.filter { project in
            switch project {
            case .wikipedia:
                return true
            default:
                return false
            }
        }
        
        let alphabeticalAppLanguageProjects = Array(appLanguageProjects).sorted { lhs, rhs in
            return lhs.projectName(shouldReturnCodedFormat: false) < rhs.projectName(shouldReturnCodedFormat: false)
        }
        
        let firstSectionItems = nonLanguageProjects.map { ItemViewModel(title: $0.projectName(shouldReturnCodedFormat: false), isSelected: !unselectedProjects.contains($0), iconName: $0.projectIconName, project: $0, remoteNotificationsController: remoteNotificationsController) }
        
        let secondSectionItems = alphabeticalAppLanguageProjects.map { ItemViewModel(title: $0.projectName(shouldReturnCodedFormat: false), isSelected: !unselectedProjects.contains($0), iconName: nil, project: $0, remoteNotificationsController: remoteNotificationsController) }
        
        let wikipediasSectionTitle = WMFLocalizedString("notifications-center-inbox-wikipedias-section-title", value: "Wikipedias", comment: "Title of the \"Wikipedias\" section on the notifications center inbox view. This section allows the user to remove certain Wikipedia language projects from displaying in their Notifications Center.")
        let wikimediaProjectsSectionTitle = WMFLocalizedString("notifications-center-inbox-wikimedia-projects-section-title", value: "Wikimedia Projects", comment: "Title of the \"Wikimedia Projects\" section on the notifications center inbox view. This section allows the user to remove other (non-Wikipedia) Wikimedia projects from displaying in their Notifications Center.")
        let wikimediaProjectsSectionFooter = WMFLocalizedString("notifications-center-inbox-wikimedia-projects-section-footer", value: "Only projects you have created an account for will appear here", comment: "Footer of the \"Wikimedia Projects\" section on the notifications center inbox view. This section only lists projects that user has an account at.")
        
        let firstSection = SectionViewModel(header: wikimediaProjectsSectionTitle.uppercased(with: NSLocale.current), footer: wikimediaProjectsSectionFooter, items: firstSectionItems)
        let secondSection = SectionViewModel(header: wikipediasSectionTitle.uppercased(with: NSLocale.current), footer: "", items: secondSectionItems)
        self.sections = [firstSection, secondSection]
    }
}
