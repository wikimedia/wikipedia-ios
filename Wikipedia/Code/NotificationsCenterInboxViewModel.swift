import Foundation
import WMF
import UIKit
import WMFComponents
import Combine

class NotificationsCenterInboxViewModel: ObservableObject {
    
    @Published var theme: Theme
    let remoteNotificationsController: RemoteNotificationsController
    let formViewModel: WMFFormViewModel
    private var subscribers: Set<AnyCancellable> = []
 
    init?(remoteNotificationsController: RemoteNotificationsController, allInboxProjects: Set<WikimediaProject>, theme: Theme) {
     
        self.theme = theme
        let filterState = remoteNotificationsController.filterState
        
        self.remoteNotificationsController = remoteNotificationsController
        
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
        
        let firstSectionItems: [WMFFormItemSelectViewModel] = nonLanguageProjects.compactMap {
            
            guard let projectIconName = $0.projectIconName else {
                return nil
            }
            
            let item = WMFFormItemSelectViewModel.init(image: UIImage(named: projectIconName), title: $0.projectName(shouldReturnCodedFormat: false), isSelected: !unselectedProjects.contains($0))
            
            return item
        }
        
        let secondSectionItems: [WMFFormItemSelectViewModel] = alphabeticalAppLanguageProjects.compactMap {
            
            let item = WMFFormItemSelectViewModel.init(image: nil, title: $0.projectName(shouldReturnCodedFormat: false), isSelected: !unselectedProjects.contains($0))
            
            return item
            
        }
        
        let wikipediasSectionTitle = CommonStrings.wikipediasHeader
        let wikimediaProjectsSectionTitle = CommonStrings.wikimediaProjectsHeader
        let wikimediaProjectsSectionFooter = CommonStrings.wikimediaProjectsFooter
        
        let firstSection = WMFFormSectionSelectViewModel(header: wikimediaProjectsSectionTitle.uppercased(with: NSLocale.current), footer: wikimediaProjectsSectionFooter, items: firstSectionItems, selectType: .multi)
        let secondSection = WMFFormSectionSelectViewModel(header: wikipediasSectionTitle.uppercased(with: NSLocale.current), items: secondSectionItems, selectType: .multi)

        self.formViewModel = WMFFormViewModel(sections: [firstSection, secondSection])
        
        for (project, sectionItem) in zip(nonLanguageProjects, firstSectionItems) {

            sectionItem.$isSelected.sink { [weak self] isSelected in

                if isSelected {
                    self?.removeProjectFromFilter(project)
                } else {
                    self?.appendProjectToFilter(project)
                }

            }.store(in: &subscribers)
        }
        
        for (project, sectionItem) in zip(alphabeticalAppLanguageProjects, secondSectionItems) {

            sectionItem.$isSelected.sink { [weak self] isSelected in

                if isSelected {
                    self?.removeProjectFromFilter(project)
                } else {
                    self?.appendProjectToFilter(project)
                }

            }.store(in: &subscribers)
        }
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
