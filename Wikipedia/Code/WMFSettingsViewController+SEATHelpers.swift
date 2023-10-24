import Foundation
import WKData

extension WMFSettingsViewController {
    @objc func generateSEATSampleData() {
        guard let appLanguageSiteURL = dataStore.languageLinkController.appLanguage?.siteURL,
           let project = WikimediaProject(siteURL: appLanguageSiteURL),
              let wkProject = project.wkProject else {
            return
        }
        
        let dataController = WKSEATDataController.shared
        
        dataController.generateSampleData(project: wkProject) {
            
        }
    }
}
