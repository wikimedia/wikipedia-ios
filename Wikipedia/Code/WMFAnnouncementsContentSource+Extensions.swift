import Foundation
import WMFData

extension WMFAnnouncementsContentSource {
    @objc func fetchMediaWikiBannerOptInForSiteURL(_ siteURL: URL) {
        let dataController = WMFFundraisingCampaignDataController.shared
        let wikimediaProject = WikimediaProject(siteURL: siteURL)
        guard let wkProject = wikimediaProject?.wkProject else {
            return
        }
        
        dataController.fetchMediaWikiBannerOptIn(project: wkProject)
        
    }
}
